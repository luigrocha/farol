// lib/features/budget/domain/budget_recommendation.dart
//
// Pure-Dart model returned by BudgetRecommendationService.
// No Flutter dependencies; unit-testable.

/// A single budget recommendation for one category.
class CategoryRecommendation {
  /// Category slug (lowercase).
  final String category;

  /// Human-readable display name (same as stored in Category.name).
  final String name;

  /// 50/30/20 bucket this category falls into.
  final RecommendationBucket bucket;

  /// Suggested percentage of net salary (0–100).
  final double suggestedPct;

  /// Actual spending percentage in the current period (0–100+).
  final double actualPct;

  /// Current budget goal percentage (0 if none set).
  final double currentGoalPct;

  const CategoryRecommendation({
    required this.category,
    required this.name,
    required this.bucket,
    required this.suggestedPct,
    required this.actualPct,
    required this.currentGoalPct,
  });

  /// True when actual spending is materially above the suggestion.
  bool get isOverspending => actualPct > suggestedPct * 1.1;

  /// True when the existing goal differs from the suggestion by >5pp.
  bool get goalDiffersSignificantly =>
      (currentGoalPct - suggestedPct).abs() > 5.0;
}

/// The three buckets of the 50/30/20 rule.
enum RecommendationBucket {
  /// Essential needs (housing, food, transport, health): 50% of net salary.
  needs,

  /// Lifestyle wants (entertainment, dining out, shopping): 30% of net salary.
  wants,

  /// Savings / investments: 20% of net salary.
  savings,
}

extension RecommendationBucketX on RecommendationBucket {
  String label(String lang) {
    switch (this) {
      case RecommendationBucket.needs:
        return lang == 'pt'
            ? 'Necessidades'
            : lang == 'es'
                ? 'Necesidades'
                : 'Needs';
      case RecommendationBucket.wants:
        return lang == 'pt'
            ? 'Desejos'
            : lang == 'es'
                ? 'Deseos'
                : 'Wants';
      case RecommendationBucket.savings:
        return lang == 'pt'
            ? 'Investimentos'
            : lang == 'es'
                ? 'Ahorros'
                : 'Savings';
    }
  }

  double targetPct() {
    switch (this) {
      case RecommendationBucket.needs:
        return 50.0;
      case RecommendationBucket.wants:
        return 30.0;
      case RecommendationBucket.savings:
        return 20.0;
    }
  }
}

/// Aggregated result returned by [BudgetRecommendationService.compute].
class BudgetRecommendation {
  /// Individual category recommendations, sorted by bucket then suggestedPct desc.
  final List<CategoryRecommendation> items;

  /// Total allocated across all suggestions (should sum to ≤100).
  final double totalSuggestedPct;

  /// Categories that are currently overspending their suggestion.
  List<CategoryRecommendation> get overspending =>
      items.where((i) => i.isOverspending).toList();

  /// True when the user has no spending history — suggestions are purely
  /// rule-based (cannot be personalised).
  final bool basedOnHistory;

  const BudgetRecommendation({
    required this.items,
    required this.totalSuggestedPct,
    required this.basedOnHistory,
  });
}
