import '../entities/recurring_rule.dart';
import '../entities/recurring_occurrence.dart';
import '../../repositories/recurring_rules_repository.dart';
import '../../repositories/recurring_occurrences_repository.dart';
import '../../repositories/expense_repository.dart';
import 'recurrence_resolver.dart';

/// Orchestrates recurring rule lifecycle: generating occurrences, paying,
/// and skipping. Injected via Riverpod.
class RecurringService {
  final RecurringRulesRepository _rulesRepo;
  final RecurringOccurrencesRepository _occurrencesRepo;
  final ExpenseRepository _expenseRepo;
  final RecurrenceResolver _resolver;

  const RecurringService({
    required RecurringRulesRepository rulesRepo,
    required RecurringOccurrencesRepository occurrencesRepo,
    required ExpenseRepository expenseRepo,
    RecurrenceResolver resolver = const RecurrenceResolver(),
  })  : _rulesRepo = rulesRepo,
        _occurrencesRepo = occurrencesRepo,
        _expenseRepo = expenseRepo,
        _resolver = resolver;

  // ── CRUD ─────────────────────────────────────────────────────────────────

  Future<RecurringRule> createRule(RecurringRule rule) async {
    final created = await _rulesRepo.create(rule);
    await _generateUpcoming(created);
    return created;
  }

  Future<RecurringRule> updateRule(String id, RecurringRule rule) async {
    final updated = await _rulesRepo.update(id, rule);
    await _generateUpcoming(updated);
    return updated;
  }

  Future<void> pauseRule(String id, {DateTime? until}) =>
      _rulesRepo.updateStatus(id, RecurringStatus.paused, pausedUntil: until);

  Future<void> resumeRule(String id) =>
      _rulesRepo.updateStatus(id, RecurringStatus.active);

  Future<void> cancelRule(String id) =>
      _rulesRepo.updateStatus(id, RecurringStatus.cancelled);

  Future<void> deleteRule(String id) => _rulesRepo.delete(id);

  // ── Pay / Skip ────────────────────────────────────────────────────────────

  /// Marks an occurrence as paid and creates the linked Expense.
  Future<RecurringOccurrence> payOccurrence({
    required RecurringOccurrence occurrence,
    required RecurringRule rule,
    DateTime? paidDate,
    double? actualAmount,
  }) async {
    final date = paidDate ?? occurrence.scheduledDate;
    final amount = actualAmount ?? occurrence.expectedAmount;

    final expenseId = await _expenseRepo.insert(
      transactionDate: date,
      month: date.month,
      year: date.year,
      payType: rule.paymentMethod ?? 'Cash',
      category: rule.categorySlug ?? 'other',
      amount: amount,
      paymentMethod: rule.paymentMethod ?? 'Cash',
      storeDescription: rule.name,
      recurringRuleId: rule.id,
      recurringOccurrenceId: occurrence.id,
    );

    return _occurrencesRepo.markPaid(
      id: occurrence.id,
      paidDate: date,
      actualAmount: amount,
      expenseId: expenseId,
    );
  }

  Future<RecurringOccurrence> skipOccurrence(
      RecurringOccurrence occurrence, {String? notes}) =>
      _occurrencesRepo.markSkipped(occurrence.id, notes: notes);

  // ── Occurrence generation job ─────────────────────────────────────────────

  /// Generates occurrences for the next [monthsAhead] months for all active
  /// rules. Safe to call multiple times — idempotent via ON CONFLICT DO NOTHING.
  Future<int> generateUpcomingOccurrences({int monthsAhead = 3}) async {
    final rules = await _rulesRepo.getActive();
    int total = 0;
    for (final rule in rules) {
      final count = await _generateUpcoming(rule, monthsAhead: monthsAhead);
      total += count;
    }
    return total;
  }

  Future<int> _generateUpcoming(RecurringRule rule,
      {int monthsAhead = 3}) async {
    final now = DateTime.now();
    final rangeStart = DateTime(now.year, now.month, 1);
    final rangeEnd = DateTime(now.year, now.month + monthsAhead + 1, 0);

    final occurrences = _resolver.generateOccurrences(
      rule,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
    if (occurrences.isEmpty) return 0;
    await _occurrencesRepo.upsertOccurrences(occurrences);
    return occurrences.length;
  }
}
