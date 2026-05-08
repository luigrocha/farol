import 'dart:math' as math;
import '../../models/expense.dart';
import '../../models/financial_period.dart';
import '../entities/burn_rate.dart';
import '../entities/cashflow_forecast.dart';
import '../entities/financial_projection.dart';
import '../entities/liquidity_risk.dart';
import '../entities/scheduled_payment.dart';
import '../value_objects/money.dart';

/// Produces a [FinancialProjection] from snapshot data + obligations.
/// Pure service — no Riverpod, no I/O.
class ForecastingEngine {
  const ForecastingEngine();

  FinancialProjection buildProjection({
    required FinancialPeriod period,
    required Money totalSpent,
    required Money totalAllocated,
    required Money currentBalance,
    required Money projectedIncome,
    required List<ScheduledPayment> obligations,
    List<Expense> expenseHistory = const [],
    bool buildForecastChart = false,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final daysElapsed = math.max(
        today.difference(DateTime(period.start.year, period.start.month, period.start.day)).inDays,
        0);
    final daysRemaining = math.max(
        DateTime(period.end.year, period.end.month, period.end.day)
            .difference(today)
            .inDays,
        0);

    // ── BurnRate ──────────────────────────────────────────────────────────────
    final burnRate = BurnRate(
      totalSpent: totalSpent,
      daysElapsed: daysElapsed,
      daysRemaining: daysRemaining,
      totalAllocated: totalAllocated,
    );

    // ── ProjectedClosingBalance ───────────────────────────────────────────────
    final confirmedObligations = obligations
        .where((p) => p.daysFromNow >= 0 && p.daysFromNow <= daysRemaining)
        .fold(Money.zero, (sum, p) => sum + p.amount);

    final projectedVariableSpend =
        burnRate.dailyRate * daysRemaining.toDouble();

    final projectedClosing = currentBalance
        + projectedIncome
        - projectedVariableSpend
        - confirmedObligations;

    // ── LiquidityRisk ─────────────────────────────────────────────────────────
    final next7 = obligations
        .where((p) => p.daysFromNow >= 0 && p.daysFromNow <= 7)
        .toList();
    final next7Total = next7.fold(Money.zero, (s, p) => s + p.amount);

    final daysEmpty = _daysUntilEmpty(
      balance: currentBalance,
      dailyRate: burnRate.dailyRate,
      obligations: obligations,
    );

    final riskLevel = _assessRisk(
      balance: currentBalance,
      next7Total: next7Total,
      projectedClosing: projectedClosing,
      daysEmpty: daysEmpty,
    );

    final liquidityRisk = LiquidityRisk(
      level: riskLevel,
      obligationsNext7Days: next7Total,
      currentBalance: currentBalance,
      daysUntilEmpty: daysEmpty,
      upcomingObligations: next7,
    );

    // ── CashflowForecast (optional) ───────────────────────────────────────────
    CashflowForecast? forecast;
    if (buildForecastChart) {
      forecast = _buildForecastChart(
        today: today,
        currentBalance: currentBalance,
        burnRate: burnRate,
        obligations: obligations,
        expenseHistory: expenseHistory,
        period: period,
        daysAhead: 90,
      );
    }

    return FinancialProjection(
      burnRate: burnRate,
      projectedClosingBalance: projectedClosing,
      liquidityRisk: liquidityRisk,
      cashflowForecast: forecast,
    );
  }

  // ── DaysUntilEmpty ────────────────────────────────────────────────────────

  int _daysUntilEmpty({
    required Money balance,
    required Money dailyRate,
    required List<ScheduledPayment> obligations,
  }) {
    if (dailyRate.isZero) return -1;
    var bal = balance;
    for (int day = 1; day <= 365; day++) {
      bal = bal - dailyRate;
      final dueToday = obligations
          .where((p) => p.daysFromNow == day)
          .fold(Money.zero, (sum, p) => sum + p.amount);
      bal = bal - dueToday;
      if (bal.isNegative) return day;
    }
    return -1;
  }

  // ── LiquidityRisk assessment ──────────────────────────────────────────────

  LiquidityRiskLevel _assessRisk({
    required Money balance,
    required Money next7Total,
    required Money projectedClosing,
    required int daysEmpty,
  }) {
    if (balance.isNegative) return LiquidityRiskLevel.critical;
    if (daysEmpty >= 0 && daysEmpty <= 7) return LiquidityRiskLevel.critical;
    if (daysEmpty >= 0 && daysEmpty <= 14) return LiquidityRiskLevel.high;
    if (projectedClosing.isNegative) return LiquidityRiskLevel.high;

    // Next 7 days obligations > 50% of current balance
    if (!balance.isZero && next7Total.amount / balance.amount > 0.5) {
      return LiquidityRiskLevel.medium;
    }
    if (daysEmpty >= 0 && daysEmpty <= 30) return LiquidityRiskLevel.medium;
    if (daysEmpty >= 0 && daysEmpty <= 60) return LiquidityRiskLevel.low;
    return LiquidityRiskLevel.none;
  }

  // ── CashflowForecast chart ────────────────────────────────────────────────

  CashflowForecast _buildForecastChart({
    required DateTime today,
    required Money currentBalance,
    required BurnRate burnRate,
    required List<ScheduledPayment> obligations,
    required List<Expense> expenseHistory,
    required FinancialPeriod period,
    required int daysAhead,
  }) {
    final points = <CashflowDataPoint>[];
    var balance = currentBalance;

    // Build a map of daily obligations for O(1) lookup
    final obligationByDay = <int, Money>{};
    for (final o in obligations) {
      final d = o.daysFromNow;
      if (d >= 0 && d <= daysAhead) {
        obligationByDay[d] = (obligationByDay[d] ?? Money.zero) + o.amount;
      }
    }

    // Historical daily expense map (past days in period)
    final historicalByDay = <DateTime, Money>{};
    for (final e in expenseHistory) {
      if (!e.isProjected && e.payType == 'Cash') {
        final d = DateTime(e.transactionDate.year, e.transactionDate.month,
            e.transactionDate.day);
        historicalByDay[d] =
            (historicalByDay[d] ?? Money.zero) + Money.fromDouble(e.amount);
      }
    }

    for (int i = 0; i <= daysAhead; i++) {
      final date = today.add(Duration(days: i));
      final isReal = !date.isAfter(today);

      Money dailyExpense;
      Money dailyIncome = Money.zero;

      if (isReal) {
        dailyExpense = historicalByDay[date] ?? Money.zero;
      } else {
        // Project: burn rate minus obligations (already counted separately)
        dailyExpense = burnRate.dailyRate;
        // Mark salary day as income if it falls in the window
        final periodStart =
            DateTime(period.start.year, period.start.month, period.start.day);
        if (date.day == periodStart.day) {
          // Rough heuristic: income resets on period start day
          // Real income is already in currentBalance; future periods: skip
        }
      }

      final obligationToday = obligationByDay[i] ?? Money.zero;
      balance = balance - dailyExpense - obligationToday + dailyIncome;

      points.add(CashflowDataPoint(
        date: date,
        balance: balance,
        hasObligation: !obligationToday.isZero,
        dailyExpense: dailyExpense,
        dailyIncome: dailyIncome,
        isReal: isReal,
      ));
    }

    return CashflowForecast(points: points, generatedAt: today);
  }
}
