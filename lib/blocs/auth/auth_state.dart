import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial uninitialized state.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state during active authentication operations.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Authenticated state holding active Firebase user session.
class Authenticated extends AuthState {
  final User user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// Unauthenticated state (guest mode or signed out).
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Error state when a sign-in or sign-out attempt fails.
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
