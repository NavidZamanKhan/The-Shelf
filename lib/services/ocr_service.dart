import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_render/pdf_render.dart';

/// On-device OCR fallback service using PDF page rasterization and Google ML Kit.
class OcrService {
  static final OcrService instance = OcrService._internal();
  OcrService._internal();

  /// Checks if extracted PDF text has insufficient real content and needs OCR fallback.
  bool needsOcrFallback(String rawExtractedText) {
    if (rawExtractedText.trim().isEmpty) return true;

    // 1. Strip URL/Domain patterns, email addresses, and known watermark boilerplate
    final sanitized = rawExtractedText
        .replaceAll(RegExp(r'https?://\S+|www\.\S+', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b[\w\.-]+@[\w\.-]+\.\w{2,}\b'), '')
        .replaceAll(
          RegExp(
            r'\b(bdebooks|pdfdrive|murchona|icsbook|boierpathshala|blogspot|scp-solutions|pdf builder|unregistered version|created with|for more books|muzic|forum|order)\b',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // 2. 80-character threshold for real text content
    return sanitized.length < 80;
  }

  /// Rasterizes up to 3 pages and runs on-device Google ML Kit text recognition.
  Future<String> extractTextFromScannedPdf(
    String filePath, {
    int maxPages = 3,
    int earlyExitCharCount = 600,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    return Future.any([
      _performOcr(filePath, maxPages: maxPages, earlyExitCharCount: earlyExitCharCount),
      Future.delayed(timeout, () {
        debugPrint('[OcrService] OCR timed out after ${timeout.inSeconds}s, returning fallback.');
        return '';
      }),
    ]);
  }

  Future<String> _performOcr(
    String filePath, {
    required int maxPages,
    required int earlyExitCharCount,
  }) async {
    PdfDocument? doc;
    TextRecognizer? textRecognizer;
    final textBuffer = StringBuffer();
    final List<File> tempFiles = [];

    try {
      doc = await PdfDocument.openFile(filePath);
      final int totalPages = doc.pageCount;
      final int pagesToScan = min(totalPages, maxPages);

      if (pagesToScan == 0) return '';

      textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final tempDir = await getTemporaryDirectory();

      for (int pageNum = 1; pageNum <= pagesToScan; pageNum++) {
        final PdfPage page = await doc.getPage(pageNum);

        // Render at 150-200 DPI (approx 2x standard 72 DPI PDF coordinates)
        final int targetWidth = (page.width * 2.0).toInt().clamp(600, 2400);
        final int targetHeight = (page.height * 2.0).toInt().clamp(800, 3200);

        final PdfPageImage pageImage = await page.render(
          width: targetWidth,
          height: targetHeight,
        );

        final ui.Image image = await pageImage.createImageIfNotAvailable();
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final tempFile = File(
            '${tempDir.path}/ocr_${DateTime.now().microsecondsSinceEpoch}_p$pageNum.png',
          );
          await tempFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
          tempFiles.add(tempFile);

          final inputImage = InputImage.fromFilePath(tempFile.path);
          final RecognizedText recognized = await textRecognizer.processImage(inputImage);

          final String pageText = recognized.text
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();

          if (pageText.isNotEmpty) {
            textBuffer.write(' ');
            textBuffer.write(pageText);
          }
        }
        image.dispose();
        pageImage.dispose();

        // Early exit if enough representative text has been gathered
        if (textBuffer.length >= earlyExitCharCount) {
          break;
        }
      }
    } catch (e) {
      debugPrint('[OcrService] OCR extraction encountered an error: $e');
    } finally {
      // Clean up temporary images immediately to preserve device RAM
      for (final f in tempFiles) {
        try {
          if (await f.exists()) {
            await f.delete();
          }
        } catch (_) {}
      }
      try {
        await doc?.dispose();
      } catch (_) {}
      try {
        await textRecognizer?.close();
      } catch (_) {}
    }

    return textBuffer.toString().trim();
  }
}
