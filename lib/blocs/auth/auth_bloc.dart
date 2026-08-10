import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_shelf/blocs/auth/auth_event.dart';
import 'package:the_shelf/blocs/auth/auth_state.dart';
import 'package:the_shelf/services/auth_repository.dart';
import 'package:the_shelf/services/document_repository.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final DocumentRepository _documentRepository;
  StreamSubscription<dynamic>? _authStateSubscription;

  AuthBloc({
    AuthRepository? authRepository,
    DocumentRepository? documentRepository,
  })  : _authRepository = authRepository ?? AuthRepository(),
        _documentRepository = documentRepository ?? DocumentRepository.instance,
        super(const AuthInitial()) {
    on<AuthStarted>(_onAuthStarted);
    on<AuthUserChanged>(_onAuthUserChanged);
    on<SignInWithGoogleRequested>(_onSignInWithGoogleRequested);
    on<SignOutRequested>(_onSignOutRequested);
  }

  void _onAuthStarted(
    AuthStarted event,
    Emitter<AuthState> emit,
  ) {
    _authStateSubscription?.cancel();
    _authStateSubscription = _authRepository.authStateChanges.listen((user) {
      add(AuthUserChanged(user));
    });
  }

  Future<void> _onAuthUserChanged(
    AuthUserChanged event,
    Emitter<AuthState> emit,
  ) async {
    final user = event.user;
    if (user != null) {
      // Claim guest data upon first sign-in
      await _documentRepository.claimGuestData(user.uid);
      emit(Authenticated(user));
    } else {
      emit(const Unauthenticated());
    }
  }

  Future<void> _onSignInWithGoogleRequested(
    SignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final credential = await _authRepository.signInWithGoogle();
      if (credential == null) {
        // User cancelled Google sign-in
        final current = _authRepository.currentUser;
        if (current != null) {
          emit(Authenticated(current));
        } else {
          emit(const Unauthenticated());
        }
      }
    } catch (e) {
      emit(AuthError('Google Sign-In failed: ${e.toString()}'));
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.signOut();
      emit(const Unauthenticated());
    } catch (e) {
      emit(AuthError('Sign out failed: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
