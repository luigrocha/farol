import '../value_objects/money.dart';
import 'scheduled_payment.dart';

enum LiquidityRiskLevel { none, low, medium, high, critical }

class LiquidityRisk {
  final LiquidityRiskLevel level;

  /// Obligations due in the next 7 days
  final Money obligationsNext7Days;

  /// Current cash balance at assessment time
  final Money currentBalance;

  /// How many days until balance hits zero (-1 = solvent > 365 days)
  final int daysUntilEmpty;

  /// The obligations driving the risk (for breakdown UI)
  final List<ScheduledPayment> upcomingObligations;

  const LiquidityRisk({
    required this.level,
    required this.obligationsNext7Days,
    required this.currentBalance,
    required this.daysUntilEmpty,
    required this.upcomingObligations,
  });

  bool get isAtRisk =>
      level == LiquidityRiskLevel.medium ||
      level == LiquidityRiskLevel.high ||
      level == LiquidityRiskLevel.critical;
}
