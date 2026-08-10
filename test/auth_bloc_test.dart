import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_shelf/blocs/auth/auth_bloc.dart';
import 'package:the_shelf/blocs/auth/auth_event.dart';
import 'package:the_shelf/blocs/auth/auth_state.dart';
import 'package:the_shelf/models/local_user.dart';
import 'package:the_shelf/models/user_profile.dart';
import 'package:the_shelf/services/auth_repository.dart';
import 'package:the_shelf/services/user_profile_repository.dart';

/// Fake auth repository operating in-memory.
class FakeAuthRepository extends AuthRepository {
  LocalUser? _currentUser;
  bool _loggedIn = false;
  String? _storedEmail;
  String? _storedPassword;

  @override
  Future<LocalUser?> getCurrentUser() async {
    return _loggedIn ? _currentUser : null;
  }

  @override
  Future<LocalUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (_storedEmail == null || _storedPassword == null) {
      throw const AuthException('No account found. Please create one first.');
    }
    if (email != _storedEmail) {
      throw const AuthException('No account found with this email.');
    }
    if (password != _storedPassword) {
      throw const AuthException('Incorrect password.');
    }
    _loggedIn = true;
    return _currentUser!;
  }

  @override
  Future<LocalUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _storedEmail = email;
    _storedPassword = password;
    _currentUser = LocalUser(
      email: email,
      displayName: displayName,
      createdAt: DateTime.now(),
    );
    _loggedIn = true;
    return _currentUser!;
  }

  @override
  Future<LocalUser> signInWithGoogle() async {
    _currentUser = LocalUser(
      email: 'googleuser@example.com',
      displayName: 'Google User',
      createdAt: DateTime.now(),
    );
    _loggedIn = true;
    return _currentUser!;
  }

  @override
  Future<LocalUser?> updateDisplayName(String displayName) async {
    if (_currentUser != null) {
      _currentUser = LocalUser(
        email: _currentUser!.email,
        displayName: displayName,
        createdAt: _currentUser!.createdAt,
      );
    }
    return _currentUser;
  }

  @override
  Future<void> signOut() async {
    _loggedIn = false;
  }
}

/// Fake user profile repository operating in-memory.
class FakeUserProfileRepository extends UserProfileRepository {
  final Map<String, UserProfile> _profiles = {};

  @override
  Future<UserProfile> getUserProfile({
    required String uid,
    required String email,
    required String displayName,
  }) async {
    if (_profiles.containsKey(uid)) {
      return _profiles[uid]!;
    }
    final profile = UserProfile(
      uid: uid,
      email: email,
      displayName: displayName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _profiles[uid] = profile;
    return profile;
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    _profiles[profile.uid] = profile;
  }

  @override
  Future<String> uploadProfileMedia({
    required String uid,
    required File imageFile,
    required String mediaType,
  }) async {
    return 'https://fake-storage.example.com/$uid/$mediaType.jpg';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuthRepository fakeAuthRepository;
  late FakeUserProfileRepository fakeUserProfileRepository;

  setUp(() {
    fakeAuthRepository = FakeAuthRepository();
    fakeUserProfileRepository = FakeUserProfileRepository();
  });

  group('AuthBloc Tests', () {
    test('initial state is AuthInitial', () {
      final bloc = AuthBloc(
        authRepository: fakeAuthRepository,
        userProfileRepository: fakeUserProfileRepository,
      );
      expect(bloc.state, equals(const AuthInitial()));
    });

    test('emits Unauthenticated when no session exists', () async {
      final bloc = AuthBloc(
        authRepository: fakeAuthRepository,
        userProfileRepository: fakeUserProfileRepository,
      );

      bloc.add(const AuthCheckSession());

      await expectLater(
        bloc.stream,
        emitsInOrder([const Unauthenticated()]),
      );
    });

    test('emits Authenticated with UserProfile after successful sign up', () async {
      final bloc = AuthBloc(
        authRepository: fakeAuthRepository,
        userProfileRepository: fakeUserProfileRepository,
      );

      bloc.add(const SignUpRequested(
        email: 'test@example.com',
        password: 'password123',
        displayName: 'Test User',
      ));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const AuthLoading(),
          isA<Authenticated>(),
        ]),
      );
    });

    test('emits Authenticated after Google Sign-In', () async {
      final bloc = AuthBloc(
        authRepository: fakeAuthRepository,
        userProfileRepository: fakeUserProfileRepository,
      );

      bloc.add(const SignInWithGoogleRequested());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const AuthLoading(),
          isA<Authenticated>(),
        ]),
      );
    });

    test('emits AuthError on sign in with no account', () async {
      final bloc = AuthBloc(
        authRepository: fakeAuthRepository,
        userProfileRepository: fakeUserProfileRepository,
      );

      bloc.add(const SignInRequested(
        email: 'nobody@example.com',
        password: 'wrong',
      ));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const AuthLoading(),
          isA<AuthError>(),
        ]),
      );
    });

    test('updates profile details (reading motto / bio) successfully', () async {
      final bloc = AuthBloc(
        authRepository: fakeAuthRepository,
        userProfileRepository: fakeUserProfileRepository,
      );

      bloc.add(const SignUpRequested(
        email: 'reader@example.com',
        password: 'password123',
        displayName: 'Bookworm',
      ));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const AuthLoading(),
          isA<Authenticated>(),
        ]),
      );

      bloc.add(const UpdateProfileDetailsRequested(
        displayName: 'Jane Austen Fan',
        bio: 'A room without books is like a body without a soul.',
      ));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<Authenticated>().having(
            (state) => state.profile.bio,
            'bio',
            contains('body without a soul'),
          ),
        ]),
      );
    });

    test('emits Unauthenticated after sign out', () async {
      final bloc = AuthBloc(
        authRepository: fakeAuthRepository,
        userProfileRepository: fakeUserProfileRepository,
      );

      // Sign up first
      bloc.add(const SignUpRequested(
        email: 'test@example.com',
        password: 'password123',
        displayName: 'Test User',
      ));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const AuthLoading(),
          isA<Authenticated>(),
        ]),
      );

      // Now sign out
      bloc.add(const SignOutRequested());

      await expectLater(
        bloc.stream,
        emitsInOrder([const Unauthenticated()]),
      );
    });
  });
}
