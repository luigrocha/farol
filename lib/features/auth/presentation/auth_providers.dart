import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';
import '../domain/app_user.dart';
import '../domain/auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository();
});

/// Reactive stream of the current authentication state.
/// Emits the current session synchronously so the app never shows a spinner
/// on cold start when the user is already logged in.
final authStateProvider = StreamProvider<AppAuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  // Read the cached session synchronously — no network call needed.
  final cachedUser = Supabase.instance.client.auth.currentUser;
  final AppAuthState initialState = cachedUser != null
      ? AppAuthAuthenticated(AppUser.fromSupabase(cachedUser))
      : const AppAuthUnauthenticated();
  // Prepend the synchronous initial value so the app never blocks on cold start.
  final controller = StreamController<AppAuthState>();
  controller.add(initialState);
  controller.addStream(repo.authStateChanges).then((_) => controller.close());
  return controller.stream;
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

  Future<void> signUpWithEmail(String email, String password, {String? fullName, String? cpf}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(authRepositoryProvider).signUpWithEmail(email, password, fullName: fullName, cpf: cpf));
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
