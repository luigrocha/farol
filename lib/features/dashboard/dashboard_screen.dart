import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/providers.dart';
import '../../core/models/budget_alert.dart';
import '../../design/farol_colors.dart' as tokens;
import '../../core/i18n/app_localizations.dart';
import '../../core/theme/farol_colors.dart';
import '../../design/ds_tokens.dart';
import '../../design/layout/layout.dart';
import '../transactions/quick_add_bottom_sheet.dart';
import 'widgets/alert_banner.dart';
import 'widgets/period_balance_hero.dart';
import 'widgets/health_gauge_card.dart';
import 'widgets/kpi_grid.dart';
import 'widgets/expense_breakdown.dart';
import 'widgets/monthly_goal_card.dart';
import 'widgets/installments_summary_card.dart';
import 'widgets/recurring_card.dart';
import 'widgets/recurring_suggestions_card.dart';
import 'widgets/burn_rate_card.dart';
import 'widgets/liquidity_alert_card.dart';
import 'widgets/connectivity_banner.dart';
import 'widgets/activity_feed_preview_card.dart';
import 'widgets/contribution_bar.dart';
import 'widgets/space_contributions_card.dart';
import '../insights/insights_panel.dart';
import '../workspace/workspace_switcher_sheet.dart';
import '../../core/providers/workspace_providers.dart' show canWriteProvider;
import '../../design/branding/branding.dart';

// ── Layout breakpoints — sourced from FarolBreakpoints ───────────────────────

const _kDesktopWide = FarolBreakpoints.wide; // 1200 — 3-column layout
const _kDesktop = FarolBreakpoints.desktop; // 800  — 2-column layout
const _kContentMaxW =
    FarolBreakpoints.contentMaxWidth; // 1440 — max content width

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final year = ref.watch(selectedYearProvider);
    final period = ref.watch(selectedPeriodProvider);
    final l10n = AppLocalizations.of(context);
    final months = l10n.months;
    final periodLabel =
        '${period.start.day} ${months[period.start.month - 1]} – '
        '${period.end.day} ${months[period.end.month - 1]}';
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= _kDesktopWide;
    final isDesktop = width >= _kDesktop;

    return Scaffold(
      body: Column(children: [
        const ConnectivityBanner(),
        Expanded(
          child: CustomScrollView(
            slivers: [
              // Greeting is now embedded in _PremiumAppBar (mobile two-row layout).
              // Desktop gets it in the nav rail header.
              _PremiumAppBar(
                month: month,
                year: year,
                months: months,
                periodLabel: periodLabel,
                onPrev: () => _changeMonth(ref, month, year, -1),
                onNext: () => _changeMonth(ref, month, year, 1),
              ),
              if (isWide)
                const _WideDesktopSliver()
              else if (isDesktop)
                const _DesktopDashboardSliver()
              else
                _MobileDashboardSliver(),
              // Dynamic bottom padding — accounts for FAB + NavigationBar + safe area.
              // Replaces hardcoded SizedBox(height: 80/100) at end of each sliver.
              const SliverToBoxAdapter(child: FarolBottomPadding()),
            ],
          ),
        ),
      ]),
      floatingActionButton: Consumer(
        builder: (context, ref, _) {
          final canWrite = ref.watch(canWriteProvider);
          if (!canWrite) return const SizedBox.shrink();
          return _PremiumFab(
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const QuickAddBottomSheet(),
            ),
          );
        },
      ),
    );
  }

  void _changeMonth(WidgetRef ref, int m, int y, int delta) {
    int nm = m + delta, ny = y;
    if (nm < 1) {
      nm = 12;
      ny--;
    } else if (nm > 12) {
      nm = 1;
      ny++;
    }
    ref.read(selectedMonthProvider.notifier).state = nm;
    ref.read(selectedYearProvider.notifier).state = ny;
  }
}

// ── Premium App Bar ───────────────────────────────────────────────────────────
//
// Two-row layout:
//   Row 1 (top)    — greeting (name + subtitle) on the left, actions on the right
//   Row 2 (bottom) — period navigator centered
//
// The greeting is embedded here directly so the separate _GreetingSliver is no
// longer needed on mobile, reducing top-of-page visual clutter.

class _PremiumAppBar extends ConsumerWidget {
  const _PremiumAppBar({
    required this.month,
    required this.year,
    required this.months,
    required this.periodLabel,
    required this.onPrev,
    required this.onNext,
  });

  final int month;
  final int year;
  final List<String> months;
  final String periodLabel;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.sizeOf(context).width >= _kDesktop;

