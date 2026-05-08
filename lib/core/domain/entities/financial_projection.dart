import '../value_objects/money.dart';
import 'burn_rate.dart';
import 'liquidity_risk.dart';
import 'cashflow_forecast.dart';

class FinancialProjection {
  final BurnRate burnRate;
  final Money projectedClosingBalance;
  final LiquidityRisk liquidityRisk;
  final CashflowForecast? cashflowForecast;

  const FinancialProjection({
    required this.burnRate,
    required this.projectedClosingBalance,
    required this.liquidityRisk,
    this.cashflowForecast,
  });

  bool get isProjectedNegative => projectedClosingBalance.isNegative;
}
