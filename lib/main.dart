import 'package:flutter/foundation.dart';
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
import 'features/auth/presentation/auth_loading_screen.dart';

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

  // Lock to portrait only on mobile — web/desktop handle their own orientation.
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

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
        '/auth_loading': (context) => const AuthLoadingScreen(),
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
        final l10n = AppLocalizations.of(context);
        debugPrint('[Auth] authStateProvider error: $err\n$stack');
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(l10n.somethingWentWrong,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    err.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => ref.invalidate(authStateProvider),
                    child: Text(l10n.retry),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.invalidate(authStateProvider);
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/login', (r) => false);
                    },
                    child: const Text('Voltar para login'),
                  ),
                ],
              ),
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

  void _onDestinationSelected(int i) => setState(() {
        _currentIndex = i;
        _visited.add(i);
      });

  Widget _buildScreenStack() {
    return Stack(
      children: List.generate(_screenBuilders.length, (i) {
        if (!_visited.contains(i)) return const SizedBox.shrink();
        return Offstage(
          offstage: i != _currentIndex,
          child: _screenBuilders[i](),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 600;

    if (isDesktop) {
      return _buildDesktopShell(l10n);
    }
    return _buildMobileShell(l10n);
  }

  // ── Desktop: NavigationRail + content side by side ────────────────────────

  Widget _buildDesktopShell(AppLocalizations l10n) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: true,
            selectedIndex: _currentIndex,
            onDestinationSelected: _onDestinationSelected,
            minExtendedWidth: 190,
            leading: _NavRailHeader(),
            destinations: _railDestinations(l10n),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _buildScreenStack()),
        ],
      ),
    );
  }

  List<NavigationRailDestination> _railDestinations(AppLocalizations l10n) => [
        NavigationRailDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: Text(l10n.dashboard),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.receipt_long_outlined),
          selectedIcon: const Icon(Icons.receipt_long),
          label: Text(l10n.transactions),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.bar_chart_outlined),
          selectedIcon: const Icon(Icons.bar_chart),
          label: Text(l10n.analytics),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.pie_chart_outline),
          selectedIcon: Icon(Icons.pie_chart),
          label: Text('Budget'),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.trending_up_outlined),
          selectedIcon: const Icon(Icons.trending_up),
          label: Text(l10n.investments),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: Text(l10n.settings),
        ),
      ];

  // ── Mobile: BottomNavigationBar ───────────────────────────────────────────

  Widget _buildMobileShell(AppLocalizations l10n) {
    return Scaffold(
      body: _buildScreenStack(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onDestinationSelected,
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

/// Logo / quick-action header shown above the rail destinations on desktop.
class _NavRailHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: tokens.FarolColors.navy,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.light_sharp, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Farol',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: tokens.FarolColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
