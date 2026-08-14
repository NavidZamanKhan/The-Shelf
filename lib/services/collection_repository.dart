import 'package:sqflite/sqflite.dart';
import 'package:the_shelf/blocs/shelf/shelf_state.dart';
import 'package:the_shelf/models/collection_model.dart';
import 'package:the_shelf/services/document_repository.dart';

class CollectionLimitException implements Exception {
  final String message;
  CollectionLimitException([this.message = 'Maximum collection cap of 20 reached.']);

  @override
  String toString() => message;
}

class CollectionRepository {
  static final CollectionRepository instance = CollectionRepository._internal();
  static const int maxCollectionCap = 20;

  final DocumentRepository _docRepo;
  final Database? _overrideDb;
  static int _idCounter = 0;

  CollectionRepository._internal({DocumentRepository? docRepo, this._overrideDb})
      : _docRepo = docRepo ?? DocumentRepository.instance;

  factory CollectionRepository({Database? overrideDb}) {
    if (overrideDb != null) {
      return CollectionRepository._internal(overrideDb: overrideDb);
    }
    return instance;
  }

  Future<Database> get _db async => _overrideDb ?? await _docRepo.database;

  /// Retrieves all collections ordered by created_at DESC with current item counts for the active user
  Future<List<CollectionModel>> getAllCollections({String? userId}) async {
    final db = await _db;
    final effectiveUid = await _docRepo.resolveUserId(userId: userId);
    final tableInfo = await db.rawQuery("PRAGMA table_info(collections)");
    final hasUserCol = tableInfo.any((c) => c['name'] == 'user_id');

    final List<Map<String, dynamic>> collectionsRaw = hasUserCol
        ? await db.query(
            'collections',
            where: 'user_id = ?',
            whereArgs: [effectiveUid],
            orderBy: 'created_at DESC',
          )
        : await db.query(
            'collections',
            orderBy: 'created_at DESC',
          );

    List<CollectionModel> collections = [];
    for (final map in collectionsRaw) {
      final colId = map['id'] as String;
      final countResult = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM collection_documents WHERE collection_id = ?',
        [colId],
      ));
      collections.add(CollectionModel.fromMap(map, itemCount: countResult ?? 0));
    }
    return collections;
  }

  /// Creates a new collection, enforcing the 20 collection cap per user
  Future<CollectionModel> createCollection({
    required String name,
    required String colorHex,
    required String iconName,
    String? userId,
  }) async {
    final db = await _db;
    final effectiveUid = await _docRepo.resolveUserId(userId: userId);
    final tableInfo = await db.rawQuery("PRAGMA table_info(collections)");
    final hasUserCol = tableInfo.any((c) => c['name'] == 'user_id');

    final count = Sqflite.firstIntValue(hasUserCol
        ? await db.rawQuery(
            'SELECT COUNT(*) FROM collections WHERE user_id = ?',
            [effectiveUid],
          )
        : await db.rawQuery('SELECT COUNT(*) FROM collections')) ?? 0;
        
    if (count >= maxCollectionCap) {
      throw CollectionLimitException('Maximum limit of $maxCollectionCap collections reached.');
    }

    final newCollection = CollectionModel(
      id: '${DateTime.now().microsecondsSinceEpoch}_${++_idCounter}',
      name: name.trim(),
      colorHex: colorHex,
      iconName: iconName,
      createdAt: DateTime.now(),
      itemCount: 0,
    );

    final map = newCollection.toMap();
    if (hasUserCol) {
      map['user_id'] = effectiveUid;
    }
    await db.insert('collections', map);
    return newCollection;
  }

  /// Updates existing collection metadata (name, color, icon)
  Future<void> updateCollection(CollectionModel collection) async {
    final db = await _db;
    await db.update(
      'collections',
      collection.toMap(),
      where: 'id = ?',
      whereArgs: [collection.id],
    );
  }

  /// Deletes a collection by ID (associated collection_documents join rows are deleted automatically via cascade)
  Future<void> deleteCollection(String collectionId) async {
    final db = await _db;
    await db.delete(
      'collections',
      where: 'id = ?',
      whereArgs: [collectionId],
    );
  }

  /// Adds a single document to a collection (many-to-many relationship)
  Future<void> addDocumentToCollection(String collectionId, String documentId) async {
    final db = await _db;
    await db.insert(
      'collection_documents',
      {
        'collection_id': collectionId,
        'document_id': documentId,
        'added_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Removes a document from a specific collection without deleting the document
  Future<void> removeDocumentFromCollection(String collectionId, String documentId) async {
    final db = await _db;
    await db.delete(
      'collection_documents',
      where: 'collection_id = ? AND document_id = ?',
      whereArgs: [collectionId, documentId],
    );
  }

  /// Sets/synchronizes all collection memberships for a given document in a single transaction
  Future<void> setDocumentCollections(String documentId, List<String> targetCollectionIds) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete(
        'collection_documents',
        where: 'document_id = ?',
        whereArgs: [documentId],
      );
      final now = DateTime.now().toIso8601String();
      for (final colId in targetCollectionIds) {
        await txn.insert(
          'collection_documents',
          {
            'collection_id': colId,
            'document_id': documentId,
            'added_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });
  }

  /// Bulk-adds multiple documents to a collection
  Future<void> addDocumentsToCollection(String collectionId, List<String> documentIds) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    for (final docId in documentIds) {
      batch.insert(
        'collection_documents',
        {
          'collection_id': collectionId,
          'document_id': docId,
          'added_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Gets all documents belonging to a collection via inner join
  Future<List<ShelfItem>> getDocumentsInCollection(String collectionId, {String? userId}) async {
    final db = await _db;
    final effectiveUid = await _docRepo.resolveUserId(userId: userId);
    final tableInfo = await db.rawQuery("PRAGMA table_info(documents)");
    final hasUserCol = tableInfo.any((c) => c['name'] == 'user_id');

    final List<Map<String, dynamic>> maps = hasUserCol
        ? await db.rawQuery('''
            SELECT d.id, d.title, d.shelf, d.file_path, d.added_at
            FROM documents d
            INNER JOIN collection_documents cd ON d.id = cd.document_id
            WHERE cd.collection_id = ? AND d.user_id = ?
            ORDER BY cd.added_at DESC
          ''', [collectionId, effectiveUid])
        : await db.rawQuery('''
            SELECT d.id, d.title, d.shelf, d.file_path, d.added_at
            FROM documents d
            INNER JOIN collection_documents cd ON d.id = cd.document_id
            WHERE cd.collection_id = ?
            ORDER BY cd.added_at DESC
          ''', [collectionId]);

    return maps.map((map) {
      return ShelfItem(
        id: map['id'] as String,
        title: map['title'] as String,
        shelf: map['shelf'] as String,
        filePath: map['file_path'] as String,
        addedAt: DateTime.parse(map['added_at'] as String),
      );
    }).toList();
  }

  /// Gets all collection IDs that a specific document belongs to
  Future<List<String>> getCollectionIdsForDocument(String documentId) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'collection_documents',
      columns: ['collection_id'],
      where: 'document_id = ?',
      whereArgs: [documentId],
    );

    return maps.map((m) => m['collection_id'] as String).toList();
  }

  /// Returns a full map of documentId -> Set of collectionIds for efficient O(1) BLoC state lookup
  Future<Map<String, Set<String>>> getDocumentCollectionMap({String? userId}) async {
    final db = await _db;
    final effectiveUid = await _docRepo.resolveUserId(userId: userId);
    final tableInfo = await db.rawQuery("PRAGMA table_info(collections)");
    final hasUserCol = tableInfo.any((c) => c['name'] == 'user_id');

    final List<Map<String, dynamic>> maps = hasUserCol
        ? await db.rawQuery('''
            SELECT cd.document_id, cd.collection_id
            FROM collection_documents cd
            INNER JOIN collections c ON cd.collection_id = c.id
            WHERE c.user_id = ?
          ''', [effectiveUid])
        : await db.query('collection_documents');

    final Map<String, Set<String>> resultMap = {};
    for (final row in maps) {
      final docId = row['document_id'] as String;
      final colId = row['collection_id'] as String;
      resultMap.putIfAbsent(docId, () => <String>{}).add(colId);
    }
    return resultMap;
  }
}
