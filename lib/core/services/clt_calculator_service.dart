import 'financial_calculator_service.dart';

// ─── Value objects ────────────────────────────────────────────────────────────

class CltBreakdownRow {
  final String label;
  final String value;
  const CltBreakdownRow(this.label, this.value);
}

class CltResult {
  final double grossSalary;
  // INSS
  final double inss;
  final List<CltBreakdownRow> inssBreakdown;
  // IRRF
  final double irrfBase;
  final double dependentDeduction;
  final double simplifiedDeduction;
  final double reducaoMensal;
  final double irrf;
  final List<CltBreakdownRow> irrfBreakdown;
  // Net / FGTS
  final double netSalary;
  final double fgts;
  // Effective rate over gross
  final double effectiveRate;

  const CltResult({
    required this.grossSalary,
    required this.inss,
    required this.inssBreakdown,
    required this.irrfBase,
    required this.dependentDeduction,
    required this.simplifiedDeduction,
    required this.reducaoMensal,
    required this.irrf,
    required this.irrfBreakdown,
    required this.netSalary,
    required this.fgts,
    required this.effectiveRate,
  });
}

// ─── Service ──────────────────────────────────────────────────────────────────

/// CLT payroll calculator — competência 2026.
///
/// Tables: Portaria MF nº 3/2024 (INSS) and
///         Instrução Normativa RFB 2.180/2024 (IRRF).
class CltCalculatorService {
  CltCalculatorService._();

  // ── INSS 2026 (progressive) ─────────────────────────────────────────────
  // Each entry: (upper limit of bracket, rate)
  static const _inssTable = <(double, double)>[
    (1621.00, 0.075),
    (2902.84, 0.09),
    (4354.27, 0.12),
    (8475.55, 0.14), // contributions capped at this salary
  ];

  // ── IRRF 2026 (marginal bracket — deduction method) ─────────────────────
  // Each entry: (upper limit, rate, fixed deduction)
  static const _irrfTable = <(double, double, double)>[
    (2428.80, 0.000, 0.00),
    (2826.65, 0.075, 182.16),
    (3751.05, 0.150, 394.16),
    (4664.68, 0.225, 675.49),
    (double.infinity, 0.275, 908.73),
  ];

  static const _dependentDeduction = 189.59;
  static const _simplifiedDeduction = 607.20;

  // Reducão mensal applies when 5_000 < irrfBase ≤ 7_350.
  // Formula: irrf_final = irrf_raw × (irrfBase − 5000) / 2350
  // This creates a linear phase-in: 0% effective rate at R$5.000 → full IRRF at R$7.350.
  static const _reducaoLow = 5000.0;
  static const _reducaoHigh = 7350.0;

  // ── Public API ─────────────────────────────────────────────────────────────

  static CltResult compute({
    required double grossSalary,
    int dependents = 0,
    double otherDeductions = 0,
    bool useSimplifiedDeduction = false,
  }) {
    // ── INSS ──────────────────────────────────────────────────────────────
    double inss = 0;
    double prev = 0;
    final inssBreakdown = <CltBreakdownRow>[];

    for (final (limit, rate) in _inssTable) {
      if (grossSalary <= prev) break;
      final taxable = (grossSalary < limit ? grossSalary : limit) - prev;
      final contrib = _round(taxable * rate);
      inss += contrib;
      if (contrib > 0) {
        inssBreakdown.add(CltBreakdownRow(
          'Até ${FinancialCalculatorService.formatBRL(limit)} (${(rate * 100).toStringAsFixed(1)}%)',
          FinancialCalculatorService.formatBRL(contrib),
        ));
      }
      prev = limit;
    }
    inss = _round(inss);

    // ── IRRF base ─────────────────────────────────────────────────────────
    final depDeduction = _round(dependents * _dependentDeduction);
    final simpDeduction = useSimplifiedDeduction ? _simplifiedDeduction : 0.0;
    final irrfBase = _round(
      (grossSalary - inss - depDeduction - simpDeduction - otherDeductions)
          .clamp(0.0, double.infinity),
    );

    // ── IRRF raw ──────────────────────────────────────────────────────────
    double irrfRaw = 0;
    final irrfBreakdown = <CltBreakdownRow>[];

    for (final (limit, rate, ded) in _irrfTable) {
      if (irrfBase <= limit) {
        irrfRaw = _round((irrfBase * rate - ded).clamp(0.0, double.infinity));
        if (irrfRaw > 0) {
          irrfBreakdown.add(CltBreakdownRow(
            '${FinancialCalculatorService.formatBRL(irrfBase)} × ${(rate * 100).toStringAsFixed(1)}% − ${FinancialCalculatorService.formatBRL(ded)}',
            FinancialCalculatorService.formatBRL(irrfRaw),
          ));
        } else {
          irrfBreakdown.add(const CltBreakdownRow('Base de cálculo', 'Isento'));
        }
        break;
      }
    }

    // ── Reducão mensal (phase-in R$5k–R$7.35k) ───────────────────────────
    double reducaoMensal = 0;
    if (irrfBase > _reducaoLow && irrfBase <= _reducaoHigh) {
      final factor = (irrfBase - _reducaoLow) / (_reducaoHigh - _reducaoLow);
      // irrfRaw × factor means: 0% effective at 5k, 100% at 7.35k.
      reducaoMensal = _round(irrfRaw * (1 - factor));
      if (reducaoMensal > 0) {
        irrfBreakdown.add(CltBreakdownRow(
          'Reducão mensal (renda R\$5k–R\$7.35k)',
          '−${FinancialCalculatorService.formatBRL(reducaoMensal)}',
        ));
      }
    }

    final irrf = _round((irrfRaw - reducaoMensal).clamp(0.0, double.infinity));
    final netSalary = _round(grossSalary - inss - irrf);
    final fgts = _round(grossSalary * 0.08);
    final effectiveRate = grossSalary > 0
        ? _round(((inss + irrf) / grossSalary) * 100)
        : 0.0;

    return CltResult(
      grossSalary: grossSalary,
      inss: inss,
      inssBreakdown: inssBreakdown,
      irrfBase: irrfBase,
      dependentDeduction: depDeduction,
      simplifiedDeduction: simpDeduction,
      reducaoMensal: reducaoMensal,
      irrf: irrf,
      irrfBreakdown: irrfBreakdown,
      netSalary: netSalary,
      fgts: fgts,
      effectiveRate: effectiveRate,
    );
  }

