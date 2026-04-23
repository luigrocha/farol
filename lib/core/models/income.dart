class Income {
  final int id;
  final String userId;
  final int month;
  final int year;
  final String incomeType;
  final double amount;
  final bool isNet;
  final double? inssDeducted;
  final double? irrfDeducted;
  final String? notes;
  final DateTime createdAt;

  const Income({
    required this.id,
    required this.userId,
    required this.month,
    required this.year,
    required this.incomeType,
    required this.amount,
    this.isNet = true,
    this.inssDeducted,
    this.irrfDeducted,
    this.notes,
    required this.createdAt,
  });

  factory Income.fromJson(Map<String, dynamic> json) => Income(
        id: (json['id'] as num).toInt(),
        userId: json['user_id'] as String,
        month: (json['month'] as num).toInt(),
        year: (json['year'] as num).toInt(),
        incomeType: json['income_type'] as String,
        amount: (json['amount'] as num).toDouble(),
        isNet: json['is_net'] as bool? ?? true,
        inssDeducted: (json['inss_deducted'] as num?)?.toDouble(),
        irrfDeducted: (json['irrf_deducted'] as num?)?.toDouble(),
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
