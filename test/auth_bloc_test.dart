import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_shelf/blocs/auth/auth_bloc.dart';
import 'package:the_shelf/blocs/auth/auth_event.dart';
import 'package:the_shelf/blocs/auth/auth_state.dart';
import 'package:the_shelf/services/auth_repository.dart';
import 'package:the_shelf/services/document_repository.dart';

class FakeAuthRepository implements AuthRepository {
  final StreamController<User?> controller = StreamController<User?>.broadcast();
  User? _user;

  void emitUser(User? user) {
    _user = user;
    controller.add(user);
  }

  @override
  Stream<User?> get authStateChanges => controller.stream;

  @override
  User? get currentUser => _user;

  @override
  Future<UserCredential?> signInWithGoogle() async => null;

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async => throw UnimplementedError();

  @override
  Future<void> updateDisplayName(String displayName) async {}

  @override
  Future<void> signOut() async => emitUser(null);
}

class FakeDocumentRepository implements DocumentRepository {
  String? claimedUserId;

  @override
  Future<void> claimGuestData(String userId) async {
    claimedUserId = userId;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuthRepository fakeAuthRepository;
  late FakeDocumentRepository fakeDocumentRepository;

  setUp(() {
    fakeAuthRepository = FakeAuthRepository();
    fakeDocumentRepository = FakeDocumentRepository();
  });

  group('AuthBloc Tests', () {
    test('initial state is AuthInitial', () {
      final bloc = AuthBloc(
        authRepository: fakeAuthRepository,
        documentRepository: fakeDocumentRepository,
      );
      expect(bloc.state, equals(const AuthInitial()));
    });

    test('emits Unauthenticated when authStateChanges emits null', () async {
      final bloc = AuthBloc(
        authRepository: fakeAuthRepository,
        documentRepository: fakeDocumentRepository,
      );

      bloc.add(const AuthStarted());
      await Future.delayed(Duration.zero);

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([const Unauthenticated()]),
      );

      fakeAuthRepository.emitUser(null);
      await expectation;
    });
  });
}
