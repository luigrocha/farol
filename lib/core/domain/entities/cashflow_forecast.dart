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
}

class CashflowForecast {
  final List<CashflowDataPoint> points;
  final DateTime generatedAt;

  const CashflowForecast({required this.points, required this.generatedAt});

  bool get isEmpty => points.isEmpty;

  /// Minimum projected balance in the forecast window
  Money get minBalance =>
      points.isEmpty ? Money.zero : points.map((p) => p.balance).reduce(
          (a, b) => a.amount < b.amount ? a : b);

  /// Whether the balance dips negative at any point
  bool get goesNegative => points.any((p) => p.balance.isNegative);
}
