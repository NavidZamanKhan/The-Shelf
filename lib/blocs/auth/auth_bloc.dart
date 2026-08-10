import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_shelf/blocs/auth/auth_event.dart';
import 'package:the_shelf/blocs/auth/auth_state.dart';
import 'package:the_shelf/models/user_profile.dart';
import 'package:the_shelf/services/auth_repository.dart';
import 'package:the_shelf/services/user_profile_repository.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final UserProfileRepository _userProfileRepository;

  AuthBloc({
    AuthRepository? authRepository,
    UserProfileRepository? userProfileRepository,
  })  : _authRepository = authRepository ?? AuthRepository(),
        _userProfileRepository = userProfileRepository ?? UserProfileRepository(),
        super(const AuthInitial()) {
    on<AuthCheckSession>(_onCheckSession);
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SendMagicLinkRequested>(_onSendMagicLinkRequested);
    on<SignInWithGoogleRequested>(_onSignInWithGoogleRequested);
    on<UpdateProfileDetailsRequested>(_onUpdateProfileDetails);
    on<SignOutRequested>(_onSignOutRequested);
  }

  String _resolveUid(String email) {
    try {
      final fbUid = FirebaseAuth.instance.currentUser?.uid;
      if (fbUid != null && fbUid.isNotEmpty) return fbUid;
    } catch (_) {}
    return email.trim().replaceAll('.', '_').replaceAll('@', '_at_');
  }

  Future<void> _onCheckSession(
    AuthCheckSession event,
    Emitter<AuthState> emit,
  ) async {
    final user = await _authRepository.getCurrentUser();
    if (user != null) {
      final uid = _resolveUid(user.email);
      final profile = await _userProfileRepository.getUserProfile(
        uid: uid,
        email: user.email,
        displayName: user.displayName,
      );
      // Auto-persist profile to Cloud Firestore
      await _userProfileRepository.saveUserProfile(profile);
      emit(Authenticated(profile));
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
      final uid = _resolveUid(user.email);
      final profile = await _userProfileRepository.getUserProfile(
        uid: uid,
        email: user.email,
        displayName: user.displayName,
      );
      // Auto-persist profile to Cloud Firestore
      await _userProfileRepository.saveUserProfile(profile);
      emit(Authenticated(profile));
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

      final uid = _resolveUid(user.email);
      final newProfile = UserProfile(
        uid: uid,
        email: user.email,
        displayName: user.displayName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Auto-persist profile to Cloud Firestore
      await _userProfileRepository.saveUserProfile(newProfile);
      emit(Authenticated(newProfile));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSendMagicLinkRequested(
    SendMagicLinkRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.sendEmailMagicLink(email: event.email);
      emit(MagicLinkSent(
        email: event.email,
        message: 'Passwordless sign-in link sent to ${event.email}! Check your inbox.',
      ));
    } on AuthException catch (e) {
      emit(MagicLinkSent(
        email: event.email,
        message: e.message,
      ));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignInWithGoogleRequested(
    SignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.signInWithGoogle();
      final uid = _resolveUid(user.email);
      final profile = await _userProfileRepository.getUserProfile(
        uid: uid,
        email: user.email,
        displayName: user.displayName,
      );
      // Auto-persist profile to Cloud Firestore
      await _userProfileRepository.saveUserProfile(profile);
      emit(Authenticated(profile));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onUpdateProfileDetails(
    UpdateProfileDetailsRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! Authenticated) return;

    final currentProfile = currentState.profile;
    final uid = currentProfile.uid;

    try {
      String? newPhotoUrl = currentProfile.photoUrl;
      String? newBannerUrl = currentProfile.bannerUrl;

      // Upload avatar image if picked
      if (event.photoPath != null && event.photoPath!.isNotEmpty) {
        newPhotoUrl = await _userProfileRepository.uploadProfileMedia(
          uid: uid,
          imageFile: File(event.photoPath!),
          mediaType: 'avatar',
        );
      }

      // Upload cover banner image if picked
      if (event.bannerPath != null && event.bannerPath!.isNotEmpty) {
        newBannerUrl = await _userProfileRepository.uploadProfileMedia(
          uid: uid,
          imageFile: File(event.bannerPath!),
          mediaType: 'banner',
        );
      }

      final updatedProfile = currentProfile.copyWith(
        displayName: event.displayName.trim().isNotEmpty
            ? event.displayName.trim()
            : currentProfile.displayName,
        bio: event.bio,
        photoUrl: newPhotoUrl,
        bannerUrl: newBannerUrl,
        updatedAt: DateTime.now(),
      );

      // Save to Cloud Firestore & Firebase Auth
      await _userProfileRepository.saveUserProfile(updatedProfile);
      await _authRepository.updateDisplayName(updatedProfile.displayName);

      emit(Authenticated(updatedProfile));
    } catch (e) {
      debugPrint('Error updating profile details: $e');
      emit(AuthError('Failed to update profile: $e'));
      // Restore authenticated state
      emit(Authenticated(currentProfile));
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
