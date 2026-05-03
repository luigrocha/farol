import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'design/farol_colors.dart' as tokens;
import 'core/theme/farol_colors.dart' show FarolColorsContext;
import 'design/farol_theme.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/transactions/transactions_screen.dart';
import 'features/analytics/analytics_screen.dart';
import 'features/investments/investments_screen.dart';
import 'features/investments/investment_detail_screen.dart';
import 'core/models/investment.dart';
import 'features/settings/settings_screen.dart';
import 'features/benefits/swile_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/signup_screen.dart';
import 'features/auth/presentation/password_reset_screen.dart';
import 'features/profile/presentation/edit_profile_screen.dart';
import 'core/i18n/app_localizations.dart';
import 'core/providers/providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/presentation/auth_providers.dart';
import 'features/auth/domain/auth_state.dart';
import 'features/health/health_screen.dart';
import 'features/simulators/thirteenth_salary_screen.dart';
import 'features/installments/installments_screen.dart';
import 'features/simulators/fgts_aniversario_screen.dart';
import 'features/simulators/rescission_simulator_screen.dart';
import 'features/period_budget/presentation/period_budget_screen.dart';
import 'features/net_worth/presentation/patrimonio_screen.dart';

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    Future.microtask(() async {
      try {
        final db = ref.read(databaseProvider);
        final local = await db.getSetting('theme_mode');
        if (local != null) state = _fromString(local);
        final remote = await ref.read(remotePreferencesProvider.future);
        if (remote.themeMode != null && remote.themeMode != local) {
          state = _fromString(remote.themeMode!);
          await db.setSetting('theme_mode', remote.themeMode!);
        }
      } catch (_) {}
    });
    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final val = _toString(mode);
    await Future.wait([
      ref.read(databaseProvider).setSetting('theme_mode', val),
      ref.read(userPreferencesRepositoryProvider).setThemeMode(val),
    ]);
  }

  ThemeMode _fromString(String s) => switch (s) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  String _toString(ThemeMode m) => switch (m) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Preload Noto fallback fonts for CanvasKit (web). CanvasKit does not use
  // system fonts — every glyph outside Inter/Manrope (e.g. fl_chart symbols)
  // must be covered by an explicitly loaded font family.
  await GoogleFonts.pendingFonts([
    GoogleFonts.notoSans(),
    GoogleFonts.notoSansSymbols2(),
  ]);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  final hasValidCredentials = supabaseUrl.isNotEmpty &&
      !supabaseUrl.contains('your-project') &&
      supabaseAnonKey.isNotEmpty &&
      supabaseAnonKey != 'your-anon-key';

  try {
    await Supabase.initialize(
      url: hasValidCredentials ? supabaseUrl : 'http://localhost:54321',
      anonKey: hasValidCredentials ? supabaseAnonKey : 'local-dev-placeholder',
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  } catch (e) {
    debugPrint('[Farol] Supabase init skipped: $e');
  }

  runApp(const ProviderScope(child: FarolApp()));
}

class FarolApp extends ConsumerWidget {
  const FarolApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Farol',
      debugShowCheckedModeBanner: false,
      theme: farolLightTheme,
      darkTheme: farolDarkTheme,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'),
        Locale('pt'),
        Locale('en'),
      ],
      initialRoute: '/',
      routes: {
        '/': (context) => const AppEntryPoint(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/edit_profile': (context) => const EditProfileScreen(),
        '/swile': (context) => const SwileScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/health': (context) => const HealthScreen(),
        '/thirteenth_salary': (context) => const ThirteenthSalaryScreen(),
        '/installments': (context) => const InstallmentsScreen(),
        '/fgts_aniversario': (context) => const FgtsAniversarioScreen(),
        '/rescission_simulator': (context) => const RescissionSimulatorScreen(),
        '/patrimonio': (context) => const PatrimonioScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/investment_detail') {
          final inv = settings.arguments as Investment;
          return MaterialPageRoute(
              builder: (context) => InvestmentDetailScreen(investment: inv));
        }
        return null;
      },
    );
  }
}

class AppEntryPoint extends ConsumerWidget {
  const AppEntryPoint({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (state) => switch (state) {
        AppAuthUnauthenticated() => const OnboardingScreen(),
        AppAuthAuthenticated(:final user) when !user.emailVerified =>
          const VerificationScreen(),
        AppAuthAuthenticated() => const MainShell(),
        AppAuthPasswordRecovery() => const PasswordResetScreen(),
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) {
        // Stream errors should be rare; surface them instead of silently hiding.
        final l10n = AppLocalizations.of(context);
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(l10n.somethingWentWrong),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(authStateProvider),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class VerificationScreen extends ConsumerWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    ref.listen<AsyncValue<void>>(authControllerProvider, (_, state) {
      if (state.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error.toString())),
        );
      }
      if (state.hasValue && !state.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.verificationEmailResent)),
        );
      }
    });

    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.email_outlined,
                  size: 80, color: tokens.FarolColors.navy),
              const SizedBox(height: 24),
              Text(l10n.verifyEmail,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(
                l10n.translate('we_sent_verification'),
                textAlign: TextAlign.center,
                style: TextStyle(color: context.colors.onSurfaceSoft),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: isLoading
                    ? null
                    : () => ref
                        .read(authControllerProvider.notifier)
                        .resendVerificationEmail(),
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(l10n.resendEmail),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
                child: Text(l10n.signOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  // Tracks which screens have been visited so they are only built once.
  final Set<int> _visited = {0};

  static const _screenBuilders = [
    DashboardScreen.new,
    TransactionsScreen.new,
    AnalyticsScreen.new,
    PeriodBudgetScreen.new,
    InvestmentsScreen.new,
    SettingsScreen.new,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Stack(
        children: List.generate(_screenBuilders.length, (i) {
          // Only build screens that have been visited at least once.
          if (!_visited.contains(i)) return const SizedBox.shrink();
          return Offstage(
            offstage: i != _currentIndex,
            child: _screenBuilders[i](),
          );
        }),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() {
          _currentIndex = i;
          _visited.add(i);
        }),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.dashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: l10n.transactions,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: l10n.analytics,
          ),
          const NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Budget',
          ),
          NavigationDestination(
            icon: const Icon(Icons.trending_up_outlined),
            selectedIcon: const Icon(Icons.trending_up),
            label: l10n.investments,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.settings,
          ),
        ],
      ),
    );
  }
}
