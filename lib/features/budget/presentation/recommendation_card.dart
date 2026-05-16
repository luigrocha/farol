// lib/features/budget/presentation/recommendation_card.dart
//
// Budget recommendation widget shown in SettingsScreen above the budget goals card.
// Uses BudgetRecommendationService (50/30/20 rule + spending history) to suggest
// category budget percentages.
//
// The section is hidden by default and revealed when the user taps
// "Ver sugestões de orçamento". Once open it shows:
//   - Three bucket rows (Necessidades 50%, Desejos 30%, Investimentos 20%)
//   - Per-category suggestions with current vs. suggested indicators
//   - Overspending alerts
//   - "Aplicar sugestões" button that upserts all recommendations as budget goals

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/providers.dart';
import '../../../core/i18n/app_localizations.dart';
import '../domain/budget_recommendation.dart';
import '../domain/budget_recommendation_service.dart';

// ─── Provider ────────────────────────────────────────────────────────────────

/// Whether the recommendation section is expanded this session.
final _recExpandedProvider = StateProvider.autoDispose<bool>((ref) => false);

/// Computed recommendation from the service.
final budgetRecommendationProvider = Provider.autoDispose<BudgetRecommendation?>((ref) {
  final categoriesAsync = ref.watch(categoriesStreamProvider);
  final goals           = ref.watch(budgetGoalsProvider).value ?? [];
  final spending        = ref.watch(expensesByCategoryProvider);
  final netSalary       = ref.watch(effectiveNetSalaryProvider);

  final categories = categoriesAsync.value;
  if (categories == null || netSalary <= 0) return null;

  const service = BudgetRecommendationService();
  return service.compute(
    categories:          categories,
    expensesByCategory:  spending,
    goals:               goals,
    netSalary:           netSalary,
  );
});

// ─── Colours for buckets ─────────────────────────────────────────────────────

Color _bucketColor(RecommendationBucket b) {
  switch (b) {
    case RecommendationBucket.needs:   return const Color(0xFF2563EB); // blue
    case RecommendationBucket.wants:   return const Color(0xFFF59E0B); // amber
    case RecommendationBucket.savings: return const Color(0xFF10B981); // green
  }
}

// ─── Main widget ─────────────────────────────────────────────────────────────

/// Controls whether the user has clicked "Get AI Recommendation" this session.
// kept for backward compatibility with any lingering references
final aiRecRequestedProvider = StateProvider.autoDispose<bool>((ref) => false);

/// Budget recommendation section shown in SettingsScreen.
class AiRecommendationSection extends ConsumerWidget {
  const AiRecommendationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded = ref.watch(_recExpandedProvider);
    final rec      = ref.watch(budgetRecommendationProvider);
    final l10n     = AppLocalizations.of(context);
    final cs       = Theme.of(context).colorScheme;
    final lang     = l10n.locale.languageCode;

