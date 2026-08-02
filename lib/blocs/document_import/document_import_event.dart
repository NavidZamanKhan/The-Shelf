import 'package:equatable/equatable.dart';

abstract class DocumentImportEvent extends Equatable {
  const DocumentImportEvent();

  @override
  List<Object?> get props => [];
}

class PickAndExtractPdfEvent extends DocumentImportEvent {
  const PickAndExtractPdfEvent();
}

class ResetImportEvent extends DocumentImportEvent {
  const ResetImportEvent();
}
