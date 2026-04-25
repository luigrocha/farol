class BudgetSettings {
  final double netSalary;
  final double swileMeal;
  final double swileFood;
  final int cutoffDay;

  const BudgetSettings({
    this.netSalary = 0,
    this.swileMeal = 0,
    this.swileFood = 0,
    this.cutoffDay = 1,
  });

  double get swileTotal => swileMeal + swileFood;
  double get totalBudget => netSalary + swileTotal;

  BudgetSettings copyWith({
    double? netSalary,
    double? swileMeal,
    double? swileFood,
    int? cutoffDay,
  }) =>
      BudgetSettings(
        netSalary: netSalary ?? this.netSalary,
        swileMeal: swileMeal ?? this.swileMeal,
        swileFood: swileFood ?? this.swileFood,
        cutoffDay: cutoffDay ?? this.cutoffDay,
      );

  Map<String, dynamic> toJson() => {
        'net_salary': netSalary,
        'swile_meal': swileMeal,
        'swile_food': swileFood,
        'cutoff_day': cutoffDay,
      };

  factory BudgetSettings.fromJson(Map<String, dynamic> json) => BudgetSettings(
        netSalary: (json['net_salary'] as num?)?.toDouble() ?? 0,
        swileMeal: (json['swile_meal'] as num?)?.toDouble() ?? 0,
        swileFood: (json['swile_food'] as num?)?.toDouble() ?? 0,
        cutoffDay: (json['cutoff_day'] as num?)?.toInt() ?? 1,
      );
}
