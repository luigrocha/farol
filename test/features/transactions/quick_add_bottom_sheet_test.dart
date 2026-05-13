/// Widget tests for [QuickAddBottomSheet].
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farol/core/models/category.dart';
import 'package:farol/core/providers/providers.dart';
import 'package:farol/features/transactions/quick_add_bottom_sheet.dart';

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

void main() {
  group('QuickAddBottomSheet', () {
    late FakeExpenseRepository expenseRepo;

    setUp(() {
      expenseRepo = FakeExpenseRepository();
    });

    tearDown(() {
      expenseRepo.dispose();
    });

    Future<void> pumpSheet(WidgetTester tester) async {
      await pumpAppWithFakeAuth(
        tester,
        const QuickAddBottomSheet(),
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

    testWidgets('renders amount field', (tester) async {
      await pumpSheet(tester);
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('shows title Add Expense', (tester) async {
      await pumpSheet(tester);
      expect(find.text('Add Expense'), findsOneWidget);
    });

    testWidgets('shows category grid when categories loaded', (tester) async {
      await pumpSheet(tester);

      expect(find.text('🛒 Supermercado'), findsOneWidget);
      expect(find.text('🚗 Transporte'), findsOneWidget);
    });

    testWidgets('shows payment method chips', (tester) async {
      await pumpSheet(tester);

      expect(find.text('PIX'), findsWidgets);
      expect(find.text('Debit'), findsWidgets);
    });

    testWidgets('includes fixed cost toggle', (tester) async {
      await pumpSheet(tester);
      expect(find.text('Fixed Cost'), findsOneWidget);
    });

    testWidgets('includes save button', (tester) async {
      await pumpSheet(tester);
      expect(find.text('SAVE'), findsOneWidget);
    });

    // ─── Validation ────────────────────────────────────────────────────

    testWidgets('empty amount shows snackbar on save', (tester) async {
      await pumpSheet(tester);

      await tester.ensureVisible(find.text('SAVE'));
      await tester.pump();
      await tester.tap(find.text('SAVE'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('shows installment field when Credit (Installments) selected',
        (tester) async {
      await pumpSheet(tester);

      await tester.tap(find.text('Credit (Installments)'));
      await tester.pump();

      expect(find.text('Number of installments'), findsOneWidget);
    });

    // ─── Create Expense ────────────────────────────────────────────────

    testWidgets('create simple expense saves to repository', (tester) async {
      await pumpSheet(tester);

      // Enter amount
      await tester.enterText(
        find.byType(TextField).first,
        '150,00',
      );
      await tester.pump();

      // Tap save
      await tester.ensureVisible(find.text('SAVE'));
      await tester.pump();
      await tester.tap(find.text('SAVE'));
      await tester.pump();

      // Should add to repository
      final all = await expenseRepo.getAll();
      expect(all.length, 1);
      expect(all.first.amount, 150.0);
      expect(all.first.category, 'food_grocery');
    });

    testWidgets('create expense with selected category', (tester) async {
      await pumpSheet(tester);

      await tester.enterText(find.byType(TextField).first, '50,00');
      await tester.pump();

      await tester.tap(find.text('🚗 Transporte'));
      await tester.pump();

      await tester.ensureVisible(find.text('SAVE'));
      await tester.pump();
      await tester.tap(find.text('SAVE'));
      await tester.pump();

      final all = await expenseRepo.getAll();
      expect(all.length, 1);
      expect(all.first.category, 'transport');
    });

    testWidgets('create fixed expense sets isFixed flag', (tester) async {
      await pumpSheet(tester);

      await tester.enterText(find.byType(TextField).first, '99,90');
      await tester.pump();

      // Toggle fixed
      await tester.tap(find.text('Fixed Cost'));
      await tester.pump();

      await tester.ensureVisible(find.text('SAVE'));
      await tester.pump();
      await tester.tap(find.text('SAVE'));
      await tester.pump();

      final all = await expenseRepo.getAll();
      expect(all.length, 1);
      expect(all.first.isFixed, true);
    });

    // ─── Error handling ────────────────────────────────────────────────

    testWidgets('network error shows snackbar', (tester) async {
      expenseRepo.behavior = FakeExpenseBehavior(shouldThrowNetworkError: true);

      await pumpSheet(tester);

      await tester.enterText(find.byType(TextField).first, '50,00');
      await tester.pump();
      await tester.ensureVisible(find.text('SAVE'));
      await tester.pump();
      await tester.tap(find.text('SAVE'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
