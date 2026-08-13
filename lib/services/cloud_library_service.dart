import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
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
    try {
      final file = File(item.filePath);
      final storage = _storage;
      if (storage != null && await file.exists()) {
        final filename = p.basename(item.filePath);
        final ref = storage.ref().child('users/$effectiveUid/documents/$safeDocId/$filename');
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
          final filePath = data['file_path'] as String? ?? '';
          final addedAtStr = data['added_at'] as String?;
          final addedAt = addedAtStr != null
              ? DateTime.tryParse(addedAtStr) ?? DateTime.now()
              : DateTime.now();

          if (!localDocIds.contains(id)) {
            final item = ShelfItem(
              id: id,
              title: title,
              shelf: shelf,
              filePath: filePath,
              addedAt: addedAt,
            );
            await DocumentRepository.instance.insertDocument(item);
            await _markDocumentSynced(id);
            restoredCount++;
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
