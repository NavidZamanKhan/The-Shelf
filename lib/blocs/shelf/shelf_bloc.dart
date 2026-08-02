import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_shelf/blocs/shelf/shelf_event.dart';
import 'package:the_shelf/blocs/shelf/shelf_state.dart';

class ShelfBloc extends Bloc<ShelfEvent, ShelfState> {
  final List<ShelfItem> _items = [];

  ShelfBloc() : super(const ShelfInitial()) {
    on<LoadShelfItemsEvent>(_onLoadShelfItems);
    on<AddDocumentToShelfEvent>(_onAddDocumentToShelf);
  }

  void _onLoadShelfItems(
    LoadShelfItemsEvent event,
    Emitter<ShelfState> emit,
  ) {
    emit(ShelfLoaded(items: List.unmodifiable(_items)));
  }

  void _onAddDocumentToShelf(
    AddDocumentToShelfEvent event,
    Emitter<ShelfState> emit,
  ) {
    final newItem = ShelfItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: event.title,
      shelf: event.shelf,
      filePath: event.filePath,
      addedAt: DateTime.now(),
    );
    _items.insert(0, newItem);
    emit(ShelfLoaded(items: List.unmodifiable(_items)));
  }
}
