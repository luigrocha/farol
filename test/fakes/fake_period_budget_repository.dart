/// In-memory fake [PeriodBudgetRepository] for widget and unit tests.
library;

import 'package:farol/core/models/financial_period.dart';
import 'package:farol/core/models/period_budget.dart';
import 'package:farol/core/repositories/period_budget_repository.dart';

class FakePeriodBudgetBehavior {
  bool shouldThrow;
  bool shouldThrowNetworkError;
  Duration delay;

  FakePeriodBudgetBehavior({
    this.shouldThrow = false,
    this.shouldThrowNetworkError = false,
    this.delay = Duration.zero,
  });
}

class FakePeriodBudgetRepository implements PeriodBudgetRepository {
  FakePeriodBudgetBehavior behavior = FakePeriodBudgetBehavior();
  final List<PeriodBudget> _budgets = [];
  int _nextId = 1;

  String _nextUuid() => 'fake-pb-${_nextId++}';

  PeriodBudget seedBudget({
    required String userId,
    required String category,
    required FinancialPeriod period,
    required double amount,
    bool isCustom = false,
    String? id,
  }) {
    final realId = id ?? _nextUuid();
    final now = DateTime.now();
    final pb = PeriodBudget(
      id: realId,
      userId: userId,
      category: category,
      periodStart: period.start,
      periodEnd: period.end,
      amount: amount,
      isCustom: isCustom,
      createdAt: now,
      updatedAt: now,
    );
    _budgets.add(pb);
    return pb;
  }

  @override
  Future<List<BudgetWithUsage>> getBudgetsWithUsage(FinancialPeriod period) async {
    await _applyDelay();
    _checkBehavior();
    return _budgets
        .where((b) => b.periodStart == period.start && b.periodEnd == period.end)
        .map((b) => BudgetWithUsage(budget: b, spent: 0))
        .toList();
  }

  @override
  Future<List<PeriodBudget>> getBudgets(FinancialPeriod period) async {
    await _applyDelay();
    _checkBehavior();
    return _budgets
        .where((b) => b.periodStart == period.start && b.periodEnd == period.end)
        .toList();
  }

  @override
  Future<void> upsert({
    required String category,
    required FinancialPeriod period,
    required double amount,
    bool isCustom = false,
  }) async {
    await _applyDelay();
    _checkBehavior();

    final matchIdx = _budgets.indexWhere((b) =>
        b.category == category &&
        b.periodStart == period.start &&
        b.periodEnd == period.end);

    final now = DateTime.now();
    if (matchIdx >= 0) {
      final old = _budgets[matchIdx];
      _budgets[matchIdx] = PeriodBudget(
        id: old.id,
        userId: old.userId,
        category: category,
        periodStart: period.start,
        periodEnd: period.end,
        amount: amount,
        isCustom: isCustom,
        createdAt: old.createdAt,
        updatedAt: now,
      );
    } else {
      _budgets.add(PeriodBudget(
        id: _nextUuid(),
        userId: 'fake-user-id',
        category: category,
        periodStart: period.start,
        periodEnd: period.end,
        amount: amount,
        isCustom: isCustom,
        createdAt: now,
        updatedAt: now,
      ));
    }
  }

  @override
  Future<void> delete(String id) async {
    await _applyDelay();
    _checkBehavior();
    _budgets.removeWhere((b) => b.id == id);
  }

  @override
  Future<int> copyFromPeriod({
    required FinancialPeriod from,
    required FinancialPeriod to,
  }) async {
    await _applyDelay();
    _checkBehavior();

    final toCopy = _budgets.where((b) =>
        b.periodStart == from.start && b.periodEnd == from.end &&
        !_budgets.any((existing) =>
            existing.category == b.category &&
            existing.periodStart == to.start &&
            existing.periodEnd == to.end));

    final now = DateTime.now();
    for (final b in toCopy) {
      _budgets.add(PeriodBudget(
        id: _nextUuid(),
        userId: b.userId,
        category: b.category,
        periodStart: to.start,
        periodEnd: to.end,
        amount: b.amount,
        isCustom: false,
        createdAt: now,
        updatedAt: now,
      ));
    }

    return toCopy.length;
  }

  void _checkBehavior() {
    if (behavior.shouldThrowNetworkError) {
      throw Exception('Network error: Unable to connect.');
    }
    if (behavior.shouldThrow) {
      throw Exception('FakePeriodBudgetRepository forced error');
    }
  }

  Future<void> _applyDelay() async {
    if (behavior.delay > Duration.zero) {
      await Future.delayed(behavior.delay);
    }
  }
}
