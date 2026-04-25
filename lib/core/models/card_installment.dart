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

  int get remainingInstallments => numInstallments - currentInstallment;
  double get progressPercent => numInstallments > 0 ? currentInstallment / numInstallments : 0.0;
  double get remainingBalance => monthlyAmount * remainingInstallments;
  bool get isComplete => currentInstallment >= numInstallments;
  bool get isActive => status == 'Active';

  CardInstallment copyWith({
    int? id,
    String? userId,
    String? description,
    DateTime? purchaseDate,
    double? totalValue,
    int? numInstallments,
    int? currentInstallment,
    double? monthlyAmount,
    String? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return CardInstallment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      description: description ?? this.description,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      totalValue: totalValue ?? this.totalValue,
      numInstallments: numInstallments ?? this.numInstallments,
      currentInstallment: currentInstallment ?? this.currentInstallment,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

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
