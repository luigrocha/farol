/// Unit tests for [AuthNotifier] — pure business logic, no widgets.
///
/// These tests verify that the notifier:
/// - Correctly transitions through AsyncLoading → AsyncData/AsyncError
/// - Delegates to AuthRepository correctly
/// - Exposes errors in a testable way
///
/// Uses [FakeAuthRepository] to avoid any network dependency.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farol/features/auth/presentation/auth_providers.dart';

import '../../../fakes/fake_auth_repository.dart';

/// Helper: builds a [ProviderContainer] with [FakeAuthRepository] injected.
ProviderContainer makeContainer(FakeAuthRepository fake) {
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(fake),
    ],
  );
}

void main() {
  group('AuthNotifier — signInWithEmail', () {
    test('happy path: transitions to AsyncData after successful sign in',
        () async {
      final fake = FakeAuthRepository()
        ..seedUser('valid@example.com', 'password123');
      final container = makeContainer(fake);
      addTearDown(container.dispose);

      final notifier = container.read(authControllerProvider.notifier);

      final states = <AsyncValue<void>>[];
      container.listen(authControllerProvider, (_, next) => states.add(next));

      await notifier.signInWithEmail('valid@example.com', 'password123');

      expect(states.length, 2);
      expect(states[0], isA<AsyncLoading<void>>());
      expect(states[1], isA<AsyncData<void>>());
      expect(states[1].hasError, isFalse);
    });

    test('invalid credentials: transitions to AsyncError with descriptive message',
        () async {
      final fake = FakeAuthRepository()
        ..seedUser('valid@example.com', 'rightpassword');
      final container = makeContainer(fake);
      addTearDown(container.dispose);

      final notifier = container.read(authControllerProvider.notifier);
      await notifier.signInWithEmail('valid@example.com', 'wrongpassword');

      final state = container.read(authControllerProvider);
      expect(state.hasError, isTrue);
      expect(state.error.toString(), contains('Invalid email or password'));
    });

    test('network error: transitions to AsyncError', () async {
      final fake = FakeAuthRepository()
        ..behavior = FakeAuthBehavior(shouldThrowNetworkError: true);
      final container = makeContainer(fake);
      addTearDown(container.dispose);

      final notifier = container.read(authControllerProvider.notifier);
      await notifier.signInWithEmail('any@example.com', 'anypassword');

      final state = container.read(authControllerProvider);
      expect(state.hasError, isTrue);
      expect(state.error.toString(), contains('Network error'));
    });

    test('unknown user: returns invalid credentials error', () async {
      // No users seeded — any login attempt fails
      final fake = FakeAuthRepository();
      final container = makeContainer(fake);
      addTearDown(container.dispose);

      final notifier = container.read(authControllerProvider.notifier);
      await notifier.signInWithEmail('ghost@example.com', 'password');

      final state = container.read(authControllerProvider);
      expect(state.hasError, isTrue);
    });
  });

  group('AuthNotifier — signUpWithEmail', () {
    test('happy path: creates user and transitions to AsyncData', () async {
      final fake = FakeAuthRepository();
      final container = makeContainer(fake);
      addTearDown(container.dispose);

      final notifier = container.read(authControllerProvider.notifier);
      await notifier.signUpWithEmail(
        'newuser@example.com',
        'securepass123',
        fullName: 'New User',
      );

      final state = container.read(authControllerProvider);
      expect(state.hasError, isFalse);
      expect(state.isLoading, isFalse);
    });

    test('duplicate email: transitions to AsyncError with descriptive message',
        () async {
      final fake = FakeAuthRepository()
        ..seedUser('existing@example.com', 'oldpass');
      final container = makeContainer(fake);
      addTearDown(container.dispose);

      final notifier = container.read(authControllerProvider.notifier);
      await notifier.signUpWithEmail('existing@example.com', 'newpass123');

      final state = container.read(authControllerProvider);
      expect(state.hasError, isTrue);
      expect(state.error.toString(), contains('already registered'));
    });

    test('weak password: transitions to AsyncError', () async {
      final fake = FakeAuthRepository()
        ..behavior = FakeAuthBehavior(shouldThrowWeakPassword: true);
      final container = makeContainer(fake);
      addTearDown(container.dispose);

      final notifier = container.read(authControllerProvider.notifier);
      await notifier.signUpWithEmail('new@example.com', '123');

      final state = container.read(authControllerProvider);
      expect(state.hasError, isTrue);
      expect(state.error.toString(), contains('6 characters'));
    });

    test('password < 6 chars is rejected by fake without explicit flag',
        () async {
      final fake = FakeAuthRepository();
      final container = makeContainer(fake);
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .signUpWithEmail('new@example.com', '123');

      expect(container.read(authControllerProvider).hasError, isTrue);
    });
  });

  group('AuthNotifier — signOut', () {
    test('clears state and transitions to AsyncData', () async {
      final fake = FakeAuthRepository()
        ..seedUser('user@example.com', 'pass123');
      final container = makeContainer(fake);
      addTearDown(container.dispose);

      final notifier = container.read(authControllerProvider.notifier);
      // Login first
      await notifier.signInWithEmail('user@example.com', 'pass123');
      expect(container.read(authControllerProvider).hasError, isFalse);

      // Then logout
      await notifier.signOut();
      final state = container.read(authControllerProvider);
      expect(state.hasError, isFalse);
      expect(state.isLoading, isFalse);
    });
  });

  group('AuthNotifier — sendPasswordResetEmail', () {
    test('completes without error for any email', () async {
      final fake = FakeAuthRepository();
      final container = makeContainer(fake);
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .sendPasswordResetEmail('forgot@example.com');

      final state = container.read(authControllerProvider);
      expect(state.hasError, isFalse);
    });

    test('network error propagates correctly', () async {
      final fake = FakeAuthRepository()
        ..behavior = FakeAuthBehavior(shouldThrowNetworkError: true);
      final container = makeContainer(fake);
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .sendPasswordResetEmail('any@example.com');

      expect(container.read(authControllerProvider).hasError, isTrue);
    });
  });
}
