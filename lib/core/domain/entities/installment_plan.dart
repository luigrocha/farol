class InstallmentPlan {
  final String id;
  final String userId;
  final String? categoryId;
  final String description;
  final String? storeName;
  final DateTime purchaseDate;
  final double totalAmount;
  final int numInstallments;
  final double installmentAmount;
  final String paymentMethod;
  final DateTime firstDueDate;
  final String status; // 'active' | 'completed' | 'cancelled' | 'paused'
  final int? originalExpenseId;
  final int? legacyCardInstallmentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Runtime-populated fields (not stored directly)
  final int paidCount;
  final String? categorySlug; // populated by caller from categories cache

  const InstallmentPlan({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.description,
    this.storeName,
    required this.purchaseDate,
    required this.totalAmount,
    required this.numInstallments,
    required this.installmentAmount,
    required this.paymentMethod,
    required this.firstDueDate,
    this.status = 'active',
    this.originalExpenseId,
    this.legacyCardInstallmentId,
    required this.createdAt,
    required this.updatedAt,
    this.paidCount = 0,
    this.categorySlug,
  });

  bool get isActive => status == 'active';
  bool get isComplete => status == 'completed';
  int get remainingPayments => numInstallments - paidCount;
  double get remainingAmount => remainingPayments * installmentAmount;
  double get progressPercent =>
      numInstallments > 0 ? paidCount / numInstallments : 0.0;

  /// Due date for a given installment number (1-based).
  DateTime dueDateFor(int installmentNum) {
    assert(installmentNum >= 1 && installmentNum <= numInstallments);
    return DateTime(
      firstDueDate.year,
      firstDueDate.month + (installmentNum - 1),
      firstDueDate.day,
    );
  }

  InstallmentPlan copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? description,
    String? storeName,
    DateTime? purchaseDate,
    double? totalAmount,
    int? numInstallments,
    double? installmentAmount,
    String? paymentMethod,
    DateTime? firstDueDate,
    String? status,
    int? originalExpenseId,
    int? legacyCardInstallmentId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? paidCount,
    String? categorySlug,
  }) {
    return InstallmentPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      storeName: storeName ?? this.storeName,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      totalAmount: totalAmount ?? this.totalAmount,
      numInstallments: numInstallments ?? this.numInstallments,
      installmentAmount: installmentAmount ?? this.installmentAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      firstDueDate: firstDueDate ?? this.firstDueDate,
      status: status ?? this.status,
      originalExpenseId: originalExpenseId ?? this.originalExpenseId,
      legacyCardInstallmentId:
          legacyCardInstallmentId ?? this.legacyCardInstallmentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paidCount: paidCount ?? this.paidCount,
      categorySlug: categorySlug ?? this.categorySlug,
    );
  }

  factory InstallmentPlan.fromJson(Map<String, dynamic> json) {
    return InstallmentPlan(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String?,
      description: json['description'] as String,
      storeName: json['store_name'] as String?,
      purchaseDate: DateTime.parse(json['purchase_date'] as String),
      totalAmount: (json['total_amount'] as num).toDouble(),
      numInstallments: (json['num_installments'] as num).toInt(),
      installmentAmount: (json['installment_amount'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String,
      firstDueDate: DateTime.parse(json['first_due_date'] as String),
      status: json['status'] as String? ?? 'active',
      originalExpenseId: json['original_expense_id'] != null
          ? (json['original_expense_id'] as num).toInt()
          : null,
      legacyCardInstallmentId: json['legacy_card_installment_id'] != null
          ? (json['legacy_card_installment_id'] as num).toInt()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        if (categoryId != null) 'category_id': categoryId,
        'description': description,
        if (storeName != null) 'store_name': storeName,
        'purchase_date': purchaseDate.toIso8601String().substring(0, 10),
        'total_amount': totalAmount,
        'num_installments': numInstallments,
        'installment_amount': installmentAmount,
        'payment_method': paymentMethod,
        'first_due_date': firstDueDate.toIso8601String().substring(0, 10),
        'status': status,
        if (originalExpenseId != null) 'original_expense_id': originalExpenseId,
        if (legacyCardInstallmentId != null)
          'legacy_card_installment_id': legacyCardInstallmentId,
      };
}
