import '../entities/scheduled_payment.dart';
import '../entities/installment_payment.dart';
import '../entities/recurring_occurrence.dart';
import '../value_objects/money.dart';

/// Merges installment payments + recurring occurrences into a unified
/// List<ScheduledPayment> ordered by due date.
/// Pure service — no I/O.
class ObligationEngine {
  const ObligationEngine();

  List<ScheduledPayment> buildObligations({
    required List<InstallmentPayment> pendingInstallments,
    required List<RecurringOccurrence> pendingOccurrences,
  }) {
    final payments = <ScheduledPayment>[];

    for (final p in pendingInstallments) {
      if (p.status != 'pending' && p.status != 'overdue') continue;
      payments.add(ScheduledPayment(
        id: 'installment_${p.id}',
        description: 'Parcela ${p.installmentNum}',
        amount: Money.fromDouble(p.amount),
        dueDate: p.dueDate,
        type: ScheduledPaymentType.installment,
      ));
    }

    for (final o in pendingOccurrences) {
      if (o.status.name != 'pending') continue;
      payments.add(ScheduledPayment(
        id: 'recurring_${o.id}',
        description: o.ruleId, // name resolved by UI layer
        amount: Money.fromDouble(o.expectedAmount),
        dueDate: o.scheduledDate,
        type: ScheduledPaymentType.recurring,
      ));
    }

    payments.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return payments;
  }

  /// Iterates day by day, subtracting burn rate + obligations.
  /// Returns days until balance hits zero, or -1 if solvent for >365 days.
  int daysUntilEmpty({
    required Money balance,
    required Money dailyRate,
    required List<ScheduledPayment> obligations,
  }) {
    var bal = balance;
    for (int day = 1; day <= 365; day++) {
      bal = bal - dailyRate;
      final dueToday = obligations
          .where((p) => p.daysFromNow == day)
          .fold(Money.zero, (sum, p) => sum + p.amount);
      bal = bal - dueToday;
      if (bal.isNegative) return day;
    }
    return -1;
  }
}
