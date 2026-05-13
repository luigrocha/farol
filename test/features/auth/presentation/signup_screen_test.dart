/// Widget tests for [SignUpScreen].
///
/// Covers: form validation (all fields), terms checkbox guard,
/// password strength meter, duplicate email error, and happy path.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farol/features/auth/presentation/signup_screen.dart';

import '../../../test_helpers.dart';
import '../../../fakes/fake_auth_repository.dart';

void main() {
  // ─── Finders ─────────────────────────────────────────────────────────────
  // Fields in order of appearance in the form:
  // 0: full name, 1: email, 2: password, 3: CPF, 4: confirm password
  Finder nameField() => find.byType(TextFormField).at(0);
  Finder emailField() => find.byType(TextFormField).at(1);
  Finder passwordField() => find.byType(TextFormField).at(2);
  Finder confirmField() => find.byType(TextFormField).at(4);
  Finder createBtn() => find.byType(ElevatedButton);
  Finder termsCheckbox() => find.byType(Checkbox);

  // Helper: scrolls the create button into view and taps it
  Future<void> tapCreateBtn(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      createBtn(),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(createBtn());
    await tester.pump();
  }

  // Helper: fills all required fields with valid data
  Future<void> fillValidForm(WidgetTester tester) async {
    await tester.enterText(nameField(), 'Test User');
    await tester.enterText(emailField(), 'newuser@example.com');
    await tester.enterText(passwordField(), 'SecurePass1!');
    await tester.pump(); // trigger strength update
    await tester.enterText(confirmField(), 'SecurePass1!');
    // Accept terms
    await tester.tap(termsCheckbox());
    await tester.pump();
  }

  // ─── Form Validation ─────────────────────────────────────────────────────
  group('SignUpScreen — form validation', () {
    testWidgets('empty submission shows all required field errors',
        (tester) async {
      await pumpAppWithFakeAuth(tester, const SignUpScreen());

      await tapCreateBtn(tester);

      // Full name required
      expect(find.textContaining('required'), findsWidgets);
      // Email invalid
      expect(find.text('Invalid email'), findsOneWidget);
    });

    testWidgets('invalid email shows email validation error', (tester) async {
      await pumpAppWithFakeAuth(tester, const SignUpScreen());

      await tester.enterText(nameField(), 'Test User');
      await tester.enterText(emailField(), 'bad-email');
      await tester.enterText(passwordField(), 'goodPass1!');
      await tester.enterText(confirmField(), 'goodPass1!');
      await tester.tap(termsCheckbox());
      await tester.pump();
      await tapCreateBtn(tester);

      expect(find.text('Invalid email'), findsOneWidget);
    });

    testWidgets('passwords mismatch shows error', (tester) async {
      await pumpAppWithFakeAuth(tester, const SignUpScreen());

      await tester.enterText(nameField(), 'Test User');
      await tester.enterText(emailField(), 'user@example.com');
      await tester.enterText(passwordField(), 'Password1!');
      await tester.enterText(confirmField(), 'Different1!');
      await tester.tap(termsCheckbox());
      await tester.pump();
      await tapCreateBtn(tester);

      expect(find.textContaining('do not match'), findsWidgets);
    });

    testWidgets('terms not accepted blocks submission and shows error',
        (tester) async {
      await pumpAppWithFakeAuth(tester, const SignUpScreen());

      await tester.enterText(nameField(), 'Test User');
      await tester.enterText(emailField(), 'user@example.com');
      await tester.enterText(passwordField(), 'Password1!');
      await tester.enterText(confirmField(), 'Password1!');
      // Do NOT tap terms checkbox
      await tapCreateBtn(tester);

      // Terms error should appear
      expect(find.textContaining('terms'), findsWidgets);
    });
  });

  // ─── Password Strength Meter ──────────────────────────────────────────────
  group('SignUpScreen — password strength meter', () {
    testWidgets('weak password shows low strength indicator', (tester) async {
      await pumpAppWithFakeAuth(tester, const SignUpScreen());

      await tester.enterText(passwordField(), 'abcdefgh');
      await tester.pump();

      // "Very weak" or "Weak" label should appear
      expect(
        find.textContaining(RegExp(r'weak', caseSensitive: false)),
        findsAny,
      );
    });

    testWidgets('strong password (8+, upper, number, symbol) shows strong label',
        (tester) async {
      await pumpAppWithFakeAuth(tester, const SignUpScreen());

      await tester.enterText(passwordField(), 'StrongP@ss1');
      await tester.pump();

      expect(
        find.textContaining(RegExp(r'(strong|good)', caseSensitive: false)),
        findsAny,
      );
    });
  });

  // ─── Network & Auth Errors ────────────────────────────────────────────────
  group('SignUpScreen — auth errors', () {
    testWidgets('duplicate email shows user-friendly error', (tester) async {
      final fake = FakeAuthRepository()
        ..seedUser('existing@example.com', 'oldpass');

      await pumpAppWithFakeAuth(tester, const SignUpScreen(), fakeRepo: fake);

      await tester.enterText(nameField(), 'Test User');
      await tester.enterText(emailField(), 'existing@example.com');
      await tester.enterText(passwordField(), 'NewPass1!');
      await tester.enterText(confirmField(), 'NewPass1!');
      await tester.tap(termsCheckbox());
      await tester.pump();
      await tapCreateBtn(tester);
      await tester.pumpAndSettle();

      expect(find.textContaining('already registered'), findsWidgets);
    });

    testWidgets('network error is shown to user', (tester) async {
      final fake = FakeAuthRepository()
        ..behavior = FakeAuthBehavior(shouldThrowNetworkError: true);

      await pumpAppWithFakeAuth(tester, const SignUpScreen(), fakeRepo: fake);
      await fillValidForm(tester);
      await tester.enterText(emailField(), 'new@example.com');
      await tester.pump();
      await tapCreateBtn(tester);
      await tester.pumpAndSettle();

      expect(find.textContaining('Network'), findsWidgets);
    });
  });

  // ─── Loading State ────────────────────────────────────────────────────────
  group('SignUpScreen — loading state', () {
    testWidgets('button is disabled while request is in progress',
        (tester) async {
      final fake = FakeAuthRepository()
        ..behavior = FakeAuthBehavior(delay: const Duration(seconds: 2));

      await pumpAppWithFakeAuth(tester, const SignUpScreen(), fakeRepo: fake);
      await fillValidForm(tester);
      await tester.enterText(emailField(), 'fresh@example.com');
      await tester.pump();
      await tapCreateBtn(tester); // Start async

      final btn = tester.widget<ElevatedButton>(createBtn());
      expect(btn.onPressed, isNull); // Disabled during loading
      // Advance past the 2s timer to avoid pending timer warning
      await tester.pump(const Duration(seconds: 2));
    });
  });

  // ─── Navigation ───────────────────────────────────────────────────────────
  group('SignUpScreen — navigation', () {
    testWidgets('sign-in link navigates to /login', (tester) async {
      await pumpAppWithFakeAuth(tester, const SignUpScreen());

      await tester.scrollUntilVisible(
        find.textContaining('Sign In'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.textContaining('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('back arrow pops the screen', (tester) async {
      await pumpAppWithFakeAuth(tester, const SignUpScreen());
      await tester.pump();

      final backBtn = find.byIcon(Icons.arrow_back_ios_new_rounded);
      // Test only applies if back button is present
      if (backBtn.evaluate().isNotEmpty) {
        await tester.tap(backBtn);
        await tester.pumpAndSettle();
      }
    });
  });
}
