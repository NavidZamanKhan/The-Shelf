import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_shelf/models/local_user.dart';

/// Authentication repository supporting email/password and Google Sign-In.
class AuthRepository {
  static const _keyEmail = 'auth_email';
  static const _keyPassword = 'auth_password';
  static const _keyDisplayName = 'auth_display_name';
  static const _keyCreatedAt = 'auth_created_at';
  static const _keyLoggedIn = 'auth_logged_in';

  /// Check if a user session is currently active.
  Future<LocalUser?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool(_keyLoggedIn) ?? false;
    if (!loggedIn) return null;

    final email = prefs.getString(_keyEmail);
    final name = prefs.getString(_keyDisplayName) ?? '';
    final createdMs = prefs.getInt(_keyCreatedAt) ?? 0;

    if (email == null || email.isEmpty) return null;

    return LocalUser(
      email: email,
      displayName: name,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdMs),
    );
  }

  /// Sign in with stored credentials.
  Future<LocalUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final storedEmail = prefs.getString(_keyEmail);
    final storedPassword = prefs.getString(_keyPassword);

    if (storedEmail == null || storedPassword == null) {
      throw AuthException('No account found. Please create one first.');
    }

    if (email.trim().toLowerCase() != storedEmail.toLowerCase()) {
      throw AuthException('No account found with this email.');
    }

    if (password != storedPassword) {
      throw AuthException('Incorrect password.');
    }

    await prefs.setBool(_keyLoggedIn, true);

    return LocalUser(
      email: storedEmail,
      displayName: prefs.getString(_keyDisplayName) ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        prefs.getInt(_keyCreatedAt) ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// Create a new account and sign in.
  Future<LocalUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (email.trim().isEmpty) {
      throw AuthException('Please enter a valid email address.');
    }
    if (password.length < 6) {
      throw AuthException('Password should be at least 6 characters.');
    }

    final prefs = await SharedPreferences.getInstance();
    final existingEmail = prefs.getString(_keyEmail);

    if (existingEmail != null &&
        existingEmail.toLowerCase() == email.trim().toLowerCase()) {
      throw AuthException('An account already exists with this email.');
    }

    final now = DateTime.now();
    await prefs.setString(_keyEmail, email.trim());
    await prefs.setString(_keyPassword, password);
    await prefs.setString(_keyDisplayName, displayName.trim());
    await prefs.setInt(_keyCreatedAt, now.millisecondsSinceEpoch);
    await prefs.setBool(_keyLoggedIn, true);

    return LocalUser(
      email: email.trim(),
      displayName: displayName.trim(),
      createdAt: now,
    );
  }

  /// Sign in or Sign up using Google account.
  Future<LocalUser> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn.instance.authenticate();

      String email = googleUser.email;
      String displayName = googleUser.displayName ?? 'Google User';

      // Attempt Firebase authentication if configured
      try {
        final googleAuth = googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        final userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
        final fbUser = userCredential.user;
        if (fbUser != null) {
          if (fbUser.email != null) email = fbUser.email!;
          if (fbUser.displayName != null) displayName = fbUser.displayName!;
        }
      } catch (e) {
        debugPrint('Firebase Auth not available, using Google account details: $e');
      }

      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyEmail, email);
      await prefs.setString(_keyDisplayName, displayName);
      await prefs.setInt(_keyCreatedAt, now.millisecondsSinceEpoch);
      await prefs.setBool(_keyLoggedIn, true);

      return LocalUser(
        email: email,
        displayName: displayName,
        createdAt: now,
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      throw AuthException('Google Sign-In failed: $e');
    }
  }

  /// Update the display name of the current user.
  Future<LocalUser?> updateDisplayName(String displayName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDisplayName, displayName.trim());
    return getCurrentUser();
  }

  /// Sign out (clear session & Google/Firebase sign in).
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, false);
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    debugPrint('User signed out.');
  }
}

/// Simple exception for auth errors with user-friendly messages.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}
