import '../../models/expense.dart';
import '../../models/income.dart';
import '../../models/financial_period.dart';
import '../../services/financial_calculator_service.dart';
import '../entities/financial_snapshot.dart';
import '../entities/scheduled_payment.dart';
import '../entities/installment_plan.dart';
import '../entities/envelope.dart';
import '../value_objects/money.dart';

/// Produces a [FinancialSnapshot] from raw data.
/// Pure service — no Riverpod, no I/O. Fully testable.
class FinancialEngine {
  const FinancialEngine();

  FinancialSnapshot buildSnapshot({
    required FinancialPeriod period,
    required List<Income> incomes,
    required List<Expense> expenses,
    required double netSalaryOverride,
    required double swileOverride,
    required double emergencyFund,
    required List<InstallmentPlan> activePlans,
    List<Envelope> envelopes = const [],
    Money totalAllocated = Money.zero,
  }) {
    // ── Income ────────────────────────────────────────────────────────────────
    final cashIncome = Money.fromDouble(
      incomes
          .where((i) => i.incomeType == 'NET_SALARY')
          .fold(0.0, (s, i) => s + i.amount),
    );
    final swileIncome = Money.fromDouble(
      incomes
          .where((i) =>
              i.incomeType == 'SWILE_MEAL' || i.incomeType == 'SWILE_FOOD')
          .fold(0.0, (s, i) => s + i.amount),
    );

    // Use budget overrides when configured (covers months with no income rows)
    final effectiveCashIncome = netSalaryOverride > 0
        ? Money.fromDouble(netSalaryOverride)
        : cashIncome;
    final effectiveSwileIncome = swileOverride > 0
        ? Money.fromDouble(swileOverride)
        : swileIncome;

    final totalIncome = effectiveCashIncome + effectiveSwileIncome;

    // ── Expenses ──────────────────────────────────────────────────────────────
    final realExpenses = expenses.where((e) => !e.isProjected).toList();

    final cashSpent = Money.fromDouble(
      realExpenses
          .where((e) => e.payType == 'Cash')
          .fold(0.0, (s, e) => s + e.amount),
    );
    final swileSpent = Money.fromDouble(
      realExpenses
          .where((e) => e.payType == 'Swile')
          .fold(0.0, (s, e) => s + e.amount),
    );
    final totalSpent = cashSpent + swileSpent;

    // ── Balance ───────────────────────────────────────────────────────────────
    final currentBalance = effectiveCashIncome - cashSpent;
    final swileBalance = effectiveSwileIncome - swileSpent;

    // ── Health score ──────────────────────────────────────────────────────────
    final byCategory = <String, double>{};
    for (final e in realExpenses.where((e) => e.payType == 'Cash')) {
      byCategory[e.category] =
          (byCategory[e.category] ?? 0) + e.amount;
    }
    final housingExpenses = byCategory['housing'] ?? byCategory['HOUSING'] ?? 0;
    final activeInstallmentsTotal =
        activePlans.fold(0.0, (s, p) => s + p.installmentAmount);

    final healthScore = FinancialCalculatorService.calculateHealthScore(
      netSalary: effectiveCashIncome.amount,
      cashExpenses: cashSpent.amount,
      housingExpenses: housingExpenses,
      monthlyBalance: currentBalance.amount,
      emergencyFund: emergencyFund,
      avgMonthlyExpenses: cashSpent.amount,
      activeInstallmentsTotal: activeInstallmentsTotal,
    );

    final savingsRate = effectiveCashIncome.isZero
        ? 0.0
        : ((effectiveCashIncome - cashSpent).amount /
                effectiveCashIncome.amount *
                100)
            .clamp(0.0, 100.0);

    // ── Upcoming installment payments ─────────────────────────────────────────
    final now = DateTime.now();
    final upcomingPayments = activePlans
        .expand((plan) {
          final nextNum = plan.paidCount + 1;
          if (nextNum > plan.numInstallments) return <ScheduledPayment>[];
          final dueDate = plan.dueDateFor(nextNum);
          return [
            ScheduledPayment(
              id: '${plan.id}_$nextNum',
              description:
                  '${plan.description} $nextNum/${plan.numInstallments}',
              amount: Money.fromDouble(plan.installmentAmount),
              dueDate: dueDate,
              type: ScheduledPaymentType.installment,
              categorySlug: plan.categorySlug,
            ),
          ];
        })
        .where((p) => p.dueDate.isAfter(now.subtract(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final totalFutureObligations = upcomingPayments.fold(
      Money.zero,
      (sum, p) => sum + p.amount,
    );

    return FinancialSnapshot(
      period: period,
      generatedAt: now,
      totalIncome: totalIncome,
      cashIncome: effectiveCashIncome,
      swileIncome: effectiveSwileIncome,
      totalSpent: totalSpent,
      cashSpent: cashSpent,
      swileSpent: swileSpent,
      currentBalance: currentBalance,
      swileBalance: swileBalance,
      envelopes: envelopes,
      totalAllocated: totalAllocated,
      healthScore: healthScore,
      savingsRate: savingsRate,
      upcomingPayments: upcomingPayments,
      totalFutureObligations: totalFutureObligations,
    );
  }
}
