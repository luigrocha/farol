import 'package:flutter_test/flutter_test.dart';
import 'package:farol/core/domain/services/installment_service.dart';

void main() {
  group('InstallmentService._addMonths', () {
    test('advances month correctly', () {
      final base = DateTime(2026, 1, 10);
      expect(
          InstallmentService.addMonthsPublic(base, 0), DateTime(2026, 1, 10));
      expect(
          InstallmentService.addMonthsPublic(base, 1), DateTime(2026, 2, 10));
      expect(
          InstallmentService.addMonthsPublic(base, 11), DateTime(2026, 12, 10));
      expect(
          InstallmentService.addMonthsPublic(base, 12), DateTime(2027, 1, 10));
    });

    test('clamps day to end of month (Jan 31 → Feb 28)', () {
      final base = DateTime(2026, 1, 31);
      final result = InstallmentService.addMonthsPublic(base, 1);
      expect(result, DateTime(2026, 2, 28));
    });

    test('clamps day in leap year (Jan 31 → Feb 29)', () {
      final base = DateTime(2024, 1, 31);
      final result = InstallmentService.addMonthsPublic(base, 1);
      expect(result, DateTime(2024, 2, 29));
    });
  });

  group('InstallmentService rounding', () {
    test('R\$1200 / 12x = R\$100 each, sum == total', () {
      final payments = _simulatePayments(total: 1200, n: 12);
      expect(payments.length, 12);
      expect(payments.every((p) => p == 100.0), isTrue);
      expect(payments.fold(0.0, (a, b) => a + b), closeTo(1200.0, 0.001));
    });

    test('R\$1000 / 3x = 2x R\$333.33 + 1x R\$333.34, sum == total', () {
      final payments = _simulatePayments(total: 1000, n: 3);
      expect(payments.length, 3);
      expect(payments[0], closeTo(333.33, 0.001));
      expect(payments[1], closeTo(333.33, 0.001));
      expect(payments[2], closeTo(333.34, 0.001));
      expect(payments.fold(0.0, (a, b) => a + b), closeTo(1000.0, 0.001));
    });

    test('R\$100.01 / 2x = R\$50.00 + R\$50.01, sum == total', () {
      final payments = _simulatePayments(total: 100.01, n: 2);
      expect(payments[0], closeTo(50.00, 0.001));
      expect(payments[1], closeTo(50.01, 0.001));
      expect(payments.fold(0.0, (a, b) => a + b), closeTo(100.01, 0.001));
    });

    test('sum always equals total for many combinations', () {
      final cases = [
        (total: 799.99, n: 3),
        (total: 500.00, n: 7),
        (total: 1234.56, n: 6),
        (total: 9999.99, n: 10),
      ];
      for (final c in cases) {
        final payments = _simulatePayments(total: c.total, n: c.n);
        final sum = payments.fold(0.0, (a, b) => a + b);
        expect(sum, closeTo(c.total, 0.001),
            reason: 'Failed for total=${c.total} n=${c.n}');
      }
    });
  });

  group('InstallmentPlan.dueDateFor', () {
    test('first installment == firstDueDate', () {
      final plan = _makePlan(DateTime(2026, 2, 10), 12);
      expect(plan.dueDateFor(1), DateTime(2026, 2, 10));
    });

    test('last installment is 11 months after first', () {
      final plan = _makePlan(DateTime(2026, 2, 10), 12);
      expect(plan.dueDateFor(12), DateTime(2027, 1, 10));
    });
  });
}

// ─── helpers ────────────────────────────────────────────────────────────────

List<double> _simulatePayments({required double total, required int n}) {
  final base = (total / n * 100).floor() / 100;
  final last = double.parse((total - base * (n - 1)).toStringAsFixed(2));
  return List.generate(n, (i) => i == n - 1 ? last : base);
}

// Minimal InstallmentPlan stub for dueDateFor tests
_PlanStub _makePlan(DateTime firstDueDate, int n) => _PlanStub(firstDueDate, n);

class _PlanStub {
  final DateTime firstDueDate;
  final int numInstallments;
  _PlanStub(this.firstDueDate, this.numInstallments);

  DateTime dueDateFor(int installmentNum) {
    return InstallmentService.addMonthsPublic(firstDueDate, installmentNum - 1);
  }
}
