import 'package:flutter_test/flutter_test.dart';
import 'package:farol/core/domain/services/envelope_engine.dart';
import 'package:farol/core/domain/entities/envelope.dart';
import 'package:farol/core/domain/value_objects/category_ref.dart';
import 'package:farol/core/models/period_budget.dart';
import 'package:farol/core/models/expense.dart';
import 'package:farol/core/models/financial_period.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

PeriodBudget _budget(String category, double amount) => PeriodBudget(
      id: 'b-$category',
      userId: 'u',
      category: category,
      periodStart: DateTime(2026, 4, 1),
      periodEnd: DateTime(2026, 4, 30),
      amount: amount,
      isCustom: false,
      createdAt: DateTime(2026, 4, 1),
      updatedAt: DateTime(2026, 4, 1),
    );

PeriodBudgetEntry _entry(String category, double amount, {double spent = 0}) =>
    PeriodBudgetEntry(
      goal: null,
      override: _budget(category, amount),
      spent: spent,
    );

Expense _cashExpense(String category, double amount, DateTime date) => Expense(
      id: 1,
      userId: 'u',
      month: date.month,
      year: date.year,
      transactionDate: date,
      payType: 'Cash',
      category: category,
      amount: amount,
      paymentMethod: 'pix',
      createdAt: date,
    );

FinancialPeriod _prevPeriod() =>
    FinancialPeriod.current(1, now: DateTime(2026, 4, 15));

Map<String, CategoryRef> _catMap(List<String> slugs) => {
      for (final s in slugs)
        s: CategoryRef(id: s, slug: s, name: s, emoji: '📋'),
    };

