import 'financial_period.dart';
import 'budget_goal.dart';

class PeriodBudget {
  final String id;
  final String userId;
  final String category;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double amount;
  final bool isCustom;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PeriodBudget({
    required this.id,
    required this.userId,
    required this.category,
    required this.periodStart,
    required this.periodEnd,
    required this.amount,
    required this.isCustom,
    required this.createdAt,
    required this.updatedAt,
  });

  FinancialPeriod get period =>
      FinancialPeriod(start: periodStart, end: periodEnd);

  factory PeriodBudget.fromJson(Map<String, dynamic> json) => PeriodBudget(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        category: json['category'] as String,
        periodStart: DateTime.parse(json['period_start'] as String),
        periodEnd: DateTime.parse(json['period_end'] as String),
        amount: (json['amount'] as num).toDouble(),
        isCustom: (json['is_custom'] as bool?) ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

}

// ─────────────────────────────────────────────────────────────────────────────

enum BudgetStatus { ok, warning, overspent }

/// A budget entry shown in the UI. Either backed by a [BudgetGoal] (the parent
/// default), an explicit [PeriodBudget] override, or both.
///
/// If no [override] exists, [amount] falls back to [goal.targetAmount].
/// If the user edited the amount, [override.isCustom] == true.
class PeriodBudgetEntry {
  final BudgetGoal? goal;
  final PeriodBudget? override;
  final double spent;

  const PeriodBudgetEntry({
    required this.goal,
    required this.override,
    required this.spent,
  });

  String get category => override?.category ?? goal!.category;

  /// Effective budget amount: override wins, falls back to goal.
  double get amount => override?.amount ?? goal?.targetAmount ?? 0;

  /// Amount from the parent goal (null if no goal).
  double? get goalAmount => goal?.targetAmount;

  /// True when the user explicitly set a different amount for this period.
  bool get isCustom => override?.isCustom ?? false;

  /// The DB id if a period_budget row exists (needed for delete/reset).
  String? get overrideId => override?.id;

  double get remaining => amount - spent;
  double get percentage => amount > 0 ? spent / amount : 0.0;

  BudgetStatus get status {
    if (percentage >= 1.0) return BudgetStatus.overspent;
    if (percentage >= 0.8) return BudgetStatus.warning;
    return BudgetStatus.ok;
  }

  // ── Legacy compat ────────────────────────────────────────────────────────

  /// Used when the RPC returns both budget fields and [spent] in one row.
  static PeriodBudgetEntry fromRpcJson(Map<String, dynamic> json) =>
      PeriodBudgetEntry(
        goal: null,
        override: PeriodBudget.fromJson(json),
        spent: (json['spent'] as num).toDouble(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────

/// Kept for backward compat with [PeriodBudgetRepository.getBudgetsWithUsage].
class BudgetWithUsage {
  final PeriodBudget budget;
  final double spent;

  const BudgetWithUsage({required this.budget, required this.spent});

  factory BudgetWithUsage.fromRpcJson(Map<String, dynamic> json) =>
      BudgetWithUsage(
        budget: PeriodBudget.fromJson(json),
        spent: (json['spent'] as num).toDouble(),
      );
}
