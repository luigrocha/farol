import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Drift kept only for device-local UserSettings (isFirstLaunch, etc.)
import '../database/app_database.dart' show AppDatabase;
import '../models/income.dart';
import '../models/expense.dart';
import '../models/enums.dart';
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
import '../domain/value_objects/category_ref.dart';
import '../domain/services/category_resolver.dart';
import '../repositories/installment_plan_repository.dart';
import '../repositories/installment_payment_repository.dart';
import '../domain/entities/installment_plan.dart';
import '../domain/entities/installment_payment.dart';
import '../domain/services/installment_service.dart';
import '../domain/services/financial_engine.dart';
import '../domain/services/envelope_engine.dart';
import '../domain/services/recurring_service.dart';
import '../domain/services/recurring_detector.dart';
import '../domain/services/forecasting_engine.dart';
import '../domain/services/obligation_engine.dart';
import '../domain/entities/financial_projection.dart';
import '../domain/entities/financial_snapshot.dart';
import '../domain/value_objects/money.dart';
import '../domain/entities/financial_insight.dart';
import '../domain/services/intelligence_layer.dart';
import '../repositories/dismissed_insights_repository.dart';
import '../domain/entities/insight_stats.dart';
import '../repositories/forecast_cache_repository.dart';
import '../infrastructure/sync/sync_manager.dart' show SyncManager, SyncStatus;
import '../infrastructure/sync/operation_queue.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../domain/entities/envelope.dart';
import '../domain/entities/recurring_rule.dart';
import '../domain/entities/recurring_occurrence.dart';
import '../repositories/recurring_rules_repository.dart';
import '../repositories/recurring_occurrences_repository.dart';
import 'workspace_providers.dart' show activeWorkspaceIdProvider, activeWorkspaceProvider;

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
// 'all' | 'cash' | 'swile' | any category slug
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
  final wsId = ref.watch(activeWorkspaceIdProvider);
  return IncomeRepository(Supabase.instance.client, workspaceId: wsId);
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final syncManager = ref.read(syncManagerProvider);
  final wsId = ref.watch(activeWorkspaceIdProvider);
  return ExpenseRepository(
    Supabase.instance.client,
    syncManager: syncManager,
    workspaceId: wsId,
  );
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
  final wsId = ref.watch(activeWorkspaceIdProvider);
  return CategoryRepository(Supabase.instance.client, workspaceId: wsId);
});

final installmentPlanRepositoryProvider =
    Provider<InstallmentPlanRepository>((ref) {
  final wsId = ref.watch(activeWorkspaceIdProvider);
  return InstallmentPlanRepository(Supabase.instance.client, workspaceId: wsId);
});

final installmentPaymentRepositoryProvider =
    Provider<InstallmentPaymentRepository>((ref) {
  return InstallmentPaymentRepository(Supabase.instance.client);
});

final installmentPlansStreamProvider =
    StreamProvider.autoDispose<List<InstallmentPlan>>((ref) {
  return ref.watch(installmentPlanRepositoryProvider).watchAll();
});

final activeInstallmentPlansProvider =
    StreamProvider.autoDispose<List<InstallmentPlan>>((ref) {
  return ref.watch(installmentPlanRepositoryProvider).watchActive();
});

final pendingInstallmentPaymentsProvider =
    FutureProvider.autoDispose<List<InstallmentPayment>>((ref) {
  return ref.watch(installmentPaymentRepositoryProvider).getPending();
});

final installmentServiceProvider = Provider<InstallmentService>((ref) {
  return InstallmentService(
    planRepo: ref.read(installmentPlanRepositoryProvider),
    paymentRepo: ref.read(installmentPaymentRepositoryProvider),
    expenseRepo: ref.read(expenseRepositoryProvider),
  );
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
  // Wait for the active workspace to resolve before subscribing.
  // While loading, activeWorkspaceIdProvider returns null → the repo uses the
  // userId branch and may miss workspace-scoped categories. Gating here ensures
  // the stream always starts with a fully resolved workspaceId.
  // StreamController that never emits keeps the provider in AsyncLoading state.
  final wsAsync = ref.watch(activeWorkspaceProvider);
  if (wsAsync.isLoading) {
    final ctrl = StreamController<List<Category>>();
    ref.onDispose(ctrl.close);
    return ctrl.stream;
  }
  return ref.watch(categoryRepositoryProvider).watchAll();
});

