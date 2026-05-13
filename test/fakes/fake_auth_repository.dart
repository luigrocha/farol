// ignore_for_file: avoid_print
/// A fully in-memory, no-network AuthRepository used in Widget and Unit tests.
/// It simulates realistic auth scenarios without any Supabase dependency.
library;

import 'dart:async';
import 'package:farol/features/auth/data/auth_repository.dart';
import 'package:farol/features/auth/domain/app_user.dart';
import 'package:farol/features/auth/domain/auth_state.dart';

/// Holds a pre-canned result for the next [FakeAuthRepository] call.
/// Tests can configure these before calling auth methods.
class FakeAuthBehavior {
  bool shouldThrowNetworkError;
  bool shouldThrowInvalidCredentials;
  bool shouldThrowEmailAlreadyExists;
  bool shouldThrowWeakPassword;
  bool shouldThrowEmailNotConfirmed;
  Duration delay;

  FakeAuthBehavior({
    this.shouldThrowNetworkError = false,
    this.shouldThrowInvalidCredentials = false,
    this.shouldThrowEmailAlreadyExists = false,
    this.shouldThrowWeakPassword = false,
    this.shouldThrowEmailNotConfirmed = false,
    this.delay = const Duration(milliseconds: 10),
  });
}

class FakeAuthRepository implements AuthRepository {
  // In-memory "database"
  final Map<String, String> _users = {}; // email -> password
  String? _currentUserEmail;
  final _stateController = StreamController<AppAuthState>.broadcast();

  // Test seeding: add pre-existing users
  void seedUser(String email, String password) => _users[email] = password;

  // Configurable behavior for the next call
  FakeAuthBehavior behavior = FakeAuthBehavior();

  @override
  AppUser? get currentUser {
    if (_currentUserEmail == null) return null;
    return AppUser(
      uid: 'fake-uid-${_currentUserEmail.hashCode}',
      email: _currentUserEmail,
      emailVerified: true,
    );
  }

  @override
  Stream<AppAuthState> get authStateChanges => _stateController.stream;

  void _emitState(AppAuthState state) => _stateController.add(state);

  void _checkBehavior() {
    if (behavior.shouldThrowNetworkError) {
      throw Exception('Network error: Unable to connect.');
    }
  }

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    await Future.delayed(behavior.delay);
    _checkBehavior();

    if (behavior.shouldThrowInvalidCredentials ||
        !_users.containsKey(email) ||
        _users[email] != password) {
      throw Exception('Invalid email or password.');
    }
    if (behavior.shouldThrowEmailNotConfirmed) {
      throw Exception('Please verify your email before signing in.');
    }

    _currentUserEmail = email;
    final user = currentUser!;
    _emitState(AppAuthAuthenticated(user));
    return user;
  }

  @override
  Future<AppUser> signUpWithEmail(
    String email,
    String password, {
    String? fullName,
    String? cpf,
  }) async {
    await Future.delayed(behavior.delay);
    _checkBehavior();

    if (behavior.shouldThrowEmailAlreadyExists || _users.containsKey(email)) {
      throw Exception(
          'This email is already registered. Try signing in instead.');
    }
    if (behavior.shouldThrowWeakPassword || password.length < 6) {
      throw Exception('Password should be at least 6 characters.');
    }

    _users[email] = password;
    _currentUserEmail = email;
    final user = AppUser(
      uid: 'fake-uid-${email.hashCode}',
      email: email,
      emailVerified: false, // Simulates confirmation required
      displayName: fullName,
    );
    _emitState(AppAuthAuthenticated(user));
    return user;
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    await Future.delayed(behavior.delay);
    _checkBehavior();
    const email = 'google.user@example.com';
    _users[email] = '__google__';
    _currentUserEmail = email;
    final user = currentUser!;
    _emitState(AppAuthAuthenticated(user));
    return user;
  }

  @override
  Future<void> signInWithApple() async {
    await Future.delayed(behavior.delay);
    _checkBehavior();
    const email = 'apple.user@example.com';
    _users[email] = '__apple__';
    _currentUserEmail = email;
    _emitState(AppAuthAuthenticated(currentUser!));
  }

  @override
  Future<void> resendVerificationEmail() async {
    await Future.delayed(behavior.delay);
    _checkBehavior();
    if (_currentUserEmail == null) {
      throw Exception('No authenticated user to resend verification to');
    }
    print('[FakeAuth] Verification email "sent" to $_currentUserEmail');
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(behavior.delay);
    _checkBehavior();
    print('[FakeAuth] Password reset email "sent" to $email');
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await Future.delayed(behavior.delay);
    _checkBehavior();
    if (_currentUserEmail != null) {
      _users[_currentUserEmail!] = newPassword;
    }
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(behavior.delay);
    _currentUserEmail = null;
    _emitState(const AppAuthUnauthenticated());
  }

  void dispose() => _stateController.close();
}
