import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_shelf/models/user_profile.dart';

/// Repository for Cloud Firestore & Firebase Storage user profile synchronization.
class UserProfileRepository {
  static const _keyBio = 'auth_user_bio';
  static const _keyPhotoUrl = 'auth_photo_url';
  static const _keyBannerUrl = 'auth_banner_url';

  final FirebaseFirestore? _customFirestore;
  final FirebaseStorage? _customStorage;

  UserProfileRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _customFirestore = firestore,
        _customStorage = storage;

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseStorage? get _storage {
    if (_customStorage != null) return _customStorage;
    try {
      return FirebaseStorage.instance;
    } catch (_) {
      return null;
    }
  }

  /// Copies a temporary picked media file to permanent application documents directory.
  Future<File> savePermanentLocalMedia({
    required File tempFile,
    required String mediaType, // 'avatar' or 'banner'
  }) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final profileDir = Directory('${docsDir.path}/profile');
      if (!await profileDir.exists()) {
        await profileDir.create(recursive: true);
      }
      final String filename = '${mediaType}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String permanentPath = '${profileDir.path}/$filename';
      return await tempFile.copy(permanentPath);
    } catch (e) {
      debugPrint('Error copying media to permanent storage: $e');
      return tempFile;
    }
  }

  /// Fetches the user profile from Cloud Firestore `users/{uid}` with local cache fallback.
  Future<UserProfile> getUserProfile({
    required String uid,
    required String email,
    required String displayName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedBio = prefs.getString(_keyBio);
    final cachedPhotoUrl = prefs.getString(_keyPhotoUrl);
    final cachedBannerUrl = prefs.getString(_keyBannerUrl);

    UserProfile localFallback = UserProfile(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: cachedPhotoUrl,
      bannerUrl: cachedBannerUrl,
      bio: cachedBio,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (uid.isEmpty) return localFallback;

    try {
      final db = _firestore;
      if (db != null) {
        final doc = await db.collection('users').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          final remoteProfile = UserProfile.fromMap(doc.data()!, defaultUid: uid);

          final mergedPhotoUrl = (remoteProfile.photoUrl != null && remoteProfile.photoUrl!.isNotEmpty)
              ? remoteProfile.photoUrl
              : cachedPhotoUrl;
          final mergedBannerUrl = (remoteProfile.bannerUrl != null && remoteProfile.bannerUrl!.isNotEmpty)
              ? remoteProfile.bannerUrl
              : cachedBannerUrl;
          final mergedBio = (remoteProfile.bio != null && remoteProfile.bio!.isNotEmpty)
              ? remoteProfile.bio
              : cachedBio;

          final mergedProfile = remoteProfile.copyWith(
            photoUrl: mergedPhotoUrl,
            bannerUrl: mergedBannerUrl,
            bio: mergedBio,
          );

          // Cache to SharedPreferences
          if (mergedBio != null) await prefs.setString(_keyBio, mergedBio);
          if (mergedPhotoUrl != null) await prefs.setString(_keyPhotoUrl, mergedPhotoUrl);
          if (mergedBannerUrl != null) await prefs.setString(_keyBannerUrl, mergedBannerUrl);

          return mergedProfile;
        }
      }
    } catch (e) {
      debugPrint('Cloud Firestore fetch error (using local cache): $e');
    }

    return localFallback;
  }

  /// Saves or updates the user profile document in Cloud Firestore `users/{profile.uid}`.
  Future<void> saveUserProfile(UserProfile profile) async {
    if (profile.uid.isEmpty) return;

    // Cache locally
    final prefs = await SharedPreferences.getInstance();
    if (profile.bio != null) await prefs.setString(_keyBio, profile.bio!);
    if (profile.photoUrl != null) await prefs.setString(_keyPhotoUrl, profile.photoUrl!);
    if (profile.bannerUrl != null) await prefs.setString(_keyBannerUrl, profile.bannerUrl!);

    try {
      final db = _firestore;
      if (db != null) {
        await db.collection('users').doc(profile.uid).set(
              profile.toMap(),
              SetOptions(merge: true),
            );
        debugPrint('Cloud Firestore profile saved for user ${profile.uid}');
      }
    } catch (e) {
      debugPrint('Cloud Firestore save error: $e');
    }
  }

  /// Uploads profile media (avatar or cover banner) to Firebase Storage.
  /// Returns public HTTPS download URL if upload succeeds, or relative local path if offline.
  Future<String> uploadProfileMedia({
    required String uid,
    required File imageFile,
    required String mediaType, // 'avatar' or 'banner'
  }) async {
    // Save to permanent local application directory first
    final permanentLocalFile = await savePermanentLocalMedia(
      tempFile: imageFile,
      mediaType: mediaType,
    );

    final String relativePath = 'relative:profile/${p.basename(permanentLocalFile.path)}';

    if (uid.isEmpty) return relativePath;

    try {
      final st = _storage;
      if (st != null) {
        final ref = st.ref().child('users').child(uid).child('$mediaType.jpg');
        final uploadTask = ref.putFile(
          permanentLocalFile,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        debugPrint('Uploaded $mediaType image to Firebase Storage: $downloadUrl');
        return downloadUrl;
      }
    } catch (e) {
      debugPrint('Firebase Storage upload error: $e. Returning relative local file path.');
    }

    return relativePath;
  }

  /// Helper utility for resolving safe ImageProvider across web URLs, relative paths, and local files.
  static ImageProvider? resolveSafeImageProvider(String? urlStr, {Directory? docsDir}) {
    if (urlStr == null || urlStr.trim().isEmpty) return null;
    final trimmed = urlStr.trim();

    // 1. Remote HTTP/HTTPS image URL (Firebase Storage CDN)
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return NetworkImage(trimmed);
    }

    try {
      // 2. Relative path relative:profile/avatar_xxx.jpg or profile/avatar_xxx.jpg
      String relPath = trimmed;
      if (relPath.startsWith('relative:')) {
        relPath = relPath.substring('relative:'.length);
      }

      if (docsDir != null) {
        final fileInDocs = File('${docsDir.path}/$relPath');
        if (fileInDocs.existsSync()) {
          return FileImage(fileInDocs);
        }

        final fileName = p.basename(trimmed);
        final profileFallback = File('${docsDir.path}/profile/$fileName');
        if (profileFallback.existsSync()) {
          return FileImage(profileFallback);
        }
      }

      // 3. Absolute local file path (with fallback to basename if iOS container UUID changed)
      final directFile = File(trimmed);
      if (directFile.existsSync()) {
        return FileImage(directFile);
      }

      if (docsDir != null) {
        final baseName = p.basename(trimmed);
        final healedFile = File('${docsDir.path}/profile/$baseName');
        if (healedFile.existsSync()) {
          return FileImage(healedFile);
        }
      }
    } catch (e) {
      debugPrint('Error resolving profile image provider: $e');
    }

    return null;
  }
}
