class AccountTransfer {
  final int id;
  final String userId;
  final int fromAccountId;
  final int toAccountId;
  final double amount;
  final DateTime transferDate;
  final String? description;
  final DateTime createdAt;

  const AccountTransfer({
    required this.id,
    required this.userId,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    required this.transferDate,
    this.description,
    required this.createdAt,
  });

  factory AccountTransfer.fromJson(Map<String, dynamic> json) => AccountTransfer(
        id: (json['id'] as num).toInt(),
        userId: json['user_id'] as String,
        fromAccountId: (json['from_account_id'] as num).toInt(),
        toAccountId: (json['to_account_id'] as num).toInt(),
        amount: (json['amount'] as num).toDouble(),
        transferDate: DateTime.parse(json['transfer_date'] as String),
        description: json['description'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
