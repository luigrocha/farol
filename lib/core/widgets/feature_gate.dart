import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workspace.dart';
import '../providers/workspace_providers.dart';
import '../../design/farol_colors.dart' as tokens;

// ─────────────────────────────────────────────────────────────
// Entitlement activation flag
// Flip to true once Stripe webhook is wired and all users migrated.
// ─────────────────────────────────────────────────────────────

const _kFreemiumActive = false;

// ─────────────────────────────────────────────────────────────
// PremiumFeature enum
// ─────────────────────────────────────────────────────────────

enum PremiumFeature {
  advancedForecasting,
  aiInsights,
  multiWorkspace,
  advancedAnalytics,
  cashflowProjections,
  exportPdf,
  unlimitedInstallments,
  recurringDetection;

  bool isAllowed(WorkspacePlan plan) {
    if (!_kFreemiumActive) return true;
    return switch (this) {
      PremiumFeature.multiWorkspace => plan == WorkspacePlan.premium,
      PremiumFeature.cashflowProjections => plan == WorkspacePlan.premium,
      PremiumFeature.aiInsights => plan == WorkspacePlan.premium,
      PremiumFeature.exportPdf => plan == WorkspacePlan.premium,
      _ => true,
    };
  }

  String get label => switch (this) {
        PremiumFeature.advancedForecasting => 'Previsão avançada',
        PremiumFeature.aiInsights => 'Insights inteligentes',
        PremiumFeature.multiWorkspace => 'Múltiplos workspaces',
        PremiumFeature.advancedAnalytics => 'Análises avançadas',
        PremiumFeature.cashflowProjections => 'Projeção de caixa',
        PremiumFeature.exportPdf => 'Exportar PDF',
        PremiumFeature.unlimitedInstallments => 'Parcelamentos ilimitados',
        PremiumFeature.recurringDetection => 'Detecção de recorrências',
      };
}

// ─────────────────────────────────────────────────────────────
// FeatureGate widget
// ─────────────────────────────────────────────────────────────

/// Exibe [child] se a feature está disponível no plano atual.
/// Caso contrário exibe [fallback] ou o _UpgradePrompt padrão.
class FeatureGate extends ConsumerWidget {
  const FeatureGate({
    super.key,
    required this.feature,
    required this.child,
    this.fallback,
  });

  final PremiumFeature feature;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(workspacePlanProvider);
    if (feature.isAllowed(plan)) return child;
    return fallback ?? _UpgradePrompt(feature: feature);
  }
}

// ─────────────────────────────────────────────────────────────
// _UpgradePrompt — placeholder para paywall futuro
// ─────────────────────────────────────────────────────────────

class _UpgradePrompt extends StatelessWidget {
  const _UpgradePrompt({required this.feature});
  final PremiumFeature feature;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.FarolColors.navy.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tokens.FarolColors.navy.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 32,
            color: tokens.FarolColors.navy.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            feature.label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: tokens.FarolColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Disponível no plano Premium',
            style: TextStyle(
              fontSize: 13,
              color: tokens.FarolColors.navy.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, '/paywall'),
            style: OutlinedButton.styleFrom(
              foregroundColor: tokens.FarolColors.navy,
              side: const BorderSide(color: tokens.FarolColors.navy),
            ),
            child: const Text('Ver planos'),
          ),
        ],
      ),
    );
  }
}
