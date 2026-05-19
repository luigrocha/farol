// lib/features/budget/domain/budget_recommendation_service.dart
//
// Pure-Dart service that applies the 50/30/20 rule to the user's categories and
// spending history to produce [BudgetRecommendation].
//
// Mapping from Category.financialType to bucket:
//   'need'       → RecommendationBucket.needs   (50%)
//   'want'       → RecommendationBucket.wants   (30%)
//   'investment' → RecommendationBucket.savings (20%)
//   anything else → RecommendationBucket.wants  (fallback)
//
// Within each bucket the suggested percentages are distributed proportionally
// to actual spending when history exists, or equally when no history is available.

import 'package:farol/core/models/category.dart';
import 'package:farol/core/models/budget_goal.dart';
import 'budget_recommendation.dart';

class BudgetRecommendationService {
  const BudgetRecommendationService();

  /// Compute recommendations.
  ///
  /// [categories]         — all non-Swile, non-income categories
  /// [expensesByCategory] — slug → amount spent this period (may be empty)
  /// [goals]              — existing budget goals (may be empty)
  /// [netSalary]          — effective monthly net salary; used to compute actualPct
  BudgetRecommendation compute({
    required List<Category> categories,
    required Map<String, double> expensesByCategory,
    required List<BudgetGoal> goals,
    required double netSalary,
  }) {
    // Build a lookup map for existing goals
    final goalMap = <String, double>{
      for (final g in goals) g.category.toLowerCase(): g.targetPercentage,
    };

    // Total spending this period (fallback: 1 to avoid /0)
    final totalSpending = expensesByCategory.values.fold(0.0, (a, b) => a + b);
    final basedOnHistory = totalSpending > 0;

    // Group categories by bucket
    final bucketCats = <RecommendationBucket, List<Category>>{};
    for (final cat in categories) {
      // Skip Swile categories — they have their own budget pool
      if (cat.isSwile) continue;
      // Skip income / transfer types
      if (cat.financialType == 'income' || cat.financialType == 'transfer')
        continue;
      final bucket = _bucketFor(cat.financialType);
      bucketCats.putIfAbsent(bucket, () => []).add(cat);
    }

    final recommendations = <CategoryRecommendation>[];

    for (final bucket in RecommendationBucket.values) {
      final cats = bucketCats[bucket] ?? [];
      if (cats.isEmpty) continue;

      final bucketTarget = bucket.targetPct(); // e.g. 50.0

      // Compute spending weights for this bucket's categories
      final spendingInBucket = <String, double>{};
      double bucketTotal = 0.0;
      for (final cat in cats) {
        final spent = expensesByCategory[cat.slug.toLowerCase()] ?? 0.0;
        spendingInBucket[cat.slug.toLowerCase()] = spent;
        bucketTotal += spent;
      }

      for (final cat in cats) {
        final slug = cat.slug.toLowerCase();
        final spent = spendingInBucket[slug] ?? 0.0;

        // Suggested pct: distribute bucket proportionally to spending, or equally
        final double suggestedPct;
        if (basedOnHistory && bucketTotal > 0) {
          suggestedPct = (spent / bucketTotal) * bucketTarget;
        } else {
          suggestedPct = bucketTarget / cats.length;
        }

        // Actual pct of net salary this period
        final double actualPct =
            netSalary > 0 ? (spent / netSalary) * 100.0 : 0.0;

        recommendations.add(CategoryRecommendation(
          category: slug,
          name: cat.name,
          bucket: bucket,
          suggestedPct: double.parse(suggestedPct.toStringAsFixed(1)),
          actualPct: double.parse(actualPct.toStringAsFixed(1)),
          currentGoalPct: goalMap[slug] ?? 0.0,
        ));
      }
    }

    // Sort: by bucket order (needs → wants → savings), then suggestedPct desc
    recommendations.sort((a, b) {
      final bi = a.bucket.index.compareTo(b.bucket.index);
      if (bi != 0) return bi;
      return b.suggestedPct.compareTo(a.suggestedPct);
    });

    final totalSuggested =
        recommendations.fold(0.0, (s, r) => s + r.suggestedPct);

    return BudgetRecommendation(
      items: recommendations,
      totalSuggestedPct: double.parse(totalSuggested.toStringAsFixed(1)),
      basedOnHistory: basedOnHistory,
    );
  }

  RecommendationBucket _bucketFor(String financialType) {
    switch (financialType) {
      case 'need':
        return RecommendationBucket.needs;
      case 'investment':
        return RecommendationBucket.savings;
      case 'want':
      default:
        return RecommendationBucket.wants;
    }
  }
}
