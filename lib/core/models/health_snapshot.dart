class HealthSnapshot {
  final int id;
  final String userId;
  final int month;
  final int year;
  final int score;
  final double savingsRate;
  final double housingRate;
  final double monthlyBalance;
  final double emergencyFundMonths;
  final double installmentsRate;
  final double netSalary;
  final DateTime createdAt;

  const HealthSnapshot({
    required this.id,
    required this.userId,
    required this.month,
    required this.year,
    required this.score,
    required this.savingsRate,
    required this.housingRate,
    required this.monthlyBalance,
    required this.emergencyFundMonths,
    required this.installmentsRate,
    required this.netSalary,
    required this.createdAt,
  });

  factory HealthSnapshot.fromJson(Map<String, dynamic> json) => HealthSnapshot(
        id: json['id'] as int,
        userId: json['user_id'] as String,
        month: json['month'] as int,
        year: json['year'] as int,
        score: json['score'] as int,
        savingsRate: (json['savings_rate'] as num).toDouble(),
        housingRate: (json['housing_rate'] as num).toDouble(),
        monthlyBalance: (json['monthly_balance'] as num).toDouble(),
        emergencyFundMonths: (json['emergency_fund_months'] as num).toDouble(),
        installmentsRate: (json['installments_rate'] as num).toDouble(),
        netSalary: (json['net_salary'] as num).toDouble(),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
