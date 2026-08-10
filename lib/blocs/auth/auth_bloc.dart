import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_shelf/blocs/auth/auth_event.dart';
import 'package:the_shelf/blocs/auth/auth_state.dart';
import 'package:the_shelf/services/auth_repository.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({
    AuthRepository? authRepository,
  })  : _authRepository = authRepository ?? AuthRepository(),
        super(const AuthInitial()) {
    on<AuthCheckSession>(_onCheckSession);
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<UpdateDisplayNameRequested>(_onUpdateDisplayName);
    on<SignOutRequested>(_onSignOutRequested);
  }

  Future<void> _onCheckSession(
    AuthCheckSession event,
    Emitter<AuthState> emit,
  ) async {
    final user = await _authRepository.getCurrentUser();
    if (user != null) {
      emit(Authenticated(user));
    } else {
      emit(const Unauthenticated());
    }
  }

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      emit(Authenticated(user));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.signUpWithEmailAndPassword(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      );
      emit(Authenticated(user));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onUpdateDisplayName(
    UpdateDisplayNameRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = await _authRepository.updateDisplayName(event.displayName);
      if (user != null) {
        emit(Authenticated(user));
      }
    } catch (e) {
      emit(AuthError('Failed to update name: $e'));
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.signOut();
    emit(const Unauthenticated());
  }
}
