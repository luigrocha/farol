/// Widget tests for [PeriodBudgetScreen].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farol/core/models/budget_goal.dart';
import 'package:farol/core/models/category.dart';
import 'package:farol/core/models/financial_period.dart';
import 'package:farol/core/models/period_budget.dart';
import 'package:farol/core/providers/providers.dart';
import 'package:farol/features/period_budget/presentation/period_budget_screen.dart';
import 'package:farol/core/providers/workspace_providers.dart'
    show canWriteProvider, isSharedWorkspaceProvider;

import '../../../test_helpers.dart';

final _testPeriod =
    FinancialPeriod(start: DateTime(2026, 5, 1), end: DateTime(2026, 5, 31));

const _testCategory = Category(
  id: 'cat-food',
  slug: 'food_grocery',
  name: 'Supermercado',
  emoji: '🛒',
  financialType: 'need',
);

final _testGoal = BudgetGoal(
  id: 1,
  userId: 'user-1',
  category: 'food_grocery',
  targetPercentage: 25,
  targetAmount: 1500.0,
  type: 'need',
  createdAt: DateTime.now(),
);

PeriodBudgetEntry _makeEntry({
  double spent = 500,
}) {
  return PeriodBudgetEntry(
    goal: _testGoal,
    override: null,
    spent: spent,
  );
}

void main() {
  group('PeriodBudgetScreen', () {
    Future<void> pumpScreen(
      WidgetTester tester, {
      List<PeriodBudgetEntry> entries = const [],
      bool canWrite = true,
    }) async {
      await pumpAppWithFakeAuth(
        tester,
        const PeriodBudgetScreen(),
        extraOverrides: [
          currentPeriodProvider.overrideWithValue(_testPeriod),
          periodBudgetEntriesProvider.overrideWithValue(
            AsyncValue.data(entries),
          ),
          categoriesMapProvider.overrideWithValue(
            {_testCategory.slug: _testCategory},
          ),
          envelopesProvider.overrideWithValue(const []),
          canWriteProvider.overrideWithValue(canWrite),
          isSharedWorkspaceProvider.overrideWithValue(false),
        ],
      );
      await tester.pump();
    }

    // ─── Layout & Period ────────────────────────────────────────────────

    testWidgets('shows period label in app bar', (tester) async {
      await pumpScreen(tester);
      expect(find.textContaining('May'), findsOneWidget);
    });

    testWidgets('shows empty state when no entries', (tester) async {
      await pumpScreen(tester);
      // No entry cards rendered
      expect(find.byIcon(Icons.pie_chart_outline), findsOneWidget);
    });

    // ─── Entry cards ────────────────────────────────────────────────────

    testWidgets('shows entry card for each budget entry', (tester) async {
      await pumpScreen(tester, entries: [
        _makeEntry(spent: 500),
      ]);

      expect(find.text('🛒 Supermercado'), findsOneWidget);
    });

    testWidgets('shows spent and remaining values', (tester) async {
      await pumpScreen(tester, entries: [
        _makeEntry(spent: 500),
      ]);

      // Spent indicator visible
      expect(find.textContaining('500'), findsWidgets);
    });

    testWidgets('shows progress indicator', (tester) async {
      await pumpScreen(tester, entries: [
        _makeEntry(spent: 750),
      ]);

      // Linear progress indicator should exist
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('shows multiple entry cards', (tester) async {
      final goal2 = BudgetGoal(
        id: 2,
        userId: 'user-1',
        category: 'transport',
        targetPercentage: 15,
        targetAmount: 900.0,
        type: 'need',
        createdAt: DateTime.now(),
      );
      const cat2 = Category(
        id: 'cat-transport',
        slug: 'transport',
        name: 'Transporte',
        emoji: '🚗',
        financialType: 'need',
      );

      await pumpAppWithFakeAuth(
        tester,
        const PeriodBudgetScreen(),
        extraOverrides: [
          currentPeriodProvider.overrideWithValue(_testPeriod),
          periodBudgetEntriesProvider.overrideWithValue(
            AsyncValue.data([
              _makeEntry(spent: 500),
              PeriodBudgetEntry(goal: goal2, override: null, spent: 200),
            ]),
          ),
          categoriesMapProvider.overrideWithValue({
            _testCategory.slug: _testCategory,
            cat2.slug: cat2,
          }),
          envelopesProvider.overrideWithValue(const []),
          canWriteProvider.overrideWithValue(true),
          isSharedWorkspaceProvider.overrideWithValue(false),
        ],
      );
      await tester.pump();

      expect(find.text('🛒 Supermercado'), findsOneWidget);
      expect(find.text('🚗 Transporte'), findsOneWidget);
    });

    // ─── FAB visibility ─────────────────────────────────────────────────

    testWidgets('shows FAB when canWrite is true', (tester) async {
      await pumpScreen(tester, canWrite: true);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('hides FAB when canWrite is false', (tester) async {
      await pumpScreen(tester, canWrite: false);
      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });
}
