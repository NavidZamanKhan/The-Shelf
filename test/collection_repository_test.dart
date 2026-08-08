import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:the_shelf/services/collection_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Database Migration v1 -> v2 & Data Preservation', () {
    late String dbPath;
    late File dbFile;

    setUp(() {
      final tempDir = Directory.systemTemp.createTempSync('the_shelf_test_');
      dbPath = p.join(tempDir.path, 'migration_test.db');
      dbFile = File(dbPath);
    });

    tearDown(() {
      if (dbFile.existsSync()) {
        try {
          dbFile.deleteSync();
        } catch (_) {}
      }
    });

    test('onUpgrade from v1 to v2 preserves all existing documents intact', () async {
      // 1. Create a version 1 database with standard documents table
      var db = await openDatabase(
        dbPath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE documents (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              shelf TEXT NOT NULL,
              file_path TEXT NOT NULL,
              added_at TEXT NOT NULL
            )
          ''');
        },
      );

      // Insert pre-existing real document records
      final initialDocs = [
        {
          'id': 'doc_1',
          'title': 'Dune',
          'shelf': 'Science Fiction',
          'file_path': '/storage/dune.epub',
          'added_at': DateTime.now().toIso8601String(),
        },
        {
          'id': 'doc_2',
          'title': 'The Hobbit',
          'shelf': 'Fantasy',
          'file_path': '/storage/hobbit.epub',
          'added_at': DateTime.now().toIso8601String(),
        },
      ];

      for (final d in initialDocs) {
        await db.insert('documents', d);
      }

      await db.close();

      // 2. Re-open database with version 2 triggering _onUpgrade
      db = await openDatabase(
        dbPath,
        version: 2,
        onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON;'),
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS collections (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                color_hex TEXT NOT NULL,
                icon_name TEXT NOT NULL,
                created_at TEXT NOT NULL
              )
            ''');

            await db.execute('''
              CREATE TABLE IF NOT EXISTS collection_documents (
                collection_id TEXT NOT NULL,
                document_id TEXT NOT NULL,
                added_at TEXT NOT NULL,
                PRIMARY KEY (collection_id, document_id),
                FOREIGN KEY (collection_id) REFERENCES collections (id) ON DELETE CASCADE,
                FOREIGN KEY (document_id) REFERENCES documents (id) ON DELETE CASCADE
              )
            ''');
          }
        },
      );

      // 3. Assert all initial documents exist and are 100% uncorrupted
      final fetchedDocs = await db.query('documents');
      expect(fetchedDocs.length, equals(2));
      expect(fetchedDocs[0]['title'], equals('Dune'));
      expect(fetchedDocs[1]['title'], equals('The Hobbit'));

      // Assert new tables exist
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table';");
      final tableNames = tables.map((t) => t['name'] as String).toSet();
      expect(tableNames.contains('collections'), isTrue);
      expect(tableNames.contains('collection_documents'), isTrue);

      await db.close();
    });
  });

  group('CollectionRepository Many-to-Many & Cap Tests', () {
    late Database db;
    late CollectionRepository repository;
    late String dbPath;
    late File dbFile;

    setUp(() async {
      final tempDir = Directory.systemTemp.createTempSync('the_shelf_repo_test_');
      dbPath = p.join(tempDir.path, 'repo_test.db');
      dbFile = File(dbPath);

      db = await openDatabase(
        dbPath,
        version: 2,
        onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON;'),
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE documents (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              shelf TEXT NOT NULL,
              file_path TEXT NOT NULL,
              added_at TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE collections (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              color_hex TEXT NOT NULL,
              icon_name TEXT NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE collection_documents (
              collection_id TEXT NOT NULL,
              document_id TEXT NOT NULL,
              added_at TEXT NOT NULL,
              PRIMARY KEY (collection_id, document_id),
              FOREIGN KEY (collection_id) REFERENCES collections (id) ON DELETE CASCADE,
              FOREIGN KEY (document_id) REFERENCES documents (id) ON DELETE CASCADE
            )
          ''');
        },
      );

      repository = CollectionRepository(overrideDb: db);

      // Seed documents
      await db.insert('documents', {
        'id': 'doc_a',
        'title': 'Foundation',
        'shelf': 'Science Fiction',
        'file_path': '/docs/foundation.epub',
        'added_at': DateTime.now().toIso8601String(),
      });
      await db.insert('documents', {
        'id': 'doc_b',
        'title': 'Neuromancer',
        'shelf': 'Science Fiction',
        'file_path': '/docs/neuromancer.epub',
        'added_at': DateTime.now().toIso8601String(),
      });
    });

    tearDown(() async {
      await db.close();
      if (dbFile.existsSync()) {
        try {
          dbFile.deleteSync();
        } catch (_) {}
      }
    });

    test('Document can belong to multiple collections simultaneously', () async {
      final col1 = await repository.createCollection(
        name: 'SciFi Classics',
        colorHex: '#E06D53',
        iconName: 'star',
      );
      final col2 = await repository.createCollection(
        name: 'Favorites',
        colorHex: '#4E8A79',
        iconName: 'heart',
      );

      await repository.addDocumentToCollection(col1.id, 'doc_a');
      await repository.addDocumentToCollection(col2.id, 'doc_a');

      final col1Docs = await repository.getDocumentsInCollection(col1.id);
      final col2Docs = await repository.getDocumentsInCollection(col2.id);

      expect(col1Docs.map((d) => d.id), contains('doc_a'));
      expect(col2Docs.map((d) => d.id), contains('doc_a'));

      final colIds = await repository.getCollectionIdsForDocument('doc_a');
      expect(colIds, containsAll([col1.id, col2.id]));
    });

    test('Removing document from Collection A does NOT remove it from Collection B or documents table', () async {
      final col1 = await repository.createCollection(name: 'List 1', colorHex: '#111111', iconName: 'tag');
      final col2 = await repository.createCollection(name: 'List 2', colorHex: '#222222', iconName: 'tag');

      await repository.addDocumentToCollection(col1.id, 'doc_a');
      await repository.addDocumentToCollection(col2.id, 'doc_a');

      // Remove from Col 1
      await repository.removeDocumentFromCollection(col1.id, 'doc_a');

      final col1Docs = await repository.getDocumentsInCollection(col1.id);
      final col2Docs = await repository.getDocumentsInCollection(col2.id);

      expect(col1Docs.map((d) => d.id), isNot(contains('doc_a')));
      expect(col2Docs.map((d) => d.id), contains('doc_a'));

      // Check document still exists in documents table
      final docInDb = await db.query('documents', where: 'id = ?', whereArgs: ['doc_a']);
      expect(docInDb.length, equals(1));
    });

    test('Deleting collection cascade-deletes join rows but leaves documents intact', () async {
      final col = await repository.createCollection(name: 'Temporary List', colorHex: '#333333', iconName: 'folder');
      await repository.addDocumentToCollection(col.id, 'doc_a');
      await repository.addDocumentToCollection(col.id, 'doc_b');

      await repository.deleteCollection(col.id);

      final joinRows = await db.query('collection_documents', where: 'collection_id = ?', whereArgs: [col.id]);
      expect(joinRows.isEmpty, isTrue);

      final docA = await db.query('documents', where: 'id = ?', whereArgs: ['doc_a']);
      final docB = await db.query('documents', where: 'id = ?', whereArgs: ['doc_b']);
      expect(docA.length, equals(1));
      expect(docB.length, equals(1));
    });

    test('Enforces 20 collection cap', () async {
      for (int i = 0; i < 20; i++) {
        await repository.createCollection(
          name: 'Collection $i',
          colorHex: '#E06D53',
          iconName: 'bookmarkSimple',
        );
      }

      final allCols = await repository.getAllCollections();
      expect(allCols.length, equals(20));

      expect(
        () async => await repository.createCollection(
          name: 'Collection 21',
          colorHex: '#E06D53',
          iconName: 'bookmarkSimple',
        ),
        throwsA(isA<CollectionLimitException>()),
      );
    });
  });
}
