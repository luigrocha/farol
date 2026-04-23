import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Drift kept only for device-local UserSettings (isFirstLaunch, etc.)
import '../database/app_database.dart' show AppDatabase;
import '../models/income.dart';
import '../models/expense.dart';
import '../models/card_installment.dart';
import '../models/investment.dart';
import '../models/net_worth_snapshot.dart';
import '../models/budget_goal.dart';
import '../repositories/income_repository.dart';
import '../repositories/expense_repository.dart';
import '../repositories/installment_repository.dart';
import '../repositories/investment_repository.dart';
import '../repositories/net_worth_repository.dart';
import '../repositories/budget_goals_repository.dart';
import '../repositories/user_preferences_repository.dart';
import '../../features/budget/data/budget_settings_repository.dart';
import '../../features/budget/domain/budget_settings.dart';

// ═══════════════════════════════════════════
// LOCAL-DEVICE PROVIDERS (Drift)
// ═══════════════════════════════════════════

/// Local SQLite – used ONLY for device-specific settings (isFirstLaunch).
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final isFirstLaunchProvider = FutureProvider<bool>((ref) async {
  final db = ref.watch(databaseProvider);
  final value = await db.getSetting('has_completed_onboarding');
  return value == null || value != 'true';
});

final userSettingsProvider = FutureProvider<Map<String, String>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.getAllSettings();
});

// ═══════════════════════════════════════════
// APP STATE PROVIDERS
// ═══════════════════════════════════════════

final selectedMonthProvider = StateProvider<int>((ref) => DateTime.now().month);
final selectedYearProvider = StateProvider<int>((ref) => DateTime.now().year);
final searchQueryProvider = StateProvider<String>((ref) => '');

final userPreferencesRepositoryProvider =
    Provider<UserPreferencesRepository>((ref) {
  return UserPreferencesRepository(Supabase.instance.client);
});

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    Future.microtask(() async {
      final db = ref.read(databaseProvider);
      final remote = await ref.read(userPreferencesRepositoryProvider).fetch();
      if (remote.locale != null) {
        state = Locale(remote.locale!);
        await db.setSetting('locale', remote.locale!);
        return;
      }
      final local = await db.getSetting('locale');
      if (local != null) state = Locale(local);
    });
    return const Locale('es');
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await Future.wait([
      ref.read(databaseProvider).setSetting('locale', locale.languageCode),
      ref.read(userPreferencesRepositoryProvider).setLocale(locale.languageCode),
    ]);
  }
}

// ═══════════════════════════════════════════
// REPOSITORY PROVIDERS
// ═══════════════════════════════════════════

final incomeRepositoryProvider = Provider<IncomeRepository>((ref) {
  return IncomeRepository(Supabase.instance.client);
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(Supabase.instance.client);
});

final installmentRepositoryProvider = Provider<InstallmentRepository>((ref) {
  return InstallmentRepository(Supabase.instance.client);
});

final investmentRepositoryProvider = Provider<InvestmentRepository>((ref) {
  return InvestmentRepository(Supabase.instance.client);
});

final netWorthRepositoryProvider = Provider<NetWorthRepository>((ref) {
  return NetWorthRepository(Supabase.instance.client);
});

final budgetGoalsRepositoryProvider = Provider<BudgetGoalsRepository>((ref) {
  return BudgetGoalsRepository(Supabase.instance.client);
});

// ═══════════════════════════════════════════
// RAW SUPABASE STREAM PROVIDERS
// One stream per table – stable, not tied to month/year.
// Derived providers filter from these to avoid extra WebSocket churn.
// ═══════════════════════════════════════════

final _allIncomesStreamProvider = StreamProvider.autoDispose<List<Income>>((ref) {
  return ref.watch(incomeRepositoryProvider).watchAll();
});

final _allExpensesStreamProvider = StreamProvider.autoDispose<List<Expense>>((ref) {
  return ref.watch(expenseRepositoryProvider).watchAll();
});

// ═══════════════════════════════════════════
// INCOME PROVIDERS
// ═══════════════════════════════════════════

/// Incomes filtered to the currently selected month/year.
final incomesProvider = Provider.autoDispose<AsyncValue<List<Income>>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  final year = ref.watch(selectedYearProvider);
  return ref.watch(_allIncomesStreamProvider).whenData(
    (all) => all.where((i) => i.month == month && i.year == year).toList(),
  );
});

final totalNetSalaryProvider = Provider.autoDispose<double>((ref) {
  final incomes = ref.watch(incomesProvider).value ?? [];
  return incomes
      .where((i) => i.incomeType == 'NET_SALARY')
      .fold(0.0, (sum, i) => sum + i.amount);
});

