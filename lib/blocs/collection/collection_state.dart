import 'package:equatable/equatable.dart';
import 'package:the_shelf/models/collection_model.dart';

abstract class CollectionState extends Equatable {
  const CollectionState();

  @override
  List<Object?> get props => [];
}

class CollectionInitial extends CollectionState {
  const CollectionInitial();
}

class CollectionLoading extends CollectionState {
  const CollectionLoading();
}

class CollectionLoaded extends CollectionState {
  final List<CollectionModel> collections;
  final Map<String, Set<String>> documentCollectionMap;
  final String? notificationMessage;

  const CollectionLoaded({
    required this.collections,
    this.documentCollectionMap = const {},
    this.notificationMessage,
  });

  bool get isAtCap => collections.length >= 20;

  CollectionLoaded copyWith({
    List<CollectionModel>? collections,
    Map<String, Set<String>>? documentCollectionMap,
    String? notificationMessage,
  }) {
    return CollectionLoaded(
      collections: collections ?? this.collections,
      documentCollectionMap: documentCollectionMap ?? this.documentCollectionMap,
      notificationMessage: notificationMessage,
    );
  }

  @override
  List<Object?> get props => [collections, documentCollectionMap, notificationMessage];
}

class CollectionError extends CollectionState {
  final String message;

  const CollectionError(this.message);

  @override
  List<Object?> get props => [message];
}
