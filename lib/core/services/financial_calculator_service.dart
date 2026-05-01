import '../models/constants.dart';
import '../models/tax_calculation_result.dart';

/// Financial calculation service implementing all business logic rules.
class FinancialCalculatorService {
  FinancialCalculatorService._();

  // ═══════════════════════════════════════════
  // SAVINGS RATE
  // Rule: (Net Salary - Cash Expenses) / Net Salary × 100
  // Swile expenses excluded
  // ═══════════════════════════════════════════
  static double calculateSavingsRate(
      double netSalary, double cashExpenses) {
    if (netSalary <= 0) return 0.0;
    return ((netSalary - cashExpenses) / netSalary) * 100;
  }

  // ═══════════════════════════════════════════
  // FINANCIAL HEALTH SCORE (0–10)
  // ═══════════════════════════════════════════
  static int calculateHealthScore({
    required double netSalary,
    required double cashExpenses,
    required double housingExpenses,
    required double monthlyBalance,
    required double emergencyFund,
    required double avgMonthlyExpenses,
    required double activeInstallmentsTotal,
  }) {
    int score = 0;

    // 1. Savings rate ≥ 20% → +2 pts | 10-19% → +1 pt
    final savingsRate = calculateSavingsRate(netSalary, cashExpenses);
    if (savingsRate >= 20) {
      score += 2;
    } else if (savingsRate >= 10) {
      score += 1;
    }

    // 2. Housing ≤ 30% of net → +2 pts | 31-40% → +1 pt
    if (netSalary > 0) {
      final housingRate = housingExpenses / netSalary;
      if (housingRate <= 0.30) {
        score += 2;
      } else if (housingRate <= 0.40) {
        score += 1;
      }
    }

    // 3. No negative monthly balance → +2 pts
    if (monthlyBalance >= 0) {
      score += 2;
    }

    // 4. Emergency fund ≥ 3 months expenses → +2 pts
    if (avgMonthlyExpenses > 0 &&
        emergencyFund >= avgMonthlyExpenses * 3) {
      score += 2;
    }

    // 5. Active installments ≤ 30% of net → +1 pt
    if (netSalary > 0 &&
        activeInstallmentsTotal / netSalary <= 0.30) {
      score += 1;
    }

    // Cap at 10 (should naturally be max 9, but cap for safety)
    return score.clamp(0, 10);
  }

  /// Returns color indicator string for health score
  static String healthScoreColor(int score) {
    if (score >= 7) return 'green';
    if (score >= 4) return 'amber';
    return 'red';
  }

  /// Returns description for health score
  static String healthScoreDescription(int score) {
    if (score >= 8) return 'Excellent! Your finances are healthy.';
    if (score >= 7) return 'Very good! Keep it up.';
    if (score >= 5) return 'Fair. There is room for improvement.';
    if (score >= 3) return 'Warning! Review your spending.';
    return 'Critical! You need to act now.';
  }

  // ═══════════════════════════════════════════
  // FGTS PROJECTION
  // Rule: 8% of gross salary per month
  // ═══════════════════════════════════════════
  static double projectFgts(
      double currentBalance, int monthsAhead,
      {double? grossSalary}) {
    final monthly =
        (grossSalary ?? AppConstants.defaultGrossSalary) * AppConstants.fgtsRate;
    return currentBalance + (monthly * monthsAhead);
  }

  static double monthlyFgtsDeposit({double? grossSalary}) {
    return (grossSalary ?? AppConstants.defaultGrossSalary) *
        AppConstants.fgtsRate;
  }

  // ═══════════════════════════════════════════
  // BUDGET ALERTS
  // Rule: Alert when category reaches 80% of target
  // ═══════════════════════════════════════════
  static List<String> checkBudgetAlerts(
    Map<String, double> actualByCategory,
    Map<String, double> targetByCategory,
  ) {
    final alerts = <String>[];
    for (final category in actualByCategory.keys) {
      final actual = actualByCategory[category] ?? 0;
      final target = targetByCategory[category] ?? 0;
      if (target > 0 && actual / target >= AppConstants.budgetAlertThreshold) {
        final pct = (actual / target * 100).round();
        alerts.add(
            '$category reached $pct% of its limit (R\$ ${actual.toStringAsFixed(2)} of R\$ ${target.toStringAsFixed(2)})');
      }
    }
    return alerts;
  }

  // ═══════════════════════════════════════════
  // NET WORTH CALCULATION
  // ═══════════════════════════════════════════
  static double calculateNetWorth({
    double patrimonyTotal = 0,
    required double fgtsBalance,
    required double investmentsTotal,
    required double emergencyFund,
    required double pendingInstallments,
  }) {
    return patrimonyTotal + fgtsBalance + investmentsTotal + emergencyFund - pendingInstallments;
  }

  // ═══════════════════════════════════════════
  // 13TH SALARY CHECK
  // Rule: In Nov/Dec, show special prompt
  // ═══════════════════════════════════════════
  static bool is13thSalaryMonth(int month) {
    return month == 11 || month == 12;
  }

