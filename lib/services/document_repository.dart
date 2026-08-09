import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:the_shelf/blocs/shelf/shelf_state.dart';

/// Repository wrapping SQLite database operations for document persistence.
class DocumentRepository {
  static final DocumentRepository instance = DocumentRepository._internal();
  static const String _tableName = 'documents';
  static const int _dbVersion = 2;

  Database? _db;

  DocumentRepository._internal();

  factory DocumentRepository() => instance;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    // Initialize FFI for desktop platforms (macOS, Windows, Linux)
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'the_shelf_documents.db');

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        shelf TEXT NOT NULL,
        file_path TEXT NOT NULL,
        added_at TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_documents_shelf ON $_tableName(shelf);');
    await db.execute('CREATE INDEX idx_documents_title ON $_tableName(title);');

    await _createCollectionTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createCollectionTables(db);
    }
  }

  Future<void> _createCollectionTables(Database db) async {
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

    await db.execute('CREATE INDEX IF NOT EXISTS idx_col_docs_collection ON collection_documents(collection_id);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_col_docs_document ON collection_documents(document_id);');
  }

  /// Inserts a new document record into SQLite
  Future<void> insertDocument(ShelfItem item) async {
    final db = await database;
    await db.insert(
      _tableName,
      {
        'id': item.id,
        'title': item.title,
        'shelf': item.shelf,
        'file_path': item.filePath,
        'added_at': item.addedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves all persisted documents ordered by addedAt descending
  Future<List<ShelfItem>> getAllDocuments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'added_at DESC',
    );

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

  /// Retrieves documents matching a specific shelf category
  Future<List<ShelfItem>> getDocumentsByShelf(String shelf) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'LOWER(shelf) = ?',
      whereArgs: [shelf.trim().toLowerCase()],
      orderBy: 'added_at DESC',
    );

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

  /// Deletes a document by ID
  Future<void> deleteDocument(String id) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Clears all stored documents (used primarily for test cleanup)
  Future<void> clearAllDocuments() async {
    final db = await database;
    await db.delete(_tableName);
  }

  /// Returns genre distribution as `Map<shelfName, count>` for the Profile donut chart.
  /// Uses real SQLite data grouped by the `shelf` column.
  Future<Map<String, int>> getGenreDistribution() async {
    final db = await database;
    final results = await db.rawQuery(
      'SELECT shelf, COUNT(*) as count FROM $_tableName GROUP BY shelf ORDER BY count DESC',
    );
    return {
      for (var row in results)
        row['shelf'] as String: row['count'] as int,
    };
  }
}
