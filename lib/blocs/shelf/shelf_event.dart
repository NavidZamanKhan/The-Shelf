import 'package:equatable/equatable.dart';

abstract class ShelfEvent extends Equatable {
  const ShelfEvent();

  @override
  List<Object?> get props => [];
}

class LoadShelfItemsEvent extends ShelfEvent {
  final String? userId;
  const LoadShelfItemsEvent({this.userId});

  @override
  List<Object?> get props => [userId];
}

class ClearShelfEvent extends ShelfEvent {
  const ClearShelfEvent();
}

class AddDocumentToShelfEvent extends ShelfEvent {
  final String? id;
  final String title;
  final String shelf;
  final String filePath;

  const AddDocumentToShelfEvent({
    this.id,
    required this.title,
    required this.shelf,
    required this.filePath,
  });

  @override
  List<Object?> get props => [id, title, shelf, filePath];
}

class DeleteDocumentEvent extends ShelfEvent {
  final String id;

  const DeleteDocumentEvent(this.id);

  @override
  List<Object?> get props => [id];
}
