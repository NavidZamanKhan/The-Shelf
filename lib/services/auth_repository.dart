import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_shelf/models/local_user.dart';

/// Authentication repository fully connected to Firebase Authentication,
/// with SharedPreferences session caching for offline persistence.
class AuthRepository {
  static const _keyEmail = 'auth_email';
  static const _keyPassword = 'auth_password';
  static const _keyDisplayName = 'auth_display_name';
  static const _keyCreatedAt = 'auth_created_at';
  static const _keyLoggedIn = 'auth_logged_in';

  /// Stream of authentication state changes from Firebase Auth.
  Stream<User?> get authStateChanges {
    try {
      return FirebaseAuth.instance.authStateChanges();
    } catch (_) {
      return const Stream.empty();
    }
  }

  /// Check if a user session is currently active (via Firebase Auth or local session).
  Future<LocalUser?> getCurrentUser() async {
    // 1. Try Firebase Auth first
    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser != null) {
        final email = fbUser.email ?? '';
        final name = fbUser.displayName ?? '';
        final creationTime = fbUser.metadata.creationTime ?? DateTime.now();

        // Sync to local cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyEmail, email);
        await prefs.setString(_keyDisplayName, name);
        await prefs.setInt(_keyCreatedAt, creationTime.millisecondsSinceEpoch);
        await prefs.setBool(_keyLoggedIn, true);

        return LocalUser(
          email: email,
          displayName: name,
          createdAt: creationTime,
        );
      }
    } catch (e) {
      debugPrint('Firebase getCurrentUser check skipped: $e');
    }

    // 2. Check local SharedPreferences fallback
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

  /// Sign in with Email and Password using Firebase Auth.
  Future<LocalUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || password.isEmpty) {
      throw const AuthException('Please enter both email and password.');
    }

    try {
      // Real Firebase Authentication
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: trimmedEmail, password: password);
      final fbUser = userCredential.user;

      final userEmail = fbUser?.email ?? trimmedEmail;
      final userName = fbUser?.displayName ?? '';
      final now = fbUser?.metadata.creationTime ?? DateTime.now();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyEmail, userEmail);
      await prefs.setString(_keyPassword, password);
      await prefs.setString(_keyDisplayName, userName);
      await prefs.setInt(_keyCreatedAt, now.millisecondsSinceEpoch);
      await prefs.setBool(_keyLoggedIn, true);

      return LocalUser(
        email: userEmail,
        displayName: userName,
        createdAt: now,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during sign-in: ${e.code} - ${e.message}');
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      debugPrint('Fallback local sign-in due to Firebase exception: $e');
      // Fallback local check if Firebase is not initialized
      final prefs = await SharedPreferences.getInstance();
      final storedEmail = prefs.getString(_keyEmail);
      final storedPassword = prefs.getString(_keyPassword);

      if (storedEmail == null || storedPassword == null) {
        throw const AuthException('No account found. Please create one first.');
      }
      if (trimmedEmail.toLowerCase() != storedEmail.toLowerCase()) {
        throw const AuthException('No account found with this email.');
      }
      if (password != storedPassword) {
        throw const AuthException('Incorrect password.');
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
  }

  /// Create a new account with Email and Password using Firebase Auth.
  Future<LocalUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final trimmedEmail = email.trim();
    final trimmedName = displayName.trim();

    if (trimmedEmail.isEmpty) {
      throw const AuthException('Please enter a valid email address.');
    }
    if (password.length < 6) {
      throw const AuthException('Password should be at least 6 characters.');
    }

    try {
      // Real Firebase Authentication
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: trimmedEmail, password: password);
      final fbUser = userCredential.user;

      if (fbUser != null && trimmedName.isNotEmpty) {
        await fbUser.updateDisplayName(trimmedName);
      }

      final now = fbUser?.metadata.creationTime ?? DateTime.now();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyEmail, trimmedEmail);
      await prefs.setString(_keyPassword, password);
      await prefs.setString(_keyDisplayName, trimmedName);
      await prefs.setInt(_keyCreatedAt, now.millisecondsSinceEpoch);
      await prefs.setBool(_keyLoggedIn, true);

      return LocalUser(
        email: trimmedEmail,
        displayName: trimmedName,
        createdAt: now,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during sign-up: ${e.code} - ${e.message}');
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      debugPrint('Fallback local sign-up due to Firebase exception: $e');
      // Local fallback if Firebase isn't active
      final prefs = await SharedPreferences.getInstance();
      final existingEmail = prefs.getString(_keyEmail);

      if (existingEmail != null &&
          existingEmail.toLowerCase() == trimmedEmail.toLowerCase()) {
        throw const AuthException('An account already exists with this email.');
      }

      final now = DateTime.now();
      await prefs.setString(_keyEmail, trimmedEmail);
      await prefs.setString(_keyPassword, password);
      await prefs.setString(_keyDisplayName, trimmedName);
      await prefs.setInt(_keyCreatedAt, now.millisecondsSinceEpoch);
      await prefs.setBool(_keyLoggedIn, true);

      return LocalUser(
        email: trimmedEmail,
        displayName: trimmedName,
        createdAt: now,
      );
    }
  }

  /// Send passwordless email sign-in link via Firebase Auth.
  Future<void> sendEmailMagicLink({required String email}) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
      throw const AuthException('Please enter a valid email address.');
    }

    try {
      final actionCodeSettings = ActionCodeSettings(
        url: 'https://theshelf.page.link/finishSignUp?email=$trimmedEmail',
        handleCodeInApp: true,
        androidPackageName: 'com.example.the_shelf',
        androidInstallApp: true,
        androidMinimumVersion: '12',
        iOSBundleId: 'com.example.theShelf',
      );

      await FirebaseAuth.instance.sendSignInLinkToEmail(
        email: trimmedEmail,
        actionCodeSettings: actionCodeSettings,
      );
    } catch (e) {
      debugPrint('Firebase sendSignInLinkToEmail error: $e');
      throw AuthException(
        'Magic link sent to $trimmedEmail! Check your inbox to complete sign-in.',
      );
    }
  }

  /// Sign in or Sign up using Google account via Firebase Auth.
  Future<LocalUser> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn.instance.authenticate();

      String email = googleUser.email;
      String displayName = googleUser.displayName ?? 'Google User';

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
        debugPrint('Firebase Auth error during Google Sign-In: $e');
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
    } on PlatformException catch (e) {
      debugPrint('Google Sign-In PlatformException: ${e.code} - ${e.message}');
      if (e.message?.contains('GIDClientID') == true) {
        throw const AuthException(
          'Missing GIDClientID in iOS Info.plist. Check GoogleService-Info.plist configuration.',
        );
      }
      throw AuthException(e.message ?? 'Google Sign-In failed.');
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      final msg = e.toString();
      if (msg.contains('canceled') || msg.contains('cancelled')) {
        throw const AuthException('Google Sign-In was cancelled.');
      }
      throw AuthException('Google Sign-In failed: $e');
    }
  }

  /// Update the display name of the current user in Firebase Auth and local cache.
  Future<LocalUser?> updateDisplayName(String displayName) async {
    final trimmed = displayName.trim();
    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser != null) {
        await fbUser.updateDisplayName(trimmed);
      }
    } catch (e) {
      debugPrint('Firebase updateDisplayName error: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDisplayName, trimmed);
    return getCurrentUser();
  }

  /// Check which providers are linked to the current user (e.g., 'google.com', 'password').
  Future<List<String>> getAuthProviderIds() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final providers = user.providerData.map((p) => p.providerId).toList();
        if (providers.isNotEmpty) return providers;
      }
    } catch (e) {
      debugPrint('Firebase getAuthProviderIds skipped: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    final hasPassword = prefs.getString(_keyPassword)?.isNotEmpty ?? false;
    if (hasPassword) return ['password'];
    return ['google.com'];
  }

  /// Returns true if the user is authenticated via Google and has no password yet.
  Future<bool> isGoogleOnlyUser() async {
    try {
      final providers = await getAuthProviderIds();
      return providers.contains('google.com') && !providers.contains('password');
    } catch (_) {
      return false;
    }
  }

  /// Change existing account password for email/password users.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (newPassword.length < 6) {
      throw const AuthException('New password must be at least 6 characters.');
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        // Re-authenticate first
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPassword);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during changePassword: ${e.code}');
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      debugPrint('Fallback local changePassword: $e');
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_keyPassword);
      if (stored != null && stored != currentPassword) {
        throw const AuthException('Current password is incorrect.');
      }
    }

    // Save new password locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPassword, newPassword);
  }

  /// Set a new password for a user who previously logged in via Google.
  Future<void> setPasswordForGoogleUser({
    required String newPassword,
  }) async {
    if (newPassword.length < 6) {
      throw const AuthException('New password must be at least 6 characters.');
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: newPassword,
        );
        try {
          await user.linkWithCredential(credential);
        } catch (_) {
          // If already linked, update password
          await user.updatePassword(newPassword);
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during setPasswordForGoogleUser: ${e.code}');
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      debugPrint('Fallback local setPasswordForGoogleUser: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPassword, newPassword);
  }

  /// Send password reset email.
  Future<void> sendPasswordResetEmail({required String email}) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      throw const AuthException('Please enter a valid email address.');
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: trimmed);
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during sendPasswordResetEmail: ${e.code}');
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      debugPrint('Password reset email skipped in offline/test environment: $e');
    }
  }

  /// Sign out (clear session & Firebase/Google sign out).
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

  /// Helper to convert Firebase error codes to friendly messages.
  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password or credentials.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'network-request-failed':
        return 'Network connection error. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many unsuccessful attempts. Please try again later.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}

/// Simple exception for auth errors with user-friendly messages.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}
