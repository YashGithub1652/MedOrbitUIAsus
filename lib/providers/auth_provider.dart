import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../services/firebase_auth_service.dart';

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final bool isInitializing;
  final UserProfile? user;
  final String? error;
  final String? firebaseUid;

  const AuthState({
    this.isLoggedIn = false,
    this.isLoading = false,
    this.isInitializing = true,
    this.user,
    this.error,
    this.firebaseUid,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    bool? isInitializing,
    UserProfile? user,
    String? error,
    bool clearError = false,
    String? firebaseUid,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading ?? this.isLoading,
      isInitializing: isInitializing ?? this.isInitializing,
      user: user ?? this.user,
      error: clearError ? null : (error ?? this.error),
      firebaseUid: firebaseUid ?? this.firebaseUid,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _checkAuth();
  }

  final _authService = FirebaseAuthService();

  Future<void> _checkAuth() async {
    Future.delayed(const Duration(seconds: 4), () {
      if (state.isInitializing) {
        debugPrint('Auth timeout — forcing not-logged-in state');
        state = const AuthState(
          isInitializing: false,
          isLoggedIn: false,
        );
      }
    });

    try {
      final fbUser = _authService.currentUser;
      debugPrint('Firebase user: ${fbUser?.uid ?? 'none'}');

      if (fbUser != null) {
        UserProfile profile;
        try {
          profile = await _authService
              .loadCurrentUserProfile()
              .timeout(const Duration(seconds: 3));
        } catch (e) {
          debugPrint('Profile load failed, using basic info: $e');
          profile = UserProfile(
            id: fbUser.uid,
            name:
                fbUser.displayName ?? fbUser.email?.split('@').first ?? 'User',
            email: fbUser.email ?? '',
          );
        }

        if (mounted) {
          state = AuthState(
            isLoggedIn: true,
            isInitializing: false,
            user: profile,
            firebaseUid: fbUser.uid,
          );
        }
        return;
      }
    } catch (e) {
      debugPrint('Auth check error: $e');
    }

    if (mounted) {
      state = const AuthState(
        isInitializing: false,
        isLoggedIn: false,
      );
    }
  }

  Future<bool> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      state = state.copyWith(
        error: 'Email and password are required.',
        isLoading: false,
      );
      return false;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final profile = await _authService.loginWithEmail(email, password);
      state = AuthState(
        isLoggedIn: true,
        isInitializing: false,
        user: profile,
        firebaseUid: _authService.currentUser?.uid,
      );
      return true;
    } catch (e) {
      debugPrint('Login error: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> formData) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final profile = await _authService.registerWithEmail(formData);
      state = AuthState(
        isLoggedIn: true,
        isInitializing: false,
        user: profile,
        firebaseUid: _authService.currentUser?.uid,
      );
      return true;
    } catch (e) {
      debugPrint('Register error: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final profile = await _authService.signInWithGoogle();
      state = AuthState(
        isLoggedIn: true,
        isInitializing: false,
        user: profile,
        firebaseUid: _authService.currentUser?.uid,
      );
      return true;
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState(isInitializing: false);
  }

  Future<void> updateProfile(UserProfile updated) async {
    try {
      await _authService.updateProfile(updated);
      state = state.copyWith(user: updated);
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}
