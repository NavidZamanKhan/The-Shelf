import 'package:the_shelf/services/shelf_classifier_service.dart';

/// Container for metadata and classification results of an imported document.
class ImportedDocumentSummary {
  final String filePath;
  final String fileName;
  final String title;
  final String textSnippet;
  final ClassificationResult classification;
  final bool isOcrUsed;
  final bool isLowConfidence;

  ImportedDocumentSummary({
    required this.filePath,
    required this.fileName,
    required this.title,
    required this.textSnippet,
    required this.classification,
    this.isOcrUsed = false,
    bool? isLowConfidence,
  }) : isLowConfidence = isLowConfidence ??
            (textSnippet.trim().length < 50 || classification.confidence < 0.15);
}
