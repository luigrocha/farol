class BudgetGoal {
  final int id;
  final String userId;
  final String category;
  final double targetPercentage;
  final double targetAmount;
  final String type;
  final DateTime createdAt;

  const BudgetGoal({
    required this.id,
    required this.userId,
    required this.category,
    required this.targetPercentage,
    required this.targetAmount,
    required this.type,
    required this.createdAt,
  });

  factory BudgetGoal.fromJson(Map<String, dynamic> json) => BudgetGoal(
        id: (json['id'] as num).toInt(),
        userId: json['user_id'] as String,
        category: json['category'] as String,
        targetPercentage: (json['target_percentage'] as num).toDouble(),
        targetAmount: (json['target_amount'] as num).toDouble(),
        type: json['type'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
