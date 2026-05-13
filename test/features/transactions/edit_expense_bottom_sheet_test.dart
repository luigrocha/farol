/// Widget tests for [EditExpenseBottomSheet].
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farol/core/models/category.dart';
import 'package:farol/core/models/expense.dart';
import 'package:farol/core/providers/providers.dart';
import 'package:farol/features/transactions/edit_expense_bottom_sheet.dart';

import '../../test_helpers.dart';
import '../../fakes/fake_expense_repository.dart';

final _testCategories = [
  const Category(
    id: 'cat-food',
    slug: 'food_grocery',
    name: 'Supermercado',
    emoji: '🛒',
    financialType: 'need',
    isSystem: false,
    isSwile: false,
    isFixed: false,
    isArchived: false,
    displayOrder: 1,
  ),
  const Category(
    id: 'cat-transport',
    slug: 'transport',
    name: 'Transporte',
    emoji: '🚗',
    financialType: 'need',
    isSystem: false,
    isSwile: false,
    isFixed: false,
    isArchived: false,
    displayOrder: 2,
  ),
];

Expense _makeExpense({
  int id = 1,
  double amount = 100.0,
  String category = 'food_grocery',
  String paymentMethod = 'DEBIT',
  bool isFixed = false,
  int month = 5,
  int year = 2026,
}) {
  return Expense(
    id: id,
    userId: 'user-1',
    month: month,
    year: year,
    transactionDate: DateTime(year, month, 15),
    payType: 'Cash',
    category: category,
    amount: amount,
    paymentMethod: paymentMethod,
    installments: 1,
    isFixed: isFixed,
    createdAt: DateTime.now(),
  );
}

void main() {
  group('EditExpenseBottomSheet', () {
    late FakeExpenseRepository expenseRepo;

    setUp(() {
      expenseRepo = FakeExpenseRepository();
    });

    tearDown(() {
      expenseRepo.dispose();
    });

    Future<void> pumpSheet(WidgetTester tester, Expense expense) async {
      await pumpAppWithFakeAuth(
        tester,
        EditExpenseBottomSheet(expense: expense),
        extraOverrides: [
          categoriesStreamProvider.overrideWith(
            (ref) => Stream.value(_testCategories),
          ),
          expenseRepositoryProvider.overrideWithValue(expenseRepo),
        ],
      );
      await tester.pump();
    }

    // ─── Rendering ─────────────────────────────────────────────────────

    testWidgets('loads existing amount into text field', (tester) async {
      await pumpSheet(tester, _makeExpense(amount: 250.0));
      await tester.pump();

      final amountField = find.byType(TextField).first;
      expect(
        (amountField.evaluate().single.widget as TextField).controller?.text,
        contains('250'),
      );
    });

    testWidgets('shows edit expense title', (tester) async {
      await pumpSheet(tester, _makeExpense());
      expect(find.text('Edit Expense'), findsOneWidget);
    });

    testWidgets('shows category grid', (tester) async {
      await pumpSheet(tester, _makeExpense());
      expect(find.text('🛒 Supermercado'), findsOneWidget);
      expect(find.text('🚗 Transporte'), findsOneWidget);
    });

    testWidgets('shows payment method chips', (tester) async {
      await pumpSheet(tester, _makeExpense());
      expect(find.text('PIX'), findsWidgets);
    });

    testWidgets('shows save button', (tester) async {
      await pumpSheet(tester, _makeExpense());
      expect(find.text('SAVE'), findsOneWidget);
    });

    // ─── Edit & Save ───────────────────────────────────────────────────

    testWidgets('save updates expense in repository', (tester) async {
      final eid = expenseRepo.seedExpense(
        userId: 'user-1',
        month: 5, year: 2026,
        transactionDate: DateTime(2026, 5, 15),
        payType: 'Cash', category: 'food_grocery', amount: 100.0,
        paymentMethod: 'DEBIT',
      );

      await pumpSheet(tester, _makeExpense(id: eid, amount: 100.0));
      await tester.pump();

      final amountField = find.byType(TextField).first;
      await tester.tap(amountField);
      await tester.enterText(amountField, '175,50');
      await tester.pump();

      await tester.ensureVisible(find.text('SAVE'));
      await tester.pump();
      await tester.tap(find.text('SAVE'));
      await tester.pump();

      final all = await expenseRepo.getAll();
      expect(all.length, 1);
      expect(all.first.amount, 175.50);
    });

    testWidgets('save with different category updates category', (tester) async {
      final eid = expenseRepo.seedExpense(
        userId: 'user-1',
        month: 5, year: 2026,
        transactionDate: DateTime(2026, 5, 15),
        payType: 'Cash', category: 'food_grocery', amount: 100.0,
        paymentMethod: 'DEBIT',
      );

      await pumpSheet(tester, _makeExpense(id: eid, amount: 100.0));
      await tester.pump();

      await tester.tap(find.text('🚗 Transporte'));
      await tester.pump();

      await tester.ensureVisible(find.text('SAVE'));
      await tester.pump();
      await tester.tap(find.text('SAVE'));
      await tester.pump();

      final all = await expenseRepo.getAll();
      expect(all.first.category, 'transport');
    });

    // ─── Fixed expense propagation ─────────────────────────────────────

    testWidgets('shows scope dialog for fixed expense', (tester) async {
      final eid = expenseRepo.seedExpense(
        userId: 'user-1',
        month: 5, year: 2026,
        transactionDate: DateTime(2026, 5, 15),
        payType: 'Cash', category: 'food_grocery', amount: 100.0,
        paymentMethod: 'DEBIT', isFixed: true,
      );
      final expense = _makeExpense(id: eid, amount: 100.0, isFixed: true);

      await pumpSheet(tester, expense);

      await tester.ensureVisible(find.text('SAVE'));
      await tester.pump();
      await tester.tap(find.text('SAVE'));
      await tester.pump();

      expect(find.text('Só este mês'), findsOneWidget);
      expect(find.text('Este e todos os futuros'), findsOneWidget);
    });

    // ─── Error handling ────────────────────────────────────────────────

    testWidgets('network error shows snackbar', (tester) async {
      final eid = expenseRepo.seedExpense(
        userId: 'user-1',
        month: 5, year: 2026,
        transactionDate: DateTime(2026, 5, 15),
        payType: 'Cash', category: 'food_grocery', amount: 100.0,
        paymentMethod: 'DEBIT',
      );
      expenseRepo.behavior = FakeExpenseBehavior(shouldThrowNetworkError: true);

      await pumpSheet(tester, _makeExpense(id: eid, amount: 100.0));

      await tester.ensureVisible(find.text('SAVE'));
      await tester.pump();
      await tester.tap(find.text('SAVE'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
