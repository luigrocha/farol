import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Drift kept only for device-local UserSettings (isFirstLaunch, etc.)
import '../database/app_database.dart' show AppDatabase;
import '../models/income.dart';
import '../models/expense.dart';
import '../models/enums.dart';
import '../models/card_installment.dart';
import '../models/investment.dart';
import '../models/net_worth_snapshot.dart';
import '../models/account.dart';
import '../models/account_transfer.dart';
import '../repositories/account_repository.dart';
import '../repositories/account_transfer_repository.dart';
import '../models/budget_goal.dart';
import '../models/financial_period.dart';
import '../models/period_budget.dart';
import '../repositories/income_repository.dart';
import '../repositories/expense_repository.dart';
import '../repositories/installment_repository.dart';
import '../repositories/investment_repository.dart';
import '../repositories/net_worth_repository.dart';
import '../repositories/budget_goals_repository.dart';
import '../repositories/period_budget_repository.dart';
import '../repositories/user_preferences_repository.dart';
import '../repositories/health_repository.dart';
import '../repositories/salary_settings_repository.dart';
import '../services/export_service.dart';
import '../models/health_snapshot.dart';
import '../models/budget_alert.dart';
import '../models/salary_settings.dart';
import '../services/financial_calculator_service.dart';
import '../services/clt_calculator_service.dart';

import '../../features/budget/data/budget_settings_repository.dart';
import '../../features/budget/domain/budget_settings.dart';
import '../models/category.dart';
import '../repositories/category_repository.dart';

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
// 'all' | 'cash' | 'swile' | any ExpenseCategory.dbValue
final txPayTypeFilterProvider = StateProvider<String>((ref) => 'all');
final txCategoryFilterProvider = StateProvider<String?>((ref) => null);

final userPreferencesRepositoryProvider =
    Provider<UserPreferencesRepository>((ref) {
  return UserPreferencesRepository(Supabase.instance.client);
});

// Single fetch shared by locale, theme and privacy — avoids 3 separate Supabase round-trips.
final remotePreferencesProvider = FutureProvider<({String? locale, String? themeMode, bool? privacyMode})>((ref) {
  return ref.read(userPreferencesRepositoryProvider).fetch();
});

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    Future.microtask(() async {
      try {
        final db = ref.read(databaseProvider);
        final local = await db.getSetting('locale');
        if (local != null) state = Locale(local);
        final remote = await ref.read(remotePreferencesProvider.future);
        if (remote.locale != null && remote.locale != local) {
          state = Locale(remote.locale!);
          await db.setSetting('locale', remote.locale!);
        }
      } catch (_) {}
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

final privacyModeProvider = NotifierProvider<PrivacyModeNotifier, bool>(PrivacyModeNotifier.new);

class PrivacyModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    Future.microtask(() async {
      try {
        final db = ref.read(databaseProvider);
        final local = await db.getSetting('privacy_mode');
        if (local != null) state = local == 'true';
        final remote = await ref.read(remotePreferencesProvider.future);
        if (remote.privacyMode != null) {
          state = remote.privacyMode!;
          await db.setSetting('privacy_mode', state.toString());
        }
      } catch (_) {}
    });
    return false;
  }

  Future<void> toggle() async {
    state = !state;
    await Future.wait([
      ref.read(databaseProvider).setSetting('privacy_mode', state.toString()),
      ref.read(userPreferencesRepositoryProvider).setPrivacyMode(state),
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

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(Supabase.instance.client);
});

// ═══════════════════════════════════════════
// HYBRID REALTIME + POLLING PROVIDERS
// Realtime active when screen is foreground,
// polling fallback when background or on error.
// ═══════════════════════════════════════════

final realtimeActiveProvider = StateProvider<bool>((ref) => true);
final realtimeMaxRetriesReachedProvider = StateProvider<bool>((ref) => false);

final _allIncomesStreamProvider = StreamProvider.autoDispose<List<Income>>((ref) {
  final useRealtime = ref.watch(realtimeActiveProvider);
  final repository = ref.watch(incomeRepositoryProvider);
  final maxRetries = ref.watch(realtimeMaxRetriesReachedProvider);

  if (maxRetries) {
    ref.read(realtimeActiveProvider.notifier).state = false;
  }

  final effectiveRealtime = useRealtime && !maxRetries;

  if (effectiveRealtime) {
    return repository.watchRealtime().handleError((error, stackTrace) {
      ref.read(realtimeMaxRetriesReachedProvider.notifier).state = true;
      return <Income>[];
    });
  } else {
    return Stream.periodic(
      const Duration(seconds: 30),
      (_) => repository.fetchAll(),
    ).asyncMap((future) => future);
  }
});

final _allExpensesStreamProvider = StreamProvider.autoDispose<List<Expense>>((ref) {
  final useRealtime = ref.watch(realtimeActiveProvider);
  final repository = ref.watch(expenseRepositoryProvider);
  final maxRetries = ref.watch(realtimeMaxRetriesReachedProvider);

  if (maxRetries) {
    ref.read(realtimeActiveProvider.notifier).state = false;
  }

  final effectiveRealtime = useRealtime && !maxRetries;

  if (effectiveRealtime) {
    return repository.watchRealtime().handleError((error, stackTrace) {
      ref.read(realtimeMaxRetriesReachedProvider.notifier).state = true;
      return <Expense>[];
    });
  } else {
    return Stream.periodic(
      const Duration(seconds: 30),
      (_) => repository.fetchAll(),
    ).asyncMap((future) => future);
  }
});

final categoriesStreamProvider = StreamProvider.autoDispose<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchAll();
});

