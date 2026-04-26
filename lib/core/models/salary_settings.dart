class SalarySettings {
  final String? id;
  final String? userId;
  final double grossSalary;
  final double inss;
  final double irrf;
  final double netSalary;
  final double fgts;
  final int dependents;
  final double otherDeductions;
  final bool useSimplifiedDeduction;
  final DateTime? updatedAt;

  const SalarySettings({
    this.id,
    this.userId,
    required this.grossSalary,
    required this.inss,
    required this.irrf,
    required this.netSalary,
    required this.fgts,
    this.dependents = 0,
    this.otherDeductions = 0,
    this.useSimplifiedDeduction = false,
    this.updatedAt,
  });

  double get totalDeductions => inss + irrf;
  double get effectiveRate =>
      grossSalary > 0 ? (totalDeductions / grossSalary) * 100 : 0.0;

  SalarySettings copyWith({
    double? grossSalary,
    double? inss,
    double? irrf,
    double? netSalary,
    double? fgts,
    int? dependents,
    double? otherDeductions,
    bool? useSimplifiedDeduction,
  }) =>
      SalarySettings(
        id: id,
        userId: userId,
        grossSalary: grossSalary ?? this.grossSalary,
        inss: inss ?? this.inss,
        irrf: irrf ?? this.irrf,
        netSalary: netSalary ?? this.netSalary,
        fgts: fgts ?? this.fgts,
        dependents: dependents ?? this.dependents,
        otherDeductions: otherDeductions ?? this.otherDeductions,
        useSimplifiedDeduction:
            useSimplifiedDeduction ?? this.useSimplifiedDeduction,
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'salario_bruto': grossSalary,
        'inss': inss,
        'irrf': irrf,
        'salario_liquido': netSalary,
        'fgts': fgts,
        'dependentes': dependents,
        'outras_deducoes': otherDeductions,
        'desconto_simplificado': useSimplifiedDeduction,
        'updated_at': DateTime.now().toIso8601String(),
      };

  factory SalarySettings.fromJson(Map<String, dynamic> json) => SalarySettings(
        id: json['id'] as String?,
        userId: json['user_id'] as String?,
        grossSalary: (json['salario_bruto'] as num?)?.toDouble() ?? 0,
        inss: (json['inss'] as num?)?.toDouble() ?? 0,
        irrf: (json['irrf'] as num?)?.toDouble() ?? 0,
        netSalary: (json['salario_liquido'] as num?)?.toDouble() ?? 0,
        fgts: (json['fgts'] as num?)?.toDouble() ?? 0,
        dependents: (json['dependentes'] as num?)?.toInt() ?? 0,
        otherDeductions: (json['outras_deducoes'] as num?)?.toDouble() ?? 0,
        useSimplifiedDeduction:
            (json['desconto_simplificado'] as bool?) ?? false,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'] as String)
            : null,
      );
}
