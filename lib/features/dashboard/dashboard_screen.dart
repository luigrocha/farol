import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/models/budget_alert.dart';
import '../../design/farol_colors.dart' as tokens;
import '../../core/i18n/app_localizations.dart';
import '../../core/theme/farol_colors.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'widgets/swile_dashboard_card.dart';
import 'widgets/recent_transactions_card.dart';
import '../insights/insights_panel.dart';
import '../workspace/workspace_switcher_sheet.dart';
import '../../core/providers/workspace_providers.dart' show canWriteProvider;

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  // Desktop breakpoint: two-column grid above this width.
  static const double _desktopBreakpoint = 800;

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
    final isDesktop =
        MediaQuery.sizeOf(context).width >= _desktopBreakpoint;

    final appBar = SliverAppBar(
      floating: true,
      // titleSpacing: 0 lets the title use all available space without extra margins.
      titleSpacing: 0,
      toolbarHeight: 56,
      // Use automaticallyImplyLeading: false so Flutter doesn't reserve space for
      // a back button, which would shrink the available title width.
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          // ── Left: chevron + date column + chevron ─────────────────────────
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            visualDensity: VisualDensity.compact,
            onPressed: () => _changeMonth(ref, month, year, -1),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${months[month - 1]} $year',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Text(
                periodLabel,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                  color: context.colors.onSurfaceSoft,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            visualDensity: VisualDensity.compact,
            onPressed: () => _changeMonth(ref, month, year, 1),
          ),
          // ── Right: workspace chip + icons (use Expanded + Row so they never overflow)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const WorkspaceAppBarChip(),
                Consumer(builder: (_, ref, __) {
                  final isPrivate = ref.watch(privacyModeProvider);
                  return IconButton(
                    icon: Icon(
                      isPrivate
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: () =>
                        ref.read(privacyModeProvider.notifier).toggle(),
                  );
                }),
                Consumer(builder: (_, ref, __) {
                  final alerts = ref.watch(budgetAlertsProvider);
                  final critical =
                      alerts.where((a) => a.level != AlertLevel.warning).length;
                  return Badge(
                    isLabelVisible: critical > 0,
                    label: Text('$critical'),
                    backgroundColor: tokens.FarolColors.coral,
                    child: IconButton(
                      icon: const Icon(Icons.notifications_outlined, size: 20),
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          Navigator.pushNamed(context, '/notifications'),
                    ),
                  );
                }),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      body: Column(children: [
        const ConnectivityBanner(),
        Expanded(
          child: CustomScrollView(
            slivers: [
              appBar,
              if (isDesktop)
                _DesktopDashboardSliver()
              else
                _MobileDashboardSliver(),
            ],
          ),
        ),
      ]),
      floatingActionButton: Consumer(
        builder: (context, ref, _) {
          final canWrite = ref.watch(canWriteProvider);
          if (!canWrite) return const SizedBox.shrink();
          return FloatingActionButton(
            heroTag: 'fab_dashboard',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const QuickAddBottomSheet(),
            ),
            backgroundColor: tokens.FarolColors.beam,
            child: const Icon(Icons.add, color: tokens.FarolColors.navy),
          );
        },
      ),
    );
  }

  void _changeMonth(WidgetRef ref, int m, int y, int delta) {
    int nm = m + delta;
    int ny = y;
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

// ── Mobile: single-column list (unchanged behaviour) ─────────────────────────

class _MobileDashboardSliver extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // 1. Alerts — urgent signals at the top
          const LiquidityAlertCard(),
          const AlertBanner(),
          const SizedBox(height: 12),
          // 2. Period hero — primary financial summary
          const PeriodBalanceHero(),
          const SizedBox(height: 12),
          // 3. Insights — contextual alerts beneath the balance
          const InsightsPanel(),
          const SizedBox(height: 12),
          // 4. Health + KPIs
          const HealthGaugeCard(),
          const SizedBox(height: 12),
          const KpiGrid(),
          const SizedBox(height: 16),
          // 5. Category spending breakdown
          const ExpenseBreakdown(),
          const SizedBox(height: 16),
          // 6. Monthly savings goal
          const MonthlyGoalCard(),
          const SizedBox(height: 16),
          // 7. Installments
          const InstallmentsSummaryCard(),
          const SizedBox(height: 16),
          // 8. Burn rate
          const BurnRateCard(),
          const SizedBox(height: 16),
          // 9. Recurring rules
          const RecurringCard(),
          const SizedBox(height: 16),
          const RecurringSuggestionsCard(),
          const SizedBox(height: 16),
          // 10. Collaboration widgets (only visible in shared workspaces)
          const ContributionBar(),
          const SizedBox(height: 12),
          const ActivityFeedPreviewCard(),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }
}