  static double _round(double v) =>
      (v * 100).roundToDouble() / 100;

    // ── Rescisão (Termination) ─────────────────────────────────────────────────
 
   static RescissionResult computeRescission({
     required double grossSalary,
     required DateTime startDate,
     required DateTime endDate,
     required double fgtsBalance,
     required bool isUnjustifiedDismissal, // Demissão sem justa causa
     required bool workedNoticePeriod, // Aviso prévio trabalhado
     int unusedVacationDays = 0,
   }) {
     final yearsWorked = endDate.year - startDate.year;
     
     // 1. Saldo de Salário (Days worked in last month)
     final daysInMonth = DateTime(endDate.year, endDate.month + 1, 0).day;
     final salaryBalance = _round((grossSalary / daysInMonth) * endDate.day);
 
     // 2. 13º Proporcional
     // Rule: worked 15+ days in a month counts as a full month
     int thirteenthMonths = endDate.month;
     if (endDate.day < 15) thirteenthMonths--;
     final proportional13th = _round((grossSalary / 12) * thirteenthMonths);
 
     // 3. Férias Proporcionais + 1/3
     // Simplified: months since last anniversary or start
     final monthsForVacation = ((endDate.year * 12 + endDate.month) - (startDate.year * 12 + startDate.month)) % 12;
     final proportionalVacation = _round((grossSalary / 12) * monthsForVacation);
     final unusedVacationPay = _round((grossSalary / 30) * unusedVacationDays);
     final totalVacation = proportionalVacation + unusedVacationPay;
     final vacationThird = _round(totalVacation / 3);
 
     // 4. Aviso Prévio (Indenizado)
     double noticePeriodPay = 0;
     if (isUnjustifiedDismissal && !workedNoticePeriod) {
       // 30 days + 3 days per year worked (capped at 90 days)
       final extraDays = (yearsWorked * 3).clamp(0, 60);
       noticePeriodPay = _round((grossSalary / 30) * (30 + extraDays));
     }
 
     // 5. FGTS Multa (40%)
     double fgtsFine = 0;
     if (isUnjustifiedDismissal) {
       fgtsFine = _round(fgtsBalance * 0.40);
     }
 
     final totalGross = salaryBalance + proportional13th + totalVacation + vacationThird + noticePeriodPay + fgtsFine;
 
     return RescissionResult(
       salaryBalance: salaryBalance,
       proportional13th: proportional13th,
       proportionalVacation: proportionalVacation,
       unusedVacationPay: unusedVacationPay,
       vacationThird: vacationThird,
       noticePeriodPay: noticePeriodPay,
       fgtsFine: fgtsFine,
       totalToReceive: totalGross,
     );
   }
}

class RescissionResult {
  final double salaryBalance;
  final double proportional13th;
  final double proportionalVacation;
  final double unusedVacationPay;
  final double vacationThird;
  final double noticePeriodPay;
  final double fgtsFine;
  final double totalToReceive;

  const RescissionResult({
    required this.salaryBalance,
    required this.proportional13th,
    required this.proportionalVacation,
    required this.unusedVacationPay,
    required this.vacationThird,
    required this.noticePeriodPay,
    required this.fgtsFine,
    required this.totalToReceive,
  });
}
