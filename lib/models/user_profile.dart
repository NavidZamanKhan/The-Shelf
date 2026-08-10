import 'package:equatable/equatable.dart';

/// User profile model with Cloud Firestore synchronization support.
class UserProfile extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? bannerUrl;
  final String? bio;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.bannerUrl,
    this.bio,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Computes display initial letter for avatar fallback.
  String get initials {
    if (displayName.trim().isNotEmpty) return displayName.trim()[0].toUpperCase();
    if (email.trim().isNotEmpty) return email.trim()[0].toUpperCase();
    return 'U';
  }

  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? bannerUrl,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'bannerUrl': bannerUrl,
      'bio': bio,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, {required String defaultUid}) {
    DateTime parseDate(dynamic val) {
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val != null) {
        try {
          return (val as dynamic).toDate() as DateTime;
        } catch (_) {}
      }
      return DateTime.now();
    }

    return UserProfile(
      uid: (map['uid'] as String?) ?? defaultUid,
      email: (map['email'] as String?) ?? '',
      displayName: (map['displayName'] as String?) ?? '',
      photoUrl: map['photoUrl'] as String?,
      bannerUrl: map['bannerUrl'] as String?,
      bio: map['bio'] as String?,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  @override
  List<Object?> get props => [
        uid,
        email,
        displayName,
        photoUrl,
        bannerUrl,
        bio,
        createdAt,
        updatedAt,
      ];
}
