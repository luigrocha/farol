class Investment {
  final int id;
  final String userId;
  final String type;
  final String productName;
  final String institution;
  final DateTime dateAdded;
  final double totalInvested;
  final double currentBalance;
  final double returnAmount;
  final String? liquidity;
  final String? notes;
  final DateTime createdAt;

  const Investment({
    required this.id,
    required this.userId,
    required this.type,
    required this.productName,
    required this.institution,
    required this.dateAdded,
    required this.totalInvested,
    required this.currentBalance,
    this.returnAmount = 0,
    this.liquidity,
    this.notes,
    required this.createdAt,
  });

  factory Investment.fromJson(Map<String, dynamic> json) => Investment(
        id: (json['id'] as num).toInt(),
        userId: json['user_id'] as String,
        type: json['type'] as String,
        productName: json['product_name'] as String,
        institution: json['institution'] as String,
        dateAdded: DateTime.parse(json['date_added'] as String),
        totalInvested: (json['total_invested'] as num).toDouble(),
        currentBalance: (json['current_balance'] as num).toDouble(),
        returnAmount: (json['return_amount'] as num?)?.toDouble() ?? 0,
        liquidity: json['liquidity'] as String?,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
