import 'package:flutter/material.dart';
import '../i18n/app_localizations.dart';

/// Enums used throughout the Farol application.

// ═══════════════════════════════════════════
// Income Type Enum
// ═══════════════════════════════════════════
enum IncomeType {
  netSalary('NET_SALARY', 'Net Salary', '💰'),
  swileMeal('SWILE_MEAL', 'Swile Meal', '🍽️'),
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
}

// ═══════════════════════════════════════════
// Expense Category Enum
// ═══════════════════════════════════════════
enum ExpenseCategory {
  housing('HOUSING', 'Housing', '🏠'),
  transport('TRANSPORT', 'Transport', '🚗'),
  foodGrocery('FOOD_GROCERY', 'Food/Grocery', '🛒'),
  health('HEALTH', 'Health', '🏥'),
  subscriptions('SUBSCRIPTIONS', 'Subscriptions', '📱'),
  leisure('LEISURE', 'Leisure', '🎮'),
  education('EDUCATION', 'Education', '📚'),
  cardInstallments('CARD_INSTALLMENTS', 'Card Installments', '💳'),
  other('OTHER', 'Other', '📋');

  final String dbValue;
  final String label;
  final String emoji;
  const ExpenseCategory(this.dbValue, this.label, this.emoji);

  static ExpenseCategory fromDb(String value) =>
      ExpenseCategory.values.firstWhere((e) => e.dbValue == value);

  String localizedLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case ExpenseCategory.housing: return l10n.translate('cat_housing');
      case ExpenseCategory.transport: return l10n.translate('cat_transport');
      case ExpenseCategory.foodGrocery: return l10n.translate('cat_food');
      case ExpenseCategory.health: return l10n.translate('cat_health');
      case ExpenseCategory.subscriptions: return l10n.translate('cat_subs');
      case ExpenseCategory.leisure: return l10n.translate('cat_leisure');
      case ExpenseCategory.education: return l10n.translate('cat_edu');
      case ExpenseCategory.cardInstallments: return l10n.translate('cat_card');
      case ExpenseCategory.other: return l10n.translate('cat_other');
    }
  }
}

// ═══════════════════════════════════════════
// Payment Method Enum
// ═══════════════════════════════════════════
enum PaymentMethod {
  debit('DEBIT', 'Debit', '💳'),
  creditFull('CREDIT_FULL', 'Credit (Full)', '💳'),
  creditInstallment('CREDIT_INSTALLMENT', 'Credit (Installment)', '💳'),
  pix('PIX', 'PIX', '⚡'),
  swileMeal('SWILE_MEAL', 'Swile Meal', '🍽️'),
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