void main() {
  const engine = EnvelopeEngine();

  // ── Basic envelope creation ─────────────────────────────────────────────────

  group('EnvelopeEngine — basic', () {
    test('creates one envelope per entry', () {
      final entries = [_entry('food', 500), _entry('transport', 200)];
      final envelopes = engine.buildEnvelopes(
        entries: entries,
        categoriesBySlug: _catMap(['food', 'transport']),
        previousExpenses: [],
        previousPeriod: _prevPeriod(),
      );
      expect(envelopes.length, 2);
    });

    test('envelope allocated matches entry amount', () {
      final envelopes = engine.buildEnvelopes(
        entries: [_entry('food', 800)],
        categoriesBySlug: _catMap(['food']),
        previousExpenses: [],
        previousPeriod: _prevPeriod(),
      );
      expect(envelopes.first.allocated.amount, 800);
    });

    test('envelope spent matches entry spent', () {
      final envelopes = engine.buildEnvelopes(
        entries: [_entry('food', 800, spent: 350)],
        categoriesBySlug: _catMap(['food']),
        previousExpenses: [],
        previousPeriod: _prevPeriod(),
      );
      expect(envelopes.first.spent.amount, 350);
    });

    test('unknown slug resolves to uncategorized CategoryRef', () {
      final envelopes = engine.buildEnvelopes(
        entries: [_entry('rare_category', 100)],
        categoriesBySlug: {},
        previousExpenses: [],
        previousPeriod: _prevPeriod(),
      );
      expect(envelopes.first.category.slug, 'rare_category');
    });
  });

  // ── Rollover ────────────────────────────────────────────────────────────────

  group('EnvelopeEngine — rollover', () {
    test('rollover = previous surplus (allocated - spent)', () {
      final prev = _prevPeriod();
      final expense =
          _cashExpense('food', 300, prev.start.add(const Duration(days: 5)));
      final envelopes = engine.buildEnvelopes(
        entries: [_entry('food', 500)],
        categoriesBySlug: _catMap(['food']),
        previousExpenses: [expense],
        previousPeriod: prev,
      );
      // previousSpent=300, goalAmount=500 → surplus=200 → rollover=200
      expect(envelopes.first.rolloverAmount.amount, closeTo(200, 0.01));
    });

    test('no rollover when previous period was overspent', () {
      final prev = _prevPeriod();
      final expense =
          _cashExpense('food', 700, prev.start.add(const Duration(days: 5)));
      final envelopes = engine.buildEnvelopes(
        entries: [_entry('food', 500)],
        categoriesBySlug: _catMap(['food']),
        previousExpenses: [expense],
        previousPeriod: prev,
      );
      expect(envelopes.first.rolloverAmount.amount, 0);
    });

    test('rollover = full allocation when previous expenses are zero', () {
      // With no spending in previous period, the entire budget surplus carries forward
      final envelopes = engine.buildEnvelopes(
        entries: [_entry('food', 500)],
        categoriesBySlug: _catMap(['food']),
        previousExpenses: [],
        previousPeriod: _prevPeriod(),
      );
      expect(envelopes.first.rolloverAmount.amount, closeTo(500, 0.01));
    });

    test('effectiveAllocated = allocated + rollover', () {
      final prev = _prevPeriod();
      final expense =
          _cashExpense('food', 200, prev.start.add(const Duration(days: 5)));
      final envelopes = engine.buildEnvelopes(
        entries: [_entry('food', 500)],
        categoriesBySlug: _catMap(['food']),
        previousExpenses: [expense],
        previousPeriod: prev,
      );
      // allocated=500, goalAmount=500, prevSpent=200, rollover=300
      expect(envelopes.first.effectiveAllocated.amount, closeTo(800, 0.01));
    });

    test('Swile expenses are excluded from rollover calculation', () {
      final prev = _prevPeriod();
      final swileExpense = Expense(
        id: 1,
        userId: 'u',
        month: prev.start.month,
        year: prev.start.year,
        transactionDate: prev.start.add(const Duration(days: 3)),
        payType: 'Swile',
        category: 'food',
        amount: 400,
        paymentMethod: 'swile',
        createdAt: prev.start,
      );
      final envelopes = engine.buildEnvelopes(
        entries: [_entry('food', 500)],
        categoriesBySlug: _catMap(['food']),
        previousExpenses: [swileExpense],
        previousPeriod: prev,
      );
      // Swile excluded → prevSpent=0 → rollover=500
      expect(envelopes.first.rolloverAmount.amount, closeTo(500, 0.01));
    });

    test('projected expenses are excluded from rollover calculation', () {
      final prev = _prevPeriod();
      final projected = Expense(
        id: 1,
        userId: 'u',
        month: prev.start.month,
        year: prev.start.year,
        transactionDate: prev.start.add(const Duration(days: 3)),
        payType: 'Cash',
        category: 'food',
        amount: 400,
        paymentMethod: 'pix',
        createdAt: prev.start,
        isProjected: true,
      );
      final envelopes = engine.buildEnvelopes(
        entries: [_entry('food', 500)],
        categoriesBySlug: _catMap(['food']),
        previousExpenses: [projected],
        previousPeriod: prev,
      );
      // Projected excluded → prevSpent=0 → rollover=500
      expect(envelopes.first.rolloverAmount.amount, closeTo(500, 0.01));
    });
  });

  // ── Envelope status ─────────────────────────────────────────────────────────
  // Zero out rollover by spending the full allocation in the previous period.

  group('EnvelopeEngine — envelope status', () {
    List<Envelope> envelopesNoRollover(
        String slug, double allocated, double spent) {
      final prev = _prevPeriod();
      // Spend 100% of goal in previous period → surplus=0 → rollover=0
      final prevExpense = _cashExpense(
          slug, allocated, prev.start.add(const Duration(days: 5)));
      return engine.buildEnvelopes(
        entries: [_entry(slug, allocated, spent: spent)],
        categoriesBySlug: _catMap([slug]),
        previousExpenses: [prevExpense],
        previousPeriod: prev,
      );
    }

    test('status is ok when usage < 85%', () {
      final env = envelopesNoRollover('food', 1000, 500).first;
      expect(env.status, EnvelopeStatus.ok);
    });

    test('status is warning when usage >= 85%', () {
      final env = envelopesNoRollover('food', 1000, 900).first;
      expect(env.status, EnvelopeStatus.warning);
    });

    test('status is overspent when spent > allocated', () {
      final env = envelopesNoRollover('food', 1000, 1100).first;
      expect(env.status, EnvelopeStatus.overspent);
    });
  });

  // ── Aggregates ───────────────────────────────────────────────────────────────

  group('EnvelopeEngine — aggregates', () {
    test('totalAllocated sums effectiveAllocated across all envelopes', () {
      final prev = _prevPeriod();
      // Spend full budget in previous period to zero out rollover on both categories
      final prevExpenses = [
        _cashExpense('food', 500, prev.start.add(const Duration(days: 3))),
        _cashExpense('transport', 200, prev.start.add(const Duration(days: 3))),
      ];
      final entries = [_entry('food', 500), _entry('transport', 200)];
      final envelopes = engine.buildEnvelopes(
        entries: entries,
        categoriesBySlug: _catMap(['food', 'transport']),
        previousExpenses: prevExpenses,
        previousPeriod: prev,
      );
      expect(engine.totalAllocated(envelopes).amount, closeTo(700, 0.01));
    });

    test('totalSpent sums spent across all envelopes', () {
      final entries = [
        _entry('food', 500, spent: 300),
        _entry('transport', 200, spent: 150),
      ];
      final envelopes = engine.buildEnvelopes(
        entries: entries,
        categoriesBySlug: _catMap(['food', 'transport']),
        previousExpenses: [],
        previousPeriod: _prevPeriod(),
      );
      expect(engine.totalSpent(envelopes).amount, closeTo(450, 0.01));
    });

    test('empty entries produce empty envelopes list', () {
      final envelopes = engine.buildEnvelopes(
        entries: [],
        categoriesBySlug: {},
        previousExpenses: [],
        previousPeriod: _prevPeriod(),
      );
      expect(envelopes, isEmpty);
      expect(engine.totalAllocated(envelopes).amount, 0);
    });
  });
}
