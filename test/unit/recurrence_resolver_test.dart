import 'package:flutter_test/flutter_test.dart';
import 'package:farol/core/domain/entities/recurring_rule.dart';
import 'package:farol/core/domain/entities/recurring_occurrence.dart';
import 'package:farol/core/domain/services/recurrence_resolver.dart';

RecurringRule _rule({
  RecurringFrequency frequency = RecurringFrequency.monthly,
  DateTime? startsOn,
  DateTime? endsOn,
  int? endsAfterN,
  int? dayOfMonth,
  List<int>? monthsOfYear,
  int intervalCount = 1,
  RecurringStatus status = RecurringStatus.active,
  DateTime? pausedUntil,
}) =>
    RecurringRule(
      id: 'r1',
      userId: 'u1',
      name: 'Test',
      baseAmount: 100,
      frequency: frequency,
      intervalCount: intervalCount,
      startsOn: startsOn ?? DateTime(2026, 1, 10),
      endsOn: endsOn,
      endsAfterN: endsAfterN,
      dayOfMonth: dayOfMonth,
      monthsOfYear: monthsOfYear,
      status: status,
      pausedUntil: pausedUntil,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

const resolver = RecurrenceResolver();

void main() {
  // ── Monthly ───────────────────────────────────────────────────────────────

  group('monthly', () {
    test('generates 12 occurrences for a full year', () {
      final rule = _rule(dayOfMonth: 10);
      final result = resolver.generateOccurrences(
        rule,
        rangeStart: DateTime(2026, 1, 1),
        rangeEnd: DateTime(2026, 12, 31),
      );
      expect(result.length, 12);
      expect(result.first.scheduledDate, DateTime(2026, 1, 10));
      expect(result.last.scheduledDate, DateTime(2026, 12, 10));
    });

    test('all occurrences are on day 10', () {
      final rule = _rule(dayOfMonth: 10);
      final result = resolver.generateOccurrences(
        rule,
        rangeStart: DateTime(2026, 1, 1),
        rangeEnd: DateTime(2026, 6, 30),
      );
      expect(result.every((o) => o.scheduledDate.day == 10), isTrue);
    });

    test('day 31 clamps to last day of month', () {
      final rule = _rule(
        dayOfMonth: 31,
        startsOn: DateTime(2026, 1, 31),
      );
      final result = resolver.generateOccurrences(
        rule,
        rangeStart: DateTime(2026, 1, 1),
        rangeEnd: DateTime(2026, 4, 30),
      );
      final dates = result.map((o) => o.scheduledDate).toList();
      expect(dates[0], DateTime(2026, 1, 31));
      expect(dates[1], DateTime(2026, 2, 28)); // Feb clamp
      expect(dates[2], DateTime(2026, 3, 31));
      expect(dates[3], DateTime(2026, 4, 30));
    });

    test('day 29 in February (non-leap) clamps to 28', () {
      final rule = _rule(
        dayOfMonth: 29,
        startsOn: DateTime(2026, 1, 29),
      );
      final result = resolver.generateOccurrences(
        rule,
        rangeStart: DateTime(2026, 2, 1),
        rangeEnd: DateTime(2026, 2, 28),
      );
      expect(result.length, 1);
      expect(result.first.scheduledDate, DateTime(2026, 2, 28));
    });

    test('day 29 in February (leap year 2028) is 29', () {
      final rule = _rule(
        dayOfMonth: 29,
        startsOn: DateTime(2028, 1, 29),
      );
      final result = resolver.generateOccurrences(
        rule,
        rangeStart: DateTime(2028, 2, 1),
        rangeEnd: DateTime(2028, 2, 29),
      );
      expect(result.length, 1);
      expect(result.first.scheduledDate, DateTime(2028, 2, 29));
    });
  });

  // ── ends_after_n ─────────────────────────────────────────────────────────

  group('endsAfterN', () {
    test('exactly N occurrences returned when range is wide enough', () {
      final rule = _rule(endsAfterN: 6, dayOfMonth: 1);
      final result = resolver.generateOccurrences(
        rule,
        rangeStart: DateTime(2026, 1, 1),
        rangeEnd: DateTime(2026, 12, 31),
      );
      expect(result.length, 6);
    });

    test('fewer than N if range ends before N-th occurrence', () {
      final rule = _rule(endsAfterN: 6, dayOfMonth: 1);
      final result = resolver.generateOccurrences(
        rule,
        rangeStart: DateTime(2026, 1, 1),
        rangeEnd: DateTime(2026, 3, 31),
      );
      expect(result.length, 3);
    });

    test('endsAfterN counts from first occurrence, not from rangeStart', () {
      // Rule starts Jan, we query from Mar. Only 4 remain (of 6 total).
      final rule = _rule(endsAfterN: 6, dayOfMonth: 1);
      final result = resolver.generateOccurrences(
        rule,
        rangeStart: DateTime(2026, 3, 1),
        rangeEnd: DateTime(2026, 12, 31),
      );
      expect(result.length, 4); // Mar, Apr, May, Jun (months 3–6)
    });
  });

  // ── endsOn ────────────────────────────────────────────────────────────────

  group('endsOn', () {
    test('no occurrences after endsOn', () {
      final rule = _rule(
        dayOfMonth: 1,
        endsOn: DateTime(2026, 3, 31),
      );
      final result = resolver.generateOccurrences(
        rule,
        rangeStart: DateTime(2026, 1, 1),
        rangeEnd: DateTime(2026, 12, 31),
      );
      expect(result.length, 3); // Jan, Feb, Mar
    });
  });

  // ── Paused ────────────────────────────────────────────────────────────────

  group('paused', () {
    test('skips occurrences while paused', () {
      final rule = _rule(
        dayOfMonth: 1,
        status: RecurringStatus.paused,
        pausedUntil: DateTime(2026, 2, 28),
      );
      final result = resolver.generateOccurrences(
        rule,
        rangeStart: DateTime(2026, 1, 1),
        rangeEnd: DateTime(2026, 4, 30),
      );
      // Jan 1 and Feb 1 are within pause; Mar 1 and Apr 1 are after
      expect(result.length, 2);
      expect(result.first.scheduledDate, DateTime(2026, 3, 1));
      expect(result.last.scheduledDate, DateTime(2026, 4, 1));
    });
  });

  // ── Cancelled ─────────────────────────────────────────────────────────────

  group('cancelled', () {
    test('returns empty list for cancelled rule', () {
      final rule = _rule(status: RecurringStatus.cancelled);
      final result = resolver.generateOccurrences(
        rule,
        rangeStart: DateTime(2026, 1, 1),
        rangeEnd: DateTime(2026, 12, 31),
      );
      expect(result, isEmpty);
    });
  });

  // ── Semiannual ────────────────────────────────────────────────────────────

  group('semiannual', () {
    test('2 occurrences per year with monthsOfYear [1, 7]', () {
      final rule = _rule(
        frequency: RecurringFrequency.semiannual,
        startsOn: DateTime(2026, 1, 15),
        dayOfMonth: 15,
        monthsOfYear: [1, 7],
      );
      final result = resolver.generateOccurrences(
        rule,
        rangeStart: DateTime(2026, 1, 1),
        rangeEnd: DateTime(2026, 12, 31),
      );
      expect(result.length, 2);
      expect(result[0].scheduledDate, DateTime(2026, 1, 15));
      expect(result[1].scheduledDate, DateTime(2026, 7, 15));
    });

    test('wraps to next year correctly', () {
      final rule = _rule(
        frequency: RecurringFrequency.semiannual,
        startsOn: DateTime(2026, 7, 1),
        dayOfMonth: 1,
        monthsOfYear: [1, 7],
      );
      final result = resolver.generateOccurrences(
        rule,
        rangeStart: DateTime(2026, 7, 1),
        rangeEnd: DateTime(2027, 6, 30),
      );
      expect(result.length, 2);
      expect(result[0].scheduledDate, DateTime(2026, 7, 1));
      expect(result[1].scheduledDate, DateTime(2027, 1, 1));
    });
  });

  // ── Weekly ────────────────────────────────────────────────────────────────

  group('weekly', () {
    test('4 occurrences in a 4-week window', () {
      final rule = _rule(
        frequency: RecurringFrequency.weekly,
        startsOn: DateTime(2026, 1, 5), // Monday
      );
      final result = resolver.generateOccurrences(
        rule,
        rangeStart: DateTime(2026, 1, 5),
        rangeEnd: DateTime(2026, 1, 31),
      );
      expect(result.length, 4);
      expect(result[0].scheduledDate, DateTime(2026, 1, 5));
      expect(result[1].scheduledDate, DateTime(2026, 1, 12));
    });
  });

  // ── Quarterly ────────────────────────────────────────────────────────────

  group('quarterly', () {
    test('4 occurrences in a year', () {
      final rule = _rule(
        frequency: RecurringFrequency.quarterly,
        dayOfMonth: 1,
      );
      final result = resolver.generateOccurrences(
        rule,
        rangeStart: DateTime(2026, 1, 1),
        rangeEnd: DateTime(2026, 12, 31),
      );
      expect(result.length, 4);
      expect(result.map((o) => o.scheduledDate.month).toList(), [1, 4, 7, 10]);
    });
  });

  // ── Out-of-range start ────────────────────────────────────────────────────

  group('range filtering', () {
    test('rule starting before range only returns in-range occurrences', () {
      final rule = _rule(
        dayOfMonth: 1,
        startsOn: DateTime(2025, 1, 1),
      );
      final result = resolver.generateOccurrences(
        rule,
        rangeStart: DateTime(2026, 3, 1),
        rangeEnd: DateTime(2026, 5, 31),
      );
      expect(result.length, 3);
      expect(result.first.scheduledDate, DateTime(2026, 3, 1));
    });
  });

  // ── Occurrence shape ──────────────────────────────────────────────────────

  group('occurrence shape', () {
    test('generated occurrences are pending with correct amount', () {
      final rule = _rule(dayOfMonth: 5);
      final result = resolver.generateOccurrences(
        rule,
        rangeStart: DateTime(2026, 1, 1),
        rangeEnd: DateTime(2026, 1, 31),
      );
      expect(result.length, 1);
      expect(result.first.status, OccurrenceStatus.pending);
      expect(result.first.expectedAmount, 100);
      expect(result.first.ruleId, 'r1');
    });
  });
}
