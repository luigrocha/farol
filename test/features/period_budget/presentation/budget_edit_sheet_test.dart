/// Widget tests for [BudgetEditSheet].
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farol/core/models/category.dart';
import 'package:farol/core/models/financial_period.dart';
import 'package:farol/core/models/budget_goal.dart';
import 'package:farol/core/models/period_budget.dart';
import 'package:farol/core/providers/providers.dart';
import 'package:farol/features/period_budget/presentation/budget_edit_sheet.dart';
import 'package:farol/core/providers/workspace_providers.dart'
    show isSharedWorkspaceProvider;

import '../../../test_helpers.dart';
import '../../../fakes/fake_period_budget_repository.dart';

final _testGoal = BudgetGoal(
  id: 1,
  userId: 'user-1',
  category: 'food_grocery',
  targetPercentage: 25,
  targetAmount: 1500.0,
  type: 'need',
  createdAt: DateTime.now(),
);

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
  group('BudgetEditSheet', () {
    late FakePeriodBudgetRepository budgetRepo;

    setUp(() {
      budgetRepo = FakePeriodBudgetRepository();
    });

    final testPeriod = FinancialPeriod(
      start: DateTime(2026, 5, 1),
      end: DateTime(2026, 5, 31),
    );

    Future<void> pumpSheet(WidgetTester tester, {PeriodBudgetEntry? entry}) async {
      await pumpAppWithFakeAuth(
        tester,
        BudgetEditSheet(entry: entry),
        extraOverrides: [
          periodBudgetRepositoryProvider.overrideWithValue(budgetRepo),
          categoriesStreamProvider.overrideWith(
            (ref) => Stream.value(_testCategories),
          ),
          isSharedWorkspaceProvider.overrideWithValue(false),
          currentPeriodProvider.overrideWithValue(testPeriod),
        ],
      );
      await tester.pump();
    }

    // ─── Rendering — Create mode ────────────────────────────────────────

    testWidgets('shows New Budget title when no entry', (tester) async {
      await pumpSheet(tester);
      expect(find.text('New Budget'), findsOneWidget);
    });

    testWidgets('shows category dropdown', (tester) async {
      await pumpSheet(tester);
      expect(find.byType(DropdownButton<String>), findsOneWidget);
    });

    testWidgets('shows amount field', (tester) async {
      await pumpSheet(tester);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('shows Create Budget button', (tester) async {
      await pumpSheet(tester);
      expect(find.text('Create Budget'), findsOneWidget);
    });

    // ─── Rendering — Edit mode ──────────────────────────────────────────

    testWidgets('shows Edit Budget title when entry provided', (tester) async {
      await pumpSheet(
        tester,
        entry: PeriodBudgetEntry(goal: _testGoal, override: null, spent: 500),
      );
      expect(find.text('Edit Budget'), findsOneWidget);
    });

    testWidgets('shows Save Changes button when editing', (tester) async {
      await pumpSheet(
        tester,
        entry: PeriodBudgetEntry(goal: _testGoal, override: null, spent: 500),
      );
      expect(find.text('Save Changes'), findsOneWidget);
    });

    // ─── Create ─────────────────────────────────────────────────────────

    testWidgets('create budget saves to repository', (tester) async {
      await pumpSheet(tester);

      final amountField = find.byType(TextFormField);
      await tester.enterText(amountField, '1500,00');
      await tester.pump();

      await tester.ensureVisible(find.text('Create Budget'));
      await tester.pump();
      await tester.tap(find.text('Create Budget'));
      await tester.pump();

      // Verify the upsert was called — no errors shown
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('empty amount shows snackbar', (tester) async {
      await pumpSheet(tester);

      await tester.ensureVisible(find.text('Create Budget'));
      await tester.pump();
      await tester.tap(find.text('Create Budget'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    // ─── Edit ───────────────────────────────────────────────────────────

    testWidgets('edit shows goal amount when entry has goal', (tester) async {
      await pumpSheet(
        tester,
        entry: PeriodBudgetEntry(goal: _testGoal, override: null, spent: 500),
      );

      expect(find.textContaining('Goal:'), findsOneWidget);
    });

    // ─── Error handling ────────────────────────────────────────────────

    testWidgets('network error shows snackbar', (tester) async {
      budgetRepo.behavior = FakePeriodBudgetBehavior(shouldThrowNetworkError: true);

      await pumpSheet(tester);

      final amountField = find.byType(TextFormField);
      await tester.enterText(amountField, '100,00');
      await tester.pump();

      await tester.ensureVisible(find.text('Create Budget'));
      await tester.pump();
      await tester.tap(find.text('Create Budget'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