final totalSwileProvider = Provider.autoDispose<double>((ref) {
  final incomes = ref.watch(incomesProvider).value ?? [];
  return incomes
      .where((i) => i.incomeType == 'SWILE_MEAL' || i.incomeType == 'SWILE_FOOD')
      .fold(0.0, (sum, i) => sum + i.amount);
});

final totalIncomeProvider = Provider.autoDispose<double>((ref) {
  final incomes = ref.watch(incomesProvider).value ?? [];
  return incomes.fold(0.0, (sum, i) => sum + i.amount);
});

// ═══════════════════════════════════════════
// EXPENSE PROVIDERS
// ═══════════════════════════════════════════

/// Expenses filtered to the currently selected month/year.
final expensesProvider = Provider.autoDispose<AsyncValue<List<Expense>>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  final year = ref.watch(selectedYearProvider);
  return ref.watch(_allExpensesStreamProvider).whenData(
    (all) => all.where((e) => e.month == month && e.year == year).toList(),
  );
});

final totalExpensesProvider = Provider.autoDispose<double>((ref) {
  final expenses = ref.watch(expensesProvider).value ?? [];
  return expenses.fold(0.0, (sum, e) => sum + e.amount);
});

final cashExpensesProvider = Provider.autoDispose<double>((ref) {
  final expenses = ref.watch(expensesProvider).value ?? [];
  return expenses
      .where((e) => e.payType == 'Cash')
      .fold(0.0, (sum, e) => sum + e.amount);
});

final swileExpensesProvider = Provider.autoDispose<double>((ref) {
  final expenses = ref.watch(expensesProvider).value ?? [];
  return expenses
      .where((e) => e.payType == 'Swile')
      .fold(0.0, (sum, e) => sum + e.amount);
});

final expensesByCategoryProvider = Provider.autoDispose<Map<String, double>>((ref) {
  final expenses = ref.watch(expensesProvider).value ?? [];
  final map = <String, double>{};
  for (final e in expenses) {
    map[e.category] = (map[e.category] ?? 0) + e.amount;
  }
  return map;
});

final cashExpensesByCategoryProvider = Provider.autoDispose<Map<String, double>>((ref) {
  final expenses = ref.watch(expensesProvider).value ?? [];
  final map = <String, double>{};
  for (final e in expenses.where((e) => e.payType == 'Cash')) {
    map[e.category] = (map[e.category] ?? 0) + e.amount;
  }
  return map;
});

final filteredExpensesProvider = Provider.autoDispose<List<Expense>>((ref) {
  final expenses = ref.watch(expensesProvider).value ?? [];
  final query = ref.watch(searchQueryProvider).toLowerCase();
  if (query.isEmpty) return expenses;
  return expenses.where((e) {
    return (e.storeDescription?.toLowerCase().contains(query) ?? false) ||
        (e.subcategory?.toLowerCase().contains(query) ?? false) ||
        e.category.toLowerCase().contains(query);
  }).toList();
});

// ═══════════════════════════════════════════
// BALANCE PROVIDERS
// ═══════════════════════════════════════════

final monthlyBalanceProvider = Provider.autoDispose<double>((ref) {
  final netSalary = ref.watch(totalNetSalaryProvider);
  final cashExpenses = ref.watch(cashExpensesProvider);
  return netSalary - cashExpenses;
});

final savingsRateProvider = Provider.autoDispose<double>((ref) {
  final netSalary = ref.watch(totalNetSalaryProvider);
  final cashExpenses = ref.watch(cashExpensesProvider);
  if (netSalary <= 0) return 0.0;
  return ((netSalary - cashExpenses) / netSalary) * 100;
});

// ═══════════════════════════════════════════
// INSTALLMENTS PROVIDERS
// ═══════════════════════════════════════════

final installmentsProvider = StreamProvider.autoDispose<List<CardInstallment>>((ref) {
  return ref.watch(installmentRepositoryProvider).watchActive();
});

// ═══════════════════════════════════════════
// INVESTMENTS PROVIDERS
// ═══════════════════════════════════════════

final investmentsProvider = StreamProvider.autoDispose<List<Investment>>((ref) {
  return ref.watch(investmentRepositoryProvider).watchAll();
});

final totalInvestedProvider = Provider.autoDispose<double>((ref) {
  final investments = ref.watch(investmentsProvider).value ?? [];
  return investments.fold(0.0, (sum, i) => sum + i.totalInvested);
});

final totalInvestmentBalanceProvider = Provider.autoDispose<double>((ref) {
  final investments = ref.watch(investmentsProvider).value ?? [];
  return investments.fold(0.0, (sum, i) => sum + i.currentBalance);
});

final totalInvestmentReturnProvider = Provider.autoDispose<double>((ref) {
  final invested = ref.watch(totalInvestedProvider);
  final balance = ref.watch(totalInvestmentBalanceProvider);
  if (invested <= 0) return 0.0;
  return ((balance - invested) / invested) * 100;
});

