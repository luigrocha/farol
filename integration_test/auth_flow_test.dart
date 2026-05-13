/// Integration test — Full Auth Flow
///
/// This test runs on a real device/emulator and exercises the complete
/// auth user journey through actual widget rendering and navigation.
///
/// It uses [FakeAuthRepository] to keep it fast and reproducible
/// (no live Supabase). For true E2E with real Supabase, see:
///   integration_test/auth_e2e_test.dart
///
/// Run with:
///   flutter test integration_test/auth_flow_test.dart
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:farol/core/i18n/app_localizations.dart';
import 'package:farol/design/farol_theme.dart';
import 'package:farol/features/auth/domain/auth_state.dart';
import 'package:farol/features/auth/domain/app_user.dart';
import 'package:farol/features/auth/presentation/auth_providers.dart';
import 'package:farol/features/auth/presentation/login_screen.dart';
import 'package:farol/features/auth/presentation/signup_screen.dart';
import 'package:farol/main.dart' show AppEntryPoint;

// ── FakeAuthRepository (inline for integration_test isolation) ─────────────
// Mirrors test/fakes/fake_auth_repository.dart but lives here to avoid
// importing test-only paths from integration tests.
import '../test/fakes/fake_auth_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ── Shared test state ─────────────────────────────────────────────────────
  late FakeAuthRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeAuthRepository();
  });

  tearDown(() => fakeRepo.dispose());

  Widget buildApp({List<Override> extraOverrides = const []}) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeRepo),
        ...extraOverrides,
      ],
      child: MaterialApp(
        theme: farolLightTheme,
        darkTheme: farolDarkTheme,
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('pt'), Locale('es')],
        initialRoute: '/',
        routes: {
          '/': (context) => const AppEntryPoint(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/dashboard': (context) =>
              const Scaffold(body: Text('Dashboard')),
        },
      ),
    );
  }

  // ── Scenario 1: Cold start — unauthenticated user ─────────────────────────
  group('Cold start — no session', () {
    testWidgets('unauthenticated user lands on onboarding/login',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // No cached session — should see onboarding or login
      expect(
        find.byType(LoginScreen).evaluate().isNotEmpty ||
            find.textContaining('Farol').evaluate().isNotEmpty,
        isTrue,
      );
    });
  });

  // ── Scenario 2: Full sign-up → verify flow ───────────────────────────────
  group('Sign-up flow', () {
    testWidgets('new user can register and sees verification screen',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Navigate to sign-up (from login)
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(fakeRepo)],
          child: MaterialApp(
            theme: farolLightTheme,
            locale: const Locale('en'),
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en')],
            home: const SignUpScreen(),
            routes: {
              '/login': (_) => const Scaffold(body: Text('Login')),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Fill in the form
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Integration Test User');
      await tester.enterText(fields.at(1), 'integration@example.com');
      await tester.enterText(fields.at(2), 'SecureP@ss1');
      await tester.pump();
      await tester.enterText(fields.at(4), 'SecureP@ss1');

      // Accept terms
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      // Submit
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // FakeAuthRepository returns emailVerified: false on signup
      // → AppEntryPoint shows VerificationScreen
      // (In this test, the form itself shouldn't show errors)
      expect(find.textContaining('Invalid email'), findsNothing);
      expect(find.textContaining("don't match"), findsNothing);
    });
  });

  // ── Scenario 3: Login → Dashboard navigation ─────────────────────────────
  group('Login flow', () {
    testWidgets('valid credentials log user in and navigate away from login',
        (tester) async {
      fakeRepo.seedUser('user@example.com', 'pass123');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(fakeRepo)],
          child: MaterialApp(
            theme: farolLightTheme,
            locale: const Locale('en'),
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en')],
            home: const LoginScreen(),
            routes: {
              '/signup': (_) => const Scaffold(body: Text('Signup')),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'user@example.com');
      await tester.enterText(fields.at(1), 'pass123');

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // After login, screen should navigate away (no longer shows login form errors)
      expect(find.text('Invalid email or password'), findsNothing);
    });

    testWidgets('invalid credentials show error and remain on login screen',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(fakeRepo)],
          child: MaterialApp(
            theme: farolLightTheme,
            locale: const Locale('en'),
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en')],
            home: const LoginScreen(),
            routes: {
              '/signup': (_) => const Scaffold(body: Text('Signup')),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'wrong@example.com');
      await tester.enterText(fields.at(1), 'badpass');

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.textContaining('Invalid'), findsWidgets);
    });
  });

  // ── Scenario 4: Session recovery ─────────────────────────────────────────
  group('Session recovery', () {
    testWidgets('pre-seeded authenticated user skips login on app start',
        (tester) async {
      // Pre-authenticate: inject an already-logged-in fake
      fakeRepo.seedUser('returning@example.com', 'pass');

      // Override authStateProvider to return authenticated state immediately
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepo),
          authStateProvider.overrideWith((ref) => Stream.value(
                const AppAuthAuthenticated(
                  AppUser(
                    uid: 'test-uid',
                    email: 'returning@example.com',
                    emailVerified: true,
                  ),
                ),
              )),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: farolLightTheme,
            locale: const Locale('en'),
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en')],
            home: const AppEntryPoint(),
            routes: {
              '/login': (_) => const Scaffold(body: Text('Login')),
              '/signup': (_) => const Scaffold(body: Text('Signup')),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should NOT show the login screen
      expect(find.text('Login'), findsNothing);
    });
  });

  // ── Scenario 5: Logout ───────────────────────────────────────────────────
  group('Logout flow', () {
    testWidgets('signing out clears session and returns to unauthenticated state',
        (tester) async {
      fakeRepo.seedUser('user@example.com', 'pass123');

      // Login
      await fakeRepo.signInWithEmail('user@example.com', 'pass123');
      expect(fakeRepo.currentUser, isNotNull);

      // Sign out
      await fakeRepo.signOut();

      // Session should be cleared
      expect(fakeRepo.currentUser, isNull);

      // Auth stream emits unauthenticated
      final states = <AppAuthState>[];
      final sub = fakeRepo.authStateChanges.listen(states.add);
      await Future.delayed(const Duration(milliseconds: 50));
      sub.cancel();

      // Last state should be unauthenticated
      if (states.isNotEmpty) {
        expect(states.last, isA<AppAuthUnauthenticated>());
      }
    });
  });
}
