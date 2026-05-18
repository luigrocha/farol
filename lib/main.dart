import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'design/farol_colors.dart' as tokens;
import 'core/theme/farol_colors.dart' show FarolColorsContext;
import 'design/farol_theme.dart';
import 'design/branding/branding.dart';
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
import 'core/providers/workspace_providers.dart'
    show activeWorkspaceProvider, isSharedWorkspaceProvider;
import 'core/models/workspace.dart' show WorkspaceType;
import 'core/services/workspace_realtime_service.dart';
import 'core/services/app_lifecycle_service.dart';
import 'features/workspace/workspace_switcher_sheet.dart';
import 'features/workspace/accept_invite_screen.dart';
import 'features/workspace/invite_notification_overlay.dart';
import 'features/space/accept_space_invite_screen.dart';
import 'package:app_links/app_links.dart';
import 'features/paywall/paywall_screen.dart';
import 'core/models/budget_alert.dart' show AlertLevel;
import 'core/domain/entities/financial_insight.dart' show InsightPriority;

final navigatorKey = GlobalKey<NavigatorState>();

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
      navigatorKey: navigatorKey,
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
        '/paywall': (context) => const PaywallScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/investment_detail') {
          final inv = settings.arguments as Investment;
          return MaterialPageRoute(
              builder: (context) => InvestmentDetailScreen(investment: inv));
        }
        final name = settings.name ?? '';
        final uri  = Uri.tryParse(name);
        if (uri != null && uri.pathSegments.length == 2) {
          final seg0  = uri.pathSegments[0];
          final token = uri.pathSegments[1];

          // Workspace invite: /invite/:token
          if (seg0 == 'invite') {
            return MaterialPageRoute(
                builder: (context) => AcceptInviteScreen(token: token),
                settings: settings);
          }

          // Space invite: /join/:token
          if (seg0 == 'join') {
            return MaterialPageRoute(
                builder: (context) => AcceptSpaceInviteScreen(token: token),
                settings: settings);
          }
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
  final _appLinks = AppLinks();

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
    // Activate workspace realtime on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncRealtime();
      _initDeepLinks();
    });
  }

  void _initDeepLinks() {
    // Handle deep links while app is running
    _appLinks.uriLinkStream.listen(_handleDeepLink);
    // Handle cold-start deep link
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.length >= 2 && segments[0] == 'invite') {
      // Workspace invite: farol.app/invite/:token
      final token = segments[1];
      navigatorKey.currentState?.pushNamed('/invite/$token');
    } else if (segments.length >= 2 && segments[0] == 'join') {
      // Space invite: farol.app/join/:token
      final token = segments[1];
      navigatorKey.currentState?.pushNamed('/join/$token');
    }
  }

  @override
  void dispose() {
    WorkspaceRealtimeService.instance.pause();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // Use AppLifecycleService to debounce + selectively invalidate stale
        // providers instead of a bare setState() which caused a full tree
        // rebuild while providers were in AsyncLoading → gray screen.
        AppLifecycleService.instance.onResume(
          ProviderScope.containerOf(context),
        );
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        AppLifecycleService.instance.onPause();
        WorkspaceRealtimeService.instance.pause();
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // No action needed
        break;
    }
  }

  void _syncRealtime() {
    if (!mounted) return;
    try {
      final container = ProviderScope.containerOf(context);
      final ws = container.read(activeWorkspaceProvider).valueOrNull;
      final isShared = container.read(isSharedWorkspaceProvider);
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (ws != null && isShared && uid != null) {
        WorkspaceRealtimeService.instance.setWorkspace(ws.id, uid);
      }
    } catch (e) {
      debugPrint('[MainShell] _syncRealtime error: $e');
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

    // Re-sync realtime service whenever the active workspace changes.
    // Invite notifications are now handled by InviteNotificationManager overlay
    // (persistent banner with inline Accept/Decline) — no more MaterialBanner.
    return Consumer(
      builder: (ctx, ref, child) {
        ref.listen(activeWorkspaceProvider, (_, next) {
          final ws = next.valueOrNull;
          final isShared = ref.read(isSharedWorkspaceProvider);
          final uid = Supabase.instance.client.auth.currentUser?.id;
          if (ws != null && isShared && uid != null) {
            WorkspaceRealtimeService.instance.setWorkspace(ws.id, uid);
          } else {
            WorkspaceRealtimeService.instance.pause();
          }
        });
        return child!;
      },
      child: _ProviderKeepAlive(
        child: InviteNotificationManager(
          child: isDesktop ? _buildDesktopShell(l10n) : _buildMobileShell(l10n),
        ),
      ),
    );
  }

  // ── Desktop: NavigationRail + content side by side ────────────────────────

  Widget _buildDesktopShell(AppLocalizations l10n) {
    return Scaffold(
      body: Row(
        children: [
          _DesktopNavRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onDestinationSelected,
            l10n: l10n,
          ),
          Expanded(child: _buildScreenStack()),
        ],
      ),
    );
  }

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
          NavigationDestination(
            icon: const Icon(Icons.pie_chart_outline),
            selectedIcon: const Icon(Icons.pie_chart),
            label: l10n.budgetNav,
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

// ── Provider Keep-Alive ───────────────────────────────────────────────────────
//
// Holds ref.watch subscriptions to the two most critical stream providers so
// that Riverpod's autoDispose never drops the underlying Supabase WebSocket
// connections while MainShell is alive. Without this, switching screens or
// brief inactivity could dispose the streams → gray UI on wake-up.

class _ProviderKeepAlive extends ConsumerWidget {
  const _ProviderKeepAlive({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep root data streams alive as long as MainShell is mounted.
    // These watches are purely for the keepAlive side-effect — the values
    // are consumed by individual screen providers, not here.
    ref.watch(allExpensesStreamProvider);
    ref.watch(allIncomesStreamProvider);
    ref.watch(categoriesStreamProvider);
    return child;
  }
}

// ── Desktop Navigation Rail ───────────────────────────────────────────────────
//
// Custom rail that matches the reference design:
//   - Navy sidebar with amber accent for selected item
//   - Logo with amber flame icon + "Farol" wordmark
//   - Workspace chip below logo
//   - Badge counts on nav items
//   - Dark mode toggle + Settings pinned at bottom

class _DesktopNavRail extends ConsumerStatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final AppLocalizations l10n;

  const _DesktopNavRail({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.l10n,
  });

  @override
  ConsumerState<_DesktopNavRail> createState() => _DesktopNavRailState();
}

class _DesktopNavRailState extends ConsumerState<_DesktopNavRail> {
  // Premium sidebar palette — sourced from FarolBrand tokens
  static const _navyBg    = FarolBrand.navySidebar;
  static const _navyBg2   = FarolBrand.navySidebarHover;
  static const _amber      = FarolBrand.beam;
  static Color get _selectedBg => FarolBrand.beamSubtle;

  @override
  Widget build(BuildContext context) {
    final activeWs  = ref.watch(activeWorkspaceProvider).valueOrNull;
    final alerts    = ref.watch(budgetAlertsProvider);
    final insights  = ref.watch(insightsProvider).valueOrNull ?? [];
    final themeMode = ref.watch(themeModeProvider);

    final isShared = activeWs?.type == WorkspaceType.shared;
    final hasEmoji = activeWs?.emoji != null && activeWs!.emoji!.isNotEmpty;

    final dashboardBadge =
        alerts.where((a) => a.level != AlertLevel.warning).length +
        insights.where((i) => i.priority == InsightPriority.critical).length;
    final budgetBadge =
        alerts.where((a) => a.level == AlertLevel.exceeded).length;

    final items = [
      _NavItem(icon: Icons.home_outlined,         selectedIcon: Icons.home_rounded,           label: widget.l10n.dashboard,    badge: dashboardBadge),
      _NavItem(icon: Icons.receipt_long_outlined,  selectedIcon: Icons.receipt_long_rounded,   label: widget.l10n.transactions),
      _NavItem(icon: Icons.bar_chart_outlined,     selectedIcon: Icons.bar_chart_rounded,      label: widget.l10n.analytics),
      _NavItem(icon: Icons.pie_chart_outline_rounded, selectedIcon: Icons.pie_chart_rounded,   label: widget.l10n.budgetNav,    badge: budgetBadge),
      _NavItem(icon: Icons.trending_up_outlined,   selectedIcon: Icons.trending_up_rounded,    label: widget.l10n.investments),
    ];

    return SizedBox(
      width: 212,
      child: Container(
        decoration: BoxDecoration(
          color: _navyBg,
          border: Border(
            right: BorderSide(
              color: Colors.white.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Logo / brand ──────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: FarolLogo(
                variant: FarolLogoVariant.dark,
                markSize: FarolBrand.markSizeNavRail,
                wordmarkFontSize: 17,
                showGlow: false,
                spacing: 10,
              ),
            ),

            // ── Workspace chip ────────────────────────────────────────────
            if (activeWs != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: _WorkspaceChip(
                  workspace: activeWs,
                  hasEmoji: hasEmoji,
                  isShared: isShared,
                  navyBg2: _navyBg2,
                ),
              ),

            // ── Compact greeting ──────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 6, 16, 2),
              child: FarolGreeting(variant: FarolGreetingVariant.compact),
            ),

            const SizedBox(height: 8),

            // ── Section label ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                widget.l10n.navSectionMenu,
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
              ),
            ),

            // ── Nav items ─────────────────────────────────────────────────
            ...items.asMap().entries.map((e) {
              final idx = e.key;
              final item = e.value;
              final selected = widget.selectedIndex == idx;
              return _NavRailItem(
                item: item,
                selected: selected,
                selectedBg: _selectedBg,
                selectedColor: _amber,
                unselectedColor: Colors.white.withValues(alpha: 0.55),
                hoverBg: Colors.white.withValues(alpha: 0.06),
                onTap: () => widget.onDestinationSelected(idx),
              );
            }),

            const Spacer(),

            // ── Divider ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),

            // ── Dark mode toggle ──────────────────────────────────────────
            _SidebarFooterBtn(
              icon: themeMode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              label: themeMode == ThemeMode.dark ? widget.l10n.lightMode : widget.l10n.darkMode,
              hoverBg: Colors.white.withValues(alpha: 0.06),
              onTap: () {
                final next = themeMode == ThemeMode.dark
                    ? ThemeMode.light
                    : ThemeMode.dark;
                ref.read(themeModeProvider.notifier).setThemeMode(next);
              },
            ),

            // ── Settings ──────────────────────────────────────────────────
            _NavRailItem(
              item: _NavItem(
                icon: Icons.settings_outlined,
                selectedIcon: Icons.settings_rounded,
                label: widget.l10n.settings,
              ),
              selected: widget.selectedIndex == 5,
              selectedBg: _selectedBg,
              selectedColor: _amber,
              unselectedColor: Colors.white.withValues(alpha: 0.55),
              hoverBg: Colors.white.withValues(alpha: 0.06),
              onTap: () => widget.onDestinationSelected(5),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Workspace chip in sidebar ─────────────────────────────────────────────────

class _WorkspaceChip extends StatefulWidget {
  const _WorkspaceChip({
    required this.workspace,
    required this.hasEmoji,
    required this.isShared,
    required this.navyBg2,
  });

  final dynamic workspace;
  final bool hasEmoji;
  final bool isShared;
  final Color navyBg2;

  @override
  State<_WorkspaceChip> createState() => _WorkspaceChipState();
}

class _WorkspaceChipState extends State<_WorkspaceChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => WorkspaceSwitcherSheet.show(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: _hovered ? 0.12 : 0.06),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              if (widget.hasEmoji)
                Text(
                  (widget.workspace.emoji as String?)!,
                  style: const TextStyle(fontSize: 14),
                )
              else
                Icon(
                  widget.isShared
                      ? Icons.group_outlined
                      : Icons.person_outline,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.workspace.name as String,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.unfold_more_rounded,
                size: 14,
                color: Colors.white.withValues(alpha: 0.30),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sidebar footer button (dark mode toggle, etc.) ────────────────────────────

class _SidebarFooterBtn extends StatefulWidget {
  const _SidebarFooterBtn({
    required this.icon,
    required this.label,
    required this.hoverBg,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color hoverBg;
  final VoidCallback onTap;

  @override
  State<_SidebarFooterBtn> createState() => _SidebarFooterBtnState();
}

class _SidebarFooterBtnState extends State<_SidebarFooterBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _hovered ? widget.hoverBg : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  size: 17,
                  color: Colors.white.withValues(alpha: 0.50),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.label,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.50),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int badge;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badge = 0,
  });
}

// ── Nav rail item with hover animation ───────────────────────────────────────

class _NavRailItem extends StatefulWidget {
  const _NavRailItem({
    required this.item,
    required this.selected,
    required this.selectedBg,
    required this.selectedColor,
    required this.unselectedColor,
    required this.hoverBg,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final Color selectedBg;
  final Color selectedColor;
  final Color unselectedColor;
  final Color hoverBg;
  final VoidCallback onTap;

  @override
  State<_NavRailItem> createState() => _NavRailItemState();
}

class _NavRailItemState extends State<_NavRailItem>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _ctrl;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 150),
    );
    _slide = Tween(
      begin: Offset.zero,
      end: const Offset(0.02, 0),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final color = widget.selected
        ? widget.selectedColor
        : (_hovered
            ? Colors.white.withValues(alpha: 0.80)
            : widget.unselectedColor);

    final bg = widget.selected
        ? widget.selectedBg
        : (_hovered ? widget.hoverBg : Colors.transparent);

    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        _ctrl.forward();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _ctrl.reverse();
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: AnimatedBuilder(
            animation: _slide,
            builder: (_, child) => SlideTransition(
              position: _slide,
              child: child,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
                // Subtle left accent for selected state
                border: widget.selected
                    ? Border(
                        left: BorderSide(
                          color: widget.selectedColor,
                          width: 2.5,
                        ),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        child: Icon(
                          widget.selected
                              ? widget.item.selectedIcon
                              : widget.item.icon,
                          key: ValueKey(widget.selected),
                          size: 18,
                          color: color,
                        ),
                      ),
                      if (widget.item.badge > 0)
                        Positioned(
                          top: -5,
                          right: -7,
                          child: Container(
                            width: 15,
                            height: 15,
                            decoration: const BoxDecoration(
                              color: tokens.FarolColors.coral,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${widget.item.badge}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.item.label,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: widget.selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.selected)
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: widget.selectedColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