// ═══════════════════════════════════════════
// BUDGET GOALS PROVIDERS
// ═══════════════════════════════════════════

final budgetGoalsProvider = StreamProvider.autoDispose<List<BudgetGoal>>((ref) {
  return ref.watch(budgetGoalsRepositoryProvider).watchAll();
});

final budgetGoalsMapProvider = Provider.autoDispose<Map<String, BudgetGoal>>((ref) {
  final goals = ref.watch(budgetGoalsProvider).value ?? [];
  return {for (var g in goals) g.category: g};
});

// ═══════════════════════════════════════════
// NET WORTH PROVIDER
// ═══════════════════════════════════════════

final netWorthSnapshotProvider = FutureProvider.autoDispose<NetWorthSnapshot?>((ref) {
  final month = ref.watch(selectedMonthProvider);
  final year = ref.watch(selectedYearProvider);
  return ref.watch(netWorthRepositoryProvider).getByMonth(month, year);
});

// ═══════════════════════════════════════════
// BUDGET SETTINGS PROVIDERS
// ═══════════════════════════════════════════

final budgetSettingsRepositoryProvider = Provider<BudgetSettingsRepository>((ref) {
  return BudgetSettingsRepository(Supabase.instance.client);
});

final budgetSettingsProvider =
    AsyncNotifierProvider<BudgetSettingsNotifier, BudgetSettings?>(() {
  return BudgetSettingsNotifier();
});

class BudgetSettingsNotifier extends AsyncNotifier<BudgetSettings?> {
  @override
  Future<BudgetSettings?> build() =>
      ref.read(budgetSettingsRepositoryProvider).fetch();

  Future<void> save(BudgetSettings settings) async {
    await ref.read(budgetSettingsRepositoryProvider).save(settings);
    state = AsyncData(settings);
  }
}

/// Net salary: uses budget if configured, falls back to actual income records.
final effectiveNetSalaryProvider = Provider.autoDispose<double>((ref) {
  final budget = ref.watch(budgetSettingsProvider).value;
  if (budget != null && budget.netSalary > 0) return budget.netSalary;
  return ref.watch(totalNetSalaryProvider);
});

/// Swile total: uses budget if configured, falls back to actual income records.
final effectiveSwileProvider = Provider.autoDispose<double>((ref) {
  final budget = ref.watch(budgetSettingsProvider).value;
  if (budget != null && budget.swileTotal > 0) return budget.swileTotal;
  return ref.watch(totalSwileProvider);
});

/// Remaining cash: budget net salary minus actual cash expenses.
final cashRemainingProvider = Provider.autoDispose<double>((ref) {
  return ref.watch(effectiveNetSalaryProvider) - ref.watch(cashExpensesProvider);
});

/// Remaining Swile: budget swile minus actual swile expenses.
final swileRemainingProvider = Provider.autoDispose<double>((ref) {
  return ref.watch(effectiveSwileProvider) - ref.watch(swileExpensesProvider);
});

/// Savings rate computed against the effective (budget-aware) net salary.
final effectiveSavingsRateProvider = Provider.autoDispose<double>((ref) {
  final net = ref.watch(effectiveNetSalaryProvider);
  final cash = ref.watch(cashExpensesProvider);
  if (net <= 0) return 0.0;
  return ((net - cash) / net) * 100;
});

// ═══════════════════════════════════════════
// ANALYTICS RANGE PROVIDERS
// ═══════════════════════════════════════════

enum AnalyticsRange { threeMonths, sixMonths, twelveMonths, custom }

final analyticsRangeProvider =
    StateProvider<AnalyticsRange>((ref) => AnalyticsRange.threeMonths);

final analyticsExpensesProvider =
    FutureProvider.autoDispose<List<Expense>>((ref) async {
  final repo = ref.watch(expenseRepositoryProvider);
  final range = ref.watch(analyticsRangeProvider);
  final now = DateTime.now();
  final months = switch (range) {
    AnalyticsRange.threeMonths => 3,
    AnalyticsRange.sixMonths => 6,
    AnalyticsRange.twelveMonths => 12,
    AnalyticsRange.custom => 12,
  };
  final start = DateTime(now.year, now.month - months + 1, 1);
  return repo.getByRange(start.month, start.year, now.month, now.year);
});

final analyticsIncomesProvider =
    FutureProvider.autoDispose<List<Income>>((ref) async {
  final repo = ref.watch(incomeRepositoryProvider);
  final range = ref.watch(analyticsRangeProvider);
  final now = DateTime.now();
  final months = switch (range) {
    AnalyticsRange.threeMonths => 3,
    AnalyticsRange.sixMonths => 6,
    AnalyticsRange.twelveMonths => 12,
    AnalyticsRange.custom => 12,
  };
  final start = DateTime(now.year, now.month - months + 1, 1);
  return repo.getByRange(start.month, start.year, now.month, now.year);
});
