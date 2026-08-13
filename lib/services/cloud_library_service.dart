import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_shelf/blocs/shelf/shelf_state.dart';
import 'package:the_shelf/services/document_repository.dart';

/// Service managing Cloud Library synchronization, document backup to Firestore,
/// and cross-device library restoration.
class CloudLibraryService {
  static final CloudLibraryService instance = CloudLibraryService._internal();
  CloudLibraryService._internal();

  factory CloudLibraryService() => instance;

  static const String _keySyncedDocIds = 'cloud_synced_document_ids';

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseStorage? get _storage {
    try {
      return FirebaseStorage.instanceFor(bucket: 'the-shelf-39f9d.firebasestorage.app');
    } catch (_) {
      try {
        return FirebaseStorage.instance;
      } catch (_) {
        return null;
      }
    }
  }

  /// Resolves the effective active user ID.
  Future<String> resolveUid({String? uid}) async {
    if (uid != null && uid.isNotEmpty) return uid;
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

  /// Attempts to find the local file even if the iOS app container sandbox UUID changed.
  Future<File?> _resolveLocalFile(String rawPath) async {
    if (rawPath.trim().isEmpty) return null;
    final direct = File(rawPath.trim());
    if (await direct.exists()) return direct;

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final importsDir = Directory('${docsDir.path}/imports');
      final fileName = p.basename(rawPath.trim());

      final inImports = File('${importsDir.path}/$fileName');
      if (await inImports.exists()) return inImports;

      final inDocs = File('${docsDir.path}/$fileName');
      if (await inDocs.exists()) return inDocs;

      if (await importsDir.exists()) {
        final list = importsDir.listSync();
        for (final entity in list) {
          if (entity is File) {
            final base = p.basename(entity.path);
            if (base == fileName || base.endsWith('_$fileName') || base.endsWith(fileName)) {
              return entity;
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Uploads a document's metadata to Cloud Firestore and its file to Firebase Storage.
  Future<bool> uploadDocument(ShelfItem item, {String? uid}) async {
    final effectiveUid = await resolveUid(uid: uid);
    String? cloudFileUrl;
    String? storagePath;
    String? embeddedFileData;
    final safeDocId = item.id.replaceAll('/', '_').replaceAll('\\', '_');

    final File? resolvedFile = await _resolveLocalFile(item.filePath);
    final bool fileExists = resolvedFile != null && await resolvedFile.exists();

    // 1. If file is small (< 750KB), embed Base64 in Firestore document for guaranteed instant cross-device sync
    if (fileExists) {
      try {
        final length = await resolvedFile.length();
        if (length > 0 && length <= 750 * 1024) {
          final bytes = await resolvedFile.readAsBytes();
          embeddedFileData = base64Encode(bytes);
          debugPrint('Embedded base64 file data (${bytes.length} bytes) for "${item.title}"');
        }
      } catch (e) {
        debugPrint('Error embedding base64 file data: $e');
      }
    }

    // 2. Try uploading the physical file to Firebase Storage if available
    try {
      final storage = _storage;
      if (storage != null && fileExists) {
        final filename = p.basename(resolvedFile.path);
        final candidatePath = 'users/$effectiveUid/documents/$safeDocId/$filename';
        final ref = storage.ref().child(candidatePath);
        final uploadTask = await ref.putFile(resolvedFile);
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        if (downloadUrl.isNotEmpty) {
          cloudFileUrl = downloadUrl;
          storagePath = candidatePath;
          debugPrint('Uploaded file to Firebase Storage: $candidatePath');
        }
      }
    } catch (e) {
      debugPrint('Firebase Storage upload skipped/fallback: $e');
    }

    // 3. Write metadata record to Cloud Firestore `users/{uid}/documents/{docId}`
    try {
      final db = _firestore;
      if (db != null) {
        final Map<String, dynamic> docMap = {
          'id': item.id,
          'title': item.title,
          'shelf': item.shelf,
          'file_path': item.filePath,
          'file_url': cloudFileUrl,
          'storage_path': storagePath,
          'added_at': item.addedAt.toIso8601String(),
          'synced_at': DateTime.now().toIso8601String(),
          'user_id': effectiveUid,
        };
        if (embeddedFileData != null) {
          docMap['file_data'] = embeddedFileData;
        }

        await db
            .collection('users')
            .doc(effectiveUid)
            .collection('documents')
            .doc(safeDocId)
            .set(docMap, SetOptions(merge: true));
        debugPrint('Synced document "${item.title}" ($safeDocId) to Cloud Firestore for user $effectiveUid (embeddedData: ${embeddedFileData != null})');
      }
    } catch (e) {
      debugPrint('Firestore document sync error: $e');
      return false;
    }

    // 4. Mark document as synced locally
    await _markDocumentSynced(item.id);
    return true;
  }

  /// Downloads a cloud document file (from Firestore embedded base64, Firebase Storage, or HTTP URL).
  /// Returns the local File if successful, or null.
  Future<File?> downloadDocumentFile({
    required String docId,
    String? cloudFileUrl,
    String? storagePath,
    String? originalFileName,
    String? uid,
  }) async {
    try {
      final effectiveUid = await resolveUid(uid: uid);
      final docsDir = await getApplicationDocumentsDirectory();
      final importsDir = Directory('${docsDir.path}/imports');
      if (!await importsDir.exists()) {
        await importsDir.create(recursive: true);
      }

      final safeDocId = docId.replaceAll('/', '_').replaceAll('\\', '_');
      final fileName = (originalFileName != null && originalFileName.isNotEmpty)
          ? p.basename(originalFileName)
          : '$safeDocId.pdf';
      final localFile = File('${importsDir.path}/$fileName');

      // 1. Fetch latest metadata from Cloud Firestore if URL or storage path is missing
      String? resolvedUrl = cloudFileUrl;
      String? resolvedStoragePath = storagePath;
      String? embeddedData;

      try {
        final db = _firestore;
        if (db != null) {
          final docSnap = await db
              .collection('users')
              .doc(effectiveUid)
              .collection('documents')
              .doc(safeDocId)
              .get();
          if (docSnap.exists && docSnap.data() != null) {
            final data = docSnap.data()!;
            resolvedUrl ??= data['file_url'] as String?;
            resolvedStoragePath ??= data['storage_path'] as String?;
            embeddedData ??= data['file_data'] as String?;
          } else {
            // Fallback: search all documents in user collection by title or filename
            final allDocs = await db
                .collection('users')
                .doc(effectiveUid)
                .collection('documents')
                .get();
            for (final d in allDocs.docs) {
              final dData = d.data();
              final dTitle = (dData['title'] as String? ?? '').toLowerCase();
              final dPath = (dData['file_path'] as String? ?? '').toLowerCase();
              final targetName = fileName.toLowerCase();
              final targetBase = p.basenameWithoutExtension(fileName).toLowerCase();

              if (dTitle == targetBase ||
                  dTitle == targetName ||
                  p.basename(dPath) == targetName ||
                  p.basenameWithoutExtension(dPath) == targetBase) {
                resolvedUrl ??= dData['file_url'] as String?;
                resolvedStoragePath ??= dData['storage_path'] as String?;
                embeddedData ??= dData['file_data'] as String?;
                debugPrint('Matched document in cloud by name fallback: ${d.id}');
                break;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error querying Firestore for document metadata: $e');
      }

      // 2. If Base64 embedded data is in Firestore, write bytes directly!
      if (embeddedData != null && embeddedData.isNotEmpty) {
        try {
          final bytes = base64Decode(embeddedData);
          if (bytes.isNotEmpty) {
            await localFile.writeAsBytes(bytes, flush: true);
            debugPrint('Restored document file from embedded Firestore Data URL: ${localFile.path}');
            return localFile;
          }
        } catch (e) {
          debugPrint('Error decoding embedded base64 file data: $e');
        }
      }

      // 3. If storage path is available, download via Firebase Storage SDK
      final storage = _storage;
      if (storage != null) {
        final path = (resolvedStoragePath != null && resolvedStoragePath.isNotEmpty)
            ? resolvedStoragePath
            : 'users/$effectiveUid/documents/$safeDocId/$fileName';
        try {
          final ref = storage.ref().child(path);
          // Try writeToFile first
          try {
            await ref.writeToFile(localFile);
            if (await localFile.exists() && await localFile.length() > 0) {
              debugPrint('Downloaded document file from Firebase Storage writeToFile: ${localFile.path}');
              return localFile;
            }
          } catch (_) {}

          // Fallback to getData
          final data = await ref.getData(50 * 1024 * 1024); // up to 50MB
          if (data != null && data.isNotEmpty) {
            await localFile.writeAsBytes(data, flush: true);
            debugPrint('Downloaded document file from Firebase Storage getData: ${localFile.path}');
            return localFile;
          }
        } catch (e) {
          debugPrint('Firebase Storage download error: $e');
        }
      }

      // 4. If HTTP download URL is available, download via HttpClient
      if (resolvedUrl != null && resolvedUrl.startsWith('http')) {
        try {
          final client = HttpClient();
          final request = await client.getUrl(Uri.parse(resolvedUrl));
          final response = await request.close();
          if (response.statusCode == 200) {
            final sink = localFile.openWrite();
            await response.pipe(sink);
            await sink.close();
            client.close();
            if (await localFile.exists() && await localFile.length() > 0) {
              debugPrint('Downloaded document file from HTTP URL: ${localFile.path}');
              return localFile;
            }
          }
          client.close();
        } catch (e) {
          debugPrint('HTTP download error: $e');
        }
      }
    } catch (e) {
      debugPrint('Error downloading cloud document file: $e');
    }
    return null;
  }

  /// Checks if a document has been synced to cloud.
  Future<bool> isDocumentSynced(String docId, {String? uid}) async {
    final prefs = await SharedPreferences.getInstance();
    final synced = prefs.getStringList(_keySyncedDocIds) ?? [];
    if (synced.contains(docId)) return true;

    try {
      final effectiveUid = await resolveUid(uid: uid);
      final safeDocId = docId.replaceAll('/', '_').replaceAll('\\', '_');
      final db = _firestore;
      if (db != null) {
        final doc = await db
            .collection('users')
            .doc(effectiveUid)
            .collection('documents')
            .doc(safeDocId)
            .get();
        if (doc.exists) {
          await _markDocumentSynced(docId);
          return true;
        }
      }
    } catch (_) {}

    return false;
  }

  /// Deletes a document record and its storage file from Cloud Firestore & Firebase Storage.
  Future<bool> deleteDocumentFromCloud(String docId, {String? uid}) async {
    try {
      final effectiveUid = await resolveUid(uid: uid);
      final safeDocId = docId.replaceAll('/', '_').replaceAll('\\', '_');

      // 1. Delete from Firestore and check for storage_path
      final db = _firestore;
      if (db != null) {
        final docRef = db
            .collection('users')
            .doc(effectiveUid)
            .collection('documents')
            .doc(safeDocId);
        final docSnap = await docRef.get();
        if (docSnap.exists) {
          final storagePath = docSnap.data()?['storage_path'] as String?;
          if (storagePath != null && storagePath.isNotEmpty) {
            try {
              final storage = _storage;
              if (storage != null) {
                await storage.ref().child(storagePath).delete();
              }
            } catch (_) {}
          }
          await docRef.delete();
        }
      }

      // 2. Remove from local synced doc IDs cache
      final prefs = await SharedPreferences.getInstance();
      final synced = prefs.getStringList(_keySyncedDocIds) ?? [];
      if (synced.contains(docId)) {
        synced.remove(docId);
        await prefs.setStringList(_keySyncedDocIds, synced);
      }

      debugPrint('Deleted document $docId from cloud for user $effectiveUid');
      return true;
    } catch (e) {
      debugPrint('Error deleting document from cloud: $e');
      return false;
    }
  }

  /// Backs up all local documents into the user's Cloud Firestore account.
  Future<int> backupAllDocuments({String? uid}) async {
    final effectiveUid = await resolveUid(uid: uid);
    final docs = await DocumentRepository.instance.getAllDocuments();
    int successCount = 0;

    for (final doc in docs) {
      try {
        final success = await uploadDocument(doc, uid: effectiveUid);
        if (success) successCount++;
      } catch (e) {
        debugPrint('Error backing up document ${doc.id}: $e');
      }
    }

    debugPrint('Completed backup: $successCount of ${docs.length} documents uploaded to user $effectiveUid');
    return successCount;
  }

  /// Restores cloud documents for the signed-in user into local SQLite storage.
  /// Strictly checks local device storage and SQLite first; only downloads missing files.
  Future<int> restoreCloudLibrary({String? uid}) async {
    final effectiveUid = await resolveUid(uid: uid);
    int restoredCount = 0;

    try {
      final db = _firestore;
      if (db != null) {
        final snapshot = await db
            .collection('users')
            .doc(effectiveUid)
            .collection('documents')
            .get();

        final localDocs = await DocumentRepository.instance.getAllDocuments();
        final localDocMap = {for (var d in localDocs) d.id: d};

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final id = data['id'] as String? ?? doc.id;
          final title = data['title'] as String? ?? 'Untitled';
          final shelf = data['shelf'] as String? ?? 'Miscellaneous';
          final remoteFilePath = data['file_path'] as String? ?? '';
          final cloudFileUrl = data['file_url'] as String?;
          final storagePath = data['storage_path'] as String?;
          final addedAtStr = data['added_at'] as String?;
          final addedAt = addedAtStr != null
              ? DateTime.tryParse(addedAtStr) ?? DateTime.now()
              : DateTime.now();

          final existingLocal = localDocMap[id];

          // 1. Check if the physical file already exists locally on this device
          File? localFile;
          if (existingLocal != null && existingLocal.filePath.isNotEmpty) {
            localFile = await _resolveLocalFile(existingLocal.filePath);
          }
          localFile ??= await _resolveLocalFile(remoteFilePath);

          String effectiveFilePath = localFile?.path ?? remoteFilePath;

          // 2. Only download if genuinely NOT present on this device
          if (localFile == null || !await localFile.exists()) {
            final downloadedFile = await downloadDocumentFile(
              docId: id,
              cloudFileUrl: cloudFileUrl,
              storagePath: storagePath,
              originalFileName: p.basename(remoteFilePath),
              uid: effectiveUid,
            );
            if (downloadedFile != null && await downloadedFile.exists()) {
              effectiveFilePath = downloadedFile.path;
              localFile = downloadedFile;
            }
          }

          // 3. Insert or heal in SQLite
          if (existingLocal == null) {
            final item = ShelfItem(
              id: id,
              title: title,
              shelf: shelf,
              filePath: effectiveFilePath,
              addedAt: addedAt,
            );
            await DocumentRepository.instance.insertDocument(item);
            await _markDocumentSynced(id);
            restoredCount++;
          } else if (localFile != null && existingLocal.filePath != localFile.path) {
            await DocumentRepository.instance.updateDocumentFilePath(id, localFile.path);
          }
        }
        debugPrint('Restored $restoredCount cloud documents for user $effectiveUid (found ${snapshot.docs.length} total in cloud)');
      }
    } catch (e) {
      debugPrint('Error restoring cloud library: $e');
    }

    return restoredCount;
  }

  /// Deletes a document from Cloud Firestore and local synced registry.
  Future<void> deleteCloudDocument(String docId, {String? uid}) async {
    final effectiveUid = await resolveUid(uid: uid);
    try {
      final db = _firestore;
      if (db != null) {
        await db
            .collection('users')
            .doc(effectiveUid)
            .collection('documents')
            .doc(docId)
            .delete();
      }
    } catch (e) {
      debugPrint('Error deleting cloud document: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    final synced = prefs.getStringList(_keySyncedDocIds) ?? [];
    synced.remove(docId);
    await prefs.setStringList(_keySyncedDocIds, synced);
  }

  Future<void> _markDocumentSynced(String docId) async {
    final prefs = await SharedPreferences.getInstance();
    final synced = (prefs.getStringList(_keySyncedDocIds) ?? []).toSet();
    synced.add(docId);
    await prefs.setStringList(_keySyncedDocIds, synced.toList());
  }
}
