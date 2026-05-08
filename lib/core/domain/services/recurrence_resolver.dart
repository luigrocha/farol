import '../entities/recurring_rule.dart';
import '../entities/recurring_occurrence.dart';

/// Generates [RecurringOccurrence] instances from a [RecurringRule] for a
/// given date range. Pure Dart — no I/O, no Riverpod. Fully testable.
class RecurrenceResolver {
  const RecurrenceResolver();

  /// Returns all occurrences of [rule] whose scheduled_date falls within
  /// [rangeStart]..[rangeEnd] (inclusive).
  ///
  /// Respects:
  ///   - [RecurringRule.endsOn]
  ///   - [RecurringRule.endsAfterN] (counts from the very first occurrence,
  ///     not from rangeStart)
  ///   - [RecurringRule.pausedUntil] (skips dates while paused)
  ///   - Day-of-month clamping (e.g. day 31 → last day of Feb)
  List<RecurringOccurrence> generateOccurrences(
    RecurringRule rule, {
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    if (rule.status == RecurringStatus.cancelled) return [];
    if (rule.endsOn != null && rangeStart.isAfter(rule.endsOn!)) return [];

    final occurrences = <RecurringOccurrence>[];
    int totalGenerated = 0;

    // Walk from the first occurrence on or after rule.startsOn
    DateTime cursor = _firstOccurrence(rule);

    while (!cursor.isAfter(rangeEnd)) {
      // Hard stop: rule ended
      if (rule.endsOn != null && cursor.isAfter(rule.endsOn!)) break;

      // Hard stop: N-occurrence limit (counts all occurrences, not just in range)
      if (rule.endsAfterN != null && totalGenerated >= rule.endsAfterN!) break;

      totalGenerated++;

      // Only collect if within requested range
      if (!cursor.isBefore(rangeStart)) {
        // Skip if rule is paused and cursor is within the pause window
        final isPaused = rule.isPaused &&
            rule.pausedUntil != null &&
            !cursor.isAfter(rule.pausedUntil!);

        if (!isPaused) {
          occurrences.add(RecurringOccurrence(
            id: '',
            ruleId: rule.id,
            userId: rule.userId,
            scheduledDate: cursor,
            expectedAmount: rule.baseAmount,
            status: OccurrenceStatus.pending,
            createdAt: DateTime.now(),
          ));
        }
      }

      cursor = _nextDate(rule, cursor);
    }

    return occurrences;
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// The first occurrence date (on or after [rule.startsOn]).
  DateTime _firstOccurrence(RecurringRule rule) {
    final start = rule.startsOn;
    return switch (rule.frequency) {
      RecurringFrequency.weekly ||
      RecurringFrequency.biweekly =>
        start,
      RecurringFrequency.monthly ||
      RecurringFrequency.quarterly ||
      RecurringFrequency.semiannual ||
      RecurringFrequency.yearly =>
        _clampToMonth(
          start.year,
          start.month,
          rule.dayOfMonth ?? start.day,
        ),
    };
  }

  /// The next occurrence after [current].
  DateTime _nextDate(RecurringRule rule, DateTime current) {
    final n = rule.intervalCount;
    return switch (rule.frequency) {
      RecurringFrequency.weekly => current.add(Duration(days: 7 * n)),
      RecurringFrequency.biweekly => current.add(Duration(days: 14 * n)),
      RecurringFrequency.monthly => _addMonths(current, 1 * n, rule.dayOfMonth),
      RecurringFrequency.quarterly =>
        _addMonths(current, 3 * n, rule.dayOfMonth),
      RecurringFrequency.semiannual =>
        _nextSemiannual(current, rule.monthsOfYear, rule.dayOfMonth),
      RecurringFrequency.yearly => _addMonths(current, 12 * n, rule.dayOfMonth),
    };
  }

  /// Adds [months] to [date], preserving the intended [targetDay] and clamping
  /// to the last valid day of the resulting month.
  DateTime _addMonths(DateTime date, int months, int? targetDay) {
    final day = targetDay ?? date.day;
    final totalMonths = date.year * 12 + (date.month - 1) + months;
    final year = totalMonths ~/ 12;
    final month = (totalMonths % 12) + 1;
    return _clampToMonth(year, month, day);
  }

  /// Returns a date clamped to the last valid day of [year]/[month].
  DateTime _clampToMonth(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day.clamp(1, lastDay));
  }

  /// Semiannual: advances to the next month in [monthsOfYear] (e.g. [1, 7]).
  /// Falls back to +6 months if monthsOfYear is null/empty.
  DateTime _nextSemiannual(
      DateTime current, List<int>? monthsOfYear, int? dayOfMonth) {
    if (monthsOfYear == null || monthsOfYear.isEmpty) {
      return _addMonths(current, 6, dayOfMonth);
    }

    final sorted = [...monthsOfYear]..sort();
    final day = dayOfMonth ?? current.day;

    // Find the next month in the list after current.month
    for (final m in sorted) {
      if (m > current.month) {
        return _clampToMonth(current.year, m, day);
      }
    }
    // Wrap to next year, first month in list
    return _clampToMonth(current.year + 1, sorted.first, day);
  }
}
