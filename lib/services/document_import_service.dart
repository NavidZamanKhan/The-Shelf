import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:read_pdf_text/read_pdf_text.dart';
import 'package:the_shelf/models/imported_document_summary.dart';
import 'package:the_shelf/services/shelf_classifier_service.dart';

/// Service for picking PDF files, extracting text, and predicting shelf classification.
class DocumentImportService {
  static final DocumentImportService instance = DocumentImportService._internal();
  DocumentImportService._internal();

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

  /// Picks a PDF document, extracts plain text, and runs on-device classification.
  Future<ImportedDocumentSummary?> pickAndExtractPdf({int textLimit = 1000}) async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
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
    final String cleanedTitle = cleanFileName(rawFileName);

    // Extract text using read_pdf_text plugin
    String extractedRawText = '';
    try {
      extractedRawText = await ReadPdfText.getPDFtext(filePath);
    } catch (e) {
      // Fallback if PDF text extraction encounters encrypted or non-text streams
      extractedRawText = '';
    }

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
      filePath: filePath,
      fileName: rawFileName,
      title: cleanedTitle,
      textSnippet: textSnippet,
      classification: classification,
    );
  }
}
