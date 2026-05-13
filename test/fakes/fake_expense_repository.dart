/// In-memory fake [ExpenseRepository] for widget and unit tests.
///
/// Stores a list of [Expense] objects in memory.
/// Use [seedExpense] to pre-populate data, [behavior] to configure errors/delay.
library;

import 'dart:async';
import 'package:farol/core/models/expense.dart';
import 'package:farol/core/repositories/expense_repository.dart';

/// Configurable behavior for [FakeExpenseRepository] calls.
class FakeExpenseBehavior {
  bool shouldThrow;
  bool shouldThrowNetworkError;
  Duration delay;

  FakeExpenseBehavior({
    this.shouldThrow = false,
    this.shouldThrowNetworkError = false,
    this.delay = Duration.zero,
  });
}

class FakeExpenseRepository implements ExpenseRepository {
  @override
  final String? workspaceId;

  FakeExpenseRepository({this.workspaceId});
  final List<Expense> _expenses = [];
  int _nextId = 1;
  final _streamController = StreamController<List<Expense>>.broadcast();
  FakeExpenseBehavior behavior = FakeExpenseBehavior();

  /// Seeds a pre-existing expense into the in-memory store.
  /// Returns the seed id for later reference.
  int seedExpense({
    int? id,
    required String userId,
    required int month,
    required int year,
    required DateTime transactionDate,
    required String payType,
    required String category,
    String? subcategory,
    required double amount,
    required String paymentMethod,
    int installments = 1,
    bool isFixed = false,
    String? storeDescription,
    bool isProjected = false,
    String? authorUserId,
  }) {
    final realId = id ?? _nextId;
    if (id == null) _nextId++;
    final expense = Expense(
      id: realId,
      userId: userId,
      month: month,
      year: year,
      transactionDate: transactionDate,
      payType: payType,
      category: category,
      subcategory: subcategory,
      amount: amount,
      paymentMethod: paymentMethod,
      installments: installments,
      isFixed: isFixed,
      storeDescription: storeDescription,
      createdAt: DateTime.now(),
      isProjected: isProjected,
      authorUserId: authorUserId,
    );
    _expenses.add(expense);
    if (id != null && id >= _nextId) _nextId = id + 1;
    return realId;
  }

  @override
  Stream<List<Expense>> watchAll() {
    _emit();
    return _streamController.stream;
  }

  @override
  Future<List<Expense>> getAll() async {
    await _applyDelay();
    return List.unmodifiable(_expenses);
  }

  @override
  Future<List<Expense>> getByRange(
    int startMonth, int startYear, int endMonth, int endYear,
  ) async {
    await _applyDelay();
    return _expenses
        .where((e) => _inRange(e.month, e.year, startMonth, startYear, endMonth, endYear))
        .toList();
  }

  @override
  Future<int> insert({
    required DateTime transactionDate,
    required int month,
    required int year,
    required String payType,
    required String category,
    String? subcategory,
    required double amount,
    required String paymentMethod,
    int installments = 1,
    bool isFixed = false,
    String? storeDescription,
    bool isProjected = false,
    int? installmentPlanId,
    String? installmentPlanUuidId,
    String? installmentPaymentId,
    String? recurringRuleId,
    String? recurringOccurrenceId,
  }) async {
    await _applyDelay();
    _checkBehavior();

    final id = _nextId++;
    final expense = Expense(
      id: id,
      userId: 'fake-user-id',
      month: month,
      year: year,
      transactionDate: transactionDate,
      payType: payType,
      category: category,
      subcategory: subcategory,
      amount: amount,
      paymentMethod: paymentMethod,
      installments: installments,
      isFixed: isFixed,
      storeDescription: storeDescription,
      createdAt: DateTime.now(),
      isProjected: isProjected,
      installmentPlanId: installmentPlanId,
      installmentPlanUuid: installmentPlanUuidId,
    );
    _expenses.add(expense);
    _emit();
    return id;
  }

