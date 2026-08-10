import 'package:equatable/equatable.dart';

/// Simple local user model for frontend-only authentication.
class LocalUser extends Equatable {
  final String email;
  final String displayName;
  final DateTime createdAt;

  const LocalUser({
    required this.email,
    required this.displayName,
    required this.createdAt,
  });

  String get initials {
    if (displayName.isNotEmpty) return displayName[0].toUpperCase();
    if (email.isNotEmpty) return email[0].toUpperCase();
    return 'U';
  }

  @override
  List<Object?> get props => [email, displayName, createdAt];
}
