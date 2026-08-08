import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:the_shelf/blocs/shelf/shelf_state.dart';

/// Repository wrapping SQLite database operations for document persistence.
class DocumentRepository {
  static final DocumentRepository instance = DocumentRepository._internal();
  static const String _tableName = 'documents';
  static const int _dbVersion = 1;

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
    );
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
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Version 1 schema upgrade scaffold for future non-destructive database migrations
    if (oldVersion < 2) {
      // Future migrations (e.g. adding last_opened_at column) will go here
    }
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
}
