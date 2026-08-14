import 'package:flutter_test/flutter_test.dart';
import 'package:the_shelf/models/imported_document_summary.dart';
import 'package:the_shelf/services/ocr_service.dart';
import 'package:the_shelf/services/shelf_classifier_service.dart';

void main() {
  group('OcrService needsOcrFallback Tests', () {
    final ocrService = OcrService.instance;

    test('Returns true for empty text', () {
      expect(ocrService.needsOcrFallback(''), isTrue);
      expect(ocrService.needsOcrFallback('   '), isTrue);
    });

    test('Returns true for watermark-only text from scanned PDFs', () {
      // 1. Chatim watermark
      expect(ocrService.needsOcrFallback('https://boierpathshala.blogspot.com'), isTrue);

      // 2. Quran commentary watermark repetition
      const quranWatermark = 'www.icsbook.info www.icsbook.info www.icsbook.info www.icsbook.info www.icsbook.info';
      expect(ocrService.needsOcrFallback(quranWatermark), isTrue);

      // 3. Shibram Chakraborty PDF builder ad
      const shibramAd = 'Jaha Bahanno by Shibram Chakrabarti For More Books & Muzic Visit www.MurchOna.com MurchOna Forum : http://www.murchona.com/forum suman_ahm@yahoo.com s4suman@yahoo.com Created with an unregistered version of SCP PDF Builder';
      expect(ocrService.needsOcrFallback(shibramAd), isTrue);
    });

    test('Returns false for genuine high-text native PDF', () {
      const lecture8Sample = 'CSE 417: Software Engineering & Design Pattern Lecture 8: Data Flow Diagrams Md. Mushtaq Shahriyar Rafee January 14, 2026 Assistant Professor and Head Department of Data Science Metropolitan University Table of contents 1. Data Flow Diagrams 2. Components of DFD 3. Symbols used in DFD 4. Levels in Data Flow Diagrams (DFD) 1 Data Flow Diagrams Visual representation of the information flows within a system.';
      expect(ocrService.needsOcrFallback(lecture8Sample), isFalse);
    });
  });

  group('ImportedDocumentSummary isLowConfidence Safety Net Tests', () {
    test('Correctly sets isLowConfidence to true when confidence is under 20%', () {
      final summary = ImportedDocumentSummary(
        filePath: '/path/doc.pdf',
        fileName: 'chatim.pdf',
        title: 'Chatim',
        textSnippet: 'https://boierpathshala.blogspot.com',
        classification: ClassificationResult(
          label: 'Miscellaneous',
          confidence: 0.144,
          probabilities: {'Miscellaneous': 0.144, 'Romance': 0.11},
          top3: const [MapEntry('Miscellaneous', 0.144), MapEntry('Romance', 0.11)],
          latencyMs: 0.5,
        ),
      );

      expect(summary.isLowConfidence, isTrue);
    });

    test('Correctly sets isLowConfidence to true when text snippet is under 50 characters', () {
      final summary = ImportedDocumentSummary(
        filePath: '/path/doc.pdf',
        fileName: 'short.pdf',
        title: 'Short Doc',
        textSnippet: 'Short text snippet',
        classification: ClassificationResult(
          label: 'Science Fiction',
          confidence: 0.45,
          probabilities: {'Science Fiction': 0.45},
          top3: const [MapEntry('Science Fiction', 0.45)],
          latencyMs: 0.5,
        ),
      );

      expect(summary.isLowConfidence, isTrue);
    });

    test('Correctly sets isLowConfidence to false when high confidence and rich text exist', () {
      final summary = ImportedDocumentSummary(
        filePath: '/path/doc.pdf',
        fileName: 'lecture8.pdf',
        title: 'Lecture 8',
        textSnippet: 'CSE 417: Software Engineering & Design Pattern Lecture 8: Data Flow Diagrams Md. Mushtaq Shahriyar Rafee January 14, 2026 Assistant Professor and Head Department of Data Science',
        classification: ClassificationResult(
          label: 'School/Reference',
          confidence: 0.43,
          probabilities: {'School/Reference': 0.43, 'Science Fiction': 0.12},
          top3: const [MapEntry('School/Reference', 0.43)],
          latencyMs: 0.5,
        ),
      );

      expect(summary.isLowConfidence, isFalse);
    });
  });
}
