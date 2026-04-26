import 'package:drift/drift.dart';
import 'app_database.dart';
import '../models/constants.dart';

/// Seeds the database with initial data on first launch.
class SeedData {
  final AppDatabase db;

  SeedData(this.db);

  /// Check if this is the first launch and seed if needed.
  Future<void> seedIfNeeded() async {
    final seeded = await db.getSetting('data_seeded');
    if (seeded == 'true') return;

    await _seedIncome();
    await _seedExpenses();
    await _seedCardInstallments();
    await _seedNetWorthSnapshot();
    await _seedBudgetGoals();
    await _seedUserSettings();

    await db.setSetting('data_seeded', 'true');
  }

  Future<void> _seedIncome() async {
    // April 2025 Income
    await db.insertIncome(const IncomesCompanion(
      month: Value(4),
      year: Value(2025),
      incomeType: Value('NET_SALARY'),
      amount: Value(9651.91),
      isNet: Value(true),
      notes: Value('CLT net salary'),
    ));

    await db.insertIncome(const IncomesCompanion(
      month: Value(4),
      year: Value(2025),
      incomeType: Value('SWILE_MEAL'),
      amount: Value(1400.00),
      isNet: Value(true),
      notes: Value('Swile Meal'),
    ));

    await db.insertIncome(const IncomesCompanion(
      month: Value(4),
      year: Value(2025),
      incomeType: Value('SWILE_FOOD'),
      amount: Value(1031.00),
      isNet: Value(true),
      notes: Value('Swile Food'),
    ));
  }

  Future<void> _seedExpenses() async {
    final seedExpenses = [
      // HOUSING
      _expenseData('Cash', 'HOUSING', 'Rent', 3000.00, 'PIX', true),
      _expenseData('Cash', 'HOUSING', 'Condo Fee', 1100.00, 'DEBIT', true),
      _expenseData('Cash', 'HOUSING', 'Electricity', 500.00, 'DEBIT', false),
      _expenseData('Cash', 'HOUSING', 'Internet', 107.00, 'DEBIT', true),
      // TRANSPORT
      _expenseData('Cash', 'TRANSPORT', 'UberEats', 177.80, 'CREDIT_FULL', false),
      _expenseData('Cash', 'TRANSPORT', 'Subway/Bus', 130.00, 'DEBIT', true),
      // SUBSCRIPTIONS
      _expenseData('Cash', 'SUBSCRIPTIONS', 'Apps', 220.77, 'CREDIT_FULL', true),
      _expenseData('Cash', 'SUBSCRIPTIONS', 'Gym', 150.00, 'DEBIT', true),
      _expenseData('Cash', 'SUBSCRIPTIONS', 'Claude AI', 110.00, 'CREDIT_FULL', true),
      _expenseData('Cash', 'SUBSCRIPTIONS', 'Mobile Phone', 151.90, 'DEBIT', true),
      // FOOD (Swile)
      _expenseData('Swile', 'FOOD_GROCERY', 'Supermarket', 1400.00, 'SWILE_MEAL', true),
      _expenseData('Swile', 'FOOD_GROCERY', 'Supermarket', 1031.00, 'SWILE_FOOD', true),
      // CARD_INSTALLMENTS
      _expenseData('Cash', 'CARD_INSTALLMENTS', 'Spouse Surgery (1/12)', 754.97,
          'CREDIT_INSTALLMENT', true),
      _expenseData('Cash', 'CARD_INSTALLMENTS', 'Spouse Surgery (2/12)', 754.97,
          'CREDIT_INSTALLMENT', true),
    ];

    for (final expense in seedExpenses) {
      await db.insertExpense(expense);
    }
  }

  ExpensesCompanion _expenseData(String payType, String category,
      String subcategory, double amount, String paymentMethod, bool isFixed) {
    return ExpensesCompanion(
      month: const Value(4),
      year: const Value(2025),
      payType: Value(payType),
      category: Value(category),
      subcategory: Value(subcategory),
      amount: Value(amount),
      paymentMethod: Value(paymentMethod),
      isFixed: Value(isFixed),
      storeDescription: Value(subcategory),
    );
  }

  Future<void> _seedCardInstallments() async {
    await db.insertInstallment(CardInstallmentsCompanion(
      description: const Value('Spouse Surgery'),
      purchaseDate: Value(DateTime(2025, 3, 1)),
      totalValue: const Value(9059.64),
      numInstallments: const Value(12),
      currentInstallment: const Value(2), // April = 2nd installment
      monthlyAmount: const Value(754.97),
      status: const Value('Active'),
      notes: const Value('Started in March 2025'),
    ));
  }

  Future<void> _seedNetWorthSnapshot() async {
    await db.insertSnapshot(const NetWorthSnapshotsCompanion(
      month: Value(4),
      year: Value(2025),
      fgtsBalance: Value(19888.00),
      investmentsTotal: Value(0.0),
      emergencyFund: Value(0.0),
      pendingInstallments: Value(7549.70), // 10 remaining × 754.97
    ));
  }

  Future<void> _seedBudgetGoals() async {
    final goals = {
      'HOUSING': [30.0, 'Need'],
      'TRANSPORT': [5.0, 'Need'],
      'FOOD_GROCERY': [0.0, 'Need'], // Covered by Swile
      'HEALTH': [3.0, 'Need'],
      'SUBSCRIPTIONS': [4.0, 'Want'],
      'LEISURE': [6.0, 'Want'],
      'EDUCATION': [2.0, 'Want'],
      'CARD_INSTALLMENTS': [26.0, 'Need'],
      'SAVINGS': [20.0, 'Invest'],
      'OTHER': [4.0, 'Want'],
    };

    for (final entry in goals.entries) {
      final pct = entry.value[0] as double;
      await db.insertBudgetGoal(BudgetGoalsCompanion(
        category: Value(entry.key),
        targetPercentage: Value(pct),
        targetAmount: Value(AppConstants.defaultNetSalary * pct / 100),
        type: Value(entry.value[1] as String),
      ));
    }
  }

  Future<void> _seedUserSettings() async {
    await db.setSetting('user_name', 'User');
    await db.setSetting('gross_salary', '${AppConstants.defaultGrossSalary}');
    await db.setSetting('net_salary', '${AppConstants.defaultNetSalary}');
    await db.setSetting('swile_meal', '${AppConstants.defaultSwileMeal}');
    await db.setSetting('swile_food', '${AppConstants.defaultSwileFood}');
    await db.setSetting('theme_mode', 'system');
  }
}
