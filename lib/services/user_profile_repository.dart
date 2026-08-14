import 'dart:convert';
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
  String _userBioKey(String uid) => 'auth_user_bio_$uid';
  String _userPhotoKey(String uid) => 'auth_photo_url_$uid';
  String _userBannerKey(String uid) => 'auth_banner_url_$uid';

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
      return FirebaseStorage.instanceFor(bucket: 'the-shelf-39f9d.firebasestorage.app');
    } catch (_) {
      try {
        return FirebaseStorage.instance;
      } catch (_) {
        return null;
      }
    }
  }

  /// Copies a temporary picked media file to permanent application documents directory.
  Future<File> savePermanentLocalMedia({
    required String uid,
    required File tempFile,
    required String mediaType, // 'avatar' or 'banner'
  }) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final profileDir = Directory('${docsDir.path}/profile/$uid');
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

  /// Fetches the user profile from Cloud Firestore `users/{uid}` with strict per-user local cache fallback.
  Future<UserProfile> getUserProfile({
    required String uid,
    required String email,
    required String displayName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Purge any legacy un-namespaced keys to avoid cross-profile pollution
    await prefs.remove('auth_user_bio');
    await prefs.remove('auth_photo_url');
    await prefs.remove('auth_banner_url');

    final cachedBio = prefs.getString(_userBioKey(uid));
    final cachedPhotoUrl = prefs.getString(_userPhotoKey(uid));
    final cachedBannerUrl = prefs.getString(_userBannerKey(uid));

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

          // Cache to SharedPreferences strictly under this user's UID
          if (mergedBio != null) {
            await prefs.setString(_userBioKey(uid), mergedBio);
          } else {
            await prefs.remove(_userBioKey(uid));
          }
          if (mergedPhotoUrl != null) {
            await prefs.setString(_userPhotoKey(uid), mergedPhotoUrl);
          } else {
            await prefs.remove(_userPhotoKey(uid));
          }
          if (mergedBannerUrl != null) {
            await prefs.setString(_userBannerKey(uid), mergedBannerUrl);
          } else {
            await prefs.remove(_userBannerKey(uid));
          }

          return mergedProfile;
        } else {
          // Document does not exist in Firestore for this new user - return completely pristine profile
          return UserProfile(
            uid: uid,
            email: email,
            displayName: displayName,
            photoUrl: null,
            bannerUrl: null,
            bio: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
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

    // Cache locally scoped to this UID
    final prefs = await SharedPreferences.getInstance();
    if (profile.bio != null && profile.bio!.isNotEmpty) {
      await prefs.setString(_userBioKey(profile.uid), profile.bio!);
    } else {
      await prefs.remove(_userBioKey(profile.uid));
    }
    if (profile.photoUrl != null && profile.photoUrl!.isNotEmpty) {
      await prefs.setString(_userPhotoKey(profile.uid), profile.photoUrl!);
    } else {
      await prefs.remove(_userPhotoKey(profile.uid));
    }
    if (profile.bannerUrl != null && profile.bannerUrl!.isNotEmpty) {
      await prefs.setString(_userBannerKey(profile.uid), profile.bannerUrl!);
    } else {
      await prefs.remove(_userBannerKey(profile.uid));
    }

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
  /// Falls back to a cross-device synced Base64 Data URL if Firebase Storage is unavailable or offline.
  Future<String> uploadProfileMedia({
    required String uid,
    required File imageFile,
    required String mediaType, // 'avatar' or 'banner'
  }) async {
    // 1. Save to permanent local application directory scoped to this UID
    final permanentLocalFile = await savePermanentLocalMedia(
      uid: uid,
      tempFile: imageFile,
      mediaType: mediaType,
    );

    // 2. Attempt real Firebase Storage upload
    if (uid.isNotEmpty) {
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
        debugPrint('Firebase Storage upload error: $e. Falling back to Cloud Firestore Data URL.');
      }
    }

    // 3. Robust cross-device Fallback: Read bytes and create Base64 Data URL
    try {
      final bytes = await permanentLocalFile.readAsBytes();
      if (bytes.isNotEmpty) {
        final base64Str = base64Encode(bytes);
        return 'data:image/jpeg;base64,$base64Str';
      }
    } catch (e) {
      debugPrint('Error creating base64 data URL for profile media: $e');
    }

    return 'relative:profile/${p.basename(permanentLocalFile.path)}';
  }

  /// Helper utility for resolving safe ImageProvider across web URLs, base64 data URLs, and local files.
  static ImageProvider? resolveSafeImageProvider(String? urlStr, {Directory? docsDir}) {
    if (urlStr == null || urlStr.trim().isEmpty) return null;
    final trimmed = urlStr.trim();

    // 1. Remote HTTP/HTTPS image URL (Firebase Storage CDN)
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return NetworkImage(trimmed);
    }

    // 2. Base64 Data URL (cross-device Cloud Firestore sync)
    if (trimmed.startsWith('data:image/') || trimmed.contains(';base64,')) {
      try {
        final commaIndex = trimmed.indexOf(',');
        final base64Content = commaIndex != -1 ? trimmed.substring(commaIndex + 1) : trimmed;
        final bytes = base64Decode(base64Content.trim());
        return MemoryImage(bytes);
      } catch (e) {
        debugPrint('Error decoding base64 profile image: $e');
      }
    }

    try {
      // 3. Relative path relative:profile/avatar_xxx.jpg or profile/avatar_xxx.jpg
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

      // 4. Absolute local file path (with fallback to basename if iOS container UUID changed)
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
