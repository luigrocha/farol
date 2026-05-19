import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/shimmer_box.dart';
import 'insight_card.dart';
import 'insights_screen.dart';

class InsightsPanel extends ConsumerWidget {
  const InsightsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(insightsProvider);

    return insightsAsync.when(
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.insightsLabel,
              style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey)),
          const SizedBox(height: 8),
          const ShimmerBox(
              width: double.infinity, height: 64, borderRadius: 12),
          const SizedBox(height: 8),
          const ShimmerBox(
              width: double.infinity, height: 64, borderRadius: 12),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (insights) {
        if (insights.isEmpty) return const SizedBox.shrink();

        final visible = insights.take(3).toList();
        final hasMore = insights.length > 3;

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(context.l10n.insightsLabel,
                style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey)),
            const Spacer(),
            if (hasMore)
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InsightsScreen()),
                ),
                child: Text(
                  context.l10n.insightsSeeAll(insights.length),
                  style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: const Color(0xFF2196F3),
                      fontWeight: FontWeight.w600),
                ),
              ),
          ]),
          const SizedBox(height: 8),
          ...visible.map((i) => InsightCard(insight: i)),
        ]);
      },
    );
  }
}
