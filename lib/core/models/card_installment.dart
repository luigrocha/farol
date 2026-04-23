class CardInstallment {
  final int id;
  final String userId;
  final String description;
  final DateTime purchaseDate;
  final double totalValue;
  final int numInstallments;
  final int currentInstallment;
  final double monthlyAmount;
  final String status;
  final String? notes;
  final DateTime createdAt;

  const CardInstallment({
    required this.id,
    required this.userId,
    required this.description,
    required this.purchaseDate,
    required this.totalValue,
    required this.numInstallments,
    required this.currentInstallment,
    required this.monthlyAmount,
    this.status = 'Active',
    this.notes,
    required this.createdAt,
  });

  factory CardInstallment.fromJson(Map<String, dynamic> json) => CardInstallment(
        id: (json['id'] as num).toInt(),
        userId: json['user_id'] as String,
        description: json['description'] as String,
        purchaseDate: DateTime.parse(json['purchase_date'] as String),
        totalValue: (json['total_value'] as num).toDouble(),
        numInstallments: (json['num_installments'] as num).toInt(),
        currentInstallment: (json['current_installment'] as num).toInt(),
        monthlyAmount: (json['monthly_amount'] as num).toDouble(),
        status: json['status'] as String? ?? 'Active',
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
