import '../value_objects/money.dart';
import 'envelope.dart';
import 'scheduled_payment.dart';
import '../../models/financial_period.dart';

class FinancialSnapshot {
  final FinancialPeriod period;
  final DateTime generatedAt;

  // ── Income ──────────────────────────────────────
  final Money totalIncome;
  final Money cashIncome;
  final Money swileIncome;

  // ── Expenses ────────────────────────────────────
  final Money totalSpent;
  final Money cashSpent;
  final Money swileSpent;

  // ── Balance ─────────────────────────────────────
  final Money currentBalance;
  final Money swileBalance;

  // ── Envelopes ───────────────────────────────────
  final List<Envelope> envelopes;
  final Money totalAllocated;

  // ── Health ──────────────────────────────────────
  final int healthScore;
  final double savingsRate;

  // ── Upcoming ────────────────────────────────────
  final List<ScheduledPayment> upcomingPayments;
  final Money totalFutureObligations;

  const FinancialSnapshot({
    required this.period,
    required this.generatedAt,
    required this.totalIncome,
    required this.cashIncome,
    required this.swileIncome,
    required this.totalSpent,
    required this.cashSpent,
    required this.swileSpent,
    required this.currentBalance,
    required this.swileBalance,
    required this.envelopes,
    required this.totalAllocated,
    required this.healthScore,
    required this.savingsRate,
    required this.upcomingPayments,
    required this.totalFutureObligations,
  });

  factory FinancialSnapshot.empty(FinancialPeriod period) => FinancialSnapshot(
        period: period,
        generatedAt: DateTime.now(),
        totalIncome: Money.zero,
        cashIncome: Money.zero,
        swileIncome: Money.zero,
        totalSpent: Money.zero,
        cashSpent: Money.zero,
        swileSpent: Money.zero,
        currentBalance: Money.zero,
        swileBalance: Money.zero,
        envelopes: const [],
        totalAllocated: Money.zero,
        healthScore: 0,
        savingsRate: 0,
        upcomingPayments: const [],
        totalFutureObligations: Money.zero,
      );

  bool get isPositive => currentBalance.isPositive;
  Money get remainingCash => cashIncome - cashSpent;

  String get healthColor {
    if (healthScore >= 7) return 'green';
    if (healthScore >= 4) return 'amber';
    return 'red';
  }

  FinancialSnapshot copyWith({
    FinancialPeriod? period,
    DateTime? generatedAt,
    Money? totalIncome,
    Money? cashIncome,
    Money? swileIncome,
    Money? totalSpent,
    Money? cashSpent,
    Money? swileSpent,
    Money? currentBalance,
    Money? swileBalance,
    List<Envelope>? envelopes,
    Money? totalAllocated,
    int? healthScore,
    double? savingsRate,
    List<ScheduledPayment>? upcomingPayments,
    Money? totalFutureObligations,
  }) =>
      FinancialSnapshot(
        period: period ?? this.period,
        generatedAt: generatedAt ?? this.generatedAt,
        totalIncome: totalIncome ?? this.totalIncome,
        cashIncome: cashIncome ?? this.cashIncome,
        swileIncome: swileIncome ?? this.swileIncome,
        totalSpent: totalSpent ?? this.totalSpent,
        cashSpent: cashSpent ?? this.cashSpent,
        swileSpent: swileSpent ?? this.swileSpent,
        currentBalance: currentBalance ?? this.currentBalance,
        swileBalance: swileBalance ?? this.swileBalance,
        envelopes: envelopes ?? this.envelopes,
        totalAllocated: totalAllocated ?? this.totalAllocated,
        healthScore: healthScore ?? this.healthScore,
        savingsRate: savingsRate ?? this.savingsRate,
        upcomingPayments: upcomingPayments ?? this.upcomingPayments,
        totalFutureObligations:
            totalFutureObligations ?? this.totalFutureObligations,
      );
}
