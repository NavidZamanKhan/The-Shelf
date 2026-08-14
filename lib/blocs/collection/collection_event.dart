import 'package:equatable/equatable.dart';
import 'package:the_shelf/models/collection_model.dart';

abstract class CollectionEvent extends Equatable {
  const CollectionEvent();

  @override
  List<Object?> get props => [];
}

class LoadCollections extends CollectionEvent {
  final String? userId;
  const LoadCollections({this.userId});

  @override
  List<Object?> get props => [userId];
}

class ClearCollections extends CollectionEvent {
  const ClearCollections();
}

class CreateCollection extends CollectionEvent {
  final String name;
  final String colorHex;
  final String iconName;

  const CreateCollection({
    required this.name,
    required this.colorHex,
    required this.iconName,
  });

  @override
  List<Object?> get props => [name, colorHex, iconName];
}

class UpdateCollection extends CollectionEvent {
  final CollectionModel collection;

  const UpdateCollection(this.collection);

  @override
  List<Object?> get props => [collection];
}

class DeleteCollection extends CollectionEvent {
  final String collectionId;

  const DeleteCollection(this.collectionId);

  @override
  List<Object?> get props => [collectionId];
}

class ToggleDocumentCollection extends CollectionEvent {
  final String documentId;
  final String collectionId;
  final bool isMember;

  const ToggleDocumentCollection({
    required this.documentId,
    required this.collectionId,
    required this.isMember,
  });

  @override
  List<Object?> get props => [documentId, collectionId, isMember];
}

class BatchSetDocumentCollections extends CollectionEvent {
  final String documentId;
  final List<String> collectionIds;

  const BatchSetDocumentCollections({
    required this.documentId,
    required this.collectionIds,
  });

  @override
  List<Object?> get props => [documentId, collectionIds];
}

class AddDocumentsToCollectionEvent extends CollectionEvent {
  final String collectionId;
  final List<String> documentIds;

  const AddDocumentsToCollectionEvent({
    required this.collectionId,
    required this.documentIds,
  });

  @override
  List<Object?> get props => [collectionId, documentIds];
}
