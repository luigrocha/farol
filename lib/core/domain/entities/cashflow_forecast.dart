import '../value_objects/money.dart';

class CashflowDataPoint {
  final DateTime date;
  final Money balance;

  /// True if this day has a scheduled obligation (installment or recurring)
  final bool hasObligation;
  final Money dailyExpense;
  final Money dailyIncome;

  /// True for dates in the past (real data), false for projection
  final bool isReal;

  const CashflowDataPoint({
    required this.date,
    required this.balance,
    required this.hasObligation,
    required this.dailyExpense,
    required this.dailyIncome,
    required this.isReal,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'balance': balance.amount,
        'hasObligation': hasObligation,
        'dailyExpense': dailyExpense.amount,
        'dailyIncome': dailyIncome.amount,
        'isReal': isReal,
      };

  factory CashflowDataPoint.fromJson(Map<String, dynamic> json) =>
      CashflowDataPoint(
        date: DateTime.parse(json['date'] as String),
        balance: Money.fromDouble((json['balance'] as num).toDouble()),
        hasObligation: json['hasObligation'] as bool,
        dailyExpense:
            Money.fromDouble((json['dailyExpense'] as num).toDouble()),
        dailyIncome: Money.fromDouble((json['dailyIncome'] as num).toDouble()),
        isReal: json['isReal'] as bool,
      );
}

class CashflowForecast {
  final List<CashflowDataPoint> points;
  final DateTime generatedAt;

  const CashflowForecast({required this.points, required this.generatedAt});

  bool get isEmpty => points.isEmpty;

  /// Minimum projected balance in the forecast window
  Money get minBalance => points.isEmpty
      ? Money.zero
      : points
          .map((p) => p.balance)
          .reduce((a, b) => a.amount < b.amount ? a : b);

  /// Whether the balance dips negative at any point
  bool get goesNegative => points.any((p) => p.balance.isNegative);

  Map<String, dynamic> toJson() => {
        'generatedAt': generatedAt.toIso8601String(),
        'points': points.map((p) => p.toJson()).toList(),
      };

  factory CashflowForecast.fromJson(Map<String, dynamic> json) =>
      CashflowForecast(
        generatedAt: DateTime.parse(json['generatedAt'] as String),
        points: (json['points'] as List<dynamic>)
            .map((p) => CashflowDataPoint.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}
