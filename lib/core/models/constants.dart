/// Constants used throughout the Farol application.
library;

class AppConstants {
  AppConstants._();

  // ═══════════════════════════════════════════
  // User Financial Defaults (CLT Regime)
  // ═══════════════════════════════════════════
  static const double defaultGrossSalary = 13287.90;
  static const double defaultNetSalary = 9651.91;
  static const double defaultSwileMeal = 1400.00;
  static const double defaultSwileFood = 1031.00;
  static const double defaultSwileTotal = 2431.00;

  // Fixed costs
  static const double defaultRent = 3100.00;
  static const double defaultCondo = 1100.00;
  static const double defaultFixedHousing = 4200.00;

  // FGTS
  static const double defaultFgtsBalance = 19888.00;
  static const double fgtsRate = 0.08; // 8% of gross salary
  static double get monthlyFgtsDeposit => defaultGrossSalary * fgtsRate;

  // ═══════════════════════════════════════════
  // Financial Health Score Thresholds
  // ═══════════════════════════════════════════
  static const double savingsRateGood = 0.20; // ≥ 20%
  static const double savingsRateOk = 0.10; // 10-19%
  static const double housingRateGood = 0.30; // ≤ 30%
  static const double housingRateOk = 0.40; // 31-40%
  static const double emergencyFundMonths = 3.0;
  static const double installmentRateLimit = 0.30; // ≤ 30%
  static const int healthScoreMax = 10;

  // Budget alert threshold
  static const double budgetAlertThreshold = 0.80; // 80%

  // ═══════════════════════════════════════════
  // Default Budget Goals (% of net salary)
  // ═══════════════════════════════════════════
  static const Map<String, double> defaultBudgetGoals = {
    'HOUSING': 30.0,
    'TRANSPORT': 5.0,
    'FOOD_GROCERY': 0.0, // Swile covers this
    'HEALTH': 3.0,
    'SUBSCRIPTIONS': 4.0,
    'LEISURE': 6.0,
    'EDUCATION': 2.0,
    'CARD_INSTALLMENTS': 26.0,
    'SAVINGS': 20.0,
    'OTHER': 4.0,
  };

  // ═══════════════════════════════════════════
  // UI Constants
  // ═══════════════════════════════════════════
  static const String appName = 'Farol';
  static const String currencySymbol = 'R\$';
  static const String locale = 'pt_BR';

  // Color Hex Values
  static const int primaryColor = 0xFF1B3A5C;
  static const int secondaryColor = 0xFF1A7A4A;
  static const int errorColor = 0xFFB91C1C;
  static const int warningColor = 0xFF92400E;
  static const int surfaceColor = 0xFFF3F4F6;
}
