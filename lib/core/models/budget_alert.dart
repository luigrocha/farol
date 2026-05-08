import 'package:flutter/material.dart';

enum AlertLevel { warning, critical, exceeded }

class BudgetAlert {
  final String category; // slug
  final String categoryName;
  final String categoryEmoji;
  final double spent;
  final double limit;
  final double percentage;
  final AlertLevel level;

  const BudgetAlert({
    required this.category,
    required this.categoryName,
    required this.categoryEmoji,
    required this.spent,
    required this.limit,
    required this.percentage,
    required this.level,
  });

  String get emoji => categoryEmoji;
  String get categoryLabel => categoryName;
  String localizedCategoryLabel(BuildContext context) => categoryName;
  String get percentageLabel => '${(percentage * 100).toStringAsFixed(0)}%';
}
