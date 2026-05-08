import 'dart:math' as math;
import '../value_objects/money.dart';

enum BurnPace {
  /// Projected spend < 80% of allocated
  comfortable,
  /// 80–100% of allocated
  onTrack,
  /// > 100% — will overspend
  overspending,
}

class BurnRate {
  final Money totalSpent;
  final int daysElapsed;
  final int daysRemaining;
  final Money totalAllocated;

  const BurnRate({
    required this.totalSpent,
    required this.daysElapsed,
    required this.daysRemaining,
    required this.totalAllocated,
  });

  /// R$/day average
  Money get dailyRate {
    final d = math.max(daysElapsed, 1);
    return Money.fromDouble(totalSpent.amount / d);
  }

  /// What we'll have spent by period end if pace continues
  Money get projectedTotalSpend =>
      totalSpent + dailyRate * daysRemaining.toDouble();

  /// 1.0 = on track; > 1.0 = will overspend
  double get paceVsBudget => totalAllocated.isZero
      ? 0.0
      : projectedTotalSpend.amount / totalAllocated.amount;

  BurnPace get pace {
    if (paceVsBudget < 0.8) return BurnPace.comfortable;
    if (paceVsBudget < 1.0) return BurnPace.onTrack;
    return BurnPace.overspending;
  }
}
