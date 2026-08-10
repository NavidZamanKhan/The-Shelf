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
    on<SignInWithEmailPasswordRequested>(_onSignInWithEmailPasswordRequested);
    on<SignUpWithEmailPasswordRequested>(_onSignUpWithEmailPasswordRequested);
    on<UpdateDisplayNameRequested>(_onUpdateDisplayNameRequested);
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
      // Claim guest data upon sign-in
      await _documentRepository.claimGuestData(user.uid);
      emit(Authenticated(user));
    } else {
      emit(const Unauthenticated());
    }
  }

  Future<void> _onSignInWithEmailPasswordRequested(
    SignInWithEmailPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
    } catch (e) {
      emit(AuthError(_cleanErrorMessage(e)));
    }
  }

  Future<void> _onSignUpWithEmailPasswordRequested(
    SignUpWithEmailPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.signUpWithEmailAndPassword(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      );
    } catch (e) {
      emit(AuthError(_cleanErrorMessage(e)));
    }
  }

  Future<void> _onUpdateDisplayNameRequested(
    UpdateDisplayNameRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.updateDisplayName(event.displayName);
      final current = _authRepository.currentUser;
      if (current != null) {
        emit(Authenticated(current));
      }
    } catch (e) {
      emit(AuthError('Failed to update name: ${_cleanErrorMessage(e)}'));
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
        final current = _authRepository.currentUser;
        if (current != null) {
          emit(Authenticated(current));
        } else {
          emit(const Unauthenticated());
        }
      }
    } catch (e) {
      emit(AuthError(_cleanErrorMessage(e)));
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
      emit(AuthError('Sign out failed: ${_cleanErrorMessage(e)}'));
    }
  }

  String _cleanErrorMessage(dynamic e) {
    final str = e.toString();
    if (str.contains('user-not-found')) return 'No account found with this email.';
    if (str.contains('wrong-password')) return 'Incorrect password.';
    if (str.contains('email-already-in-use')) return 'An account already exists for this email.';
    if (str.contains('invalid-email')) return 'Please enter a valid email address.';
    if (str.contains('weak-password')) return 'Password should be at least 6 characters.';
    return str.replaceAll(RegExp(r'\[.*?\]'), '').trim();
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
