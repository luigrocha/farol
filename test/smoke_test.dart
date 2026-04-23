import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:farol/core/database/app_database.dart';
import 'package:farol/core/services/financial_calculator_service.dart';
import 'package:drift/drift.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('Database & Logic Smoke Test', () async {
    // 1. Insert a mock income
    await db.insertIncome(IncomesCompanion.insert(
      month: 4,
      year: 2025,
      incomeType: 'NET_SALARY',
      amount: 10000.0,
      isNet: const Value(true),
    ));

    // 2. Insert a mock expense
    await db.insertExpense(ExpensesCompanion.insert(
      month: 4,
      year: 2025,
      payType: 'Cash',
      category: 'LEISURE',
      amount: 2000.0,
      paymentMethod: 'Pix',
    ));

    // 3. Verify data
    final incomes = await db.getIncomesByMonth(4, 2025);
    final expenses = await db.getExpensesByMonth(4, 2025);

    expect(incomes.length, 1);
    expect(expenses.length, 1);
    expect(incomes.first.amount, 10000.0);

    // 4. Test Calculator logic (Static methods)
    final savingsRate = FinancialCalculatorService.calculateSavingsRate(10000, 2000);
    expect(savingsRate, 80.0); // (10000 - 2000) / 10000 * 100

    final healthScore = FinancialCalculatorService.calculateHealthScore(
      netSalary: 10000,
      cashExpenses: 2000,
      housingExpenses: 3000,
      monthlyBalance: 5000,
      emergencyFund: 30000,
      avgMonthlyExpenses: 5000,
      activeInstallmentsTotal: 1000,
    );

    expect(healthScore, greaterThanOrEqualTo(7));
  });
}
