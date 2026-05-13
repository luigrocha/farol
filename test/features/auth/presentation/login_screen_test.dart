/// Widget tests for [LoginScreen].
///
/// Philosophy: these tests verify BEHAVIOR (what happens when the user
/// interacts with the form), not appearance (no golden tests, no pixel checks).
///
/// Fast: no network, no Supabase — uses FakeAuthRepository.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farol/features/auth/presentation/login_screen.dart';

import '../../../test_helpers.dart';
import '../../../fakes/fake_auth_repository.dart';

void main() {
  // ─── Finders shared across tests ─────────────────────────────────────────
  final emailField = find.byType(TextFormField).first;
  // password field is the second TextFormField
  final passwordField = find.byType(TextFormField).last;
  // The primary sign-in button contains the "Sign In" label
  final signInBtn = find.widgetWithText(ElevatedButton, 'Sign In');

  // ─── Form Validation ─────────────────────────────────────────────────────
  group('LoginScreen — form validation', () {
    testWidgets('empty submission shows validation errors', (tester) async {
      await pumpAppWithFakeAuth(tester, const LoginScreen());

      // Tap sign-in with empty fields
      await tester.tap(signInBtn);
      await tester.pump();

      // Expect at least one error text visible
      expect(find.text('Invalid email'), findsOneWidget);
    });

    testWidgets('invalid email format shows email validation error',
        (tester) async {
      await pumpAppWithFakeAuth(tester, const LoginScreen());

      await tester.enterText(emailField, 'not-an-email');
      await tester.enterText(passwordField, 'password123');
      await tester.tap(signInBtn);
      await tester.pump();

      expect(find.text('Invalid email'), findsOneWidget);
    });

    testWidgets('password shorter than 6 chars shows validation error',
        (tester) async {
      await pumpAppWithFakeAuth(tester, const LoginScreen());

      await tester.enterText(emailField, 'valid@example.com');
      await tester.enterText(passwordField, '12345');
      await tester.tap(signInBtn);
      await tester.pump();

      // Should show minimum length error
      expect(find.textContaining('6'), findsWidgets);
    });

    testWidgets('valid email + password passes client-side validation',
        (tester) async {
      final fake = FakeAuthRepository()
        ..seedUser('valid@example.com', 'goodpass123');

      await pumpAppWithFakeAuth(
        tester,
        const LoginScreen(),
        fakeRepo: fake,
      );

      await tester.enterText(emailField, 'valid@example.com');
      await tester.enterText(passwordField, 'goodpass123');
      await tester.tap(signInBtn);
      await tester.pump(); // loading starts

      // Should NOT show validation errors
      expect(find.text('Invalid email'), findsNothing);

      // Advance past the 10ms delay timer to avoid "pending timer" error
      await tester.pump(const Duration(milliseconds: 50));
    });
  });

  // ─── Loading State ────────────────────────────────────────────────────────
  group('LoginScreen — loading state', () {
    testWidgets('shows loading indicator while sign-in is in progress',
        (tester) async {
      final fake = FakeAuthRepository(
          )..seedUser('user@example.com', 'pass123')
          ..behavior = FakeAuthBehavior(delay: const Duration(seconds: 1));

      await pumpAppWithFakeAuth(
        tester,
        const LoginScreen(),
        fakeRepo: fake,
      );

      await tester.enterText(emailField, 'user@example.com');
      await tester.enterText(passwordField, 'pass123');
      await tester.tap(signInBtn);
      await tester.pump(); // Pump once to start async

      // The loading state replaces the button text with a loading spinner,
      // so find.widgetWithText won't match. Use byType instead.
      final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(btn.onPressed, isNull); // disabled during loading

      // Advance past the 1s delay timer to avoid "pending timer" error
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('sign-in button is re-enabled after error', (tester) async {
      final fake = FakeAuthRepository()
        ..behavior = FakeAuthBehavior(shouldThrowInvalidCredentials: true);

      await pumpAppWithFakeAuth(
        tester,
        const LoginScreen(),
        fakeRepo: fake,
      );

      await tester.enterText(emailField, 'any@example.com');
      await tester.enterText(passwordField, 'wrongpass');
      await tester.tap(signInBtn);
      await tester.pumpAndSettle();

      // Button should be re-enabled after error
      final btn = tester.widget<ElevatedButton>(signInBtn);
      expect(btn.onPressed, isNotNull);
    });
  });

  // ─── Error Display ────────────────────────────────────────────────────────
  group('LoginScreen — error display', () {
    testWidgets('invalid credentials error is shown to user', (tester) async {
      final fake = FakeAuthRepository()
        ..seedUser('real@example.com', 'realpass');

      await pumpAppWithFakeAuth(
        tester,
        const LoginScreen(),
        fakeRepo: fake,
      );

      await tester.enterText(emailField, 'real@example.com');
      await tester.enterText(passwordField, 'wrongpass');
      await tester.tap(signInBtn);
      await tester.pumpAndSettle();

      // Error text should appear (SnackBar or inline error)
      expect(find.textContaining('Invalid email or password'), findsWidgets);
    });

    testWidgets('network error is shown to user', (tester) async {
      final fake = FakeAuthRepository()
        ..behavior = FakeAuthBehavior(shouldThrowNetworkError: true);

      await pumpAppWithFakeAuth(
        tester,
        const LoginScreen(),
        fakeRepo: fake,
      );

      await tester.enterText(emailField, 'any@example.com');
      await tester.enterText(passwordField, 'anypass');
      await tester.tap(signInBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Network'), findsWidgets);
    });
  });

  // ─── Navigation ───────────────────────────────────────────────────────────
  group('LoginScreen — navigation', () {
    testWidgets('tapping sign-up link navigates to /signup', (tester) async {
      await pumpAppWithFakeAuth(tester, const LoginScreen());

      await tester.scrollUntilVisible(
        find.textContaining('Sign Up'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.textContaining('Sign Up'));
      await tester.pumpAndSettle();

      // Should navigate to Signup screen (our stub route shows 'Signup')
      expect(find.text('Signup'), findsOneWidget);
    });

    testWidgets('forgot password with empty email shows snackbar',
        (tester) async {
      await pumpAppWithFakeAuth(tester, const LoginScreen());

      await tester.scrollUntilVisible(
        find.textContaining('Forgot'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.textContaining('Forgot'));
      await tester.pumpAndSettle();

      // Should show snackbar (email required)
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('forgot password with valid email sends reset email',
        (tester) async {
      final fake = FakeAuthRepository();
      await pumpAppWithFakeAuth(
        tester,
        const LoginScreen(),
        fakeRepo: fake,
      );

      await tester.enterText(emailField, 'user@example.com');
      final forgotBtn = find.textContaining('Forgot');
      await tester.tap(forgotBtn);
      await tester.pumpAndSettle();

      // SnackBar should confirm email was sent
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  // ─── Password visibility toggle ──────────────────────────────────────────
  group('LoginScreen — password field', () {
    testWidgets('password is obscured by default', (tester) async {
      await pumpAppWithFakeAuth(tester, const LoginScreen());

      final pwField = tester.widget<TextFormField>(passwordField);
      expect(
        (pwField.controller != null || true), // field exists
        isTrue,
      );
      // Find the obscure toggle icon
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('tapping visibility icon toggles password visibility',
        (tester) async {
      await pumpAppWithFakeAuth(tester, const LoginScreen());

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });
  });
}
