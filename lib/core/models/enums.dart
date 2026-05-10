import 'package:flutter/material.dart';
import '../i18n/app_localizations.dart';

/// Enums used throughout the Farol application.

// ═══════════════════════════════════════════
// Income Type Enum
// ═══════════════════════════════════════════
enum IncomeType {
  netSalary('NET_SALARY', 'Net Salary', '💰'),
  swileMeal('SWILE_MEAL', 'Swile Saldo Livre', '🍽️'),
  swileFood('SWILE_FOOD', 'Swile Food', '🛒'),
  bonus('BONUS', 'Bonus', '🎉'),
  thirteenthSalary('13TH_SALARY', '13th Salary', '🎄'),
  overtime('OVERTIME', 'Overtime', '⏰'),
  other('OTHER', 'Other', '📋');

  final String dbValue;
  final String label;
  final String emoji;
  const IncomeType(this.dbValue, this.label, this.emoji);

  static IncomeType fromDb(String value) =>
      IncomeType.values.firstWhere((e) => e.dbValue == value);

  String labelForLocale(String languageCode) {
    switch (this) {
      case IncomeType.netSalary: return AppLocalizations.translateStatic(languageCode, 'income_net_salary');
      case IncomeType.swileMeal: return AppLocalizations.translateStatic(languageCode, 'income_swile_meal');
      case IncomeType.swileFood: return AppLocalizations.translateStatic(languageCode, 'income_swile_food');
      case IncomeType.bonus: return AppLocalizations.translateStatic(languageCode, 'income_bonus');
      case IncomeType.thirteenthSalary: return AppLocalizations.translateStatic(languageCode, 'income_13th');
      case IncomeType.overtime: return AppLocalizations.translateStatic(languageCode, 'income_overtime');
      case IncomeType.other: return AppLocalizations.translateStatic(languageCode, 'income_other');
    }
  }
}

/// Slugs of categories funded by Swile vouchers — excluded from cash budget pool.
const Set<String> swileCategories = {'food_grocery'};

// ═══════════════════════════════════════════
// Payment Method Enum
// ═══════════════════════════════════════════
enum PaymentMethod {
  debit('DEBIT', 'Debit', '💳'),
  creditFull('CREDIT_FULL', 'Credit (Full)', '💳'),
  creditInstallment('CREDIT_INSTALLMENT', 'Credit (Installment)', '💳'),
  pix('PIX', 'PIX', '⚡'),
  swileMeal('SWILE_MEAL', 'Swile Saldo Livre', '🍽️'),
  swileFood('SWILE_FOOD', 'Swile Food', '🛒'),
  transfer('TRANSFER', 'Transfer', '🏦');

  final String dbValue;
  final String label;
  final String emoji;
  const PaymentMethod(this.dbValue, this.label, this.emoji);

  static PaymentMethod fromDb(String value) =>
      PaymentMethod.values.firstWhere((e) => e.dbValue == value);

  String localizedLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case PaymentMethod.debit: return l10n.translate('pay_debit');
      case PaymentMethod.pix: return l10n.translate('pay_pix');
      case PaymentMethod.creditFull: return l10n.translate('pay_credit');
      case PaymentMethod.creditInstallment: return l10n.translate('pay_credit_inst');
      case PaymentMethod.swileMeal: return l10n.translate('pay_swile_meal');
      case PaymentMethod.swileFood: return l10n.translate('pay_swile_food');
      case PaymentMethod.transfer: return 'Transfer';
    }
  }

  bool get isSwile =>
      this == PaymentMethod.swileMeal || this == PaymentMethod.swileFood;
}

// ═══════════════════════════════════════════
// Pay Type Enum
// ═══════════════════════════════════════════
enum PayType {
  cash('Cash', 'Cash/Account'),
  swile('Swile', 'Swile Benefit');

  final String dbValue;
  final String label;
  const PayType(this.dbValue, this.label);

  static PayType fromDb(String value) =>
      PayType.values.firstWhere((e) => e.dbValue == value);
}

// ═══════════════════════════════════════════
// Investment Type Enum
// ═══════════════════════════════════════════
enum InvestmentType {
  tesouroSelic('TESOURO_SELIC', 'Treasury Selic', '🏛️'),
  cdb('CDB', 'CDB', '🏦'),
  lciLca('LCI_LCA', 'LCI/LCA', '🏗️'),
  fii('FII', 'Real Estate Funds', '🏢'),
  stocksBr('STOCKS_BR', 'Brazilian Stocks', '📈'),
  stocksIntl('STOCKS_INTL', 'International Stocks', '🌎'),
  pension('PENSION', 'Pension', '👴'),
  savings('SAVINGS', 'Savings', '🐷'),
  other('OTHER', 'Other', '📋');

  final String dbValue;
  final String label;
  final String emoji;
  const InvestmentType(this.dbValue, this.label, this.emoji);

  static InvestmentType fromDb(String value) =>
      InvestmentType.values.firstWhere((e) => e.dbValue == value);
}

// ═══════════════════════════════════════════
// Account Type Enum
// ═══════════════════════════════════════════
enum AccountType {
  checking('CHECKING', 'Conta Corrente', '🏦'),
  savings('SAVINGS', 'Poupança', '🐷'),
  investment('INVESTMENT', 'Conta Investimento', '📈'),
  fgts('FGTS', 'FGTS', '🏛️');

  final String dbValue;
  final String label;
  final String emoji;
  const AccountType(this.dbValue, this.label, this.emoji);

  static AccountType fromDb(String value) =>
      AccountType.values.firstWhere((e) => e.dbValue == value);

  bool get isLiquid => this != AccountType.fgts;

  String localizedLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case AccountType.checking: return l10n.accountTypeChecking;
      case AccountType.savings: return l10n.accountTypeSavings;
      case AccountType.investment: return l10n.accountTypeInvestment;
      case AccountType.fgts: return l10n.accountTypeFgts;
    }
  }
}

// ═══════════════════════════════════════════
// Installment Status Enum
// ═══════════════════════════════════════════
enum InstallmentStatus {
  active('Active', 'Active'),
  settled('Settled', 'Settled'),
  suspended('Suspended', 'Suspended');

  final String dbValue;
  final String label;
  const InstallmentStatus(this.dbValue, this.label);

  static InstallmentStatus fromDb(String value) =>
      InstallmentStatus.values.firstWhere((e) => e.dbValue == value);
}

// ═══════════════════════════════════════════
// Budget Goal Type Enum
// ═══════════════════════════════════════════
enum BudgetGoalType {
  need('Need', 'Need'),
  want('Want', 'Want'),
  invest('Invest', 'Investment');

  final String dbValue;
  final String label;
  const BudgetGoalType(this.dbValue, this.label);

  static BudgetGoalType fromDb(String value) =>
      BudgetGoalType.values.firstWhere((e) => e.dbValue == value);
}
