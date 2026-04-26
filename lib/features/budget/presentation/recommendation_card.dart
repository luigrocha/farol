import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/enums.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/budget_recommendation_service.dart';
import '../../../design/farol_colors.dart' as tokens;
import '../../../core/theme/farol_colors.dart';
import 'rebalance_budget_sheet.dart';

/// Controls whether the user has clicked "Get AI Recommendation" this session.
final aiRecRequestedProvider = StateProvider.autoDispose<bool>((ref) => false);

/// The full AI recommendation UI: button → loading → card (or error).
/// Only renders when overflow is true OR no goals exist.
class AiRecommendationSection extends ConsumerWidget {
  const AiRecommendationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overflow = ref.watch(budgetPercentageOverflowProvider);
    final goals = ref.watch(budgetGoalsProvider).value ?? [];
    final noGoals = goals.isEmpty;
    if (!overflow && !noGoals) return const SizedBox.shrink();

    final dismissedAsync = ref.watch(aiRecommendationDismissedProvider);
    if (dismissedAsync.value == true) return const SizedBox.shrink();

    final requested = ref.watch(aiRecRequestedProvider);
    if (!requested) {
      return _GetButton(
        onPressed: () =>
            ref.read(aiRecRequestedProvider.notifier).state = true,
      );
    }

    return ref.watch(budgetRecommendationProvider).when(
          loading: () => const _LoadingCard(),
          error: (e, _) => _ErrorCard(
            onRetry: () => ref.invalidate(budgetRecommendationProvider),
            onDismiss: () =>
                ref.read(aiRecRequestedProvider.notifier).state = false,
          ),
          data: (rec) => _RecommendationCard(
            recommendation: rec,
            onDismiss: () async {
              final db = ref.read(databaseProvider);
              final until = DateTime.now()
                  .add(const Duration(days: 7))
                  .toIso8601String();
              await db.setSetting('ai_rec_dismissed_until', until);
              ref.invalidate(aiRecommendationDismissedProvider);
              ref.read(aiRecRequestedProvider.notifier).state = false;
            },
          ),
        );
  }
}

// ─── Get button ───────────────────────────────────────────────────────────────

class _GetButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _GetButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.FarolColors.navy.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: tokens.FarolColors.navy.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.iconTintBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome,
                size: 16, color: tokens.FarolColors.navy),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Get AI budget recommendation',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
          ),
          TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              foregroundColor: tokens.FarolColors.navy,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Analyze',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─── Loading card ─────────────────────────────────────────────────────────────

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: tokens.FarolColors.navy.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: tokens.FarolColors.navy.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: tokens.FarolColors.navy,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Analyzing your spending patterns…',
            style: TextStyle(fontSize: 13, color: colors.onSurfaceSoft),
          ),
        ],
      ),
    );
  }
}

// ─── Error card ───────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onDismiss;
  const _ErrorCard({required this.onRetry, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.orange, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Could not generate recommendations. Try again later.',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Retry',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: onDismiss,
            color: Colors.orange,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ─── Recommendation card ──────────────────────────────────────────────────────

class _RecommendationCard extends StatelessWidget {
  final BudgetRecommendation recommendation;
  final VoidCallback onDismiss;

  const _RecommendationCard({
    required this.recommendation,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.FarolColors.navy.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: tokens.FarolColors.navy.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colors.iconTintBlue,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(Icons.auto_awesome,
                    size: 14, color: tokens.FarolColors.navy),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI Budget Recommendation',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: onDismiss,
                color: colors.onSurfaceSoft,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          if (recommendation.summary.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              recommendation.summary,
              style: TextStyle(
                fontSize: 11,
                color: colors.onSurfaceSoft,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 10),
          // Diff table
          ...recommendation.recommendations.map((r) {
            final cat = _resolveCategory(r.category);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Text(
                    cat?.emoji ?? '💰',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      cat?.localizedLabel(context) ?? r.category,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${r.percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _applyRecommendation(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.FarolColors.navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text(
                'Apply recommendations',
                style:
                    TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _applyRecommendation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RebalanceBudgetSheet(
        initialPercentages: recommendation.percentageMap,
      ),
    );
  }

  ExpenseCategory? _resolveCategory(String dbValue) {
    try {
      return ExpenseCategory.fromDb(dbValue);
    } catch (_) {
      return null;
    }
  }
}