  static double calculate13thSalary(double grossSalary, int monthsWorked) {
    return (grossSalary / 12) * monthsWorked;
  }

  // ═══════════════════════════════════════════
  // SUGGESTED ALLOCATION (Conservative BR Profile)
  // ═══════════════════════════════════════════
  static Map<String, double> suggestedAllocation(String profile) {
    switch (profile) {
      case 'conservative':
        return {
          'Treasury Selic': 40.0,
          'CDB/LCI/LCA': 30.0,
          'Real Estate Funds': 15.0,
          'Brazilian Stocks': 10.0,
          'International Stocks': 5.0,
        };
      case 'moderate':
        return {
          'Treasury Selic': 25.0,
          'CDB/LCI/LCA': 20.0,
          'Real Estate Funds': 20.0,
          'Brazilian Stocks': 20.0,
          'International Stocks': 15.0,
        };
      default: // aggressive
        return {
          'Treasury Selic': 10.0,
          'CDB/LCI/LCA': 10.0,
          'Real Estate Funds': 20.0,
          'Brazilian Stocks': 30.0,
          'International Stocks': 30.0,
        };
    }
  }

  // ═══════════════════════════════════════════
  // TAX CALCULATIONS (2025)
  // ═══════════════════════════════════════════

  static TaxCalculationResult calculateINSS(double gross) {
    const inssTable = <(double, double)>[
      (1518.00, 0.075),
      (2793.88, 0.09),
      (4190.83, 0.12),
      (8157.41, 0.14),
    ];
    const inssMax = AppConstants.inssMax;

    double inss = 0;
    double prev = 0;
    final rows = <TaxBreakdownRow>[];

    for (final (limit, rate) in inssTable) {
      if (gross > prev) {
        final taxable = (gross < limit ? gross : limit) - prev;
        final contrib = taxable * rate;
        inss += contrib;
        if (contrib > 0) {
          rows.add(TaxBreakdownRow(
            label: 'Até ${formatBRL(limit)} (${(rate * 100).toStringAsFixed(1)}%)',
            value: formatBRL(contrib),
          ));
        }
        prev = limit;
      }
    }

    if (inss > inssMax) {
      rows.clear();
      rows.add(TaxBreakdownRow(label: 'Teto máximo INSS', value: formatBRL(inssMax)));
      inss = inssMax;
    }

    return TaxCalculationResult(total: inss, rows: rows);
  }

  static TaxCalculationResult calculateIRRF(double taxableBase, int dependents) {
    final depDeduction = dependents * AppConstants.dependentDeduction;
    final base = (taxableBase - depDeduction).clamp(0.0, double.infinity);

    const irrfTable = <(double, double, double)>[
      (2259.20, 0.0,   0.0),
      (2826.65, 0.075, 169.44),
      (3751.05, 0.15,  381.44),
      (4664.68, 0.225, 662.77),
      (double.infinity, 0.275, 896.00),
    ];

    double irrf = 0;
    final rows = <TaxBreakdownRow>[];

    for (final (limit, rate, ded) in irrfTable) {
      if (base <= limit) {
        irrf = (base * rate - ded).clamp(0.0, double.infinity);
        if (irrf > 0) {
          rows.add(TaxBreakdownRow(
            label: 'Base ${formatBRL(base)} × ${(rate * 100).toStringAsFixed(1)}%',
            value: formatBRL(irrf),
          ));
        } else {
          rows.add(TaxBreakdownRow(label: 'Base ${formatBRL(base)}', value: 'Isento'));
        }
        break;
      }
    }

    return TaxCalculationResult(total: irrf, rows: rows);
  }

  // ═══════════════════════════════════════════
  // NET SALARY CALCULATOR (Gross → Net)
  // Computes INSS + IRRF deductions from gross
  // ═══════════════════════════════════════════

  static NetSalaryResult calculateNetFromGross(double grossSalary, {int dependents = 0}) {
    if (grossSalary <= 0) {
      return NetSalaryResult(
        gross: grossSalary,
        inss: 0,
        irrf: 0,
        net: grossSalary,
        inssBreakdown: [],
        irrfBreakdown: [],
      );
    }

    final inssResult = calculateINSS(grossSalary);
    final taxableBase = grossSalary - inssResult.total;
    final irrfResult = calculateIRRF(taxableBase, dependents);
    final net = grossSalary - inssResult.total - irrfResult.total;

    return NetSalaryResult(
      gross: grossSalary,
      inss: inssResult.total,
      irrf: irrfResult.total,
      net: net,
      inssBreakdown: inssResult.rows,
      irrfBreakdown: irrfResult.rows,
    );
  }

  // ═══════════════════════════════════════════
  // RESCISSION SIMULATOR
  // ═══════════════════════════════════════════

  static double calculateFgtsFine(double fgtsBalance) {
    return fgtsBalance * 0.40;
  }

