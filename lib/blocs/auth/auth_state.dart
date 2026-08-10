import 'package:equatable/equatable.dart';
import 'package:the_shelf/models/local_user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state — checking if user session exists.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state during active authentication operations.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Authenticated state holding local user session.
class Authenticated extends AuthState {
  final LocalUser user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// Unauthenticated state — must sign in or sign up.
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// State emitted when a passwordless email magic link has been sent.
class MagicLinkSent extends AuthState {
  final String email;
  final String message;

  const MagicLinkSent({required this.email, required this.message});

  @override
  List<Object?> get props => [email, message];
}

/// Error state when a sign-in or sign-up attempt fails.
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
