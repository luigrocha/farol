import 'package:flutter_test/flutter_test.dart';
import 'package:farol/core/domain/services/financial_engine.dart';
import 'package:farol/core/domain/entities/installment_plan.dart';
import 'package:farol/core/models/expense.dart';
import 'package:farol/core/models/income.dart';
import 'package:farol/core/models/financial_period.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

FinancialPeriod _period({int year = 2026, int month = 5}) =>
    FinancialPeriod.current(1, now: DateTime(year, month, 15));

Income _salary(double amount, {int month = 5, int year = 2026}) => Income(
      id: 1,
      userId: 'u',
      month: month,
      year: year,
      incomeType: 'NET_SALARY',
      amount: amount,
      createdAt: DateTime(year, month, 1),
    );

Income _swile(double amount, {String type = 'SWILE_MEAL'}) => Income(
      id: 2,
      userId: 'u',
      month: 5,
      year: 2026,
      incomeType: type,
      amount: amount,
      createdAt: DateTime(2026, 5, 1),
    );

Expense _cash(double amount, {String category = 'food_grocery', bool projected = false}) =>
    Expense(
      id: 1,
      userId: 'u',
      month: 5,
      year: 2026,
      transactionDate: DateTime(2026, 5, 10),
      payType: 'Cash',
      category: category,
      amount: amount,
      paymentMethod: 'pix',
      createdAt: DateTime(2026, 5, 10),
      isProjected: projected,
    );

Expense _swileExpense(double amount) => Expense(
      id: 2,
      userId: 'u',
      month: 5,
      year: 2026,
      transactionDate: DateTime(2026, 5, 10),
      payType: 'Swile',
      category: 'food_restaurant',
      amount: amount,
      paymentMethod: 'swile',
      createdAt: DateTime(2026, 5, 10),
    );

InstallmentPlan _plan({
  double installmentAmount = 500,
  int numInstallments = 6,
  int paidCount = 1,
}) {
  // firstDueDate = next month so upcoming payments are always in the future
  final firstDue = DateTime.now().add(const Duration(days: 30));
  return InstallmentPlan(
    id: 'plan-1',
    userId: 'u',
    description: 'Notebook',
    purchaseDate: DateTime(2026, 4, 1),
    totalAmount: installmentAmount * numInstallments,
    numInstallments: numInstallments,
    installmentAmount: installmentAmount,
    paymentMethod: 'credit',
    firstDueDate: firstDue,
    status: 'active',
    createdAt: DateTime(2026, 4, 1),
    updatedAt: DateTime(2026, 4, 1),
    paidCount: paidCount,
  );
}

