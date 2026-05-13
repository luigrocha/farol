/// Shared test helpers for pumping widgets with all required app providers,
/// themes and localizations. Import this in every widget test file.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farol/core/i18n/app_localizations.dart';
import 'package:farol/design/farol_theme.dart';
import 'package:farol/features/auth/presentation/auth_providers.dart';

import 'fakes/fake_auth_repository.dart';

/// Pumps a [widget] inside a full app shell (Material, Riverpod, i18n).
/// Pass [overrides] to inject fakes for specific providers.
Future<void> pumpApp(
  WidgetTester tester,
  Widget widget, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: farolLightTheme,
        darkTheme: farolDarkTheme,
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('pt'),
          Locale('es'),
        ],
        locale: const Locale('en'),
        home: Scaffold(body: widget),
        routes: {
          '/login': (_) => const Scaffold(body: Text('Login')),
          '/signup': (_) => const Scaffold(body: Text('Signup')),
          '/auth_loading': (_) => const Scaffold(body: Text('AuthLoading')),
        },
      ),
    ),
  );
  // Allow first frame to settle (timers, future builders)
  await tester.pump();
}

/// An [AuthNotifier] that skips the AsyncLoading initial state.
/// This prevents [AuthActionHandler] from interpreting the initial
/// build transition (loading → data) as a completed auth action.
class _StableAuthNotifier extends AuthNotifier {
  @override
  FutureOr<void> build() {
    state = const AsyncData(null);
  }
}

/// Convenience: pumps a widget with a [FakeAuthRepository] injected.
Future<FakeAuthRepository> pumpAppWithFakeAuth(
  WidgetTester tester,
  Widget widget, {
  FakeAuthRepository? fakeRepo,
  List<Override> extraOverrides = const [],
}) async {
  final fake = fakeRepo ?? FakeAuthRepository();
  await pumpApp(
    tester,
    widget,
    overrides: [
      authRepositoryProvider.overrideWithValue(fake),
      authControllerProvider.overrideWith(() => _StableAuthNotifier()),
      ...extraOverrides,
    ],
  );
  return fake;
}
