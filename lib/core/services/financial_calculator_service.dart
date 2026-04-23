import '../models/constants.dart';

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
    required double fgtsBalance,
    required double investmentsTotal,
    required double emergencyFund,
    required double pendingInstallments,
  }) {
    return fgtsBalance + investmentsTotal + emergencyFund - pendingInstallments;
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
