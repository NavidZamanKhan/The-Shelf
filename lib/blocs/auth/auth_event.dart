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

/// Triggered when user submits email & password for Sign In.
class SignInWithEmailPasswordRequested extends AuthEvent {
  final String email;
  final String password;

  const SignInWithEmailPasswordRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Triggered when user submits email, password & display name for Sign Up.
class SignUpWithEmailPasswordRequested extends AuthEvent {
  final String email;
  final String password;
  final String displayName;

  const SignUpWithEmailPasswordRequested({
    required this.email,
    required this.password,
    required this.displayName,
  });

  @override
  List<Object?> get props => [email, password, displayName];
}

/// Triggered when user updates their display name from Profile Screen.
class UpdateDisplayNameRequested extends AuthEvent {
  final String displayName;

  const UpdateDisplayNameRequested(this.displayName);

  @override
  List<Object?> get props => [displayName];
}

/// Triggered when the user taps "Continue with Google".
class SignInWithGoogleRequested extends AuthEvent {
  const SignInWithGoogleRequested();
}

/// Triggered when the user taps "Log out".
class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}
