import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_shelf/models/local_user.dart';

/// Frontend-only authentication repository using SharedPreferences.
/// Stores user credentials locally — no backend required.
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

  /// Create a new local account and sign in.
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

  /// Update the display name of the current user.
  Future<LocalUser?> updateDisplayName(String displayName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDisplayName, displayName.trim());
    return getCurrentUser();
  }

  /// Sign out (clear the session flag).
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, false);
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
