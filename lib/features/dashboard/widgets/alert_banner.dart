import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/models/budget_alert.dart';
import '../../../design/farol_colors.dart' as tokens;

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

    final catModel = catsMap[top.category];
    final label = catModel?.name ?? top.category;
    final emoji = catModel?.emoji ?? '📊';

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/notifications'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$emoji $label: ${top.percentageLabel} del presupuesto',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            if (alerts.length > 1)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '+${alerts.length - 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            Icon(Icons.chevron_right, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}