    return SliverAppBar(
      floating: true,
      snap: true,
      titleSpacing: 0,
      // Two rows: ~52px greeting row + ~44px period row
      toolbarHeight: isDesktop ? 60 : 96,
      automaticallyImplyLeading: false,
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : tokens.FarolColors.navy.withValues(alpha: 0.06),
        ),
      ),
      title: isDesktop
          // Desktop: keep the original single-row compact layout
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: DSSpacing.lg),
              child: Row(
                children: [
                  const FarolMark(
                      size: FarolBrand.markSizeCompact,
                      variant: FarolLogoVariant.dark),
                  const SizedBox(width: DSSpacing.sm),
                  _MonthPicker(
                    month: month,
                    year: year,
                    months: months,
                    periodLabel: periodLabel,
                    onPrev: onPrev,
                    onNext: onNext,
                  ),
                  const Spacer(),
                  const WorkspaceAppBarChip(),
                  const SizedBox(width: DSSpacing.xs),
                  _NotificationBell(),
                ],
              ),
            )
          // Mobile: two-row layout
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: DSSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Row 1: greeting + actions ─────────────────────────
                  Row(
                    children: [
                      const FarolMark(
                          size: FarolBrand.markSizeCompact,
                          variant: FarolLogoVariant.dark),
                      const SizedBox(width: DSSpacing.sm),
                      const Expanded(
                        child:
                            FarolGreeting(variant: FarolGreetingVariant.appBar),
                      ),
                      const WorkspaceAppBarChip(),
                      const SizedBox(width: DSSpacing.xs),
                      _NotificationBell(),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // ── Row 2: period navigator — centered ────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MonthPicker(
                        month: month,
                        year: year,
                        months: months,
                        periodLabel: periodLabel,
                        onPrev: onPrev,
                        onNext: onNext,
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _MonthPicker extends StatelessWidget {
  const _MonthPicker({
    required this.month,
    required this.year,
    required this.months,
    required this.periodLabel,
    required this.onPrev,
    required this.onNext,
  });

  final int month;
  final int year;
  final List<String> months;
  final String periodLabel;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NavArrow(icon: Icons.chevron_left_rounded, onTap: onPrev),
        const SizedBox(width: DSSpacing.xs),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${months[month - 1]} $year',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: onSurface,
              ),
            ),
            Text(
              periodLabel,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 10,
                color: onSurface.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
        const SizedBox(width: DSSpacing.xs),
        _NavArrow(icon: Icons.chevron_right_rounded, onTap: onNext),
      ],
    );
  }
}

class _NavArrow extends StatefulWidget {
  const _NavArrow({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_NavArrow> createState() => _NavArrowState();
}

class _NavArrowState extends State<_NavArrow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: DSDuration.fast,
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _hovered
                ? (isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : tokens.FarolColors.navy.withValues(alpha: 0.08))
                : Colors.transparent,
            borderRadius: DSRadius.xsBR,
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _NotificationBell extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(budgetAlertsProvider);
    final critical = alerts.where((a) => a.level != AlertLevel.warning).length;
    return Badge(
      isLabelVisible: critical > 0,
      label: Text('$critical'),
      backgroundColor: tokens.FarolColors.coral,
      child: _AppBarIconBtn(
        icon: Icons.notifications_outlined,
        onTap: () => Navigator.pushNamed(context, '/notifications'),
      ),
    );
  }
}

class _AppBarIconBtn extends StatefulWidget {
  const _AppBarIconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_AppBarIconBtn> createState() => _AppBarIconBtnState();
}