final categoriesMapProvider = Provider.autoDispose<Map<String, Category>>((ref) {
  final cats = ref.watch(categoriesStreamProvider).value ?? [];
  return {for (var c in cats) c.dbValue: c};
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

// Total for the currently active transaction filter
final filteredTotalProvider = Provider.autoDispose<double>((ref) {
  final filtered = ref.watch(filteredExpensesProvider);
  return filtered.fold(0.0, (sum, e) => sum + e.amount);
});

// Category breakdown for the currently active filter
final filteredByCategoryProvider = Provider.autoDispose<Map<String, double>>((ref) {
  final filtered = ref.watch(filteredExpensesProvider);
  final map = <String, double>{};
  for (final e in filtered) {
    map[e.category] = (map[e.category] ?? 0) + e.amount;
  }
  return map;
});

final swileTransactionsProvider = Provider.autoDispose<AsyncValue<List<Expense>>>((ref) {
  return ref.watch(_allExpensesStreamProvider).whenData(
    (all) {
      final swile = all.where((e) => e.payType == 'Swile').toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return swile;
    },
  );
});

final swileMealBalanceProvider = Provider.autoDispose<double>((ref) {
  final incomes = ref.watch(incomesProvider).value ?? [];
  return incomes
      .where((i) => i.incomeType == 'SWILE_MEAL')
      .fold(0.0, (s, i) => s + i.amount);
});

final swileFoodBalanceProvider = Provider.autoDispose<double>((ref) {
  final incomes = ref.watch(incomesProvider).value ?? [];
  return incomes
      .where((i) => i.incomeType == 'SWILE_FOOD')
      .fold(0.0, (s, i) => s + i.amount);
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
  final payTypeFilter = ref.watch(txPayTypeFilterProvider);
  final categoryFilter = ref.watch(txCategoryFilterProvider);

  return expenses.where((e) {
    // pay-type chip filter
    if (payTypeFilter == 'cash' && e.payType != 'Cash') return false;
    if (payTypeFilter == 'swile' && e.payType != 'Swile') return false;

    // category sub-filter
    if (categoryFilter != null && e.category != categoryFilter) return false;

    // search query
    if (query.isNotEmpty) {
      return (e.storeDescription?.toLowerCase().contains(query) ?? false) ||
          (e.subcategory?.toLowerCase().contains(query) ?? false) ||
          e.category.toLowerCase().contains(query);
    }
    return true;
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

final allInstallmentsProvider = StreamProvider.autoDispose<List<CardInstallment>>((ref) {
  return ref.watch(installmentRepositoryProvider).watchAll();
});

final totalMonthlyInstallmentsProvider = Provider.autoDispose<double>((ref) {
  final list = ref.watch(installmentsProvider).value ?? [];
  return list.fold(0.0, (sum, i) => sum + i.monthlyAmount);
});

final totalRemainingInstallmentsProvider = Provider.autoDispose<double>((ref) {
  final list = ref.watch(installmentsProvider).value ?? [];
  return list.fold(0.0, (sum, i) => sum + i.remainingBalance);
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

/// Sum of targetPercentage for all non-Swile budget goals.
final budgetCashPercentageTotalProvider = Provider.autoDispose<double>((ref) {
  final goals = ref.watch(budgetGoalsProvider).value ?? [];
  return goals
      .where((g) => !swileCategories.contains(g.category))
      .fold(0.0, (sum, g) => sum + g.targetPercentage);
});

/// How many percentage points remain before hitting 100% (clamped to 0).
final budgetPercentageRemainingProvider = Provider.autoDispose<double>((ref) {
  return (100.0 - ref.watch(budgetCashPercentageTotalProvider)).clamp(0.0, 100.0);
});

/// True when the total cash budget percentage exceeds 100%.
final budgetPercentageOverflowProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(budgetCashPercentageTotalProvider) > 100.0;
});

/// Non-Swile categories that contribute to the overflow, sorted by targetPercentage descending.
final overBudgetCategoriesProvider = Provider.autoDispose<List<BudgetGoal>>((ref) {
  final goals = ref.watch(budgetGoalsProvider).value ?? [];
  final cashGoals = goals.where((g) => !swileCategories.contains(g.category)).toList()
    ..sort((a, b) => b.targetPercentage.compareTo(a.targetPercentage));
  return cashGoals;
});

// ═══════════════════════════════════════════
// NET WORTH PROVIDER
// ═══════════════════════════════════════════

final netWorthSnapshotProvider = FutureProvider.autoDispose<NetWorthSnapshot?>((ref) {
  final month = ref.watch(selectedMonthProvider);
  final year = ref.watch(selectedYearProvider);
  return ref.watch(netWorthRepositoryProvider).getByMonth(month, year);
});

enum NetWorthFilter { sixMonths, oneYear, allTime }

final netWorthFilterProvider = StateProvider<NetWorthFilter>((ref) => NetWorthFilter.sixMonths);

final netWorthHistoryProvider = FutureProvider.autoDispose<List<NetWorthSnapshot>>((ref) async {
  final filter = ref.watch(netWorthFilterProvider);
  final repo = ref.watch(netWorthRepositoryProvider);
  final limit = switch (filter) {
    NetWorthFilter.sixMonths => 6,
    NetWorthFilter.oneYear => 12,
    NetWorthFilter.allTime => null,
  };
  return repo.getHistory(limit: limit);
});

// ═══════════════════════════════════════════
// ACCOUNTS REPOSITORY PROVIDERS
// ═══════════════════════════════════════════

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(Supabase.instance.client);
});

final accountTransferRepositoryProvider = Provider<AccountTransferRepository>((ref) {
  return AccountTransferRepository(Supabase.instance.client);
});

// ═══════════════════════════════════════════
// ACCOUNTS PROVIDERS
// ═══════════════════════════════════════════

final _allAccountsStreamProvider = StreamProvider.autoDispose<List<Account>>((ref) {
  return ref.watch(accountRepositoryProvider).watchAll();
});

final accountsProvider = Provider.autoDispose<AsyncValue<List<Account>>>((ref) {
  return ref.watch(_allAccountsStreamProvider).whenData(
    (all) => all.where((a) => a.isActive).toList(),
  );
});

final liquidAccountsProvider = Provider.autoDispose<AsyncValue<List<Account>>>((ref) {
  return ref.watch(_allAccountsStreamProvider).whenData(
    (all) => all.where((a) => a.isActive && a.accountType.isLiquid).toList(),
  );
});

final fgtsAccountProvider = Provider.autoDispose<Account?>((ref) {
  final all = ref.watch(_allAccountsStreamProvider).value ?? [];
  try {
    return all.firstWhere((a) => a.type == AccountType.fgts.dbValue && a.isActive);
  } catch (_) {
    return null;
  }
});

final liquidAccountsTotalProvider = Provider.autoDispose<double>((ref) {
  final accounts = ref.watch(liquidAccountsProvider).value ?? [];
  return accounts.fold(0.0, (sum, a) => sum + a.currentBalance);
});

final fgtsBalanceFromAccountsProvider = Provider.autoDispose<double>((ref) {
  return ref.watch(fgtsAccountProvider)?.currentBalance ?? 0.0;
});

// ═══════════════════════════════════════════
// ACCOUNT TRANSFERS PROVIDERS
// ═══════════════════════════════════════════

final _allTransfersStreamProvider = StreamProvider.autoDispose<List<AccountTransfer>>((ref) {
  return ref.watch(accountTransferRepositoryProvider).watchAll();
});

final periodTransfersProvider = Provider.autoDispose<AsyncValue<List<AccountTransfer>>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  final year = ref.watch(selectedYearProvider);
  return ref.watch(_allTransfersStreamProvider).whenData(
    (all) => all
        .where((t) => t.transferDate.month == month && t.transferDate.year == year)
        .toList(),
  );
});

// ═══════════════════════════════════════════
// ENHANCED NET WORTH PROVIDERS
// ═══════════════════════════════════════════

final enhancedNetWorthProvider = Provider.autoDispose<double>((ref) {
  final liquidTotal = ref.watch(liquidAccountsTotalProvider);
  final fgtsTotal = ref.watch(fgtsBalanceFromAccountsProvider);
  final investmentsTotal = ref.watch(totalInvestmentBalanceProvider);
  final snap = ref.watch(netWorthSnapshotProvider).value;
  final patrimonyTotal = snap?.patrimonyTotal ?? 0.0;
  final pendingInstallments = ref.watch(totalRemainingInstallmentsProvider);
  return liquidTotal + fgtsTotal + investmentsTotal + patrimonyTotal - pendingInstallments;
});

final assetAllocationProvider = Provider.autoDispose<({
  double banks,
  double investments,
  double fgts,
  double patrimony,
})>((ref) {
  return (
    banks: ref.watch(liquidAccountsTotalProvider),
    investments: ref.watch(totalInvestmentBalanceProvider),
    fgts: ref.watch(fgtsBalanceFromAccountsProvider),
    patrimony: ref.watch(netWorthSnapshotProvider).value?.patrimonyTotal ?? 0.0,
  );
});

// ═══════════════════════════════════════════
// ACCOUNT MUTATION NOTIFIERS
// ═══════════════════════════════════════════

final accountNotifierProvider =
    AsyncNotifierProvider<AccountNotifier, void>(AccountNotifier.new);

class AccountNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> insert({
    required String name,
    required String institution,
    required String type,
    double initialBalance = 0,
    String? notes,
  }) async {
    await ref.read(accountRepositoryProvider).insert(
          name: name,
          institution: institution,
          type: type,
          initialBalance: initialBalance,
          notes: notes,
        );
    ref.invalidate(_allAccountsStreamProvider);
  }

  Future<void> updateBalance(int id, double balance) async {
    await ref.read(accountRepositoryProvider).updateBalance(id, balance);
    ref.invalidate(_allAccountsStreamProvider);
  }

  Future<void> updateAccount(int id, {String? name, String? institution, String? notes, bool? isActive}) async {
    await ref.read(accountRepositoryProvider).update(
          id,
          name: name,
          institution: institution,
          notes: notes,
          isActive: isActive,
        );
    ref.invalidate(_allAccountsStreamProvider);
  }

  Future<void> delete(int id) async {
    await ref.read(accountRepositoryProvider).delete(id);
    ref.invalidate(_allAccountsStreamProvider);
  }
}

final transferNotifierProvider =
    AsyncNotifierProvider<TransferNotifier, void>(TransferNotifier.new);

class TransferNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> transfer({
    required int fromAccountId,
    required int toAccountId,
    required double amount,
    required DateTime date,
    String? description,
  }) async {
    await ref.read(accountTransferRepositoryProvider).transfer(
          fromAccountId: fromAccountId,
          toAccountId: toAccountId,
          amount: amount,
          date: date,
          description: description,
        );
    ref.invalidate(_allAccountsStreamProvider);
    ref.invalidate(_allTransfersStreamProvider);
  }
}

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

