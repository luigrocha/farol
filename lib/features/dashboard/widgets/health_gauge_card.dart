import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/financial_calculator_service.dart';
import '../../../core/widgets/health_gauge.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/farol_colors.dart';
import '../utils/dashboard_constants.dart';

class HealthGaugeCard extends ConsumerWidget {
  const HealthGaugeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final net = ref.watch(effectiveNetSalaryProvider);
    final cash = ref.watch(cashExpensesProvider);
    final byCategory = ref.watch(cashExpensesByCategoryProvider);
    final bal = ref.watch(cashRemainingProvider);
    final snapAsync = ref.watch(netWorthSnapshotProvider);
    final instAsync = ref.watch(installmentsProvider);

    if (snapAsync.isLoading || instAsync.isLoading) {
      return const DashboardCardSkeleton(height: 200);
    }

    final snap = snapAsync.value;
    final inst = instAsync.value ?? [];
    final housing = byCategory['HOUSING'] ?? 0;
    final instTotal = inst.fold(0.0, (s, i) => s + i.monthlyAmount);
    final ef = snap?.emergencyFund ?? 0;
    final score = FinancialCalculatorService.calculateHealthScore(
      netSalary: net,
      cashExpenses: cash,
      housingExpenses: housing,
      monthlyBalance: bal,
      emergencyFund: ef,
      avgMonthlyExpenses: cash,
      activeInstallmentsTotal: instTotal,
    );

    ref.watch(healthAutoSaveProvider);

    String statusLabel = l10n.healthHealthy;
    String description = l10n.healthExcellentDesc;
    if (score < 4) {
      statusLabel = l10n.healthCritical;
      description = l10n.healthCriticalDesc;
    } else if (score < 7) {
      statusLabel = l10n.healthWarning;
      description = score < 5 ? l10n.healthFairDesc : l10n.healthGoodDesc;
    }

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/health'),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(kCardPadding),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.healthScore,
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: colors.onSurfaceFaint,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              HealthGauge(
                score: score.toDouble() * 10,
                size: kHealthGaugeSize,
                statusLabel: statusLabel,
              ),
              const SizedBox(height: 16),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: colors.onSurfaceSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
