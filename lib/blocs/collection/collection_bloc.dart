import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_shelf/blocs/collection/collection_event.dart';
import 'package:the_shelf/blocs/collection/collection_state.dart';
import 'package:the_shelf/services/collection_repository.dart';

class CollectionBloc extends Bloc<CollectionEvent, CollectionState> {
  final CollectionRepository _repository;

  CollectionBloc({CollectionRepository? repository})
      : _repository = repository ?? CollectionRepository.instance,
        super(const CollectionInitial()) {
    on<LoadCollections>(_onLoadCollections);
    on<ClearCollections>(_onClearCollections);
    on<CreateCollection>(_onCreateCollection);
    on<UpdateCollection>(_onUpdateCollection);
    on<DeleteCollection>(_onDeleteCollection);
    on<ToggleDocumentCollection>(_onToggleDocumentCollection);
    on<BatchSetDocumentCollections>(_onBatchSetDocumentCollections);
    on<AddDocumentsToCollectionEvent>(_onAddDocumentsToCollection);
  }

  Future<void> _onLoadCollections(
    LoadCollections event,
    Emitter<CollectionState> emit,
  ) async {
    emit(const CollectionLoading());
    try {
      final collections = await _repository.getAllCollections(userId: event.userId);
      final docMap = await _repository.getDocumentCollectionMap();
      emit(CollectionLoaded(
        collections: collections,
        documentCollectionMap: docMap,
      ));
    } catch (e) {
      emit(CollectionError('Failed to load collections: ${e.toString()}'));
    }
  }

  void _onClearCollections(
    ClearCollections event,
    Emitter<CollectionState> emit,
  ) {
    emit(const CollectionLoaded(collections: []));
  }

  Future<void> _onCreateCollection(
    CreateCollection event,
    Emitter<CollectionState> emit,
  ) async {
    try {
      await _repository.createCollection(
        name: event.name,
        colorHex: event.colorHex,
        iconName: event.iconName,
      );
      final collections = await _repository.getAllCollections();
      final docMap = await _repository.getDocumentCollectionMap();
      emit(CollectionLoaded(
        collections: collections,
        documentCollectionMap: docMap,
        notificationMessage: 'Collection created successfully',
      ));
    } catch (e) {
      if (e is CollectionLimitException) {
        if (state is CollectionLoaded) {
          final currentState = state as CollectionLoaded;
          emit(currentState.copyWith(notificationMessage: e.message));
        } else {
          emit(CollectionError(e.message));
        }
      } else {
        emit(CollectionError('Failed to create collection: ${e.toString()}'));
      }
    }
  }

  Future<void> _onUpdateCollection(
    UpdateCollection event,
    Emitter<CollectionState> emit,
  ) async {
    try {
      await _repository.updateCollection(event.collection);
      final collections = await _repository.getAllCollections();
      final docMap = await _repository.getDocumentCollectionMap();
      emit(CollectionLoaded(
        collections: collections,
        documentCollectionMap: docMap,
        notificationMessage: 'Collection updated',
      ));
    } catch (e) {
      emit(CollectionError('Failed to update collection: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteCollection(
    DeleteCollection event,
    Emitter<CollectionState> emit,
  ) async {
    try {
      await _repository.deleteCollection(event.collectionId);
      final collections = await _repository.getAllCollections();
      final docMap = await _repository.getDocumentCollectionMap();
      emit(CollectionLoaded(
        collections: collections,
        documentCollectionMap: docMap,
        notificationMessage: 'Collection deleted',
      ));
    } catch (e) {
      emit(CollectionError('Failed to delete collection: ${e.toString()}'));
    }
  }

  Future<void> _onToggleDocumentCollection(
    ToggleDocumentCollection event,
    Emitter<CollectionState> emit,
  ) async {
    try {
      if (event.isMember) {
        await _repository.addDocumentToCollection(event.collectionId, event.documentId);
      } else {
        await _repository.removeDocumentFromCollection(event.collectionId, event.documentId);
      }
      final collections = await _repository.getAllCollections();
      final docMap = await _repository.getDocumentCollectionMap();
      emit(CollectionLoaded(
        collections: collections,
        documentCollectionMap: docMap,
      ));
    } catch (e) {
      emit(CollectionError('Failed to update document collection: ${e.toString()}'));
    }
  }

  Future<void> _onBatchSetDocumentCollections(
    BatchSetDocumentCollections event,
    Emitter<CollectionState> emit,
  ) async {
    try {
      await _repository.setDocumentCollections(event.documentId, event.collectionIds);
      final collections = await _repository.getAllCollections();
      final docMap = await _repository.getDocumentCollectionMap();
      emit(CollectionLoaded(
        collections: collections,
        documentCollectionMap: docMap,
        notificationMessage: 'Document collections saved',
      ));
    } catch (e) {
      emit(CollectionError('Failed to update collections for document: ${e.toString()}'));
    }
  }

  Future<void> _onAddDocumentsToCollection(
    AddDocumentsToCollectionEvent event,
    Emitter<CollectionState> emit,
  ) async {
    try {
      await _repository.addDocumentsToCollection(event.collectionId, event.documentIds);
      final collections = await _repository.getAllCollections();
      final docMap = await _repository.getDocumentCollectionMap();
      emit(CollectionLoaded(
        collections: collections,
        documentCollectionMap: docMap,
        notificationMessage: 'Items added to collection',
      ));
    } catch (e) {
      emit(CollectionError('Failed to add items to collection: ${e.toString()}'));
    }
  }
}
