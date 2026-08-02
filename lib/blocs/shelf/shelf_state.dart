import 'package:equatable/equatable.dart';

class ShelfItem extends Equatable {
  final String id;
  final String title;
  final String shelf;
  final String filePath;
  final DateTime addedAt;

  const ShelfItem({
    required this.id,
    required this.title,
    required this.shelf,
    required this.filePath,
    required this.addedAt,
  });

  @override
  List<Object?> get props => [id, title, shelf, filePath, addedAt];
}

abstract class ShelfState extends Equatable {
  const ShelfState();

  @override
  List<Object?> get props => [];
}

class ShelfInitial extends ShelfState {
  const ShelfInitial();
}

class ShelfLoading extends ShelfState {
  const ShelfLoading();
}

class ShelfLoaded extends ShelfState {
  final List<ShelfItem> items;
  final String activeFilter;

  const ShelfLoaded({
    required this.items,
    this.activeFilter = 'All Items',
  });

  @override
  List<Object?> get props => [items, activeFilter];
}

class ShelfError extends ShelfState {
  final String errorMessage;

  const ShelfError(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
