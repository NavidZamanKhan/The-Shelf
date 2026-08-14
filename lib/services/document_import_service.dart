import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:read_pdf_text/read_pdf_text.dart';
import 'package:the_shelf/models/imported_document_summary.dart';
import 'package:the_shelf/services/shelf_classifier_service.dart';

/// Service for picking PDF and EPUB files, extracting text, and predicting shelf classification.
class DocumentImportService {
  static final DocumentImportService instance = DocumentImportService._internal();
  DocumentImportService._internal();

  /// Copies picked file to permanent application documents directory.
  Future<String> _copyToPermanentStorage(String sourcePath, String rawFileName) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final importsDir = Directory('${docsDir.path}/imports');
      if (!await importsDir.exists()) {
        await importsDir.create(recursive: true);
      }
      final String filename = '${DateTime.now().millisecondsSinceEpoch}_$rawFileName';
      final String permanentPath = '${importsDir.path}/$filename';
      
      final sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        final bytes = await sourceFile.readAsBytes();
        final savedFile = await File(permanentPath).writeAsBytes(bytes, flush: true);
        return savedFile.path;
      }
    } catch (e) {
      // Fallback
    }
    return sourcePath;
  }

  /// Cleans raw file name into a human-readable title.
  String cleanFileName(String fileName) {
    String nameWithoutExt = fileName;
    final int lastDot = fileName.lastIndexOf('.');
    if (lastDot != -1) {
      nameWithoutExt = fileName.substring(0, lastDot);
    }
    // Replace underscores, dashes, and dots with spaces
    String cleaned = nameWithoutExt.replaceAll(RegExp(r'[_.-]+'), ' ');
    // Remove common unwanted download prefixes/suffixes
    cleaned = cleaned.replaceAll(RegExp(r'\b(v\d+|\d+p|pdf|epub|vol\d+)\b', caseSensitive: false), '');
    // Collapse spaces
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned.isEmpty ? fileName : cleaned;
  }

  /// Extracts text and metadata (title, chapter text) from an EPUB file using archive.
  Future<({String? title, String text})> _extractEpubData(String filePath, {int textLimit = 1500}) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      String? extractedTitle;
      final textBuffer = StringBuffer();

      // 1. Search for .opf file for metadata (dc:title, dc:description)
      for (final file in archive) {
        if (file.name.endsWith('.opf')) {
          final content = utf8.decode(file.content as List<int>, allowMalformed: true);
          final titleMatch = RegExp(r'<dc:title[^>]*>(.*?)</dc:title>', caseSensitive: false, dotAll: true).firstMatch(content);
          if (titleMatch != null) {
            final t = titleMatch.group(1)?.trim();
            if (t != null && t.isNotEmpty) {
              extractedTitle = t.replaceAll(RegExp(r'<[^>]*>'), '').trim();
            }
          }
          final descMatch = RegExp(r'<dc:description[^>]*>(.*?)</dc:description>', caseSensitive: false, dotAll: true).firstMatch(content);
          if (descMatch != null) {
            final desc = descMatch.group(1)?.replaceAll(RegExp(r'<[^>]*>'), '') ?? '';
            if (desc.isNotEmpty) {
              textBuffer.write(' ');
              textBuffer.write(desc);
            }
          }
          break;
        }
      }

      // 2. Read chapters (html/xhtml files)
      for (final file in archive) {
        final lowerName = file.name.toLowerCase();
        if (lowerName.endsWith('.xhtml') || lowerName.endsWith('.html') || lowerName.endsWith('.htm')) {
          if (lowerName.contains('nav') || lowerName.contains('toc')) continue;
          
          final content = utf8.decode(file.content as List<int>, allowMalformed: true);
          // Strip HTML tags & scripts & styles
          final cleanHtml = content
              .replaceAll(RegExp(r'<style[^>]*>.*?</style>', caseSensitive: false, dotAll: true), '')
              .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true), '')
              .replaceAll(RegExp(r'<[^>]*>'), ' ')
              .replaceAll('&nbsp;', ' ')
              .replaceAll('&amp;', '&')
              .replaceAll('&lt;', '<')
              .replaceAll('&gt;', '>')
              .replaceAll('&quot;', '"')
              .replaceAll('&#39;', "'")
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();

          if (cleanHtml.isNotEmpty) {
            textBuffer.write(' ');
            textBuffer.write(cleanHtml);
          }

          if (textBuffer.length >= textLimit * 2) {
            break;
          }
        }
      }

      return (title: extractedTitle, text: textBuffer.toString().trim());
    } catch (e) {
      debugPrint('Error extracting EPUB data: $e');
      return (title: null, text: '');
    }
  }

  /// Picks a PDF or EPUB document, extracts plain text, and runs on-device classification.
  Future<ImportedDocumentSummary?> pickAndExtractPdf({int textLimit = 1000}) async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'epub'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      return null; // User cancelled file picker
    }

    final PlatformFile platformFile = result.files.first;
    final String? filePath = platformFile.path;

    if (filePath == null || !File(filePath).existsSync()) {
      throw StateError('Selected file path is invalid or inaccessible.');
    }

    final String rawFileName = platformFile.name;
    final bool isEpub = rawFileName.toLowerCase().endsWith('.epub');

    // Copy file to permanent storage directory so it survives temp folder cleanups
    final String permanentPath = await _copyToPermanentStorage(filePath, rawFileName);

    String extractedRawText = '';
    String? metadataTitle;

    if (isEpub) {
      final epubData = await _extractEpubData(permanentPath, textLimit: textLimit);
      extractedRawText = epubData.text;
      metadataTitle = epubData.title;
    } else {
      // Extract text using read_pdf_text plugin
      try {
        extractedRawText = await ReadPdfText.getPDFtext(permanentPath);
      } catch (e) {
        // Fallback if PDF text extraction encounters encrypted or non-text streams
        extractedRawText = '';
      }
    }

    final String cleanedTitle = (metadataTitle != null && metadataTitle.isNotEmpty)
        ? metadataTitle
        : cleanFileName(rawFileName);

    // Clean extracted body text
    String cleanedBodyText = extractedRawText.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Use placeholder length (1,000 characters)
    String textSnippet = cleanedBodyText;
    if (textSnippet.length > textLimit) {
      textSnippet = textSnippet.substring(0, textLimit);
    }

    // Formulate payload: Title + Text Snippet
    final String classificationPayload = textSnippet.isNotEmpty
        ? '$cleanedTitle $textSnippet'
        : cleanedTitle;

    // Run classification
    final classification = await ShelfClassifierService.instance.classifyAsync(classificationPayload);

    return ImportedDocumentSummary(
      filePath: permanentPath,
      fileName: rawFileName,
      title: cleanedTitle,
      textSnippet: textSnippet,
      classification: classification,
    );
  }
}
