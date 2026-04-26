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

  String get emoji {
    try {
      return ExpenseCategory.fromDb(category).emoji;
    } catch (_) {
      return '📊';
    }
  }

  String get categoryLabel {
    try {
      return ExpenseCategory.fromDb(category).label;
    } catch (_) {
      return category;
    }
  }

  String localizedCategoryLabel(BuildContext context) {
    try {
      return ExpenseCategory.fromDb(category).localizedLabel(context);
    } catch (_) {
      return category;
    }
  }

  String get percentageLabel => '${(percentage * 100).toStringAsFixed(0)}%';
}
