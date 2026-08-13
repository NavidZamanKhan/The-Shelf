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
      return FirebaseStorage.instance;
    } catch (_) {
      return null;
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

  /// Uploads a document's metadata to Cloud Firestore and its file to Firebase Storage.
  Future<bool> uploadDocument(ShelfItem item, {String? uid}) async {
    final effectiveUid = await resolveUid(uid: uid);
    String? cloudFileUrl;
    final safeDocId = item.id.replaceAll('/', '_').replaceAll('\\', '_');

    // 1. Try uploading the physical file to Firebase Storage if exists
    String? storagePath;
    try {
      final file = File(item.filePath);
      final storage = _storage;
      if (storage != null && await file.exists()) {
        final filename = p.basename(item.filePath);
        storagePath = 'users/$effectiveUid/documents/$safeDocId/$filename';
        final ref = storage.ref().child(storagePath);
        final uploadTask = await ref.putFile(file);
        cloudFileUrl = await uploadTask.ref.getDownloadURL();
      }
    } catch (e) {
      debugPrint('Firebase Storage upload skipped/fallback: $e');
    }

    // 2. Write metadata record to Cloud Firestore `users/{uid}/documents/{docId}`
    try {
      final db = _firestore;
      if (db != null) {
        await db
            .collection('users')
            .doc(effectiveUid)
            .collection('documents')
            .doc(safeDocId)
            .set({
          'id': item.id,
          'title': item.title,
          'shelf': item.shelf,
          'file_path': item.filePath,
          'file_url': cloudFileUrl,
          'storage_path': storagePath,
          'added_at': item.addedAt.toIso8601String(),
          'synced_at': DateTime.now().toIso8601String(),
          'user_id': effectiveUid,
        }, SetOptions(merge: true));
        debugPrint('Synced document "${item.title}" ($safeDocId) to Cloud Firestore for user $effectiveUid');
      }
    } catch (e) {
      debugPrint('Firestore document sync error: $e');
      return false;
    }

    // 3. Mark document as synced locally
    await _markDocumentSynced(item.id);
    return true;
  }

  /// Downloads a cloud document file (from Firebase Storage or HTTP URL) to local app storage.
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

      // 1. If storage path is provided or derivable, download via Firebase Storage SDK
      final storage = _storage;
      if (storage != null) {
        final path = (storagePath != null && storagePath.isNotEmpty)
            ? storagePath
            : 'users/$effectiveUid/documents/$safeDocId/$fileName';
        try {
          final ref = storage.ref().child(path);
          await ref.writeToFile(localFile);
          if (await localFile.exists() && await localFile.length() > 0) {
            debugPrint('Downloaded document file from Firebase Storage to: ${localFile.path}');
            return localFile;
          }
        } catch (e) {
          debugPrint('Firebase Storage writeToFile skipped: $e');
        }
      }

      // 2. If HTTP download URL is available, download via HttpClient
      if (cloudFileUrl != null && cloudFileUrl.startsWith('http')) {
        try {
          final client = HttpClient();
          final request = await client.getUrl(Uri.parse(cloudFileUrl));
          final response = await request.close();
          if (response.statusCode == 200) {
            final sink = localFile.openWrite();
            await response.pipe(sink);
            await sink.close();
            client.close();
            if (await localFile.exists() && await localFile.length() > 0) {
              debugPrint('Downloaded document file from HTTP URL to: ${localFile.path}');
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
  /// Used when logging into a new device.
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
        final localDocIds = localDocs.map((d) => d.id).toSet();

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

          // Check if file exists locally, otherwise download immediately!
          String effectiveFilePath = remoteFilePath;
          File localCheck = File(remoteFilePath);
          if (!localCheck.existsSync()) {
            final downloadedFile = await downloadDocumentFile(
              docId: id,
              cloudFileUrl: cloudFileUrl,
              storagePath: storagePath,
              originalFileName: p.basename(remoteFilePath),
              uid: effectiveUid,
            );
            if (downloadedFile != null) {
              effectiveFilePath = downloadedFile.path;
            }
          }

          if (!localDocIds.contains(id)) {
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
          } else if (effectiveFilePath != remoteFilePath) {
            // Update existing SQLite record with downloaded local path
            await DocumentRepository.instance.updateDocumentFilePath(id, effectiveFilePath);
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