final categoriesMapProvider = Provider.autoDispose<Map<String, Category>>((ref) {
  final cats = ref.watch(categoriesStreamProvider).value ?? [];
  return {for (var c in cats) c.slug: c};
});

/// List of CategoryRef — domain value objects derived from the loaded categories.
final categoriesRefProvider = Provider.autoDispose<List<CategoryRef>>((ref) {
  final cats = ref.watch(categoriesStreamProvider).value ?? [];
  return cats.map(CategoryRef.fromCategory).toList();
});

/// Only root categories (parentId == null). Use this for category pickers in
/// expense sheets so subcategories don't bleed into the top-level grid.
final rootCategoriesRefProvider = Provider.autoDispose<List<CategoryRef>>((ref) {
  return ref.watch(categoriesRefProvider).where((c) => c.parentId == null).toList();
});

/// Subcategories for a given parent category id. Returns empty list when the
/// category has no children in the DB (i.e. hardcoded subcategories are gone).
final subcategoriesForProvider =
    Provider.autoDispose.family<List<CategoryRef>, String>((ref, parentId) {
  return ref.watch(categoriesRefProvider).where((c) => c.parentId == parentId).toList();
});

/// Singleton CategoryResolver kept in sync with loaded categories.
/// Use this to safely resolve raw category strings without risk of StateError.
final categoryResolverProvider = Provider<CategoryResolver>((ref) {
  final resolver = CategoryResolver();
  ref.listen(categoriesRefProvider, (_, refs) => resolver.updateCache(refs), fireImmediately: true);
  return resolver;
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

/// Expenses filtered to the currently selected month/year (includes projected).
final expensesProvider = Provider.autoDispose<AsyncValue<List<Expense>>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  final year = ref.watch(selectedYearProvider);
  return ref.watch(_allExpensesStreamProvider).whenData(
    (all) => all.where((e) => e.month == month && e.year == year).toList(),
  );
});

/// Real (non-projected) expenses for the selected month/year.
/// Use this for totals and budget calculations.
final realExpensesProvider = Provider.autoDispose<AsyncValue<List<Expense>>>((ref) {
  return ref.watch(expensesProvider).whenData(
    (all) => all.where((e) => !e.isProjected).toList(),
  );
});

final totalExpensesProvider = Provider.autoDispose<double>((ref) {
  final expenses = ref.watch(realExpensesProvider).value ?? [];
  return expenses.fold(0.0, (sum, e) => sum + e.amount);
});

final cashExpensesProvider = Provider.autoDispose<double>((ref) {
  final expenses = ref.watch(realExpensesProvider).value ?? [];
  return expenses
      .where((e) => e.payType == 'Cash')
      .fold(0.0, (sum, e) => sum + e.amount);
});

final swileExpensesProvider = Provider.autoDispose<double>((ref) {
  final expenses = ref.watch(realExpensesProvider).value ?? [];
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
  final expenses = ref.watch(realExpensesProvider).value ?? [];
  final map = <String, double>{};
  for (final e in expenses) {
    final slug = e.category.toLowerCase();
    map[slug] = (map[slug] ?? 0) + e.amount;
  }
  return map;
});

