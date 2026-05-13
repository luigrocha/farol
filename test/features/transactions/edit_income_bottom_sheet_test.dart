/// Widget tests for [EditIncomeBottomSheet].
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farol/core/models/income.dart';
import 'package:farol/core/providers/providers.dart';
import 'package:farol/features/transactions/edit_income_bottom_sheet.dart';

import '../../test_helpers.dart';
import '../../fakes/fake_income_repository.dart';

Income _makeIncome({
  int id = 1,
  double amount = 5000.0,
  String incomeType = 'NET_SALARY',
  bool isNet = true,
  double? inssDeducted,
  double? irrfDeducted,
  String? notes,
  int month = 5,
  int year = 2026,
}) {
  return Income(
    id: id,
    userId: 'user-1',
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
}

void main() {
  group('EditIncomeBottomSheet', () {
    late FakeIncomeRepository incomeRepo;

    setUp(() {
      incomeRepo = FakeIncomeRepository();
    });

    tearDown(() {
      incomeRepo.dispose();
    });

    Future<void> pumpSheet(WidgetTester tester, Income income) async {
      await pumpAppWithFakeAuth(
        tester,
        EditIncomeBottomSheet(income: income),
        extraOverrides: [
          incomeRepositoryProvider.overrideWithValue(incomeRepo),
        ],
      );
      await tester.pump();
    }

    // ─── Rendering ─────────────────────────────────────────────────────

    testWidgets('loads existing amount into text field', (tester) async {
      await pumpSheet(tester, _makeIncome(amount: 5000.0));

      final amountField = find.byType(TextField).first;
      expect(
        (amountField.evaluate().single.widget as TextField).controller?.text,
        contains('5000'),
      );
    });

    testWidgets('shows edit income title', (tester) async {
      await pumpSheet(tester, _makeIncome());
      expect(find.text('Edit Income'), findsOneWidget);
    });

    testWidgets('shows income type chips', (tester) async {
      await pumpSheet(tester, _makeIncome(incomeType: 'NET_SALARY'));
      expect(find.textContaining('Net Salary'), findsOneWidget);
      expect(find.textContaining('Bonus'), findsOneWidget);
    });

    testWidgets('shows net value toggle', (tester) async {
      await pumpSheet(tester, _makeIncome());
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('shows notes field', (tester) async {
      await pumpSheet(tester, _makeIncome(notes: 'Monthly salary'));
      final notesField = find.byType(TextField).last;
      expect(
        (notesField.evaluate().single.widget as TextField).controller?.text,
        'Monthly salary',
      );
    });

    testWidgets('shows save button', (tester) async {
      await pumpSheet(tester, _makeIncome());
      expect(find.text('Save changes'), findsOneWidget);
    });

    // ─── Edit & Save ───────────────────────────────────────────────────

    testWidgets('save updates income in repository', (tester) async {
      final iid = incomeRepo.seedIncome(
        id: 1,
        userId: 'user-1',
        month: 5, year: 2026,
        incomeType: 'NET_SALARY', amount: 5000.0,
      );

      await pumpSheet(tester, _makeIncome(id: iid, amount: 5000.0));

      final amountField = find.byType(TextField).first;
      await tester.tap(amountField);
      await tester.enterText(amountField, '5500,00');
      await tester.pump();

      await tester.tap(find.text('Save changes'));
      await tester.pump();

      final all = await incomeRepo.getAll();
      expect(all.length, 1);
      expect(all.first.amount, 5500.00);
    });

    testWidgets('save with notes updates notes', (tester) async {
      final iid = incomeRepo.seedIncome(
        id: 1,
        userId: 'user-1',
        month: 5, year: 2026,
        incomeType: 'NET_SALARY', amount: 5000.0,
      );

      await pumpSheet(tester, _makeIncome(id: iid, amount: 5000.0));

      final notesField = find.byType(TextField).last;
      await tester.tap(notesField);
      await tester.enterText(notesField, 'Updated salary');
      await tester.pump();

      await tester.tap(find.text('Save changes'));
      await tester.pump();

      final all = await incomeRepo.getAll();
      expect(all.first.notes, 'Updated salary');
    });

    // ─── Net salary calculation ────────────────────────────────────────

    testWidgets('shows salary calculation for NET_SALARY type', (tester) async {
      await pumpSheet(tester, _makeIncome(incomeType: 'NET_SALARY'));
      expect(find.text('Calculate net'), findsOneWidget);
    });

    testWidgets('does not show salary calculation for other types', (tester) async {
      await pumpSheet(tester, _makeIncome(incomeType: 'BONUS'));
      expect(find.text('Calculate net'), findsNothing);
    });

    testWidgets('shows breakdown when income has inss/irrf values', (tester) async {
      await pumpSheet(tester, _makeIncome(
        incomeType: 'NET_SALARY',
        amount: 3500.0,
        inssDeducted: 500.0,
        irrfDeducted: 300.0,
      ));

      expect(find.text('Salary Breakdown'), findsOneWidget);
      expect(find.text('INSS'), findsOneWidget);
      expect(find.text('IRRF'), findsOneWidget);
      expect(find.text('Use net value'), findsOneWidget);
    });

    // ─── Error handling ────────────────────────────────────────────────

    testWidgets('invalid amount shows snackbar', (tester) async {
      await pumpSheet(tester, _makeIncome());

      final amountField = find.byType(TextField).first;
      await tester.tap(amountField);
      await tester.enterText(amountField, '');
      await tester.pump();

      await tester.tap(find.text('Save changes'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('network error shows snackbar', (tester) async {
      final iid = incomeRepo.seedIncome(
        id: 1,
        userId: 'user-1',
        month: 5, year: 2026,
        incomeType: 'NET_SALARY', amount: 5000.0,
      );
      incomeRepo.behavior = FakeIncomeBehavior(shouldThrowNetworkError: true);

      await pumpSheet(tester, _makeIncome(id: iid, amount: 5000.0));

      await tester.tap(find.text('Save changes'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
