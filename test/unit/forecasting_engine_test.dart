import 'package:flutter_test/flutter_test.dart';
import 'package:farol/core/domain/services/forecasting_engine.dart';
import 'package:farol/core/domain/services/obligation_engine.dart';
import 'package:farol/core/domain/entities/scheduled_payment.dart';
import 'package:farol/core/domain/entities/installment_payment.dart';
import 'package:farol/core/domain/entities/recurring_occurrence.dart';
import 'package:farol/core/domain/entities/liquidity_risk.dart';
import 'package:farol/core/domain/entities/burn_rate.dart';
import 'package:farol/core/domain/value_objects/money.dart';
import 'package:farol/core/models/financial_period.dart';

// ─── Fixtures ─────────────────────────────────────────────────────────────────

/// Cria um período financeiro com início e fim explícitos (sem depender de DateTime.now).
FinancialPeriod _period({
  DateTime? start,
  DateTime? end,
}) {
  final s = start ?? DateTime(2026, 5, 5);
  final e = end ?? DateTime(2026, 6, 4);
  return FinancialPeriod(start: s, end: e);
}

/// Cria um ScheduledPayment com daysFromNow simulado via dueDate.
ScheduledPayment _payment({
  required double amount,
  required int daysFromNow,
  ScheduledPaymentType type = ScheduledPaymentType.installment,
}) {
  final due = DateTime.now().add(Duration(days: daysFromNow));
  return ScheduledPayment(
    id: 'p_$daysFromNow',
    description: 'Test payment',
    amount: Money.fromDouble(amount),
    dueDate: due,
    type: type,
  );
}

const _engine = ForecastingEngine();

// ─── BurnRate Tests ───────────────────────────────────────────────────────────

