import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/domain/entities/financial_insight.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/providers/providers.dart';

class InsightCard extends ConsumerWidget {
  const InsightCard({super.key, required this.insight, this.onDismissed});
  final FinancialInsight insight;
  final VoidCallback? onDismissed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (color, icon) = _style(insight.priority);
    final l10n = context.l10n;
    final title = _resolveTitle(l10n);
    final body = _resolveBody(l10n);
    final actionLabel = insight.actionKey != null ? _resolveAction(l10n) : insight.actionLabel;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: GoogleFonts.manrope(
                      fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(body,
                  style: GoogleFonts.manrope(
                      fontSize: 12, color: Colors.grey.shade700, height: 1.4)),
              if (actionLabel != null) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    if (insight.actionRoute != null) {
                      Navigator.pushNamed(context, insight.actionRoute!);
                    }
                  },
                  child: Text(
                    actionLabel,
                    style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ]),
          ),
          if (insight.isDismissable)
            GestureDetector(
              onTap: () async {
                final repo =
                    ref.read(dismissedInsightsRepositoryProvider);
                await repo.dismiss(
                    insight.dismissGroup ?? insight.id);
                await repo.trackDismiss(insight.type);
                ref.invalidate(dismissedInsightsProvider);
                ref.invalidate(insightsProvider);
                ref.invalidate(insightStatsProvider);
                onDismissed?.call();
              },
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close, size: 14, color: Colors.grey.shade400),
              ),
            ),
        ]),
      ),
    );
  }

  String _resolveTitle(AppLocalizations l10n) {
    final d = insight.data;
    switch (insight.titleKey) {
      case 'insight_overdraft_title': return l10n.insightOverdraftTitle;
      case 'insight_liquidity_critical_title': return l10n.insightLiquidityCriticalTitle;
      case 'insight_liquidity_warning_title': return l10n.insightLiquidityWarningTitle;
      case 'insight_spike_title': return l10n.insightSpikeTitle('${d['category'] ?? ''}');
      case 'insight_duplicate_title': return l10n.insightDuplicateTitle;
      case 'insight_subscription_title': return l10n.insightSubscriptionTitle;
      case 'insight_savings_title': return l10n.insightSavingsTitle('${d['categoryName'] ?? d['category'] ?? ''}');
      case 'insight_invest_title': return l10n.insightInvestTitle('${d['amountFormatted'] ?? ''}');
      case 'insight_streak_title': return l10n.insightStreakTitle((d['streak'] as num?)?.toInt() ?? 0);
      case 'insight_debt_title': return l10n.insightDebtTitle;
      case 'insight_unusual_title': return l10n.insightUnusualTitle;
      default: return insight.title;
    }
  }

  String _resolveBody(AppLocalizations l10n) {
    final d = insight.data;
    switch (insight.bodyKey) {
      case 'insight_overdraft_body':
        return l10n.insightOverdraftBody('${d['projectedFormatted'] ?? ''}', '${d['obligationsFormatted'] ?? ''}');
      case 'insight_liquidity_body':
        return l10n.insightLiquidityBody('${d['balanceFormatted'] ?? ''}', '${d['obligationsFormatted'] ?? ''}');
      case 'insight_spike_body':
        return l10n.insightSpikeBody('${d['currentFormatted'] ?? ''}', '${d['averageFormatted'] ?? ''}', '${d['deviationPct'] ?? ''}');
      case 'insight_duplicate_body':
        return l10n.insightDuplicateBody('${d['count'] ?? ''}', '${d['desc'] ?? ''}', '${d['amountFormatted'] ?? ''}', '${d['days'] ?? ''}');
      case 'insight_subscription_body':
        return l10n.insightSubscriptionBody('${d['growthFormatted'] ?? ''}');
      case 'insight_savings_body':
        return l10n.insightSavingsBody('${d['categoryName'] ?? d['category'] ?? ''}', '${d['overspentFormatted'] ?? ''}');
      case 'insight_invest_body':
        return l10n.insightInvestBody('${d['amountFormatted'] ?? ''}');
      case 'insight_streak_body':
        return l10n.insightStreakBody((d['streak'] as num?)?.toInt() ?? 0);
      case 'insight_debt_body':
        return l10n.insightDebtBody('${d['reductionFormatted'] ?? ''}');
      case 'insight_unusual_body':
        return l10n.insightUnusualBody('${d['desc'] ?? ''}', '${d['amountFormatted'] ?? ''}');
      default: return insight.body;
    }
  }

  String? _resolveAction(AppLocalizations l10n) {
    final d = insight.data;
    switch (insight.actionKey) {
      case 'insight_overdraft_action': return l10n.insightOverdraftAction;
      case 'insight_spike_action': return l10n.insightSpikeAction('${d['category'] ?? ''}');
      case 'insight_duplicate_action': return l10n.insightDuplicateAction;
      case 'insight_subscription_action': return l10n.insightSubscriptionAction;
      case 'insight_savings_action': return l10n.insightSavingsAction;
      case 'insight_invest_action': return l10n.insightInvestAction;
      case 'insight_unusual_action': return l10n.insightUnusualAction;
      default: return insight.actionLabel;
    }
  }

  (Color, IconData) _style(InsightPriority p) => switch (p) {
        InsightPriority.critical => (Colors.red, Icons.error_outline_rounded),
        InsightPriority.warning =>
          (const Color(0xFFF59E0B), Icons.warning_amber_rounded),
        InsightPriority.info =>
          (const Color(0xFF2196F3), Icons.lightbulb_outline),
        InsightPriority.achievement =>
          (const Color(0xFF00897B), Icons.emoji_events_outlined),
      };
}
