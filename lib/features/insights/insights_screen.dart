import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/domain/entities/financial_insight.dart';
import '../../core/domain/entities/insight_stats.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/providers/providers.dart';
import 'insight_card.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(insightsProvider);

    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          floating: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(context.l10n.insightsLabel,
              style: GoogleFonts.manrope(
                  fontSize: 17, fontWeight: FontWeight.w800)),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(
                context.l10n.insightsSubtitle,
                style: GoogleFonts.manrope(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              insightsAsync.when(
                loading: () => const Center(
                    child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: CircularProgressIndicator())),
                error: (e, _) => Text('${context.l10n.error}: $e'),
                data: (insights) {
                  if (insights.isEmpty) {
                    return const _EmptyState();
                  }
                  return _GroupedInsights(insights: insights);
                },
              ),
              const SizedBox(height: 32),
              const _DismissStats(),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _GroupedInsights extends StatelessWidget {
  const _GroupedInsights({required this.insights});
  final List<FinancialInsight> insights;

  @override
  Widget build(BuildContext context) {
    final groups = {
      InsightPriority.critical: <FinancialInsight>[],
      InsightPriority.warning: <FinancialInsight>[],
      InsightPriority.info: <FinancialInsight>[],
      InsightPriority.achievement: <FinancialInsight>[],
    };
    for (final i in insights) {
      groups[i.priority]!.add(i);
    }

    final l10n = context.l10n;
    final labels = {
      InsightPriority.critical: l10n.insightsGroupCritical,
      InsightPriority.warning: l10n.insightsGroupWarning,
      InsightPriority.info: l10n.insightsGroupInfo,
      InsightPriority.achievement: l10n.insightsGroupAchievement,
    };

    final sections = <Widget>[];
    for (final entry in groups.entries) {
      if (entry.value.isEmpty) continue;
      sections.add(Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 12),
        child: Text(labels[entry.key]!,
            style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.grey,
                letterSpacing: 0.5)),
      ));
      for (final insight in entry.value) {
        sections.add(InsightCard(insight: insight));
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: sections);
  }
}

/// Section that shows which insight types the user dismisses most often.
/// Only displayed when at least one type has been dismissed ≥2 times.
class _DismissStats extends ConsumerWidget {
  const _DismissStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(insightStatsProvider);

    return statsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) {
        // Only show types dismissed at least twice — noise filter.
        final frequent = stats.where((s) => s.dismissedCount >= 2).toList();
        if (frequent.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                context.l10n.insightsMostIgnored,
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ...frequent.map((s) => _StatRow(stat: s)),
          ],
        );
      },
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.stat});
  final InsightStats stat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Expanded(
          child: Text(
            InsightStats.labelFor(stat.type),
            style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${stat.dismissedCount}×',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Text(
            context.l10n.insightsEmpty,
            textAlign: TextAlign.center,
          ),
        ),
      );
}
