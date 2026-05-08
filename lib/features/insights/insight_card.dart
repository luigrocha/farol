import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/domain/entities/financial_insight.dart';
import '../../core/providers/providers.dart';

class InsightCard extends ConsumerWidget {
  const InsightCard({super.key, required this.insight, this.onDismissed});
  final FinancialInsight insight;
  final VoidCallback? onDismissed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (color, icon) = _style(insight.priority);

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
              Text(insight.title,
                  style: GoogleFonts.manrope(
                      fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(insight.body,
                  style: GoogleFonts.manrope(
                      fontSize: 12, color: Colors.grey.shade700, height: 1.4)),
              if (insight.actionLabel != null) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    if (insight.actionRoute != null) {
                      Navigator.pushNamed(context, insight.actionRoute!);
                    }
                  },
                  child: Text(
                    insight.actionLabel!,
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
                ref.invalidate(dismissedInsightsProvider);
                ref.invalidate(insightsProvider);
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
