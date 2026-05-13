/// Unit tests for [FakeExpenseRepository] and (inline) real [ExpenseRepository]
/// online/offline behavior.
///
/// The fake is the cornerstone of widget tests — verify it's correct here.
library;

import 'package:flutter_test/flutter_test.dart';
import '../../test/fakes/fake_expense_repository.dart';

int _seed(FakeExpenseRepository repo, {int? id, int month = 5, int year = 2026, double amount = 100, String? storeDescription}) {
  return repo.seedExpense(
    id: id,
    userId: 'user-1',
    month: month,
    year: year,
    transactionDate: DateTime(year, month, 15),
    payType: 'Cash',
    category: 'food',
    amount: amount,
    paymentMethod: 'DEBIT',
    installments: 1,
    isFixed: false,
    storeDescription: storeDescription ?? 'Supermarket',
  );
}

void main() {
  group('FakeExpenseRepository', () {
    late FakeExpenseRepository repo;

    setUp(() {
      repo = FakeExpenseRepository();
    });

    tearDown(() {
      repo.dispose();
    });

    // ─── Insert ────────────────────────────────────────────────────────────────

    test('insert creates expense and returns id > 0', () async {
      final id = await repo.insert(
        transactionDate: DateTime(2026, 5, 10),
        month: 5,
        year: 2026,
        payType: 'Cash',
        category: 'transport',
        amount: 50.0,
        paymentMethod: 'PIX',
        installments: 1,
      );

      expect(id, greaterThan(0));
      final all = await repo.getAll();
      expect(all.length, 1);
      expect(all.first.id, id);
      expect(all.first.category, 'transport');
      expect(all.first.amount, 50.0);
    });

    test('insert with all optional fields stores them correctly', () async {
      await repo.insert(
        transactionDate: DateTime(2026, 6, 1),
        month: 6,
        year: 2026,
        payType: 'Swile',
        category: 'meal',
        subcategory: 'lunch',
        amount: 35.90,
        paymentMethod: 'SWILE_MEAL',
        installments: 1,
        isFixed: true,
        storeDescription: 'Restaurant',
        isProjected: false,
        installmentPlanUuidId: 'plan-uuid-123',
      );

      final all = await repo.getAll();
      expect(all.length, 1);
      expect(all.first.subcategory, 'lunch');
      expect(all.first.isFixed, true);
      expect(all.first.storeDescription, 'Restaurant');
      expect(all.first.installmentPlanUuid, 'plan-uuid-123');
    });

    test('consecutive inserts yield incrementing ids', () async {
      final id1 = await repo.insert(
        transactionDate: DateTime(2026, 5, 1),
        month: 5, year: 2026,
        payType: 'Cash', category: 'food', amount: 10, paymentMethod: 'DEBIT',
      );
      final id2 = await repo.insert(
        transactionDate: DateTime(2026, 5, 2),
        month: 5, year: 2026,
        payType: 'Cash', category: 'transport', amount: 20, paymentMethod: 'PIX',
      );

      expect(id2, id1 + 1);
    });

    test('insert with shouldThrowNetworkError throws', () async {
      repo.behavior = FakeExpenseBehavior(shouldThrowNetworkError: true);

      await expectLater(
        repo.insert(
          transactionDate: DateTime(2026, 5, 1),
          month: 5, year: 2026,
          payType: 'Cash', category: 'food', amount: 10, paymentMethod: 'DEBIT',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('insert with delay respects the delay', () async {
      repo.behavior = FakeExpenseBehavior(delay: const Duration(milliseconds: 50));
      final stopwatch = Stopwatch()..start();

      await repo.insert(
        transactionDate: DateTime(2026, 5, 1),
        month: 5, year: 2026,
        payType: 'Cash', category: 'food', amount: 10, paymentMethod: 'DEBIT',
      );

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(45));
    });

    // ─── GetAll ────────────────────────────────────────────────────────────────

    test('getAll returns all seeded expenses', () async {
      _seed(repo, amount: 100);
      _seed(repo, amount: 200);

      final all = await repo.getAll();
      expect(all.length, 2);
    });

    test('getAll returns empty list when no expenses exist', () async {
      final all = await repo.getAll();
      expect(all, isEmpty);
    });

    // ─── GetByRange ────────────────────────────────────────────────────────────

    test('getByRange returns expenses within the month/year range', () async {
      _seed(repo, month: 1, year: 2026, amount: 10);
      _seed(repo, month: 3, year: 2026, amount: 20);
      _seed(repo, month: 6, year: 2026, amount: 30);
      _seed(repo, month: 1, year: 2027, amount: 40);

      final result = await repo.getByRange(2, 2026, 5, 2026);
      // Only month 3/2026 (value 20) is in range [Feb 2026, May 2026]
      expect(result.length, 1);
      expect(result.first.amount, 20);
    });

    test('getByRange across year boundary', () async {
      _seed(repo, month: 11, year: 2025, amount: 10);
      _seed(repo, month: 2, year: 2026, amount: 20);

      final result = await repo.getByRange(10, 2025, 3, 2026);
      expect(result.length, 2);
    });

    test('getByRange empty when nothing matches', () async {
      _seed(repo, month: 1, year: 2025);
      final result = await repo.getByRange(1, 2026, 12, 2026);
      expect(result, isEmpty);
    });

    // ─── Update ────────────────────────────────────────────────────────────────

    test('update modifies expense fields in place', () async {
      final sid = repo.seedExpense(
        userId: 'user-1',
        month: 5, year: 2026,
        transactionDate: DateTime(2026, 5, 15),
        payType: 'Cash', category: 'food', amount: 50.0, paymentMethod: 'DEBIT',
      );

      await repo.update(
        id: sid,
        transactionDate: DateTime(2026, 5, 20),
        month: 5, year: 2026,
        payType: 'Cash', category: 'transport', amount: 75.0, paymentMethod: 'PIX',
      );

      final all = await repo.getAll();
      expect(all.length, 1);
      expect(all.first.category, 'transport');
      expect(all.first.amount, 75.0);
      expect(all.first.paymentMethod, 'PIX');
      expect(all.first.transactionDate.day, 20);
    });

    test('update with non-existent id throws', () async {
      await expectLater(
        repo.update(
          id: 999,
          transactionDate: DateTime(2026, 5, 1),
          month: 5, year: 2026,
          payType: 'Cash', category: 'food', amount: 10, paymentMethod: 'DEBIT',
        ),
        throwsA(isA<Exception>()),
      );
    });

    // ─── Delete ────────────────────────────────────────────────────────────────

    test('delete removes expense by id', () async {
      _seed(repo, amount: 100);
      final secondId = _seed(repo, amount: 200);

      await repo.delete(secondId); // secondId is already int

      final all = await repo.getAll();
      expect(all.length, 1);
      expect(all.first.amount, 100);
    });

    test('delete non-existent id does not throw', () async {
      _seed(repo);
      await repo.delete(999);
      final all = await repo.getAll();
      expect(all.length, 1);
    });

    test('delete with shouldThrowNetworkError throws', () async {
      _seed(repo);
      repo.behavior = FakeExpenseBehavior(shouldThrowNetworkError: true);

      await expectLater(repo.delete(1), throwsA(isA<Exception>()));
    });

    // ─── WatchAll ──────────────────────────────────────────────────────────────

    test('watchAll emits from insert', () async {
      // Subscribe first; broadcast stream drops pre-subscription events
      final future = repo.watchAll().first;
      await repo.insert(
        transactionDate: DateTime(2026, 5, 1),
        month: 5, year: 2026,
        payType: 'Cash', category: 'food', amount: 10, paymentMethod: 'DEBIT',
      );

      final emitted = await future;
      expect(emitted.length, 1);
    });

    // ─── UpdateFixedSeriesFrom ────────────────────────────────────────────────

    test('updateFixedSeriesFrom updates future fixed expenses with same category/payment/description', () async {
      final fromId = repo.seedExpense(
        userId: 'user-1',
        month: 5, year: 2026,
        transactionDate: DateTime(2026, 5, 15),
        payType: 'Cash', category: 'food', amount: 50.0, paymentMethod: 'DEBIT',
        isFixed: true, storeDescription: 'Mercado',
      );
      repo.seedExpense(
        userId: 'user-1',
        month: 6, year: 2026,
        transactionDate: DateTime(2026, 6, 15),
        payType: 'Cash', category: 'food', amount: 50.0, paymentMethod: 'DEBIT',
        isFixed: true, storeDescription: 'Mercado',
      );
      repo.seedExpense(
        userId: 'user-1',
        month: 6, year: 2026,
        transactionDate: DateTime(2026, 6, 10),
        payType: 'Cash', category: 'transport', amount: 100.0, paymentMethod: 'DEBIT',
        isFixed: true, storeDescription: 'Uber',
      );

      final all = await repo.getAll();
      final fromExpense = all.firstWhere((e) => e.id == fromId);

      await repo.updateFixedSeriesFrom(
        fromExpense,
        amount: 60.0,
        category: 'food',
        paymentMethod: 'DEBIT',
        storeDescription: 'Mercado Novo',
      );

      final updated = await repo.getAll();
      expect(updated.where((e) => e.category == 'food').every((e) => e.amount == 60.0), isTrue);
      expect(updated.where((e) => e.category == 'transport').first.amount, 100.0);
    });

    test('updateFixedSeriesFrom does not update past expenses', () async {
      repo.seedExpense(
        userId: 'user-1',
        month: 4, year: 2026,
        transactionDate: DateTime(2026, 4, 15),
        payType: 'Cash', category: 'food', amount: 50.0, paymentMethod: 'DEBIT',
        isFixed: true, storeDescription: 'Mercado',
      );
      final fromId = repo.seedExpense(
        userId: 'user-1',
        month: 5, year: 2026,
        transactionDate: DateTime(2026, 5, 15),
        payType: 'Cash', category: 'food', amount: 50.0, paymentMethod: 'DEBIT',
        isFixed: true, storeDescription: 'Mercado',
      );
      final all = await repo.getAll();
      final fromExpense = all.firstWhere((e) => e.id == fromId);

      await repo.updateFixedSeriesFrom(
        fromExpense,
        amount: 60.0,
        category: 'food',
        paymentMethod: 'DEBIT',
      );

      final updated = await repo.getAll();
      expect(updated.any((e) => e.month == 4 && e.amount == 50.0), isTrue);
    });

    // ─── Error recovery ──────────────────────────────────────────────────────

    test('after shouldThrow error, subsequent calls succeed', () async {
      repo.behavior = FakeExpenseBehavior(shouldThrowNetworkError: true);

      await expectLater(
        repo.insert(
          transactionDate: DateTime(2026, 5, 1),
          month: 5, year: 2026,
          payType: 'Cash', category: 'food', amount: 10, paymentMethod: 'DEBIT',
        ),
        throwsA(isA<Exception>()),
      );

      repo.behavior = FakeExpenseBehavior();
      final id = await repo.insert(
        transactionDate: DateTime(2026, 5, 1),
        month: 5, year: 2026,
        payType: 'Cash', category: 'food', amount: 20, paymentMethod: 'DEBIT',
      );

      expect(id, greaterThan(0));
      final all = await repo.getAll();
      expect(all.length, 1);
    });
  });
}
