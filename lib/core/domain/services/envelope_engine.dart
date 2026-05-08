import '../../models/period_budget.dart';
import '../../models/expense.dart';
import '../../models/financial_period.dart';
import '../entities/envelope.dart';
import '../value_objects/category_ref.dart';
import '../value_objects/money.dart';

/// Converts [PeriodBudgetEntry] list into domain [Envelope] list.
/// Pure service — no Riverpod, no I/O. Fully testable.
class EnvelopeEngine {
  const EnvelopeEngine();

  /// Builds envelopes for the current period.
  ///
  /// [previousExpenses] — all real (non-projected) expenses from the previous
  /// period, used to calculate rollover for categories that carry a surplus.
  List<Envelope> buildEnvelopes({
    required List<PeriodBudgetEntry> entries,
    required Map<String, CategoryRef> categoriesBySlug,
    required List<Expense> previousExpenses,
    required FinancialPeriod previousPeriod,
  }) {
    final prevSpentBySlug = _spentBySlug(previousExpenses, previousPeriod);

    return entries.map((entry) {
      final slug = entry.category.toLowerCase();
      final catRef = categoriesBySlug[slug] ?? CategoryRef.uncategorized(slug);
      final allocated = Money.fromDouble(entry.amount);
      final spent = Money.fromDouble(entry.spent);

      // Rollover: if previous period had a surplus on this category, carry forward.
      final prevAllocated = Money.fromDouble(entry.goalAmount ?? entry.amount);
      final prevSpent = Money.fromDouble(prevSpentBySlug[slug] ?? 0);
      final surplus = prevAllocated - prevSpent;
      final rollover = surplus.isPositive ? surplus : Money.zero;

      return Envelope(
        category: catRef,
        allocated: allocated,
        spent: spent,
        rolloverPolicy: RolloverPolicy.carryForward,
        rolloverAmount: rollover,
      );
    }).toList();
  }

  /// Aggregates cash expenses by category slug for the given period.
  Map<String, double> _spentBySlug(
      List<Expense> expenses, FinancialPeriod period) {
    final result = <String, double>{};
    for (final e in expenses) {
      if (e.isProjected) continue;
      if (e.payType == 'Swile') continue;
      if (!period.contains(e.transactionDate)) continue;
      final slug = e.category.toLowerCase();
      result[slug] = (result[slug] ?? 0) + e.amount;
    }
    return result;
  }

  /// Total amount allocated across all envelopes (effective, including rollover).
  Money totalAllocated(List<Envelope> envelopes) =>
      envelopes.fold(Money.zero, (sum, e) => sum + e.effectiveAllocated);

  /// Total amount spent across all envelopes.
  Money totalSpent(List<Envelope> envelopes) =>
      envelopes.fold(Money.zero, (sum, e) => sum + e.spent);
}