final budgetGoalsNotifierProvider =
    AsyncNotifierProvider<BudgetGoalsNotifier, void>(() {
  return BudgetGoalsNotifier();
});

class BudgetGoalsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> save(BudgetGoal goal) async {
    await ref.read(budgetGoalsRepositoryProvider).upsert(goal);
    ref.invalidate(budgetGoalsProvider);
  }

  Future<void> rebalance(Map<String, double> categoryToPercentage) async {
    final netSalary = ref.read(effectiveNetSalaryProvider);
    await ref
        .read(budgetGoalsRepositoryProvider)
        .updateAllPercentages(categoryToPercentage, netSalary);
    ref.invalidate(budgetGoalsProvider);
  }
}

final categoryNotifierProvider = AsyncNotifierProvider<CategoryNotifier, void>(() {
  return CategoryNotifier();
});

class CategoryNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Seed categories if empty when the provider is initialized
    await ref.read(categoryRepositoryProvider).seedInitialCategories();
  }

  Future<void> add(Category category) async {
    await ref.read(categoryRepositoryProvider).insert(category);
    ref.invalidate(categoriesStreamProvider);
  }

  Future<void> save(Category category) async {
    await ref.read(categoryRepositoryProvider).update(category);
    ref.invalidate(categoriesStreamProvider);
  }

  Future<void> delete(int id) async {
    await ref.read(categoryRepositoryProvider).delete(id);
    ref.invalidate(categoriesStreamProvider);
  }

  Future<void> reorder(List<Category> categories) async {
    await ref.read(categoryRepositoryProvider).reorder(categories);
    ref.invalidate(categoriesStreamProvider);
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

final netWorthNotifierProvider =
    AsyncNotifierProvider<NetWorthNotifier, void>(NetWorthNotifier.new);

class NetWorthNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> save({
    required int month,
    required int year,
    double patrimonyTotal = 0,
    double fgtsBalance = 0,
    double investmentsTotal = 0,
    double emergencyFund = 0,
  }) async {
    await ref.read(netWorthRepositoryProvider).upsert(
      month: month,
      year: year,
      patrimonyTotal: patrimonyTotal,
      fgtsBalance: fgtsBalance,
      investmentsTotal: investmentsTotal,
      emergencyFund: emergencyFund,
    );
    ref.invalidate(netWorthSnapshotProvider);
  }
}

