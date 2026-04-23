class BudgetSettings {
  final double netSalary;
  final double swileMeal;
  final double swileFood;

  const BudgetSettings({
    this.netSalary = 0,
    this.swileMeal = 0,
    this.swileFood = 0,
  });

  double get swileTotal => swileMeal + swileFood;
  double get totalBudget => netSalary + swileTotal;

  BudgetSettings copyWith({double? netSalary, double? swileMeal, double? swileFood}) =>
      BudgetSettings(
        netSalary: netSalary ?? this.netSalary,
        swileMeal: swileMeal ?? this.swileMeal,
        swileFood: swileFood ?? this.swileFood,
      );

  Map<String, dynamic> toJson() => {
        'net_salary': netSalary,
        'swile_meal': swileMeal,
        'swile_food': swileFood,
      };

  factory BudgetSettings.fromJson(Map<String, dynamic> json) => BudgetSettings(
        netSalary: (json['net_salary'] as num?)?.toDouble() ?? 0,
        swileMeal: (json['swile_meal'] as num?)?.toDouble() ?? 0,
        swileFood: (json['swile_food'] as num?)?.toDouble() ?? 0,
      );
}
