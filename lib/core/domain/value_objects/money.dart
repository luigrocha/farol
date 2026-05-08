import '../../services/financial_calculator_service.dart';

/// Immutable monetary value. Stored as integer cents to avoid float errors.
class Money {
  final int _cents;

  const Money._(this._cents);

  static const Money zero = Money._(0);

  factory Money.fromDouble(double amount) => Money._((amount * 100).round());
  factory Money.fromCents(int cents) => Money._(cents);

  double get amount => _cents / 100;
  int get cents => _cents;

  bool get isZero => _cents == 0;
  bool get isNegative => _cents < 0;
  bool get isPositive => _cents > 0;

  Money operator +(Money other) => Money._(_cents + other._cents);
  Money operator -(Money other) => Money._(_cents - other._cents);
  Money operator *(double factor) => Money._((_cents * factor).round());
  Money operator -() => Money._(-_cents);

  bool operator >(Money other) => _cents > other._cents;
  bool operator <(Money other) => _cents < other._cents;
  bool operator >=(Money other) => _cents >= other._cents;
  bool operator <=(Money other) => _cents <= other._cents;

  @override
  bool operator ==(Object other) => other is Money && _cents == other._cents;

  @override
  int get hashCode => _cents.hashCode;

  String get formatted => FinancialCalculatorService.formatBRL(amount);

  @override
  String toString() => formatted;
}
