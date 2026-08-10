import 'package:equatable/equatable.dart';
import 'package:the_shelf/models/user_profile.dart';

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

/// Authenticated state holding active user profile session.
class Authenticated extends AuthState {
  final UserProfile profile;

  const Authenticated(this.profile);

  @override
  List<Object?> get props => [profile];
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
