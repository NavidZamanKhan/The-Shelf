import 'package:the_shelf/services/shelf_classifier_service.dart';

/// Container for metadata and classification results of an imported document.
class ImportedDocumentSummary {
  final String filePath;
  final String fileName;
  final String title;
  final String textSnippet;
  final ClassificationResult classification;

  ImportedDocumentSummary({
    required this.filePath,
    required this.fileName,
    required this.title,
    required this.textSnippet,
    required this.classification,
  });
}