// ═══════════════════════════════════════════
// EXPORT SERVICE PROVIDER
// ═══════════════════════════════════════════

final exportServiceProvider = Provider<ExportService>((ref) => ExportService(
      expenseRepo: ref.watch(expenseRepositoryProvider),
      incomeRepo: ref.watch(incomeRepositoryProvider),
      installmentRepo: ref.watch(installmentRepositoryProvider),
      investmentRepo: ref.watch(investmentRepositoryProvider),
      netWorthRepo: ref.watch(netWorthRepositoryProvider),
      budgetGoalsRepo: ref.watch(budgetGoalsRepositoryProvider),
      categoryRepo: ref.watch(categoryRepositoryProvider),
    ));

// ═══════════════════════════════════════════
// HEALTH PROVIDERS
// ═══════════════════════════════════════════

final healthRepositoryProvider = Provider<HealthRepository>((ref) =>
    HealthRepository(Supabase.instance.client));

final healthHistoryProvider =
    FutureProvider.autoDispose<List<HealthSnapshot>>((ref) =>
        ref.watch(healthRepositoryProvider).fetchHistory());

final healthAutoSaveProvider =
    AsyncNotifierProvider.autoDispose<HealthAutoSaveNotifier, void>(
        HealthAutoSaveNotifier.new);

class HealthAutoSaveNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {
    // React only to the triggers that signal "data is ready"; read everything
    // else with ref.read inside _save() to avoid cascading rebuilds.
    ref.listen(selectedMonthProvider, (_, __) => _save());
    ref.listen(selectedYearProvider, (_, __) => _save());
    ref.listen(cashExpensesProvider, (_, next) {
      if (next > 0) _save();
    });
  }

  Future<void> _save() async {
    final month = ref.read(selectedMonthProvider);
    final year = ref.read(selectedYearProvider);
    final net = ref.read(effectiveNetSalaryProvider);
    if (net <= 0) return;
    final cash = ref.read(cashExpensesProvider);
    if (cash <= 0) return;
    final byCategory = ref.read(cashExpensesByCategoryProvider);
    final balance = ref.read(cashRemainingProvider);
    final snap = ref.read(netWorthSnapshotProvider).value;
    final inst = ref.read(installmentsProvider).value ?? [];
    final housing = byCategory['HOUSING'] ?? 0;
    final instTotal = inst.fold(0.0, (s, i) => s + i.monthlyAmount);
    final accountsExist = ref.read(accountsProvider).value?.isNotEmpty ?? false;
    final ef = accountsExist
        ? ref.read(liquidAccountsTotalProvider)
        : (snap?.emergencyFund ?? 0);
    final efMonths = cash > 0 ? ef / cash : 0.0;
    final score = FinancialCalculatorService.calculateHealthScore(
      netSalary: net,
      cashExpenses: cash,
      housingExpenses: housing,
      monthlyBalance: balance,
      emergencyFund: ef,
      avgMonthlyExpenses: cash,
      activeInstallmentsTotal: instTotal,
    );
    try {
      await ref.read(healthRepositoryProvider).upsert(
        month: month,
        year: year,
        score: score,
        savingsRate: (net - cash) / net * 100,
        housingRate: housing / net * 100,
        monthlyBalance: balance,
        emergencyFundMonths: efMonths,
        installmentsRate: instTotal / net * 100,
        netSalary: net,
      );
    } catch (_) {}
  }
}

