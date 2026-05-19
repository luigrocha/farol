/// Unit tests for [FakeIncomeRepository].
library;

import 'package:flutter_test/flutter_test.dart';
import '../../test/fakes/fake_income_repository.dart';

void main() {
  group('FakeIncomeRepository', () {
    late FakeIncomeRepository repo;

    setUp(() {
      repo = FakeIncomeRepository();
    });

    tearDown(() {
      repo.dispose();
    });

    // ─── Insert ────────────────────────────────────────────────────────────────

    test('insert creates income', () async {
      await repo.insert(
        month: 5,
        year: 2026,
        incomeType: 'NET_SALARY',
        amount: 5000.0,
        isNet: true,
      );

      final all = await repo.getAll();
      expect(all.length, 1);
      expect(all.first.incomeType, 'NET_SALARY');
      expect(all.first.amount, 5000.0);
      expect(all.first.isNet, true);
    });

    test('insert with all optional fields', () async {
      await repo.insert(
        month: 5,
        year: 2026,
        incomeType: 'BONUS',
        amount: 1000.0,
        isNet: false,
        inssDeducted: 100.0,
        irrfDeducted: 150.0,
        notes: 'Performance bonus',
      );

      final all = await repo.getAll();
      expect(all.length, 1);
      expect(all.first.inssDeducted, 100.0);
      expect(all.first.irrfDeducted, 150.0);
      expect(all.first.notes, 'Performance bonus');
    });

    test('consecutive inserts add multiple incomes', () async {
      await repo.insert(
          month: 5, year: 2026, incomeType: 'NET_SALARY', amount: 5000);
      await repo.insert(
          month: 5, year: 2026, incomeType: 'SWILE_MEAL', amount: 500);

      final all = await repo.getAll();
      expect(all.length, 2);
    });

    test('insert with shouldThrowNetworkError throws', () async {
      repo.behavior = FakeIncomeBehavior(shouldThrowNetworkError: true);

      await expectLater(
        repo.insert(
            month: 5, year: 2026, incomeType: 'NET_SALARY', amount: 5000),
        throwsA(isA<Exception>()),
      );
    });

    test('insert with delay respects the delay', () async {
      repo.behavior =
          FakeIncomeBehavior(delay: const Duration(milliseconds: 50));
      final stopwatch = Stopwatch()..start();

      await repo.insert(
          month: 5, year: 2026, incomeType: 'NET_SALARY', amount: 5000);

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(45));
    });

    // ─── GetAll ────────────────────────────────────────────────────────────────

    test('getAll returns all seeded incomes', () async {
      repo.seedIncome(
          userId: 'user-1',
          month: 5,
          year: 2026,
          incomeType: 'NET_SALARY',
          amount: 5000);
      repo.seedIncome(
          userId: 'user-1',
          month: 5,
          year: 2026,
          incomeType: 'SWILE_MEAL',
          amount: 500);

      final all = await repo.getAll();
      expect(all.length, 2);
    });

    test('getAll returns empty list when no incomes exist', () async {
      final all = await repo.getAll();
      expect(all, isEmpty);
    });

    // ─── GetByRange ────────────────────────────────────────────────────────────

    test('getByRange returns incomes within the month/year range', () async {
      repo.seedIncome(
          userId: 'user-1',
          month: 1,
          year: 2026,
          incomeType: 'NET_SALARY',
          amount: 5000);
      repo.seedIncome(
          userId: 'user-1',
          month: 4,
          year: 2026,
          incomeType: 'BONUS',
          amount: 2000);
      repo.seedIncome(
          userId: 'user-1',
          month: 8,
          year: 2026,
          incomeType: 'NET_SALARY',
          amount: 5000);

      final result = await repo.getByRange(3, 2026, 6, 2026);
      expect(result.length, 1);
      expect(result.first.amount, 2000);
    });

    test('getByRange empty when nothing matches', () async {
      repo.seedIncome(
          userId: 'user-1',
          month: 1,
          year: 2025,
          incomeType: 'NET_SALARY',
          amount: 5000);

      final result = await repo.getByRange(1, 2026, 12, 2026);
      expect(result, isEmpty);
    });

    // ─── Update ────────────────────────────────────────────────────────────────

    test('update modifies income fields in place', () async {
      final id = repo.seedIncome(
        userId: 'user-1',
        month: 5,
        year: 2026,
        incomeType: 'NET_SALARY',
        amount: 5000,
      );

      await repo.update(
        id: id,
        month: 5,
        year: 2026,
        incomeType: 'BONUS',
        amount: 3000,
        isNet: false,
        notes: 'Adjusted',
      );

      final all = await repo.getAll();
      expect(all.length, 1);
      expect(all.first.incomeType, 'BONUS');
      expect(all.first.amount, 3000.0);
      expect(all.first.isNet, false);
      expect(all.first.notes, 'Adjusted');
    });

    test('update with non-existent id throws', () async {
      await expectLater(
        repo.update(
          id: 999,
          month: 5,
          year: 2026,
          incomeType: 'NET_SALARY',
          amount: 5000,
        ),
        throwsA(isA<Exception>()),
      );
    });

    // ─── Delete ────────────────────────────────────────────────────────────────

    test('delete removes income by id', () async {
      final id1 = repo.seedIncome(
          userId: 'user-1',
          month: 5,
          year: 2026,
          incomeType: 'NET_SALARY',
          amount: 5000);
      repo.seedIncome(
          userId: 'user-1',
          month: 5,
          year: 2026,
          incomeType: 'SWILE_MEAL',
          amount: 500);

      await repo.delete(id1);

      final all = await repo.getAll();
      expect(all.length, 1);
      expect(all.first.incomeType, 'SWILE_MEAL');
    });

    test('delete non-existent id does not throw', () async {
      repo.seedIncome(
          userId: 'user-1',
          month: 5,
          year: 2026,
          incomeType: 'NET_SALARY',
          amount: 5000);
      await repo.delete(999);
      expect((await repo.getAll()).length, 1);
    });

    test('delete with shouldThrowNetworkError throws', () async {
      repo.seedIncome(
          userId: 'user-1',
          month: 5,
          year: 2026,
          incomeType: 'NET_SALARY',
          amount: 5000);
      repo.behavior = FakeIncomeBehavior(shouldThrowNetworkError: true);

      await expectLater(repo.delete(1), throwsA(isA<Exception>()));
    });

    // ─── WatchAll ──────────────────────────────────────────────────────────────

    test('watchAll emits from insert', () async {
      final future = repo.watchAll().first;
      await repo.insert(
          month: 5, year: 2026, incomeType: 'NET_SALARY', amount: 5000);

      final emitted = await future;
      expect(emitted.length, 1);
    });

    // ─── SeedId ────────────────────────────────────────────────────────────────

    test('seedIncome with explicit id uses that id', () async {
      final id = repo.seedIncome(
        id: 42,
        userId: 'user-1',
        month: 5,
        year: 2026,
        incomeType: 'NET_SALARY',
        amount: 5000,
      );

      expect(id, 42);
      expect((await repo.getAll()).first.id, 42);
    });

    test('seedIncome auto-increments when no id given', () async {
      final id1 = repo.seedIncome(
          userId: 'user-1', month: 5, year: 2026, incomeType: 'A', amount: 100);
      final id2 = repo.seedIncome(
          userId: 'user-1', month: 5, year: 2026, incomeType: 'B', amount: 200);

      expect(id2, id1 + 1);
    });

    // ─── Error recovery ──────────────────────────────────────────────────────

    test('after shouldThrow error, subsequent calls succeed', () async {
      repo.behavior = FakeIncomeBehavior(shouldThrowNetworkError: true);

      await expectLater(
        repo.insert(
            month: 5, year: 2026, incomeType: 'NET_SALARY', amount: 5000),
        throwsA(isA<Exception>()),
      );

      repo.behavior = FakeIncomeBehavior();
      await repo.insert(
          month: 5, year: 2026, incomeType: 'NET_SALARY', amount: 5000);

      expect((await repo.getAll()).length, 1);
    });
  });
}
