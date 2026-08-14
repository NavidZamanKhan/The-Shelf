import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:the_shelf/blocs/shelf/shelf_state.dart';

/// Repository wrapping SQLite database operations for document persistence.
class DocumentRepository {
  static final DocumentRepository instance = DocumentRepository._internal();
  static const String _tableName = 'documents';
  static const int _dbVersion = 3;

  Database? _db;

  DocumentRepository._internal();

  factory DocumentRepository() => instance;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  /// Resolves the active user ID for SQLite data scoping.
  Future<String> resolveUserId({String? userId}) async {
    if (userId != null && userId.isNotEmpty) return userId;
    try {
      final fbUid = FirebaseAuth.instance.currentUser?.uid;
      if (fbUid != null && fbUid.isNotEmpty) return fbUid;
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedUid = prefs.getString('auth_firebase_uid');
      if (cachedUid != null && cachedUid.isNotEmpty) return cachedUid;
      final email = prefs.getString('auth_email');
      if (email != null && email.isNotEmpty) {
        return email.trim().replaceAll('.', '_').replaceAll('@', '_at_');
      }
    } catch (_) {}

    return 'guest_local';
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
        added_at TEXT NOT NULL,
        user_id TEXT DEFAULT 'guest_local'
      )
    ''');

    await db.execute('CREATE INDEX idx_documents_shelf ON $_tableName(shelf);');
    await db.execute('CREATE INDEX idx_documents_title ON $_tableName(title);');
    await db.execute('CREATE INDEX idx_documents_user ON $_tableName(user_id);');

    await _createCollectionTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createCollectionTables(db);
    }
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE $_tableName ADD COLUMN user_id TEXT DEFAULT 'guest_local';");
      await db.execute("ALTER TABLE collections ADD COLUMN user_id TEXT DEFAULT 'guest_local';");
      await db.execute("CREATE INDEX IF NOT EXISTS idx_documents_user ON $_tableName(user_id);");
    }
  }

  Future<void> _createCollectionTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS collections (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color_hex TEXT NOT NULL,
        icon_name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        user_id TEXT DEFAULT 'guest_local'
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

  /// Inserts a new document record into SQLite scoped to the active user.
  Future<void> insertDocument(ShelfItem item, {String? userId}) async {
    final db = await database;
    final effectiveUid = await resolveUserId(userId: userId);
    final tableInfo = await db.rawQuery("PRAGMA table_info($_tableName)");
    final hasUserCol = tableInfo.any((c) => c['name'] == 'user_id');

    final data = <String, dynamic>{
      'id': item.id,
      'title': item.title,
      'shelf': item.shelf,
      'file_path': item.filePath,
      'added_at': item.addedAt.toIso8601String(),
    };
    if (hasUserCol) {
      data['user_id'] = effectiveUid;
    }

    await db.insert(
      _tableName,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves all persisted documents for the active user ordered by addedAt descending.
  Future<List<ShelfItem>> getAllDocuments({String? userId}) async {
    final db = await database;
    final effectiveUid = await resolveUserId(userId: userId);
    final tableInfo = await db.rawQuery("PRAGMA table_info($_tableName)");
    final hasUserCol = tableInfo.any((c) => c['name'] == 'user_id');

    final List<Map<String, dynamic>> maps = hasUserCol
        ? await db.query(
            _tableName,
            where: 'user_id = ?',
            whereArgs: [effectiveUid],
            orderBy: 'added_at DESC',
          )
        : await db.query(
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

  /// Retrieves documents matching a specific shelf category for the active user.
  Future<List<ShelfItem>> getDocumentsByShelf(String shelf, {String? userId}) async {
    final db = await database;
    final effectiveUid = await resolveUserId(userId: userId);
    final tableInfo = await db.rawQuery("PRAGMA table_info($_tableName)");
    final hasUserCol = tableInfo.any((c) => c['name'] == 'user_id');

    final List<Map<String, dynamic>> maps = hasUserCol
        ? await db.query(
            _tableName,
            where: 'LOWER(shelf) = ? AND user_id = ?',
            whereArgs: [shelf.trim().toLowerCase(), effectiveUid],
            orderBy: 'added_at DESC',
          )
        : await db.query(
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

  /// Updates file path for a document (used for path healing when iOS container UUIDs change)
  Future<void> updateDocumentFilePath(String id, String newFilePath) async {
    final db = await database;
    await db.update(
      _tableName,
      {'file_path': newFilePath},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Clears all stored documents for the active user or entire table
  Future<void> clearAllDocuments({String? userId}) async {
    final db = await database;
    if (userId != null && userId.isNotEmpty) {
      final tableInfo = await db.rawQuery("PRAGMA table_info($_tableName)");
      final hasUserCol = tableInfo.any((c) => c['name'] == 'user_id');
      if (hasUserCol) {
        await db.delete(_tableName, where: 'user_id = ?', whereArgs: [userId]);
      } else {
        await db.delete(_tableName);
      }
    } else {
      await db.delete(_tableName);
    }
  }

  /// Returns genre distribution as `Map<shelfName, count>` for the Profile donut chart.
  /// Uses real SQLite data scoped to the active user and grouped by the `shelf` column.
  Future<Map<String, int>> getGenreDistribution({String? userId}) async {
    final db = await database;
    final effectiveUid = await resolveUserId(userId: userId);
    final tableInfo = await db.rawQuery("PRAGMA table_info($_tableName)");
    final hasUserCol = tableInfo.any((c) => c['name'] == 'user_id');

    final results = hasUserCol
        ? await db.rawQuery(
            'SELECT shelf, COUNT(*) as count FROM $_tableName WHERE user_id = ? GROUP BY shelf ORDER BY count DESC',
            [effectiveUid],
          )
        : await db.rawQuery(
            'SELECT shelf, COUNT(*) as count FROM $_tableName GROUP BY shelf ORDER BY count DESC',
          );
    return {
      for (var row in results)
        row['shelf'] as String: row['count'] as int,
    };
  }

  /// Claims all `guest_local` documents and collections for a newly authenticated user.
  Future<void> claimGuestData(String userId) async {
    if (userId.isEmpty || userId == 'guest_local') return;
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        _tableName,
        {'user_id': userId},
        where: "user_id = 'guest_local'",
      );
      await txn.update(
        'collections',
        {'user_id': userId},
        where: "user_id = 'guest_local'",
      );
    });
  }
}
