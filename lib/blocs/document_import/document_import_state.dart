import 'package:equatable/equatable.dart';
import 'package:the_shelf/models/imported_document_summary.dart';

abstract class DocumentImportState extends Equatable {
  const DocumentImportState();

  @override
  List<Object?> get props => [];
}

class DocumentImportInitial extends DocumentImportState {
  const DocumentImportInitial();
}

class DocumentImportLoading extends DocumentImportState {
  const DocumentImportLoading();
}

class DocumentImportSuccess extends DocumentImportState {
  final ImportedDocumentSummary summary;

  const DocumentImportSuccess(this.summary);

  @override
  List<Object?> get props => [summary];
}

class DocumentImportFailure extends DocumentImportState {
  final String errorMessage;

  const DocumentImportFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