class _AppBarIconBtnState extends State<_AppBarIconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: DSDuration.fast,
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _hovered
                ? (isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : tokens.FarolColors.navy.withValues(alpha: 0.07))
                : Colors.transparent,
            borderRadius: DSRadius.xsBR,
          ),
          child: Icon(
            widget.icon,
            size: 19,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

// ── Premium FAB ───────────────────────────────────────────────────────────────

class _PremiumFab extends StatefulWidget {
  const _PremiumFab({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_PremiumFab> createState() => _PremiumFabState();
}

class _PremiumFabState extends State<_PremiumFab>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _ctrl;
  late Animation<double> _rot;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: DSDuration.medium);
    _rot = Tween(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(parent: _ctrl, curve: DSCurve.smooth),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        child: AnimatedContainer(
          duration: DSDuration.normal,
          curve: DSCurve.smooth,
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: tokens.FarolColors.beam,
            borderRadius: BorderRadius.circular(
              _hovered ? DSRadius.lg : DSRadius.full,
            ),
            boxShadow: [
              BoxShadow(
                color: tokens.FarolColors.beam.withValues(
                  alpha: _hovered ? 0.45 : 0.25,
                ),
                blurRadius: _hovered ? 20 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AnimatedBuilder(
            animation: _rot,
            builder: (_, child) => Transform.rotate(
              angle: _rot.value * 3.14159 * 2,
              child: child,
            ),
            child: const Icon(
              Icons.add_rounded,
              color: tokens.FarolColors.navyDeep,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Mobile: single column ─────────────────────────────────────────────────────

class _MobileDashboardSliver extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: DSSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          const SizedBox(height: DSSpacing.lg),
          const LiquidityAlertCard(),
          const AlertBanner(),
          const SizedBox(height: DSSpacing.md),
          const PeriodBalanceHero(),
          const SizedBox(height: DSSpacing.md),
          const InsightsPanel(),
          const SizedBox(height: DSSpacing.md),
          const HealthGaugeCard(),
          const SizedBox(height: DSSpacing.md),
          const KpiGrid(),
          const SizedBox(height: DSSpacing.lg),
          const ExpenseBreakdown(),
          const SizedBox(height: DSSpacing.lg),
          const MonthlyGoalCard(),
          const SizedBox(height: DSSpacing.lg),
          const InstallmentsSummaryCard(),
          const SizedBox(height: DSSpacing.lg),
          const BurnRateCard(),
          const SizedBox(height: DSSpacing.lg),
          const RecurringCard(),
          const SizedBox(height: DSSpacing.lg),
          const RecurringSuggestionsCard(),
          const SizedBox(height: DSSpacing.lg),
          const ContributionBar(),
          const SizedBox(height: DSSpacing.md),
          const SpaceContributionsCard(),
          const SizedBox(height: DSSpacing.md),
          const ActivityFeedPreviewCard(),
          const FarolBottomPadding(),
        ]),
      ),
    );
  }
}

// ── Desktop 2-column (800–1199px) ────────────────────────────────────────────

class _DesktopDashboardSliver extends StatelessWidget {
  const _DesktopDashboardSliver();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        DSSpacing.xxl,
        DSSpacing.xl,
        DSSpacing.xxl,
        DSSpacing.xl,
      ),
      sliver: SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _kContentMaxW),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Left column (primary) ──────────────────────────────
                Expanded(
                  flex: 55,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LiquidityAlertCard(),
                      AlertBanner(),
                      SizedBox(height: DSSpacing.md),
                      PeriodBalanceHero(),
                      SizedBox(height: DSSpacing.md),
                      InsightsPanel(),
                      SizedBox(height: DSSpacing.lg),
                      ExpenseBreakdown(),
                      SizedBox(height: DSSpacing.lg),
                      MonthlyGoalCard(),
                      SizedBox(height: DSSpacing.lg),
                      ContributionBar(),
                      SizedBox(height: DSSpacing.md),
                      SpaceContributionsCard(),
                      SizedBox(height: DSSpacing.md),
                      ActivityFeedPreviewCard(),
                    ],
                  ),
                ),
                const SizedBox(width: DSSpacing.xl),
                // ── Right column (secondary) ───────────────────────────
                Expanded(
                  flex: 45,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      HealthGaugeCard(),
                      SizedBox(height: DSSpacing.md),
                      KpiGrid(compact: false),
                      SizedBox(height: DSSpacing.lg),
                      BurnRateCard(),
                      SizedBox(height: DSSpacing.lg),
                      InstallmentsSummaryCard(),
                      SizedBox(height: DSSpacing.lg),
                      RecurringCard(),
                      SizedBox(height: DSSpacing.lg),
                      RecurringSuggestionsCard(),
                    ],
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

// ── Wide desktop 3-column (≥1200px) ──────────────────────────────────────────
//
//  ┌─────────────┬────────────────────────────┬──────────────────┐
//  │ Left (28%)  │ Center (44%)               │ Right (28%)      │
//  │  Alerts     │  PeriodBalanceHero         │  HealthGauge     │
//  │  KpiGrid    │  InsightsPanel             │  Installments    │
//  │  BurnRate   │  ExpenseBreakdown          │  ContribBar      │
//  │  Recurring  │  ActivityFeedPreview       │  MonthlyGoal     │
//  └─────────────┴────────────────────────────┴──────────────────┘

class _WideDesktopSliver extends StatelessWidget {
  const _WideDesktopSliver();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        DSSpacing.xxl,
        DSSpacing.xl,
        DSSpacing.xxl,
        DSSpacing.xl,
      ),
      sliver: SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _kContentMaxW),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Left sidebar ─────────────────────────────────────
                Expanded(
                  flex: 28,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LiquidityAlertCard(),
                      AlertBanner(),
                      KpiGrid(compact: false),
                      SizedBox(height: DSSpacing.lg),
                      BurnRateCard(),
                      SizedBox(height: DSSpacing.lg),
                      RecurringCard(),
                      SizedBox(height: DSSpacing.lg),
                      RecurringSuggestionsCard(),
                    ],
                  ),
                ),
                const SizedBox(width: DSSpacing.xl),
                // ── Center (primary) ──────────────────────────────────
                Expanded(
                  flex: 42,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: DSSpacing.md),
                      PeriodBalanceHero(),
                      SizedBox(height: DSSpacing.md),
                      InsightsPanel(),
                      SizedBox(height: DSSpacing.lg),
                      ExpenseBreakdown(),
                      SizedBox(height: DSSpacing.lg),
                      SpaceContributionsCard(),
                      SizedBox(height: DSSpacing.lg),
                      ActivityFeedPreviewCard(),
                    ],
                  ),
                ),
                const SizedBox(width: DSSpacing.xl),
                // ── Right sidebar ─────────────────────────────────────
                Expanded(
                  flex: 30,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      HealthGaugeCard(),
                      SizedBox(height: DSSpacing.lg),
                      InstallmentsSummaryCard(),
                      SizedBox(height: DSSpacing.lg),
                      ContributionBar(),
                      SizedBox(height: DSSpacing.lg),
                      MonthlyGoalCard(),
                    ],
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
