import 'package:flutter/material.dart';
import 'enums.dart';

enum AlertLevel { warning, critical, exceeded }

class BudgetAlert {
  final String category;
  final double spent;
  final double limit;
  final double percentage;
  final AlertLevel level;

  const BudgetAlert({
    required this.category,
    required this.spent,
    required this.limit,
    required this.percentage,
    required this.level,
  });

  // Lookup tolerates both legacy UPPERCASE and new lowercase slugs
  ExpenseCategory? get _legacyCat {
    try {
      return ExpenseCategory.fromDb(category.toUpperCase());
    } catch (_) {
      return null;
    }
  }

  String get emoji => _legacyCat?.emoji ?? '📊';

  String get categoryLabel => _legacyCat?.label ?? category;

  String localizedCategoryLabel(BuildContext context) =>
      _legacyCat?.localizedLabel(context) ?? category;

  String get percentageLabel => '${(percentage * 100).toStringAsFixed(0)}%';
}
