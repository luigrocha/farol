class NetWorthSnapshot {
  final int id;
  final String userId;
  final int month;
  final int year;
  final double fgtsBalance;
  final double investmentsTotal;
  final double emergencyFund;
  final double pendingInstallments;
  final String? notes;
  final DateTime createdAt;

  const NetWorthSnapshot({
    required this.id,
    required this.userId,
    required this.month,
    required this.year,
    this.fgtsBalance = 0,
    this.investmentsTotal = 0,
    this.emergencyFund = 0,
    this.pendingInstallments = 0,
    this.notes,
    required this.createdAt,
  });

  factory NetWorthSnapshot.fromJson(Map<String, dynamic> json) => NetWorthSnapshot(
        id: (json['id'] as num).toInt(),
        userId: json['user_id'] as String,
        month: (json['month'] as num).toInt(),
        year: (json['year'] as num).toInt(),
        fgtsBalance: (json['fgts_balance'] as num?)?.toDouble() ?? 0,
        investmentsTotal: (json['investments_total'] as num?)?.toDouble() ?? 0,
        emergencyFund: (json['emergency_fund'] as num?)?.toDouble() ?? 0,
        pendingInstallments: (json['pending_installments'] as num?)?.toDouble() ?? 0,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
