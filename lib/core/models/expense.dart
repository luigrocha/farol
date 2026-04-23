class Expense {
  final int id;
  final String userId;
  final int month;
  final int year;
  final DateTime transactionDate;
  final String payType;
  final String category;
  final String? subcategory;
  final double amount;
  final String paymentMethod;
  final int installments;
  final bool isFixed;
  final String? storeDescription;
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.userId,
    required this.month,
    required this.year,
    required this.transactionDate,
    required this.payType,
    required this.category,
    this.subcategory,
    required this.amount,
    required this.paymentMethod,
    this.installments = 1,
    this.isFixed = false,
    this.storeDescription,
    required this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(json['created_at'] as String);
    final rawDate = json['transaction_date'];
    return Expense(
      id: (json['id'] as num).toInt(),
      userId: json['user_id'] as String,
      month: (json['month'] as num).toInt(),
      year: (json['year'] as num).toInt(),
      transactionDate: rawDate != null ? DateTime.parse(rawDate as String) : createdAt,
      payType: json['pay_type'] as String,
      category: json['category'] as String,
      subcategory: json['subcategory'] as String?,
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String,
      installments: (json['installments'] as num?)?.toInt() ?? 1,
      isFixed: json['is_fixed'] as bool? ?? false,
      storeDescription: json['store_description'] as String?,
      createdAt: createdAt,
    );
  }
}
