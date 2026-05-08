import '../value_objects/money.dart';
import '../value_objects/category_ref.dart';

enum EnvelopeStatus { ok, warning, overspent }

enum RolloverPolicy { none, carryForward, reset }

class Envelope {
  final CategoryRef category;
  final Money allocated;
  final Money spent;
  final RolloverPolicy rolloverPolicy;
  final Money rolloverAmount;

  const Envelope({
    required this.category,
    required this.allocated,
    required this.spent,
    this.rolloverPolicy = RolloverPolicy.none,
    this.rolloverAmount = Money.zero,
  });

  Money get remaining => allocated - spent;
  Money get effectiveAllocated => allocated + rolloverAmount;
  Money get effectiveRemaining => effectiveAllocated - spent;

  EnvelopeStatus get status {
    if (spent > effectiveAllocated) return EnvelopeStatus.overspent;
    final pct = effectiveAllocated.isZero
        ? 0.0
        : spent.cents / effectiveAllocated.cents;
    return pct >= 0.85 ? EnvelopeStatus.warning : EnvelopeStatus.ok;
  }

  double get usagePercent => effectiveAllocated.isZero
      ? 0.0
      : (spent.cents / effectiveAllocated.cents).clamp(0.0, 1.0);
}
