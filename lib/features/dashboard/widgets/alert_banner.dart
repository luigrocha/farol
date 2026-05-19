import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/models/budget_alert.dart';
import '../../../design/farol_colors.dart' as tokens;

/// Compact single-row alert strip that stacks the top budget alert.
/// Replaces the old tall card — fits in one 36px line.
class AlertBanner extends ConsumerWidget {
  const AlertBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(budgetAlertsProvider);
    if (alerts.isEmpty) return const SizedBox.shrink();

    final top = alerts.first;
    final catsMap = ref.watch(categoriesMapProvider);

    final color = switch (top.level) {
      AlertLevel.exceeded => tokens.FarolColors.coral,
      AlertLevel.critical => const Color(0xFFFF6B35),
      AlertLevel.warning => tokens.FarolColors.beam,
    };
    final icon = switch (top.level) {
      AlertLevel.exceeded => Icons.error_outline,
      AlertLevel.critical => Icons.warning_amber_outlined,
      AlertLevel.warning => Icons.info_outline,
    };

    final catModel =
        catsMap[top.category] ?? catsMap[top.category.toLowerCase()];
    final label = catModel?.name ?? top.category;
    final emoji = catModel?.emoji ?? '📊';

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/notifications'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                '$emoji $label: ${top.percentageLabel} del presupuesto',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (alerts.length > 1) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '+${alerts.length - 1}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}
