import 'package:equatable/equatable.dart';

abstract class ShelfEvent extends Equatable {
  const ShelfEvent();

  @override
  List<Object?> get props => [];
}

class LoadShelfItemsEvent extends ShelfEvent {
  const LoadShelfItemsEvent();
}

class AddDocumentToShelfEvent extends ShelfEvent {
  final String title;
  final String shelf;
  final String filePath;

  const AddDocumentToShelfEvent({
    required this.title,
    required this.shelf,
    required this.filePath,
  });

  @override
  List<Object?> get props => [title, shelf, filePath];
}
