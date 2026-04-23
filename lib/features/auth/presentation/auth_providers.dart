import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository();
});

/// Reactive stream of the current authentication state.
final authStateProvider = StreamProvider<AppAuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Handles authentication actions and exposes loading/error state to the UI.
final authControllerProvider = AsyncNotifierProvider<AuthNotifier, void>(() {
  return AuthNotifier();
});

class AuthNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(authRepositoryProvider).signInWithEmail(email, password));
  }

  Future<void> signUpWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(authRepositoryProvider).signUpWithEmail(email, password));
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(authRepositoryProvider).signInWithGoogle());
  }

  Future<void> signInWithApple() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(authRepositoryProvider).signInWithApple());
  }

  Future<void> resendVerificationEmail() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(authRepositoryProvider).resendVerificationEmail());
  }

  Future<void> sendPasswordResetEmail(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(authRepositoryProvider).sendPasswordResetEmail(email));
  }

  Future<void> updatePassword(String newPassword) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(authRepositoryProvider).updatePassword(newPassword));
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(authRepositoryProvider).signOut());
  }
}
