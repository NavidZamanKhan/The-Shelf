import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
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
          final profile = UserProfile.fromMap(doc.data()!, defaultUid: uid);

          // Cache to SharedPreferences
          if (profile.bio != null) await prefs.setString(_keyBio, profile.bio!);
          if (profile.photoUrl != null) await prefs.setString(_keyPhotoUrl, profile.photoUrl!);
          if (profile.bannerUrl != null) await prefs.setString(_keyBannerUrl, profile.bannerUrl!);

          return profile;
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
  /// Returns download URL if upload succeeds, or local file path if offline/unconfigured.
  Future<String> uploadProfileMedia({
    required String uid,
    required File imageFile,
    required String mediaType, // 'avatar' or 'banner'
  }) async {
    if (uid.isEmpty) return imageFile.path;

    try {
      final st = _storage;
      if (st != null) {
        final ref = st.ref().child('users').child(uid).child('$mediaType.jpg');
        final uploadTask = await ref.putFile(
          imageFile,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        debugPrint('Uploaded $mediaType image to Firebase Storage: $downloadUrl');
        return downloadUrl;
      }
    } catch (e) {
      debugPrint('Firebase Storage upload error: $e. Returning local file path.');
    }
    return imageFile.path;
  }
}