    // Don't render if no salary configured
    if (rec == null) return const SizedBox.shrink();

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve:    Curves.easeInOut,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Toggle button ──────────────────────────────────────────────────
          GestureDetector(
            onTap: () => ref.read(_recExpandedProvider.notifier).state = !expanded,
            child: Container(
              margin:     const EdgeInsets.only(bottom: 8),
              padding:    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color:        cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border:       Border.all(color: cs.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_outlined,
                    size:  18,
                    color: cs.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.translate('budget_rec_title'),
                      style: GoogleFonts.manrope(
                        fontSize:   13,
                        fontWeight: FontWeight.w600,
                        color:      cs.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size:  20,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // ── Recommendation content ─────────────────────────────────────────
          if (expanded) ...[
            Container(
              margin:     const EdgeInsets.only(bottom: 12),
              padding:    const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:        cs.surface,
                borderRadius: BorderRadius.circular(16),
                border:       Border.all(color: cs.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info header
                  Text(
                    rec.basedOnHistory
                        ? l10n.translate('budget_rec_history_subtitle')
                        : l10n.translate('budget_rec_rule_subtitle'),
                    style: TextStyle(
                      fontSize: 11,
                      color:    cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bucket summary bar
                  _BucketSummaryRow(lang: lang),
                  const SizedBox(height: 16),

                  // Per-category rows, grouped by bucket
                  ...RecommendationBucket.values.expand((bucket) {
                    final items = rec.items.where((i) => i.bucket == bucket).toList();
                    if (items.isEmpty) return const <Widget>[];
                    return [
                      _BucketHeader(bucket: bucket, lang: lang),
                      ...items.map((item) => _CategoryRecRow(item: item)),
                      const SizedBox(height: 12),
                    ];
                  }),

                  // Overspending alerts
                  if (rec.overspending.isNotEmpty) ...[
                    _OverspendingAlert(items: rec.overspending, lang: lang),
                    const SizedBox(height: 12),
                  ],

                  // Apply button
                  _ApplyButton(rec: rec, l10n: l10n),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Bucket summary (50 / 30 / 20 pill row) ──────────────────────────────────

class _BucketSummaryRow extends StatelessWidget {
  final String lang;
  const _BucketSummaryRow({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: RecommendationBucket.values
          .map((b) => Expanded(child: _BucketPill(bucket: b, lang: lang)))
          .toList(),
    );
  }
}

class _BucketPill extends StatelessWidget {
  final RecommendationBucket bucket;
  final String lang;
  const _BucketPill({required this.bucket, required this.lang});

  @override
  Widget build(BuildContext context) {
    final color = _bucketColor(bucket);
    return Container(
      margin:     const EdgeInsets.symmetric(horizontal: 3),
      padding:    const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            '${bucket.targetPct().toInt()}%',
            style: GoogleFonts.manrope(
              fontSize:   16,
              fontWeight: FontWeight.w800,
              color:      color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            bucket.label(lang),
            style: TextStyle(fontSize: 10, color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Bucket header ────────────────────────────────────────────────────────────

class _BucketHeader extends StatelessWidget {
  final RecommendationBucket bucket;
  final String lang;
  const _BucketHeader({required this.bucket, required this.lang});

  @override
  Widget build(BuildContext context) {
    final color = _bucketColor(bucket);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '${bucket.label(lang)} · ${bucket.targetPct().toInt()}%',
            style: GoogleFonts.manrope(
              fontSize:   12,
              fontWeight: FontWeight.w700,
              color:      color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Per-category row ─────────────────────────────────────────────────────────

class _CategoryRecRow extends StatelessWidget {
  final CategoryRecommendation item;
  const _CategoryRecRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs       = Theme.of(context).colorScheme;
    final color    = _bucketColor(item.bucket);
    final isOver   = item.isOverspending;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Category name
          Expanded(
            flex: 3,
            child: Text(
              item.name,
              style: GoogleFonts.manrope(
                fontSize:   13,
                fontWeight: FontWeight.w500,
                color:      cs.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Actual spending bar
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bar
                LayoutBuilder(builder: (ctx, constraints) {
                  final maxW = constraints.maxWidth;
                  final sugFrac = (item.suggestedPct / 100).clamp(0.0, 1.0);
                  final actFrac = (item.actualPct   / 100).clamp(0.0, 1.0);
                  return Stack(
                    children: [
                      // suggested background
                      Container(
                        height: 6,
                        width:  maxW * sugFrac,
                        decoration: BoxDecoration(
                          color:        color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      // actual spending
                      Container(
                        height: 6,
                        width:  maxW * actFrac,
                        decoration: BoxDecoration(
                          color:        isOver ? Colors.red : color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 3),
                // Labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'atual ${item.actualPct.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 10,
                        color:    isOver ? Colors.red : cs.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'sug. ${item.suggestedPct.toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 10, color: color),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Overspending alert ───────────────────────────────────────────────────────

class _OverspendingAlert extends StatelessWidget {
  final List<CategoryRecommendation> items;
  final String lang;
  const _OverspendingAlert({required this.items, required this.lang});

  @override
  Widget build(BuildContext context) {
    final names = items.map((i) => i.name).join(', ');
    final msg = lang == 'pt'
        ? 'Você está gastando mais do que o recomendado em: $names.'
        : lang == 'es'
            ? 'Estás gastando más de lo recomendado en: $names.'
            : 'You\'re spending more than recommended on: $names.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:        Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.trending_up_rounded, color: Colors.orange, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(fontSize: 11, color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Apply button ─────────────────────────────────────────────────────────────

class _ApplyButton extends ConsumerStatefulWidget {
  final BudgetRecommendation rec;
  final AppLocalizations l10n;
  const _ApplyButton({required this.rec, required this.l10n});

  @override
  ConsumerState<_ApplyButton> createState() => _ApplyButtonState();
}

class _ApplyButtonState extends ConsumerState<_ApplyButton> {
  bool _applying = false;

  @override
  Widget build(BuildContext context) {
    final cs   = Theme.of(context).colorScheme;
    final lang = widget.l10n.locale.languageCode;
    final label = lang == 'pt'
        ? 'Aplicar sugestões'
        : lang == 'es'
            ? 'Aplicar sugerencias'
            : 'Apply suggestions';

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _applying ? null : _apply,
        icon: _applying
            ? const SizedBox(
                width:  14,
                height: 14,
                child:  CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check_circle_outline, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 13)),
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          padding:         const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Future<void> _apply() async {
    setState(() => _applying = true);
    try {
      final notifier  = ref.read(budgetGoalsNotifierProvider.notifier);
      final netSalary = ref.read(effectiveNetSalaryProvider);

      // Build a category → pct map for all recommendations
      final pctMap = <String, double>{
        for (final item in widget.rec.items) item.category: item.suggestedPct,
      };

      // rebalance() handles existing goals; it ignores categories without a row.
      await notifier.rebalance(pctMap);

      // Insert goals for categories that don't have one yet (currentGoalPct == 0)
      final repo = ref.read(budgetGoalsRepositoryProvider);
      for (final item in widget.rec.items) {
        if (item.currentGoalPct == 0) {
          await repo.insert(
            category:        item.category,
            targetPercentage: item.suggestedPct,
            targetAmount:     netSalary > 0 ? (item.suggestedPct / 100) * netSalary : 0,
            type:             item.bucket == RecommendationBucket.savings ? 'savings' : 'spending',
          );
        }
      }

      // Invalidate so UI refreshes
      ref.invalidate(budgetGoalsProvider);

      // Collapse the section after applying
      if (mounted) {
        ref.read(_recExpandedProvider.notifier).state = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.l10n.locale.languageCode == 'pt'
                  ? 'Sugestões aplicadas com sucesso!'
                  : widget.l10n.locale.languageCode == 'es'
                      ? '¡Sugerencias aplicadas!'
                      : 'Suggestions applied!',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }
}
