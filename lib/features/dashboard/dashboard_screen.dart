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
      toolbarHeight: 64,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
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
                  fontSize: 16,
                ),
              ),
              Text(
                periodLabel,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                  color: context.colors.onSurfaceSoft,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: () => _changeMonth(ref, month, year, 1),
          ),
        ],
      ),
      actions: [
        // Workspace chip — visible only when user has >1 workspace
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
            onPressed: () => ref.read(privacyModeProvider.notifier).toggle(),
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
              onPressed: () =>
                  Navigator.pushNamed(context, '/notifications'),
            ),
          );
        }),
        const SizedBox(width: 16),
      ],
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
          const LiquidityAlertCard(),
          const AlertBanner(),
          const SizedBox(height: 12),
          const InsightsPanel(),
          const SizedBox(height: 4),
          const PeriodBalanceHero(),
          const SizedBox(height: 12),
          const ContributionBar(),
          const SizedBox(height: 12),
          const ActivityFeedPreviewCard(),
          const SizedBox(height: 12),
          const HealthGaugeCard(),
          const SizedBox(height: 12),
          const KpiGrid(),
          const SizedBox(height: 16),
          const ExpenseBreakdown(),
          const SizedBox(height: 16),
          const MonthlyGoalCard(),
          const SizedBox(height: 16),
          const InstallmentsSummaryCard(),
          const SizedBox(height: 16),
          const BurnRateCard(),
          const SizedBox(height: 16),
          const RecurringCard(),
          const SizedBox(height: 16),
          const RecurringSuggestionsCard(),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }
}

// ── Desktop: two-column grid ──────────────────────────────────────────────────
//
//  ┌─────────────────────────────┬──────────────────────────┐
//  │  LiquidityAlertCard         │  HealthGaugeCard          │
//  │  AlertBanner                │  BurnRateCard             │
//  │  InsightsPanel              │  InstallmentsSummaryCard  │
//  │  PeriodBalanceHero          │  RecurringCard            │
//  │  KpiGrid                    │  RecurringSuggestionsCard │
//  │  ExpenseBreakdown           │                           │
//  │  MonthlyGoalCard            │                           │
//  └─────────────────────────────┴──────────────────────────┘

class _DesktopDashboardSliver extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 80),
      sliver: SliverToBoxAdapter(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left column (primary) ──
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  LiquidityAlertCard(),
                  AlertBanner(),
                  SizedBox(height: 12),
                  InsightsPanel(),
                  SizedBox(height: 4),
                  PeriodBalanceHero(),
                  SizedBox(height: 12),
                  ContributionBar(),
                  SizedBox(height: 12),
                  ActivityFeedPreviewCard(),
                  SizedBox(height: 12),
                  KpiGrid(),
                  SizedBox(height: 16),
                  ExpenseBreakdown(),
                  SizedBox(height: 16),
                  MonthlyGoalCard(),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // ── Right column (secondary) ──
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  HealthGaugeCard(),
                  SizedBox(height: 16),
                  BurnRateCard(),
                  SizedBox(height: 16),
                  InstallmentsSummaryCard(),
                  SizedBox(height: 16),
                  RecurringCard(),
                  SizedBox(height: 16),
                  RecurringSuggestionsCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