  static RescissionResult calculateRescission({
    required double grossSalary,
    required int monthsWorkedInYear,
    required double unusedVacationPay,
    required double fgtsBalance,
  }) {
    final proportional13th = (grossSalary / 12) * monthsWorkedInYear;
    final fgtsFine = calculateFgtsFine(fgtsBalance);
    final totalNet = proportional13th + unusedVacationPay + fgtsFine;

    return RescissionResult(
      proportional13th: proportional13th,
      unusedVacationPay: unusedVacationPay,
      fgtsFine: fgtsFine,
      totalNet: totalNet,
    );
  }

  static FgtsAniversarioResult calculateFgtsAniversario({
    required double currentBalance,
    required double grossSalary,
    required int birthMonth,
  }) {
    final now = DateTime.now();
    final months0 = (birthMonth - now.month + 12) % 12;
    final monthly = grossSalary * AppConstants.fgtsRate;

    double grow(double bal, int mo) => bal + monthly * mo;

    final bal1 = grow(currentBalance, months0);
    final br1 = _bracketOf(bal1);
    final w1 = bal1 * br1.rate + br1.bonus;
    final after1 = bal1 - w1;

    final bal2 = grow(after1, 12);
    final br2 = _bracketOf(bal2);
    final w2 = bal2 * br2.rate + br2.bonus;
    final after2 = bal2 - w2;

    final bal3 = grow(after2, 12);
    final br3 = _bracketOf(bal3);
    final w3 = bal3 * br3.rate + br3.bonus;

    return FgtsAniversarioResult(
      currentBalance: currentBalance,
      grossSalary: grossSalary,
      birthMonth: birthMonth,
      monthsUntilBirthday: months0,
      projectedBalance: bal1,
      withdrawalAmount: w1,
      withdrawalRate: br1.rate,
      withdrawalBonus: br1.bonus,
      balanceAfterWithdrawal: after1,
      bracketIndex: br1.idx,
      projections: [
        FgtsYearProjection(
            year: now.year, balance: bal1, withdrawal: w1, afterBalance: after1),
        FgtsYearProjection(
            year: now.year + 1,
            balance: bal2,
            withdrawal: w2,
            afterBalance: after2),
        FgtsYearProjection(
            year: now.year + 2,
            balance: bal3,
            withdrawal: w3,
            afterBalance: bal3 - w3),
      ],
    );
  }

  static ({double rate, double bonus, int idx}) _bracketOf(double balance) {
    if (balance <= 500) return (rate: 0.50, bonus: 0.0, idx: 0);
    if (balance <= 1000) return (rate: 0.40, bonus: 50.0, idx: 1);
    if (balance <= 5000) return (rate: 0.30, bonus: 80.0, idx: 2);
    if (balance <= 10000) return (rate: 0.20, bonus: 100.0, idx: 3);
    if (balance <= 15000) return (rate: 0.15, bonus: 100.0, idx: 4);
    if (balance <= 20000) return (rate: 0.10, bonus: 100.0, idx: 5);
    return (rate: 0.05, bonus: 100.0, idx: 6);
  }

  // ═══════════════════════════════════════════
  // FORMAT HELPERS
  // ═══════════════════════════════════════════
  static String formatBRL(double value) {
    final abs = value.abs();
    final formatted = abs.toStringAsFixed(2).replaceAll('.', ',');
    // Add thousand separator
    final parts = formatted.split(',');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? parts[1] : '00';
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(intPart[i]);
    }
    final sign = value < 0 ? '-' : '';
    return '${sign}R\$ $buffer,$decPart';
  }
}

class FgtsAniversarioResult {
  final double currentBalance;
  final double grossSalary;
  final int birthMonth;
  final int monthsUntilBirthday;
  final double projectedBalance;
  final double withdrawalAmount;
  final double withdrawalRate;
  final double withdrawalBonus;
  final double balanceAfterWithdrawal;
  final int bracketIndex;
  final List<FgtsYearProjection> projections;

  const FgtsAniversarioResult({
    required this.currentBalance,
    required this.grossSalary,
    required this.birthMonth,
    required this.monthsUntilBirthday,
    required this.projectedBalance,
    required this.withdrawalAmount,
    required this.withdrawalRate,
    required this.withdrawalBonus,
    required this.balanceAfterWithdrawal,
    required this.bracketIndex,
    required this.projections,
  });
}

class FgtsYearProjection {
  final int year;
  final double balance;
  final double withdrawal;
  final double afterBalance;
  const FgtsYearProjection({
    required this.year,
    required this.balance,
    required this.withdrawal,
    required this.afterBalance,
  });
}

class NetSalaryResult {
  final double gross;
  final double inss;
  final double irrf;
  final double net;
  final List<TaxBreakdownRow> inssBreakdown;
  final List<TaxBreakdownRow> irrfBreakdown;

  const NetSalaryResult({
    required this.gross,
    required this.inss,
    required this.irrf,
    required this.net,
    required this.inssBreakdown,
    required this.irrfBreakdown,
  });
}

class RescissionResult {
  final double proportional13th;
  final double unusedVacationPay;
  final double fgtsFine;
  final double totalNet;

  const RescissionResult({
    required this.proportional13th,
    required this.unusedVacationPay,
    required this.fgtsFine,
    required this.totalNet,
  });
}
