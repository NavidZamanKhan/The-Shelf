import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Triggers initial subscription to authStateChanges.
class AuthStarted extends AuthEvent {
  const AuthStarted();
}

/// Internal event fired when authStateChanges stream emits a user update.
class AuthUserChanged extends AuthEvent {
  final User? user;

  const AuthUserChanged(this.user);

  @override
  List<Object?> get props => [user];
}

/// Triggered when the user taps "Continue with Google".
class SignInWithGoogleRequested extends AuthEvent {
  const SignInWithGoogleRequested();
}

/// Triggered when the user taps "Log out".
class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}
