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

    ref.listen<AsyncValue<int>>(fixedExpensePropagationProvider, (_, next) {
      next.whenData((count) {
        if (count > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$count gasto${count == 1 ? '' : 's'} fijo${count == 1 ? '' : 's'} copiado${count == 1 ? '' : 's'} del mes anterior',
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
    });

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
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
                final critical = alerts
                    .where((a) => a.level != AlertLevel.warning)
                    .length;
                return Badge(
                  isLabelVisible: critical > 0,
                  label: Text('$critical'),
                  backgroundColor: tokens.FarolColors.coral,
                  child: IconButton(
                    icon: const Icon(Icons.notifications_outlined, size: 20),
                    onPressed: () => Navigator.pushNamed(context, '/notifications'),
                  ),
                );
              }),
              const SizedBox(width: 16),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const AlertBanner(),
                const SizedBox(height: 12),
                const PeriodBalanceHero(),
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
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_dashboard',
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const QuickAddBottomSheet(),
        ),
        backgroundColor: tokens.FarolColors.beam,
        child: const Icon(Icons.add, color: tokens.FarolColors.navy),
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
