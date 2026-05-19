/// In-memory fake [IncomeRepository] for widget and unit tests.
library;

import 'dart:async';
import 'package:farol/core/models/income.dart';
import 'package:farol/core/repositories/income_repository.dart';

/// Configurable behavior for [FakeIncomeRepository] calls.
class FakeIncomeBehavior {
  bool shouldThrow;
  bool shouldThrowNetworkError;
  Duration delay;

  FakeIncomeBehavior({
    this.shouldThrow = false,
    this.shouldThrowNetworkError = false,
    this.delay = Duration.zero,
  });
}

class FakeIncomeRepository implements IncomeRepository {
  @override
  final String? workspaceId;

  FakeIncomeRepository({this.workspaceId});
  final List<Income> _incomes = [];
  int _nextId = 1;
  final _streamController = StreamController<List<Income>>.broadcast();
  FakeIncomeBehavior behavior = FakeIncomeBehavior();

  /// Seeds a pre-existing income into the in-memory store.
  /// Returns the seed id for later reference.
  int seedIncome({
    int? id,
    required String userId,
    required int month,
    required int year,
    required String incomeType,
    required double amount,
    bool isNet = true,
    double? inssDeducted,
    double? irrfDeducted,
    String? notes,
  }) {
    final realId = id ?? _nextId;
    if (id == null) _nextId++;
    final income = Income(
      id: realId,
      userId: userId,
      month: month,
      year: year,
      incomeType: incomeType,
      amount: amount,
      isNet: isNet,
      inssDeducted: inssDeducted,
      irrfDeducted: irrfDeducted,
      notes: notes,
      createdAt: DateTime.now(),
    );
    _incomes.add(income);
    if (id != null && id >= _nextId) _nextId = id + 1;
    return realId;
  }

  @override
  Stream<List<Income>> watchAll() {
    _emit();
    return _streamController.stream;
  }

  @override
  Future<List<Income>> getAll() async {
    await _applyDelay();
    return List.unmodifiable(_incomes);
  }

  @override
  Future<List<Income>> getByRange(
    int startMonth,
    int startYear,
    int endMonth,
    int endYear,
  ) async {
    await _applyDelay();
    return _incomes
        .where((i) =>
            _inRange(i.month, i.year, startMonth, startYear, endMonth, endYear))
        .toList();
  }

  @override
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
    await _applyDelay();
    _checkBehavior();

    final id = _nextId++;
    final income = Income(
      id: id,
      userId: 'fake-user-id',
      month: month,
      year: year,
      incomeType: incomeType,
      amount: amount,
      isNet: isNet,
      inssDeducted: inssDeducted,
      irrfDeducted: irrfDeducted,
      notes: notes,
      createdAt: DateTime.now(),
    );
    _incomes.add(income);
    _emit();
  }

  @override
  Future<void> update({
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
    await _applyDelay();
    _checkBehavior();

    final idx = _incomes.indexWhere((i) => i.id == id);
    if (idx == -1) throw Exception('Income not found: $id');

    final old = _incomes[idx];
    _incomes[idx] = Income(
      id: id,
      userId: old.userId,
      month: month,
      year: year,
      incomeType: incomeType,
      amount: amount,
      isNet: isNet,
      inssDeducted: inssDeducted ?? old.inssDeducted,
      irrfDeducted: irrfDeducted ?? old.irrfDeducted,
      notes: notes ?? old.notes,
      createdAt: old.createdAt,
    );
    _emit();
  }

  @override
  Future<void> delete(int id) async {
    await _applyDelay();
    _checkBehavior();
    _incomes.removeWhere((i) => i.id == id);
    _emit();
  }

  void _checkBehavior() {
    if (behavior.shouldThrowNetworkError) {
      throw Exception('Network error: Unable to connect.');
    }
    if (behavior.shouldThrow) {
      throw Exception('FakeIncomeRepository forced error');
    }
  }

  Future<void> _applyDelay() async {
    if (behavior.delay > Duration.zero) {
      await Future.delayed(behavior.delay);
    }
  }

  void _emit() => _streamController.add(List.unmodifiable(_incomes));

  void dispose() => _streamController.close();

  // ─── IncomeRepository interface stubs ───────────────────────────

  @override
  Stream<List<Income>> watchRealtime() => const Stream.empty();

  @override
  Future<void> unsubscribeRealtime() async {}

  @override
  bool get shouldFallbackToPolling => false;

  @override
  Future<List<Income>> fetchAll() async => getAll();

  static bool _inRange(
    int m,
    int y,
    int sm,
    int sy,
    int em,
    int ey,
  ) {
    final v = y * 12 + m;
    return v >= sy * 12 + sm && v <= ey * 12 + em;
  }
}