void main() {
  const engine = FinancialEngine();
  final period = _period();

  // ── Income ──────────────────────────────────────────────────────────────────

  group('FinancialEngine — income', () {
    test('sums NET_SALARY as cashIncome', () {
      final snap = engine.buildSnapshot(
        period: period,
        incomes: [_salary(5000)],
        expenses: [],
        netSalaryOverride: 0,
        swileOverride: 0,
        emergencyFund: 0,
        activePlans: [],
      );
      expect(snap.cashIncome.amount, 5000);
      expect(snap.swileIncome.amount, 0);
      expect(snap.totalIncome.amount, 5000);
    });

    test('sums SWILE_MEAL and SWILE_FOOD into swileIncome', () {
      final snap = engine.buildSnapshot(
        period: period,
        incomes: [_swile(400, type: 'SWILE_MEAL'), _swile(200, type: 'SWILE_FOOD')],
        expenses: [],
        netSalaryOverride: 0,
        swileOverride: 0,
        emergencyFund: 0,
        activePlans: [],
      );
      expect(snap.swileIncome.amount, 600);
    });

    test('netSalaryOverride wins over income rows', () {
      final snap = engine.buildSnapshot(
        period: period,
        incomes: [_salary(3000)],
        expenses: [],
        netSalaryOverride: 6000,
        swileOverride: 0,
        emergencyFund: 0,
        activePlans: [],
      );
      expect(snap.cashIncome.amount, 6000);
    });

    test('netSalaryOverride=0 falls through to income rows', () {
      final snap = engine.buildSnapshot(
        period: period,
        incomes: [_salary(4500)],
        expenses: [],
        netSalaryOverride: 0,
        swileOverride: 0,
        emergencyFund: 0,
        activePlans: [],
      );
      expect(snap.cashIncome.amount, 4500);
    });

    test('swileOverride wins over income rows', () {
      final snap = engine.buildSnapshot(
        period: period,
        incomes: [_swile(300)],
        expenses: [],
        netSalaryOverride: 0,
        swileOverride: 800,
        emergencyFund: 0,
        activePlans: [],
      );
      expect(snap.swileIncome.amount, 800);
    });
  });

  // ── Expenses ────────────────────────────────────────────────────────────────

  group('FinancialEngine — expenses', () {
    test('cashSpent sums Cash payType expenses', () {
      final snap = engine.buildSnapshot(
        period: period,
        incomes: [],
        expenses: [_cash(200), _cash(300)],
        netSalaryOverride: 0,
        swileOverride: 0,
        emergencyFund: 0,
        activePlans: [],
      );
      expect(snap.cashSpent.amount, 500);
    });

    test('swileSpent sums Swile payType expenses', () {
      final snap = engine.buildSnapshot(
        period: period,
        incomes: [],
        expenses: [_swileExpense(150)],
        netSalaryOverride: 0,
        swileOverride: 0,
        emergencyFund: 0,
        activePlans: [],
      );
      expect(snap.swileSpent.amount, 150);
      expect(snap.cashSpent.amount, 0);
    });

    test('projected expenses are excluded from cashSpent', () {
      final snap = engine.buildSnapshot(
        period: period,
        incomes: [],
        expenses: [_cash(200), _cash(500, projected: true)],
        netSalaryOverride: 0,
        swileOverride: 0,
        emergencyFund: 0,
        activePlans: [],
      );
      expect(snap.cashSpent.amount, 200);
    });

    test('totalSpent = cashSpent + swileSpent', () {
      final snap = engine.buildSnapshot(
        period: period,
        incomes: [],
        expenses: [_cash(300), _swileExpense(100)],
        netSalaryOverride: 0,
        swileOverride: 0,
        emergencyFund: 0,
        activePlans: [],
      );
      expect(snap.totalSpent.amount, 400);
    });
  });

  // ── Balance ─────────────────────────────────────────────────────────────────

  group('FinancialEngine — balance', () {
    test('currentBalance = cashIncome - cashSpent', () {
      final snap = engine.buildSnapshot(
        period: period,
        incomes: [_salary(5000)],
        expenses: [_cash(1500)],
        netSalaryOverride: 0,
        swileOverride: 0,
        emergencyFund: 0,
        activePlans: [],
      );
      expect(snap.currentBalance.amount, 3500);
    });

    test('currentBalance can be negative (overspent)', () {
      final snap = engine.buildSnapshot(
        period: period,
        incomes: [_salary(1000)],
        expenses: [_cash(1800)],
        netSalaryOverride: 0,
        swileOverride: 0,
        emergencyFund: 0,
        activePlans: [],
      );
      expect(snap.currentBalance.amount, -800);
    });

    test('swileBalance = swileIncome - swileSpent', () {
      final snap = engine.buildSnapshot(
        period: period,
        incomes: [_swile(500)],
        expenses: [_swileExpense(200)],
        netSalaryOverride: 0,
        swileOverride: 0,
        emergencyFund: 0,
        activePlans: [],
      );
      expect(snap.swileBalance.amount, 300);
    });
  });

  // ── Savings rate ─────────────────────────────────────────────────────────────

  group('FinancialEngine — savingsRate', () {
    test('savingsRate = (income - cashSpent) / income * 100', () {
      final snap = engine.buildSnapshot(
        period: period,
        incomes: [_salary(5000)],
        expenses: [_cash(3000)],
        netSalaryOverride: 0,
        swileOverride: 0,
        emergencyFund: 0,
        activePlans: [],
      );
      expect(snap.savingsRate, closeTo(40.0, 0.01));
    });

    test('savingsRate is 0 when income is zero', () {
      final snap = engine.buildSnapshot(
        period: period,
        incomes: [],
        expenses: [_cash(100)],
        netSalaryOverride: 0,
        swileOverride: 0,
        emergencyFund: 0,
        activePlans: [],
      );
      expect(snap.savingsRate, 0.0);
    });

    test('savingsRate is clamped to 0 when overspent', () {
      final snap = engine.buildSnapshot(
        period: period,
        incomes: [_salary(1000)],
        expenses: [_cash(2000)],
        netSalaryOverride: 0,
        swileOverride: 0,
        emergencyFund: 0,
        activePlans: [],
      );
      expect(snap.savingsRate, 0.0);
    });
  });

  // ── Upcoming payments ────────────────────────────────────────────────────────

  group('FinancialEngine — upcomingPayments', () {
    test('produces ScheduledPayment for next unpaid installment', () {
      final plan = _plan(installmentAmount: 300, numInstallments: 3, paidCount: 1);
      final snap = engine.buildSnapshot(
        period: period,
        incomes: [],
        expenses: [],
        netSalaryOverride: 0,
        swileOverride: 0,
        emergencyFund: 0,
        activePlans: [plan],
      );
      expect(snap.upcomingPayments.length, 1);
      expect(snap.upcomingPayments.first.amount.amount, 300);
    });

    test('no upcoming payment when all installments are paid', () {
      final plan = _plan(installmentAmount: 300, numInstallments: 3, paidCount: 3);
      final snap = engine.buildSnapshot(
        period: period,
        incomes: [],
        expenses: [],
        netSalaryOverride: 0,
        swileOverride: 0,
        emergencyFund: 0,
        activePlans: [plan],
      );
      expect(snap.upcomingPayments, isEmpty);
    });

    test('totalFutureObligations sums upcoming payment amounts', () {
      final plan1 = _plan(installmentAmount: 200, numInstallments: 3, paidCount: 0);
      final plan2 = _plan(installmentAmount: 300, numInstallments: 2, paidCount: 0);
      final snap = engine.buildSnapshot(
        period: period,
        incomes: [],
        expenses: [],
        netSalaryOverride: 0,
        swileOverride: 0,
        emergencyFund: 0,
        activePlans: [plan1, plan2],
      );
      expect(snap.totalFutureObligations.amount, closeTo(500, 0.01));
    });
  });

  // ── Health score ─────────────────────────────────────────────────────────────

  group('FinancialEngine — healthScore', () {
    test('healthy finances produce score >= 7', () {
      final snap = engine.buildSnapshot(
        period: period,
        incomes: [_salary(6000)],
        expenses: [_cash(2000)],
        netSalaryOverride: 0,
        swileOverride: 0,
        emergencyFund: 18000, // 3 months reserve
        activePlans: [],
      );
      expect(snap.healthScore, greaterThanOrEqualTo(7));
    });

    test('zero income yields low health score', () {
      final snap = engine.buildSnapshot(
        period: period,
        incomes: [],
        expenses: [_cash(2000)],
        netSalaryOverride: 0,
        swileOverride: 0,
        emergencyFund: 0,
        activePlans: [],
      );
      expect(snap.healthScore, lessThan(7));
    });
  });
}