final cashExpensesByCategoryProvider = Provider.autoDispose<Map<String, double>>((ref) {
  final expenses = ref.watch(realExpensesProvider).value ?? [];
  final map = <String, double>{};
  for (final e in expenses.where((e) => e.payType == 'Cash')) {
    // Normalize slug to lowercase to avoid duplicate entries (e.g. 'OTHER' vs 'other')
    final slug = e.category.toLowerCase();
    map[slug] = (map[slug] ?? 0) + e.amount;
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

/// Returns how many projected expenses already exist for a given installment plan.
/// Used to detect legacy plans that need migration.
final projectedCountForPlanProvider =
    FutureProvider.autoDispose.family<int, int>((ref, planId) {
  return ref.read(expenseRepositoryProvider).getProjectedCountForPlan(planId);
});

final totalMonthlyInstallmentsProvider = Provider.autoDispose<double>((ref) {
  final list = ref.watch(activeInstallmentPlansProvider).value ?? [];
  return list.fold(0.0, (sum, i) => sum + i.installmentAmount);
});

final totalRemainingInstallmentsProvider = Provider.autoDispose<double>((ref) {
  final list = ref.watch(activeInstallmentPlansProvider).value ?? [];
  return list.fold(0.0, (sum, i) => sum + i.remainingAmount);
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
  // Normalize keys to lowercase to match category slug normalization in expense providers
  return {for (var g in goals) g.category.toLowerCase(): g};
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
  Future<void> build() async {}

  Future<void> add(Category category) async {
    await ref.read(categoryRepositoryProvider).insert(category);
    ref.invalidate(categoriesStreamProvider);
  }

  Future<void> save(Category category) async {
    await ref.read(categoryRepositoryProvider).update(category);
    ref.invalidate(categoriesStreamProvider);
  }

  Future<void> delete(String id) async {
    await ref.read(categoryRepositoryProvider).archive(id);
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
      installmentRepo: ref.watch(installmentPlanRepositoryProvider),
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
    final inst = ref.read(activeInstallmentPlansProvider).value ?? [];
    final housing = byCategory['HOUSING'] ?? 0;
    final instTotal = inst.fold(0.0, (s, i) => s + i.installmentAmount);
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
  final categories = ref.watch(categoriesRefProvider);

  return overridesAsync.whenData((overrides) {
    final expenses = expensesAsync.value ?? [];

    final spentByCategory = <String, double>{};
    for (final e in expenses) {
      if (e.isProjected) continue;
      if (e.payType == 'Swile') continue;
      if (!period.contains(e.transactionDate)) continue;
      // Normalize to lowercase slug for consistent keying
      final slug = e.category.toLowerCase();
      spentByCategory[slug] = (spentByCategory[slug] ?? 0) + e.amount;
    }

    final overrideMap = {for (final o in overrides) o.category.toLowerCase(): o};
    final seen = <String>{};
    final entries = <PeriodBudgetEntry>[];

    // Goal-backed entries — iterate loaded categories (includes custom).
    for (final cat in categories) {
      final goal = goalsMap[cat.slug];
      if (goal == null) continue;
      seen.add(cat.slug);
      entries.add(PeriodBudgetEntry(
        goal: goal,
        override: overrideMap[cat.slug],
        spent: spentByCategory[cat.slug] ?? 0,
      ));
    }

    // Pure-custom entries (period budget with no matching goal).
    for (final o in overrides) {
      final slug = o.category.toLowerCase();
      if (seen.contains(slug)) continue;
      entries.add(PeriodBudgetEntry(
        goal: null,
        override: o,
        spent: spentByCategory[slug] ?? 0,
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
  final catsMap = ref.watch(categoriesMapProvider);

  final alerts = <BudgetAlert>[];
  for (final goal in goalsMap.values) {
    if (goal.targetAmount <= 0) continue;
    final slug = goal.category.toLowerCase();
    final spent = byCategory[slug] ?? byCategory[goal.category] ?? 0;
    final pct = spent / goal.targetAmount;
    if (pct < 0.75) continue;
    final cat = catsMap[slug];
    alerts.add(BudgetAlert(
      category: slug,
      categoryName: cat?.name ?? goal.category,
      categoryEmoji: cat?.emoji ?? '📊',
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

// ═══════════════════════════════════════════
// FINANCIAL SNAPSHOT PROVIDER
// ═══════════════════════════════════════════

final _financialEngineProvider = Provider<FinancialEngine>((_) => const FinancialEngine());
final _envelopeEngineProvider = Provider<EnvelopeEngine>((_) => const EnvelopeEngine());

/// Envelopes for the current period, with rollover from the previous period.
final envelopesProvider = Provider.autoDispose<List<Envelope>>((ref) {
  final engine = ref.watch(_envelopeEngineProvider);
  final entries = ref.watch(periodBudgetEntriesProvider).value ?? [];
  if (entries.isEmpty) return const [];

  final allExpenses = ref.watch(_allExpensesStreamProvider).value ?? [];
  final cutoffDay = ref.watch(budgetSettingsProvider).value?.cutoffDay ?? 1;
  final period = FinancialPeriod.current(cutoffDay);
  final previousPeriod = period.previous;
  final categoriesBySlug = {
    for (final c in ref.watch(categoriesRefProvider)) c.slug: c
  };

  return engine.buildEnvelopes(
    entries: entries,
    categoriesBySlug: categoriesBySlug,
    previousExpenses: allExpenses,
    previousPeriod: previousPeriod,
  );
});

/// Single source of truth for the current period's financial state.
/// All dashboard widgets should consume this instead of individual providers.
final financialSnapshotProvider = Provider.autoDispose<FinancialSnapshot>((ref) {
  final engine = ref.watch(_financialEngineProvider);
  final incomes = ref.watch(incomesProvider).value ?? [];
  final expenses = ref.watch(realExpensesProvider).value ?? [];
  final netSalaryOverride = ref.watch(effectiveNetSalaryProvider);
  final swileOverride = ref.watch(effectiveSwileProvider);
  final activePlans = ref.watch(activeInstallmentPlansProvider).value ?? [];
  final accountsExist = ref.watch(accountsProvider).value?.isNotEmpty ?? false;
  final emergencyFund = accountsExist
      ? ref.watch(liquidAccountsTotalProvider)
      : (ref.watch(netWorthSnapshotProvider).value?.emergencyFund ?? 0);
  final envelopes = ref.watch(envelopesProvider);

  final month = ref.watch(selectedMonthProvider);
  final year = ref.watch(selectedYearProvider);
  final cutoffDay = ref.watch(budgetSettingsProvider).value?.cutoffDay ?? 1;
  final period = FinancialPeriod.current(cutoffDay,
      now: DateTime(year, month, cutoffDay));

  final envelopeEngine = ref.watch(_envelopeEngineProvider);
  final totalAllocated = envelopeEngine.totalAllocated(envelopes);

  return engine.buildSnapshot(
    period: period,
    incomes: incomes,
    expenses: expenses,
    netSalaryOverride: netSalaryOverride,
    swileOverride: swileOverride,
    emergencyFund: emergencyFund,
    activePlans: activePlans,
    envelopes: envelopes,
    totalAllocated: totalAllocated,
  );
});

// ═══════════════════════════════════════════
// RECURRING RULES PROVIDERS
// ═══════════════════════════════════════════

final recurringRulesRepositoryProvider =
    Provider<RecurringRulesRepository>((ref) {
  final wsId = ref.watch(activeWorkspaceIdProvider);
  return RecurringRulesRepository(Supabase.instance.client, workspaceId: wsId);
});

final recurringOccurrencesRepositoryProvider =
    Provider<RecurringOccurrencesRepository>((ref) {
  return RecurringOccurrencesRepository(Supabase.instance.client);
});

final recurringServiceProvider = Provider<RecurringService>((ref) {
  return RecurringService(
    rulesRepo: ref.read(recurringRulesRepositoryProvider),
    occurrencesRepo: ref.read(recurringOccurrencesRepositoryProvider),
    expenseRepo: ref.read(expenseRepositoryProvider),
  );
});

final recurringRulesStreamProvider =
    StreamProvider.autoDispose<List<RecurringRule>>((ref) {
  return ref.watch(recurringRulesRepositoryProvider).watchAll();
});

final activeRecurringRulesProvider =
    Provider.autoDispose<List<RecurringRule>>((ref) {
  return ref
      .watch(recurringRulesStreamProvider)
      .value
      ?.where((r) => r.isActive)
      .toList() ?? [];
});

/// Job provider — call ref.watch(generateRecurringOccurrencesProvider) in a
/// widget or lifecycle observer to trigger the generation job on startup.
final generateRecurringOccurrencesProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final service = ref.read(recurringServiceProvider);
  return service.generateUpcomingOccurrences(monthsAhead: 3);
});

/// Pending occurrences for the current period — used by dashboard and
/// ObligationEngine (forecasting).
final pendingRecurringOccurrencesProvider =
    FutureProvider.autoDispose<List<RecurringOccurrence>>((ref) async {
  final repo = ref.watch(recurringOccurrencesRepositoryProvider);
  final period = ref.watch(selectedPeriodProvider);
  return repo.getPendingInRange(period.start, period.end);
});

// ═══════════════════════════════════════════
// FORECASTING PROVIDERS
// ═══════════════════════════════════════════

final forecastCacheRepositoryProvider = Provider<ForecastCacheRepository>((ref) {
  return ForecastCacheRepository(ref.read(databaseProvider));
});

/// Full financial projection: BurnRate + LiquidityRisk + ProjectedClosingBalance.
/// Computed async so it never blocks the main snapshot.
final financialProjectionProvider =
    FutureProvider.autoDispose<FinancialProjection?>((ref) async {
  final snap = ref.watch(financialSnapshotProvider);
  final pendingInstallments =
      await ref.watch(pendingInstallmentPaymentsProvider.future);
  final pendingOccurrences =
      await ref.watch(pendingRecurringOccurrencesProvider.future);
  final expenses = await ref.watch(expenseRepositoryProvider).getAll();

  final obligations = const ObligationEngine().buildObligations(
    pendingInstallments: pendingInstallments,
    pendingOccurrences: pendingOccurrences,
  );

  return const ForecastingEngine().buildProjection(
    period: snap.period,
    totalSpent: snap.totalSpent,
    totalAllocated: snap.totalAllocated,
    currentBalance: snap.currentBalance,
    projectedIncome: Money.zero, // income already in currentBalance
    obligations: obligations,
    expenseHistory: expenses,
    buildForecastChart: false,
  );
});

/// Full cashflow chart — only loaded when analytics screen is open.
///
/// Uses a client-side TTL cache (2 h) stored in Drift [UserSettings].
/// The cache key includes the period start/end dates so a period change
/// automatically invalidates the result. [SyncManager] also calls
/// [ForecastCacheRepository.invalidate] after a successful sync.
final cashflowForecastProvider =
    FutureProvider.autoDispose<FinancialProjection?>((ref) async {
  final snap = ref.watch(financialSnapshotProvider);
  final cache = ref.read(forecastCacheRepositoryProvider);

  // Build a stable key from the current financial period.
  final periodKey =
      '${snap.period.start.toIso8601String()}_${snap.period.end.toIso8601String()}';

  // ── Cache hit ──────────────────────────────────────────────────────────────
  final cached = await cache.get(periodKey);
  if (cached != null) {
    // Reconstruct a FinancialProjection using the cached chart + fresh snapshot.
    // The snapshot-derived fields (burnRate, liquidityRisk, projectedClosing)
    // are recomputed from the live snapshot so they always reflect current state.
    final pendingInstallments =
        await ref.watch(pendingInstallmentPaymentsProvider.future);
    final pendingOccurrences =
        await ref.watch(pendingRecurringOccurrencesProvider.future);

    final obligations = const ObligationEngine().buildObligations(
      pendingInstallments: pendingInstallments,
      pendingOccurrences: pendingOccurrences,
    );

    final projection = const ForecastingEngine().buildProjection(
      period: snap.period,
      totalSpent: snap.totalSpent,
      totalAllocated: snap.totalAllocated,
      currentBalance: snap.currentBalance,
      projectedIncome: Money.zero,
      obligations: obligations,
      expenseHistory: const [],
      buildForecastChart: false,
    );

    // Attach the cached chart — avoids fetching all expenses again.
    return FinancialProjection(
      burnRate: projection.burnRate,
      projectedClosingBalance: projection.projectedClosingBalance,
      liquidityRisk: projection.liquidityRisk,
      cashflowForecast: cached,
    );
  }

  // ── Cache miss: full computation ───────────────────────────────────────────
  final pendingInstallments =
      await ref.watch(pendingInstallmentPaymentsProvider.future);
  final pendingOccurrences =
      await ref.watch(pendingRecurringOccurrencesProvider.future);
  final expenses = await ref.watch(expenseRepositoryProvider).getAll();

  final obligations = const ObligationEngine().buildObligations(
    pendingInstallments: pendingInstallments,
    pendingOccurrences: pendingOccurrences,
  );

  final result = const ForecastingEngine().buildProjection(
    period: snap.period,
    totalSpent: snap.totalSpent,
    totalAllocated: snap.totalAllocated,
    currentBalance: snap.currentBalance,
    projectedIncome: Money.zero,
    obligations: obligations,
    expenseHistory: expenses,
    buildForecastChart: true,
  );

  // Persist the chart to cache (burnRate/liquidityRisk are cheap to recompute).
  if (result.cashflowForecast != null) {
    await cache.put(periodKey, result.cashflowForecast!);
  }

  return result;
});

/// Detects recurring patterns from all-time expense history.
/// Returns candidates with confidence >= 0.75 not already covered by a rule.
final recurringCandidatesProvider =
    FutureProvider.autoDispose<List<RecurringRuleCandidate>>((ref) async {
  final expenses = await ref.watch(expenseRepositoryProvider).getAll();
  final rules = ref.watch(recurringRulesStreamProvider).value ?? [];
  final existingNames = rules.map((r) => r.name).toList();
  return const RecurringDetector().detect(expenses, existingRuleNames: existingNames);
});

// ═══════════════════════════════════════════
// OFFLINE SYNC PROVIDERS
// ═══════════════════════════════════════════

final operationQueueProvider = Provider<OperationQueue>((ref) {
  final db = ref.read(databaseProvider);
  return OperationQueue(db, Supabase.instance.client);
});

final syncManagerProvider = Provider<SyncManager>((ref) {
  final queue = ref.read(operationQueueProvider);
  final manager = SyncManager(queue, Supabase.instance.client);
  ref.onDispose(manager.dispose);
  return manager;
});

final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  return ref.watch(syncManagerProvider).statusStream;
});

/// True when device has no network connection.
final isOfflineProvider = StreamProvider<bool>((ref) {
  return Connectivity()
      .onConnectivityChanged
      .map((results) => results.every((r) => r == ConnectivityResult.none));
});

// ═══════════════════════════════════════════
// INTELLIGENCE LAYER PROVIDERS
// ═══════════════════════════════════════════

final dismissedInsightsRepositoryProvider =
    Provider<DismissedInsightsRepository>((ref) {
  return DismissedInsightsRepository(ref.read(databaseProvider));
});

/// Dismissed insight IDs/groups — refreshed when user dismisses.
final dismissedInsightsProvider =
    FutureProvider.autoDispose<Set<String>>((ref) {
  return ref.watch(dismissedInsightsRepositoryProvider).getDismissed();
});

/// Dismiss-rate analytics — how many times each insight type has been dismissed.
/// Invalidated whenever the user dismisses an insight (via InsightCard).
final insightStatsProvider =
    FutureProvider.autoDispose<List<InsightStats>>((ref) {
  return ref.watch(dismissedInsightsRepositoryProvider).getStats();
});

/// The full list of active insights, sorted by priority, max 3.
final insightsProvider =
    FutureProvider.autoDispose<List<FinancialInsight>>((ref) async {
  final snapshot = ref.watch(financialSnapshotProvider);
  final projection = await ref.watch(financialProjectionProvider.future);
  final allExpenses = await ref.watch(expenseRepositoryProvider).getAll();
  final dismissed = await ref.watch(dismissedInsightsProvider.future);

  final now = DateTime.now();
  final recent = allExpenses
      .where((e) =>
          e.transactionDate.isAfter(now.subtract(const Duration(days: 30))))
      .toList();

  return const IntelligenceLayer().analyze(
    snapshot: snapshot,
    projection: projection,
    recentExpenses: recent,
    allExpenses: allExpenses,
    dismissedIds: dismissed,
  );
});


