class InstallmentPayment {
  final String id;
  final String planId;
  final String userId;
  final int installmentNum;
  final DateTime dueDate;
  final double amount;
  final String status; // 'pending' | 'paid' | 'overdue' | 'skipped'
  final DateTime? paidDate;
  final double? paidAmount;
  final int? expenseId; // bigint to match expenses.id
  final DateTime? financialPeriodStart;
  final DateTime? financialPeriodEnd;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InstallmentPayment({
    required this.id,
    required this.planId,
    required this.userId,
    required this.installmentNum,
    required this.dueDate,
    required this.amount,
    this.status = 'pending',
    this.paidDate,
    this.paidAmount,
    this.expenseId,
    this.financialPeriodStart,
    this.financialPeriodEnd,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPending => status == 'pending';
  bool get isPaid => status == 'paid';

  bool get isOverdue => status == 'pending' && dueDate.isBefore(DateTime.now());

  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;

  InstallmentPayment copyWith({
    String? id,
    String? planId,
    String? userId,
    int? installmentNum,
    DateTime? dueDate,
    double? amount,
    String? status,
    DateTime? paidDate,
    double? paidAmount,
    int? expenseId,
    DateTime? financialPeriodStart,
    DateTime? financialPeriodEnd,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InstallmentPayment(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      userId: userId ?? this.userId,
      installmentNum: installmentNum ?? this.installmentNum,
      dueDate: dueDate ?? this.dueDate,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paidDate: paidDate ?? this.paidDate,
      paidAmount: paidAmount ?? this.paidAmount,
      expenseId: expenseId ?? this.expenseId,
      financialPeriodStart: financialPeriodStart ?? this.financialPeriodStart,
      financialPeriodEnd: financialPeriodEnd ?? this.financialPeriodEnd,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory InstallmentPayment.fromJson(Map<String, dynamic> json) {
    return InstallmentPayment(
      id: json['id'] as String,
      planId: json['plan_id'] as String,
      userId: json['user_id'] as String,
      installmentNum: (json['installment_num'] as num).toInt(),
      dueDate: DateTime.parse(json['due_date'] as String),
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String? ?? 'pending',
      paidDate: json['paid_date'] != null
          ? DateTime.parse(json['paid_date'] as String)
          : null,
      paidAmount: json['paid_amount'] != null
          ? (json['paid_amount'] as num).toDouble()
          : null,
      expenseId: json['expense_id'] != null
          ? (json['expense_id'] as num).toInt()
          : null,
      financialPeriodStart: json['financial_period_start'] != null
          ? DateTime.parse(json['financial_period_start'] as String)
          : null,
      financialPeriodEnd: json['financial_period_end'] != null
          ? DateTime.parse(json['financial_period_end'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'plan_id': planId,
        'user_id': userId,
        'installment_num': installmentNum,
        'due_date': dueDate.toIso8601String().substring(0, 10),
        'amount': amount,
        'status': status,
        if (paidDate != null)
          'paid_date': paidDate!.toIso8601String().substring(0, 10),
        if (paidAmount != null) 'paid_amount': paidAmount,
        if (expenseId != null) 'expense_id': expenseId,
        if (financialPeriodStart != null)
          'financial_period_start':
              financialPeriodStart!.toIso8601String().substring(0, 10),
        if (financialPeriodEnd != null)
          'financial_period_end':
              financialPeriodEnd!.toIso8601String().substring(0, 10),
      };
}