// ── Desktop: 3-column grid ────────────────────────────────────────────────────
//
//  Row 1:  BalanceHero (45%)  │  InsightsPanel (35%)  │  Health + BurnRate (20%)
//  Row 2:  KPI mini-cards — 4 cards horizontal (full width)
//  Row 3:  ExpenseBreakdown   │  InstallmentsSummary  │  SwileDashboardCard
//  Row 4:  RecentTransactionsCard (full width)

class _DesktopDashboardSliver extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SliverPadding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 80),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Alerts (collapsible, shown when needed)
            LiquidityAlertCard(),
            AlertBanner(),
            SizedBox(height: 12),

            // ── Row 1: Balance | Insights | Health+BurnRate ──
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 45, child: PeriodBalanceHero()),
                  SizedBox(width: 16),
                  Expanded(flex: 35, child: InsightsPanel()),
                  SizedBox(width: 16),
                  Expanded(
                    flex: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        HealthGaugeCard(),
                        SizedBox(height: 12),
                        BurnRateCard(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // ── Row 2: 4 KPI mini-cards horizontal ──
            _KpiRow(),
            SizedBox(height: 16),

            // ── Row 3: ExpenseBreakdown | Parcelas | Swile ──
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 45, child: ExpenseBreakdown()),
                  SizedBox(width: 16),
                  Expanded(flex: 35, child: InstallmentsSummaryCard()),
                  SizedBox(width: 16),
                  Expanded(flex: 20, child: SwileDashboardCard()),
                ],
              ),
            ),
            SizedBox(height: 16),

            // ── Row 4: Últimas Transacciones ──
            RecentTransactionsCard(),
            SizedBox(height: 16),

            // Collaboration widgets (shared workspaces only)
            ContributionBar(),
            SizedBox(height: 12),
            ActivityFeedPreviewCard(),
          ],
        ),
      ),
    );
  }
}

class _KpiRow extends ConsumerWidget {
  const _KpiRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(financialSnapshotProvider);
    final colors = context.colors;

    final items = [
      (
        icon: Icons.account_balance_wallet,
        bg: colors.iconTintBlue,
        label: 'Salário Líquido',
        value: snap.cashIncome.amount,
        color: null as Color?,
      ),
      (
        icon: Icons.fastfood,
        bg: colors.secondaryContainer,
        label: 'Beneficios Swile',
        value: snap.swileIncome.amount,
        color: tokens.FarolColors.beam as Color?,
      ),
      (
        icon: Icons.trending_down,
        bg: colors.iconTintRed,
        label: 'Gastos Totais',
        value: snap.cashSpent.amount,
        color: tokens.FarolColors.coral as Color?,
      ),
      (
        icon: Icons.savings,
        bg: colors.iconTintBlue,
        label: 'Taxa de Ahorro',
        value: null as double?,
        color: null as Color?,
      ),
    ];
    final sr = snap.savingsRate;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(
              child: i == 3
                  ? KpiCard(
                      icon: items[i].icon,
                      bg: items[i].bg,
                      label: items[i].label,
                      raw: '${sr.toStringAsFixed(1)}%',
                      compact: false,
                    )
                  : KpiCard(
                      icon: items[i].icon,
                      bg: items[i].bg,
                      label: items[i].label,
                      value: items[i].value,
                      color: items[i].color,
                      compact: false,
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
