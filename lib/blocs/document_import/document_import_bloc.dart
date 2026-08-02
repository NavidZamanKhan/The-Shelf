import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_shelf/blocs/document_import/document_import_event.dart';
import 'package:the_shelf/blocs/document_import/document_import_state.dart';
import 'package:the_shelf/services/document_import_service.dart';

class DocumentImportBloc extends Bloc<DocumentImportEvent, DocumentImportState> {
  final DocumentImportService importService;

  DocumentImportBloc({DocumentImportService? importService})
      : importService = importService ?? DocumentImportService.instance,
        super(const DocumentImportInitial()) {
    on<PickAndExtractPdfEvent>(_onPickAndExtractPdf);
    on<ResetImportEvent>(_onResetImport);
  }

  Future<void> _onPickAndExtractPdf(
    PickAndExtractPdfEvent event,
    Emitter<DocumentImportState> emit,
  ) async {
    emit(const DocumentImportLoading());
    try {
      final summary = await importService.pickAndExtractPdf();
      if (summary != null) {
        emit(DocumentImportSuccess(summary));
      } else {
        emit(const DocumentImportInitial());
      }
    } catch (e) {
      emit(DocumentImportFailure(e.toString()));
    }
  }

  void _onResetImport(
    ResetImportEvent event,
    Emitter<DocumentImportState> emit,
  ) {
    emit(const DocumentImportInitial());
  }
}
