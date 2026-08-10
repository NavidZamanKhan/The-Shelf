import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Repository encapsulating Firebase Authentication (Email/Password & Google Sign-In) operations.
class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Currently authenticated Firebase user (or null if signed out/guest).
  User? get currentUser => _firebaseAuth.currentUser;

  /// Signs in with Email and Password.
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      debugPrint('Error signing in with Email/Password: $e');
      rethrow;
    }
  }

  /// Creates a new user with Email, Password, and Display Name.
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (displayName.trim().isNotEmpty && credential.user != null) {
        await credential.user!.updateDisplayName(displayName.trim());
        await credential.user!.reload();
      }

      return credential;
    } catch (e) {
      debugPrint('Error signing up with Email/Password: $e');
      rethrow;
    }
  }

  /// Updates the display name of the current authenticated user.
  Future<void> updateDisplayName(String displayName) async {
    final user = _firebaseAuth.currentUser;
    if (user != null && displayName.trim().isNotEmpty) {
      await user.updateDisplayName(displayName.trim());
      await user.reload();
    }
  }

  /// Signs in with Google using native GoogleSignIn account selection and Firebase credential.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      return await _firebaseAuth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Error during Google Sign-In: $e');
      rethrow;
    }
  }

  /// Signs out of both Firebase Auth and Google Sign-In.
  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      debugPrint('Error during sign out: $e');
      rethrow;
    }
  }
}
