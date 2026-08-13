import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_shelf/blocs/shelf/shelf_event.dart';
import 'package:the_shelf/blocs/shelf/shelf_state.dart';
import 'package:the_shelf/services/document_repository.dart';

class ShelfBloc extends Bloc<ShelfEvent, ShelfState> {
  final DocumentRepository _repository;
  final List<ShelfItem> _items = [];

  ShelfBloc({DocumentRepository? repository})
      : _repository = repository ?? DocumentRepository.instance,
        super(const ShelfLoaded(items: [])) {
    on<LoadShelfItemsEvent>(_onLoadShelfItems);
    on<AddDocumentToShelfEvent>(_onAddDocumentToShelf);
    on<DeleteDocumentEvent>(_onDeleteDocument);
  }

  Future<void> _onLoadShelfItems(
    LoadShelfItemsEvent event,
    Emitter<ShelfState> emit,
  ) async {
    try {
      final dbItems = await _repository.getAllDocuments();
      _items.clear();
      _items.addAll(dbItems);
      emit(ShelfLoaded(items: List.unmodifiable(_items)));
    } catch (e) {
      emit(ShelfError('Failed to load shelf items: ${e.toString()}'));
    }
  }

  Future<void> _onAddDocumentToShelf(
    AddDocumentToShelfEvent event,
    Emitter<ShelfState> emit,
  ) async {
    final newItem = ShelfItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: event.title,
      shelf: event.shelf,
      filePath: event.filePath,
      addedAt: DateTime.now(),
    );

    try {
      await _repository.insertDocument(newItem);
      _items.insert(0, newItem);
      emit(ShelfLoaded(items: List.unmodifiable(_items)));
    } catch (e) {
      emit(ShelfError('Failed to save document to database: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteDocument(
    DeleteDocumentEvent event,
    Emitter<ShelfState> emit,
  ) async {
    try {
      await _repository.deleteDocument(event.id);
      _items.removeWhere((item) => item.id == event.id);
      emit(ShelfLoaded(items: List.unmodifiable(_items)));
    } catch (e) {
      emit(ShelfError('Failed to delete document: ${e.toString()}'));
    }
  }
}