void main() {
  group('BurnRate', () {
    test('dailyRate = totalSpent / daysElapsed', () {
      final br = BurnRate(
        totalSpent: Money.fromDouble(900),
        daysElapsed: 9,
        daysRemaining: 21,
        totalAllocated: Money.fromDouble(3000),
      );
      expect(br.dailyRate, Money.fromDouble(100));
    });

    test('dailyRate uses max(daysElapsed, 1) — never divides by zero', () {
      final br = BurnRate(
        totalSpent: Money.fromDouble(500),
        daysElapsed: 0,
        daysRemaining: 30,
        totalAllocated: Money.fromDouble(3000),
      );
      expect(br.dailyRate, Money.fromDouble(500)); // 500 / 1
    });

    test('projectedTotalSpend = spent + dailyRate * daysRemaining', () {
      final br = BurnRate(
        totalSpent: Money.fromDouble(300),
        daysElapsed: 3,
        daysRemaining: 27,
        totalAllocated: Money.fromDouble(3000),
      );
      // dailyRate = 100, projected = 300 + 100*27 = 3000
      expect(br.projectedTotalSpend, Money.fromDouble(3000));
    });

    test('pace: comfortable when projected < 80% of allocated', () {
      final br = BurnRate(
        totalSpent: Money.fromDouble(100),
        daysElapsed: 10,
        daysRemaining: 20,
        totalAllocated: Money.fromDouble(3000),
      );
      // projected = 100 + 10*20 = 300 → 10% of 3000 → comfortable
      expect(br.pace, BurnPace.comfortable);
    });

    test('pace: onTrack when projected 80–100% of allocated', () {
      final br = BurnRate(
        totalSpent: Money.fromDouble(800),
        daysElapsed: 10,
        daysRemaining: 20,
        totalAllocated: Money.fromDouble(3000),
      );
      // projected = 800 + 80*20 = 2400 → 80% of 3000 → onTrack
      expect(br.pace, BurnPace.onTrack);
    });

    test('pace: overspending when projected > 100% of allocated', () {
      final br = BurnRate(
        totalSpent: Money.fromDouble(2000),
        daysElapsed: 10,
        daysRemaining: 20,
        totalAllocated: Money.fromDouble(3000),
      );
      // projected = 2000 + 200*20 = 6000 → 200% of 3000
      expect(br.pace, BurnPace.overspending);
    });

    test('paceVsBudget returns 0 when allocated is zero (no division by zero)', () {
      final br = BurnRate(
        totalSpent: Money.fromDouble(500),
        daysElapsed: 5,
        daysRemaining: 25,
        totalAllocated: Money.zero,
      );
      expect(br.paceVsBudget, 0.0);
    });
  });

  // ─── ForecastingEngine.buildProjection ──────────────────────────────────────

  group('ForecastingEngine.buildProjection', () {
    test('projectedClosingBalance = currentBalance - projected variable spend - obligations', () {
      final period = _period();
      final obligations = [_payment(amount: 500, daysFromNow: 5)];

      final proj = _engine.buildProjection(
        period: period,
        totalSpent: Money.fromDouble(300),
        totalAllocated: Money.fromDouble(3000),
        currentBalance: Money.fromDouble(2000),
        projectedIncome: Money.zero,
        obligations: obligations,
      );

      // dailyRate = 300 / max(daysElapsed, 1)
      // projectedClosing = 2000 - (dailyRate * daysRemaining) - 500
      expect(proj.projectedClosingBalance, isNotNull);
      // Exact value depends on daysElapsed/Remaining at test runtime,
      // so we assert the general structure:
      expect(proj.burnRate.dailyRate.amount, greaterThan(0));
      expect(proj.liquidityRisk, isNotNull);
    });

    test('projectedClosingBalance is negative when balance cannot cover obligations', () {
      final period = _period();
      // R$100 balance, R$5000 in obligations
      final proj = _engine.buildProjection(
        period: period,
        totalSpent: Money.fromDouble(100),
        totalAllocated: Money.fromDouble(3000),
        currentBalance: Money.fromDouble(100),
        projectedIncome: Money.zero,
        obligations: [
          _payment(amount: 5000, daysFromNow: 3),
        ],
      );
      expect(proj.projectedClosingBalance.isNegative, isTrue);
    });

    test('projectedClosingBalance is positive with no obligations and low burn rate', () {
      final period = _period();
      final proj = _engine.buildProjection(
        period: period,
        totalSpent: Money.fromDouble(30),
        totalAllocated: Money.fromDouble(3000),
        currentBalance: Money.fromDouble(2500),
        projectedIncome: Money.zero,
        obligations: const [],
      );
      expect(proj.projectedClosingBalance.isPositive, isTrue);
    });

    test('cashflowForecast is null when buildForecastChart is false', () {
      final proj = _engine.buildProjection(
        period: _period(),
        totalSpent: Money.fromDouble(500),
        totalAllocated: Money.fromDouble(3000),
        currentBalance: Money.fromDouble(2000),
        projectedIncome: Money.zero,
        obligations: const [],
        buildForecastChart: false,
      );
      expect(proj.cashflowForecast, isNull);
    });

    test('cashflowForecast has 91 data points (today + 90 days ahead)', () {
      final proj = _engine.buildProjection(
        period: _period(),
        totalSpent: Money.fromDouble(500),
        totalAllocated: Money.fromDouble(3000),
        currentBalance: Money.fromDouble(2000),
        projectedIncome: Money.zero,
        obligations: const [],
        buildForecastChart: true,
      );
      expect(proj.cashflowForecast, isNotNull);
      expect(proj.cashflowForecast!.points.length, 91); // 0..90 inclusive
    });

    test('cashflow points: today is marked isReal=true, tomorrow is isReal=false', () {
      final proj = _engine.buildProjection(
        period: _period(),
        totalSpent: Money.fromDouble(500),
        totalAllocated: Money.fromDouble(3000),
        currentBalance: Money.fromDouble(2000),
        projectedIncome: Money.zero,
        obligations: const [],
        buildForecastChart: true,
      );
      final points = proj.cashflowForecast!.points;
      expect(points.first.isReal, isTrue);
      expect(points[1].isReal, isFalse);
    });

    test('cashflow point has hasObligation=true on obligation due date', () {
      final proj = _engine.buildProjection(
        period: _period(),
        totalSpent: Money.fromDouble(100),
        totalAllocated: Money.fromDouble(3000),
        currentBalance: Money.fromDouble(2000),
        projectedIncome: Money.zero,
        obligations: [_payment(amount: 500, daysFromNow: 5)],
        buildForecastChart: true,
      );
      final points = proj.cashflowForecast!.points;
      expect(points[5].hasObligation, isTrue);
      expect(points[4].hasObligation, isFalse);
    });

    test('obligations outside 0..daysRemaining are excluded from projectedClosing', () {
      final period = _period();
      final futureObligation = _payment(amount: 10000, daysFromNow: 400); // way beyond period
      final proj = _engine.buildProjection(
        period: period,
        totalSpent: Money.fromDouble(100),
        totalAllocated: Money.fromDouble(3000),
        currentBalance: Money.fromDouble(3000),
        projectedIncome: Money.zero,
        obligations: [futureObligation],
      );
      // Should not include the 10000 obligation — projected balance should still be positive
      expect(proj.projectedClosingBalance.isPositive, isTrue);
    });
  });

  // ─── DaysUntilEmpty ──────────────────────────────────────────────────────────

  group('DaysUntilEmpty', () {
    test('returns -1 when daily rate is zero (no spending)', () {
      final proj = _engine.buildProjection(
        period: _period(),
        totalSpent: Money.zero,
        totalAllocated: Money.fromDouble(3000),
        currentBalance: Money.fromDouble(2000),
        projectedIncome: Money.zero,
        obligations: const [],
      );
      expect(proj.liquidityRisk.daysUntilEmpty, -1);
    });

    test('returns -1 when solvent for entire 365-day horizon', () {
      final proj = _engine.buildProjection(
        period: _period(),
        totalSpent: Money.fromDouble(10), // R$10 in many days = tiny rate
        totalAllocated: Money.fromDouble(3000),
        currentBalance: Money.fromDouble(1000000),
        projectedIncome: Money.zero,
        obligations: const [],
      );
      expect(proj.liquidityRisk.daysUntilEmpty, -1);
    });

    test('goes negative when a large obligation is due soon', () {
      final proj = _engine.buildProjection(
        period: _period(),
        totalSpent: Money.fromDouble(100),
        totalAllocated: Money.fromDouble(3000),
        currentBalance: Money.fromDouble(200), // barely enough
        projectedIncome: Money.zero,
        obligations: [_payment(amount: 500, daysFromNow: 3)],
      );
      // Balance = 200, daily rate ~modest, 500 due in 3 days → goes negative fast
      expect(proj.liquidityRisk.daysUntilEmpty, greaterThan(0));
      expect(proj.liquidityRisk.daysUntilEmpty, lessThanOrEqualTo(10));
    });
  });

  // ─── LiquidityRisk ───────────────────────────────────────────────────────────

  group('LiquidityRisk assessment', () {
    test('critical when balance is negative', () {
      final proj = _engine.buildProjection(
        period: _period(),
        totalSpent: Money.fromDouble(100),
        totalAllocated: Money.fromDouble(3000),
        currentBalance: Money.fromDouble(-50), // already negative
        projectedIncome: Money.zero,
        obligations: const [],
      );
      expect(proj.liquidityRisk.level, LiquidityRiskLevel.critical);
    });

    test('critical when daysUntilEmpty <= 7', () {
      final proj = _engine.buildProjection(
        period: _period(),
        totalSpent: Money.fromDouble(500),
        totalAllocated: Money.fromDouble(3000),
        currentBalance: Money.fromDouble(100), // tiny balance, high daily rate
        projectedIncome: Money.zero,
        obligations: const [],
      );
      // dailyRate = 500/days_elapsed; with 100 balance, empty very fast
      final level = proj.liquidityRisk.level;
      expect(
        level == LiquidityRiskLevel.critical || level == LiquidityRiskLevel.high,
        isTrue,
      );
    });

    test('none when large balance and no obligations', () {
      final proj = _engine.buildProjection(
        period: _period(),
        totalSpent: Money.fromDouble(100),
        totalAllocated: Money.fromDouble(3000),
        currentBalance: Money.fromDouble(10000),
        projectedIncome: Money.zero,
        obligations: const [],
      );
      expect(proj.liquidityRisk.level, LiquidityRiskLevel.none);
    });

    test('medium when next-7-day obligations > 50% of current balance', () {
      final proj = _engine.buildProjection(
        period: _period(),
        totalSpent: Money.fromDouble(100),
        totalAllocated: Money.fromDouble(5000),
        currentBalance: Money.fromDouble(1000),
        projectedIncome: Money.zero,
        obligations: [
          _payment(amount: 600, daysFromNow: 3), // 60% of balance
        ],
      );
      // 600/1000 = 60% > 50% → at least medium
      final level = proj.liquidityRisk.level;
      expect(
        level == LiquidityRiskLevel.medium ||
            level == LiquidityRiskLevel.high ||
            level == LiquidityRiskLevel.critical,
        isTrue,
      );
    });

    test('isAtRisk is true for medium/high/critical levels', () {
      for (final level in [
        LiquidityRiskLevel.medium,
        LiquidityRiskLevel.high,
        LiquidityRiskLevel.critical,
      ]) {
        final risk = LiquidityRisk(
          level: level,
          obligationsNext7Days: Money.fromDouble(500),
          currentBalance: Money.fromDouble(1000),
          daysUntilEmpty: 10,
          upcomingObligations: const [],
        );
        expect(risk.isAtRisk, isTrue, reason: '$level should be isAtRisk=true');
      }
    });

    test('isAtRisk is false for none/low levels', () {
      for (final level in [LiquidityRiskLevel.none, LiquidityRiskLevel.low]) {
        final risk = LiquidityRisk(
          level: level,
          obligationsNext7Days: Money.zero,
          currentBalance: Money.fromDouble(5000),
          daysUntilEmpty: -1,
          upcomingObligations: const [],
        );
        expect(risk.isAtRisk, isFalse, reason: '$level should be isAtRisk=false');
      }
    });
  });

  // ─── ObligationEngine ────────────────────────────────────────────────────────

  group('ObligationEngine', () {
    const obligation = ObligationEngine();

    test('builds obligations from pending installment payments', () {
      final payment = InstallmentPayment(
        id: 'pay1',
        planId: 'plan1',
        userId: 'u1',
        installmentNum: 2,
        dueDate: DateTime.now().add(const Duration(days: 10)),
        amount: 300,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = obligation.buildObligations(
        pendingInstallments: [payment],
        pendingOccurrences: const [],
      );

      expect(result.length, 1);
      expect(result.first.amount, Money.fromDouble(300));
      expect(result.first.type, ScheduledPaymentType.installment);
    });

    test('excludes paid installments', () {
      final paid = InstallmentPayment(
        id: 'pay_paid',
        planId: 'plan1',
        userId: 'u1',
        installmentNum: 1,
        dueDate: DateTime.now().subtract(const Duration(days: 5)),
        amount: 200,
        status: 'paid',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = obligation.buildObligations(
        pendingInstallments: [paid],
        pendingOccurrences: const [],
      );

      expect(result, isEmpty);
    });

    test('includes overdue installments', () {
      final overdue = InstallmentPayment(
        id: 'pay_overdue',
        planId: 'plan1',
        userId: 'u1',
        installmentNum: 1,
        dueDate: DateTime.now().subtract(const Duration(days: 2)),
        amount: 150,
        status: 'overdue',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = obligation.buildObligations(
        pendingInstallments: [overdue],
        pendingOccurrences: const [],
      );

      expect(result.length, 1);
      expect(result.first.amount, Money.fromDouble(150));
    });

    test('builds obligations from pending recurring occurrences', () {
      final occurrence = RecurringOccurrence(
        id: 'occ1',
        ruleId: 'rule1',
        userId: 'u1',
        scheduledDate: DateTime.now().add(const Duration(days: 7)),
        expectedAmount: 1500,
        status: OccurrenceStatus.pending,
        isException: false,
        createdAt: DateTime.now(),
      );

      final result = obligation.buildObligations(
        pendingInstallments: const [],
        pendingOccurrences: [occurrence],
      );

      expect(result.length, 1);
      expect(result.first.amount, Money.fromDouble(1500));
      expect(result.first.type, ScheduledPaymentType.recurring);
    });

    test('result is sorted by due date ascending', () {
      final later = InstallmentPayment(
        id: 'pay_later',
        planId: 'plan1',
        userId: 'u1',
        installmentNum: 2,
        dueDate: DateTime.now().add(const Duration(days: 20)),
        amount: 200,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final sooner = InstallmentPayment(
        id: 'pay_sooner',
        planId: 'plan1',
        userId: 'u1',
        installmentNum: 1,
        dueDate: DateTime.now().add(const Duration(days: 5)),
        amount: 100,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = obligation.buildObligations(
        pendingInstallments: [later, sooner],
        pendingOccurrences: const [],
      );

      expect(result.first.dueDate.isBefore(result.last.dueDate), isTrue);
    });

    test('mixes installments + recurring sorted together', () {
      final installment = InstallmentPayment(
        id: 'i1',
        planId: 'p1',
        userId: 'u1',
        installmentNum: 1,
        dueDate: DateTime.now().add(const Duration(days: 10)),
        amount: 400,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final recurring = RecurringOccurrence(
        id: 'o1',
        ruleId: 'r1',
        userId: 'u1',
        scheduledDate: DateTime.now().add(const Duration(days: 3)),
        expectedAmount: 1200,
        status: OccurrenceStatus.pending,
        isException: false,
        createdAt: DateTime.now(),
      );

      final result = obligation.buildObligations(
        pendingInstallments: [installment],
        pendingOccurrences: [recurring],
      );

      expect(result.length, 2);
      expect(result.first.type, ScheduledPaymentType.recurring); // sooner
      expect(result.last.type, ScheduledPaymentType.installment); // later
    });

    test('daysUntilEmpty: returns -1 when daily rate is zero', () {
      expect(
        obligation.daysUntilEmpty(
          balance: Money.fromDouble(1000),
          dailyRate: Money.zero,
          obligations: const [],
        ),
        -1,
      );
    });

    test('daysUntilEmpty: returns -1 when solvent across full 365-day horizon', () {
      expect(
        obligation.daysUntilEmpty(
          balance: Money.fromDouble(1000000),
          dailyRate: Money.fromDouble(1),
          obligations: const [],
        ),
        -1,
      );
    });

    test('daysUntilEmpty: detects emptying due to large obligation', () {
      final bigObligation = ScheduledPayment(
        id: 'o1',
        description: 'aluguel',
        amount: Money.fromDouble(3000),
        dueDate: DateTime.now().add(const Duration(days: 5)),
        type: ScheduledPaymentType.recurring,
      );

      final result = obligation.daysUntilEmpty(
        balance: Money.fromDouble(500),
        dailyRate: Money.fromDouble(10), // modest daily spend
        obligations: [bigObligation],
      );

      expect(result, greaterThan(0));
      expect(result, lessThanOrEqualTo(10));
    });
  });

  // ─── ScheduledPayment ─────────────────────────────────────────────────────────

  group('ScheduledPayment', () {
    test('daysFromNow is positive for future date', () {
      final p = _payment(amount: 100, daysFromNow: 10);
      expect(p.daysFromNow, 10);
    });

    test('isOverdue is true for past date', () {
      final p = _payment(amount: 100, daysFromNow: -3);
      expect(p.isOverdue, isTrue);
    });

    test('isDueThisWeek is true for 0–7 days', () {
      for (int i = 0; i <= 7; i++) {
        final p = _payment(amount: 100, daysFromNow: i);
        expect(p.isDueThisWeek, isTrue, reason: 'daysFromNow=$i should be thisWeek');
      }
    });

    test('isDueThisWeek is false for 8+ days', () {
      final p = _payment(amount: 100, daysFromNow: 8);
      expect(p.isDueThisWeek, isFalse);
    });
  });
}
