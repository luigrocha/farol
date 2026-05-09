import 'financial_insight.dart';

/// Tracks how many times a given insight type has been dismissed by the user.
/// Used by [DismissedInsightsRepository.getStats] for dismiss rate analytics.
class InsightStats {
  final InsightType type;
  final int dismissedCount;
  final DateTime? lastDismissedAt;

  const InsightStats({
    required this.type,
    required this.dismissedCount,
    this.lastDismissedAt,
  });

  /// Human-readable label for each insight type (pt_BR).
  static String labelFor(InsightType type) => switch (type) {
        InsightType.overdraftRisk => 'Risco de saldo negativo',
        InsightType.liquidityAlert => 'Alerta de liquidez',
        InsightType.budgetOverrun => 'Orçamento estourado',
        InsightType.spendingSpike => 'Pico de gastos',
        InsightType.subscriptionCreep => 'Assinaturas acumuladas',
        InsightType.duplicateCharge => 'Cobrança duplicada',
        InsightType.unusualMerchant => 'Estabelecimento incomum',
        InsightType.savingsOpportunity => 'Oportunidade de economia',
        InsightType.earlyPayoff => 'Quitação antecipada',
        InsightType.investmentOpportunity => 'Oportunidade de investimento',
        InsightType.budgetStreak => 'Sequência no orçamento',
        InsightType.savingsRecord => 'Recorde de economia',
        InsightType.debtReduction => 'Redução de dívida',
        InsightType.categoryUnderControl => 'Categoria sob controle',
      };
}