// ═══════════════════════════════════════════
// FIXED EXPENSE AUTO-PROPAGATION
// ═══════════════════════════════════════════

final fixedExpensePropagationProvider =
    AsyncNotifierProvider.autoDispose<FixedExpensePropagationNotifier, int>(
        FixedExpensePropagationNotifier.new);

class FixedExpensePropagationNotifier extends AutoDisposeAsyncNotifier<int> {
  @override
  Future<int> build() async {
    final month = ref.watch(selectedMonthProvider);
    final year = ref.watch(selectedYearProvider);
    return ref.read(expenseRepositoryProvider).propagateFixedExpenses(month, year);
  }
}

// ═══════════════════════════════════════════
// INCOME MUTATION NOTIFIER
// ═══════════════════════════════════════════

final incomeNotifierProvider =
    AsyncNotifierProvider<IncomeNotifier, void>(IncomeNotifier.new);

class IncomeNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> insert({
    required int month,
    required int year,
    required String incomeType,
    required double amount,
    bool isNet = true,
    double? inssDeducted,
    double? irrfDeducted,
    String? notes,
  }) async {
    await ref.read(incomeRepositoryProvider).insert(
          month: month,
          year: year,
          incomeType: incomeType,
          amount: amount,
          isNet: isNet,
          inssDeducted: inssDeducted,
          irrfDeducted: irrfDeducted,
          notes: notes,
        );
    ref.invalidate(_allIncomesStreamProvider);
  }

  Future<void> delete(int id) async {
    await ref.read(incomeRepositoryProvider).delete(id);
    ref.invalidate(_allIncomesStreamProvider);
  }

  Future<void> save({
    required int id,
    required int month,
    required int year,
    required String incomeType,
    required double amount,
    bool isNet = true,
    double? inssDeducted,
    double? irrfDeducted,
    String? notes,
  }) async {
    await ref.read(incomeRepositoryProvider).update(
          id: id,
          month: month,
          year: year,
          incomeType: incomeType,
          amount: amount,
          isNet: isNet,
          inssDeducted: inssDeducted,
          irrfDeducted: irrfDeducted,
          notes: notes,
        );
    ref.invalidate(_allIncomesStreamProvider);
  }
}