  @override
  Future<void> update({
    required int id,
    required DateTime transactionDate,
    required int month,
    required int year,
    required String payType,
    required String category,
    String? subcategory,
    required double amount,
    required String paymentMethod,
    int installments = 1,
    bool isFixed = false,
    String? storeDescription,
  }) async {
    await _applyDelay();
    _checkBehavior();

    final idx = _expenses.indexWhere((e) => e.id == id);
    if (idx == -1) throw Exception('Expense not found: $id');

    final old = _expenses[idx];
    _expenses[idx] = Expense(
      id: id,
      userId: old.userId,
      month: month,
      year: year,
      transactionDate: transactionDate,
      payType: payType,
      category: category,
      subcategory: subcategory ?? old.subcategory,
      amount: amount,
      paymentMethod: paymentMethod,
      installments: installments,
      isFixed: isFixed,
      storeDescription: storeDescription ?? old.storeDescription,
      createdAt: old.createdAt,
      isProjected: old.isProjected,
      installmentPlanId: old.installmentPlanId,
      installmentPlanUuid: old.installmentPlanUuid,
      authorUserId: old.authorUserId,
    );
    _emit();
  }

  @override
  Future<void> delete(int id) async {
    await _applyDelay();
    _checkBehavior();
    _expenses.removeWhere((e) => e.id == id);
    _emit();
  }

  @override
  Future<void> updateFixedSeriesFrom(
    Expense from, {
    required double amount,
    required String category,
    String? subcategory,
    required String paymentMethod,
    String? storeDescription,
  }) async {
    await _applyDelay();
    _checkBehavior();

    for (var i = 0; i < _expenses.length; i++) {
      final e = _expenses[i];
      if (!e.isFixed) continue;
      if (e.category != from.category) continue;
      if (e.paymentMethod != from.paymentMethod) continue;
      if (e.storeDescription != from.storeDescription) continue;
      if (e.year * 12 + e.month < from.year * 12 + from.month) continue;

      _expenses[i] = Expense(
        id: e.id,
        userId: e.userId,
        month: e.month,
        year: e.year,
        transactionDate: e.transactionDate,
        payType: e.payType,
        category: category,
        subcategory: subcategory ?? e.subcategory,
        amount: amount,
        paymentMethod: paymentMethod,
        installments: e.installments,
        isFixed: true,
        storeDescription: storeDescription ?? e.storeDescription,
        createdAt: e.createdAt,
        isProjected: e.isProjected,
        installmentPlanId: e.installmentPlanId,
        installmentPlanUuid: e.installmentPlanUuid,
        authorUserId: e.authorUserId,
      );
    }
    _emit();
  }

  void _checkBehavior() {
    if (behavior.shouldThrowNetworkError) {
      throw Exception('Network error: Unable to connect.');
    }
    if (behavior.shouldThrow) {
      throw Exception('FakeExpenseRepository forced error');
    }
  }

  Future<void> _applyDelay() async {
    if (behavior.delay > Duration.zero) {
      await Future.delayed(behavior.delay);
    }
  }

  void _emit() => _streamController.add(List.unmodifiable(_expenses));

  void dispose() => _streamController.close();

  // ─── ExpenseRepository interface stubs ───────────────────────────────

  @override
  Future<void> updateProjectedByPlan(int planId, {required double amount, required String category, String? subcategory, required String paymentMethod}) async {
    throw UnimplementedError('FakeExpenseRepository does not support updateProjectedByPlan');
  }

  @override
  Future<int> getProjectedCountForPlan(int planId) async {
    throw UnimplementedError('FakeExpenseRepository does not support getProjectedCountForPlan');
  }

  @override
  Stream<List<Expense>> watchRealtime() => const Stream.empty();

  @override
  Future<void> unsubscribeRealtime() async {}

  @override
  bool get shouldFallbackToPolling => false;

  @override
  Future<List<Expense>> fetchAll() async => getAll();

  @override
  Future<List<Expense>> getFixedForMonth(int month, int year) async {
    return _expenses.where((e) => e.month == month && e.year == year && e.isFixed).toList();
  }

  @override
  Future<int> propagateFixedExpenses(int toMonth, int toYear) async {
    throw UnimplementedError('FakeExpenseRepository does not support propagateFixedExpenses');
  }

  static bool _inRange(
    int m, int y, int sm, int sy, int em, int ey,
  ) {
    final v = y * 12 + m;
    return v >= sy * 12 + sm && v <= ey * 12 + em;
  }
}
