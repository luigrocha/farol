import '../value_objects/money.dart';

enum InsightType {
  // Preventive alerts
  overdraftRisk,
  liquidityAlert,
  budgetOverrun,
  // Detected patterns
  spendingSpike,
  subscriptionCreep,
  duplicateCharge,
  unusualMerchant,
  // Opportunities
  savingsOpportunity,
  earlyPayoff,
  investmentOpportunity,
  // Achievements
  budgetStreak,
  savingsRecord,
  debtReduction,
  categoryUnderControl,
}

enum InsightPriority { critical, warning, info, achievement }

class FinancialInsight {
  final String id;
  final InsightType type;
  final InsightPriority priority;

  /// Localization key for the title (resolved in InsightCard via l10n).
  final String titleKey;
  /// Localization key for the body text.
  final String bodyKey;
  /// Localization key for the action label (null = no action).
  final String? actionKey;

  /// Fallback PT-BR strings — used in tests and as safety net.
  final String title;
  final String body;
  final String? actionLabel;

  final String? actionRoute;
  final double confidence;
  final Map<String, dynamic> data;
  final DateTime generatedAt;
  final DateTime? expiresAt;
  final bool isDismissable;
  final String? dismissGroup;

  FinancialInsight({
    required this.id,
    required this.type,
    required this.priority,
    required this.titleKey,
    required this.bodyKey,
    this.actionKey,
    required this.title,
    required this.body,
    this.actionLabel,
    this.actionRoute,
    required this.confidence,
    Map<String, dynamic>? data,
    DateTime? generatedAt,
    this.expiresAt,
    this.isDismissable = false,
    this.dismissGroup,
  })  : data = data ?? const {},
        generatedAt = generatedAt ?? DateTime.now();

  bool isExpired() =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

// ─── CategoryVelocity (used by IntelligenceLayer) ────────────────────────────

class CategoryVelocity {
  final String categorySlug;
  final String categoryName;
  final Money currentSpend;
  final Money historicalAverage;

  const CategoryVelocity({
    required this.categorySlug,
    required this.categoryName,
    required this.currentSpend,
    required this.historicalAverage,
  });

  double get deviationPercent => historicalAverage.isZero
      ? 0.0
      : (currentSpend.amount - historicalAverage.amount) /
          historicalAverage.amount *
          100;

  bool get isOverPace => deviationPercent > 20;
  bool get isUnderPace => deviationPercent < -20;
}