// ═══════════════════════════════════════════
// PERIOD BUDGET PROVIDERS
// ═══════════════════════════════════════════

final periodBudgetRepositoryProvider = Provider<PeriodBudgetRepository>((ref) {
  return PeriodBudgetRepository(Supabase.instance.client);
});

/// The current financial period derived from the user's cutoff_day setting.
final currentPeriodProvider = Provider<FinancialPeriod>((ref) {
  final settings = ref.watch(budgetSettingsProvider).value;
  return FinancialPeriod.current(settings?.cutoffDay ?? 1);
});

class _SelectedPeriodNotifier extends StateNotifier<FinancialPeriod> {
  _SelectedPeriodNotifier(super.initial);
  void setPeriod(FinancialPeriod period) => state = period;
}

/// User-selected financial period (editable). Initialized from currentPeriodProvider.
final selectedPeriodProvider = StateNotifierProvider<_SelectedPeriodNotifier, FinancialPeriod>((ref) {
  final defaultPeriod = ref.read(currentPeriodProvider);
  return _SelectedPeriodNotifier(defaultPeriod);
});

/// Raw budget rows for the selected period. Invalidate this after upsert/delete.
final _periodBudgetsRawProvider =
    FutureProvider.autoDispose<List<PeriodBudget>>((ref) async {
  final period = ref.watch(selectedPeriodProvider);
  return ref.watch(periodBudgetRepositoryProvider).getBudgets(period);
});

/// Merged view of budget goals (parents) + period overrides + live spending.
///
/// For each [BudgetGoal] the user has set:
///   - Shows the goal amount by default.
///   - If a [PeriodBudget] row exists for this period, uses its amount instead.
///   - If that row has [isCustom] == true, a "Custom" badge appears in the UI.
///
/// Also includes any period budgets for categories that have no goal (pure custom).
final periodBudgetEntriesProvider =
    Provider.autoDispose<AsyncValue<List<PeriodBudgetEntry>>>((ref) {
  final goalsMap = ref.watch(budgetGoalsMapProvider);
  final overridesAsync = ref.watch(_periodBudgetsRawProvider);
  final expensesAsync = ref.watch(_allExpensesStreamProvider);
  final period = ref.watch(selectedPeriodProvider);

  return overridesAsync.whenData((overrides) {
    final expenses = expensesAsync.value ?? [];

    final spentByCategory = <String, double>{};
    for (final e in expenses) {
      if (e.payType == 'Swile') continue;
      if (!period.contains(e.transactionDate)) continue;
      spentByCategory[e.category] =
          (spentByCategory[e.category] ?? 0) + e.amount;
    }

    final overrideMap = {for (final o in overrides) o.category: o};
    final seen = <String>{};
    final entries = <PeriodBudgetEntry>[];

    // Goal-backed entries (shown even with no override row).
    for (final cat in ExpenseCategory.values) {
      final dbVal = cat.dbValue;
      final goal = goalsMap[dbVal];
      if (goal == null) continue;
      seen.add(dbVal);
      entries.add(PeriodBudgetEntry(
        goal: goal,
        override: overrideMap[dbVal],
        spent: spentByCategory[dbVal] ?? 0,
      ));
    }

    // Pure-custom entries (period budget with no matching goal).
    for (final o in overrides) {
      if (seen.contains(o.category)) continue;
      entries.add(PeriodBudgetEntry(
        goal: null,
        override: o,
        spent: spentByCategory[o.category] ?? 0,
      ));
    }

    return entries;
  });
});

/// Notifier for budget CRUD — invalidates [_periodBudgetsRawProvider] on change.
final periodBudgetNotifierProvider =
    AsyncNotifierProvider<PeriodBudgetNotifier, void>(PeriodBudgetNotifier.new);

class PeriodBudgetNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> upsert({
    required String category,
    required double amount,
    bool isCustom = false,
  }) async {
    final period = ref.read(currentPeriodProvider);
    await ref.read(periodBudgetRepositoryProvider).upsert(
          category: category,
          period: period,
          amount: amount,
          isCustom: isCustom,
        );
    ref.invalidate(_periodBudgetsRawProvider);
  }

  Future<void> delete(String id) async {
    await ref.read(periodBudgetRepositoryProvider).delete(id);
    ref.invalidate(_periodBudgetsRawProvider);
  }

  /// Copies all budgets from the previous period into the current one.
  /// Returns the number of rows created (0 if already seeded).
  Future<int> copyFromPreviousPeriod() async {
    final current = ref.read(currentPeriodProvider);
    final previous = current.previous;
    final count = await ref
        .read(periodBudgetRepositoryProvider)
        .copyFromPeriod(from: previous, to: current);
    if (count > 0) ref.invalidate(_periodBudgetsRawProvider);
    return count;
  }
}

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

// ═══════════════════════════════════════════
// BUDGET ALERTS PROVIDER
// ═══════════════════════════════════════════

/// Derives active budget alerts from goals vs current month cash spending.
/// Thresholds: warning ≥75%, critical ≥90%, exceeded ≥100%.
final budgetAlertsProvider = Provider.autoDispose<List<BudgetAlert>>((ref) {
  final goalsMap = ref.watch(budgetGoalsMapProvider);
  final byCategory = ref.watch(cashExpensesByCategoryProvider);

  final alerts = <BudgetAlert>[];
  for (final goal in goalsMap.values) {
    if (goal.targetAmount <= 0) continue;
    final spent = byCategory[goal.category] ?? 0;
    final pct = spent / goal.targetAmount;
    if (pct < 0.75) continue;
    alerts.add(BudgetAlert(
      category: goal.category,
      spent: spent,
      limit: goal.targetAmount,
      percentage: pct,
      level: pct >= 1.0
          ? AlertLevel.exceeded
          : pct >= 0.90
              ? AlertLevel.critical
              : AlertLevel.warning,
    ));
  }
  alerts.sort((a, b) => b.percentage.compareTo(a.percentage));
  return alerts;
});

// ═══════════════════════════════════════════
// SALARY SETTINGS (CLT 2026)
// ═══════════════════════════════════════════

final salarySettingsRepositoryProvider =
    Provider<SalarySettingsRepository>((ref) =>
        SalarySettingsRepository(Supabase.instance.client));

final salarySettingsProvider =
    AsyncNotifierProvider<SalarySettingsNotifier, SalarySettings?>(
        SalarySettingsNotifier.new);

class SalarySettingsNotifier extends AsyncNotifier<SalarySettings?> {
  @override
  Future<SalarySettings?> build() =>
      ref.read(salarySettingsRepositoryProvider).fetch();

  Future<void> save({
    required double grossSalary,
    int dependents = 0,
    double otherDeductions = 0,
    bool useSimplifiedDeduction = false,
  }) async {
    final result = CltCalculatorService.compute(
      grossSalary: grossSalary,
      dependents: dependents,
      otherDeductions: otherDeductions,
      useSimplifiedDeduction: useSimplifiedDeduction,
    );
    final settings = SalarySettings(
      grossSalary: result.grossSalary,
      inss: result.inss,
      irrf: result.irrf,
      netSalary: result.netSalary,
      fgts: result.fgts,
      dependents: dependents,
      otherDeductions: otherDeductions,
      useSimplifiedDeduction: useSimplifiedDeduction,
    );
    state = const AsyncLoading();
    await ref.read(salarySettingsRepositoryProvider).upsert(settings);
    state = AsyncData(settings);

    // Keep budget_settings.net_salary in sync so effectiveNetSalaryProvider
    // reflects the updated CLT net salary immediately.
    final budgetNotifier = ref.read(budgetSettingsProvider.notifier);
    final currentBudget = ref.read(budgetSettingsProvider).value;
    final updatedBudget = (currentBudget ?? const BudgetSettings()).copyWith(
      netSalary: result.netSalary,
    );
    await budgetNotifier.save(updatedBudget);
  }
}


