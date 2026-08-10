import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check if user has an existing session on app startup.
class AuthCheckSession extends AuthEvent {
  const AuthCheckSession();
}

/// Sign in with email and password.
class SignInRequested extends AuthEvent {
  final String email;
  final String password;

  const SignInRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// Sign up with email, password, and display name.
class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String displayName;

  const SignUpRequested({
    required this.email,
    required this.password,
    required this.displayName,
  });

  @override
  List<Object?> get props => [email, password, displayName];
}

/// Request passwordless email sign-in link via Firebase.
class SendMagicLinkRequested extends AuthEvent {
  final String email;

  const SendMagicLinkRequested(this.email);

  @override
  List<Object?> get props => [email];
}

/// Sign in or Sign up with Google.
class SignInWithGoogleRequested extends AuthEvent {
  const SignInWithGoogleRequested();
}

/// Update display name.
class UpdateDisplayNameRequested extends AuthEvent {
  final String displayName;

  const UpdateDisplayNameRequested(this.displayName);

  @override
  List<Object?> get props => [displayName];
}

/// Log out.
class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}
