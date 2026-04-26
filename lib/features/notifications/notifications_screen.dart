import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/budget_alert.dart';
import '../../core/providers/providers.dart';
import '../../core/services/financial_calculator_service.dart';
import '../../design/farol_colors.dart' as tokens;
import '../../core/theme/farol_colors.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final alerts = ref.watch(budgetAlertsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: Text('Farol', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800)),
        actions: [Icon(Icons.notifications_active_outlined, size: 22, color: colors.onSurface), const SizedBox(width: 20)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notificaciones', style: GoogleFonts.manrope(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.7)),
            const SizedBox(height: 6),
            Text('Alertas de presupuesto en tiempo real', style: TextStyle(fontSize: 13, color: colors.onSurfaceSoft)),

            if (alerts.isEmpty) ...[
              const SizedBox(height: 40),
              _EmptyState(),
            ] else ...[
              _buildAlertGroup(context, alerts, AlertLevel.exceeded, 'Límite superado', tokens.FarolColors.coral),
              _buildAlertGroup(context, alerts, AlertLevel.critical, 'Alerta crítica', const Color(0xFFFF6B35)),
              _buildAlertGroup(context, alerts, AlertLevel.warning, 'Aviso', tokens.FarolColors.beam),
            ],

            const _CategoryLabel(label: 'Tips', color: tokens.FarolColors.tide),
            const _NotifCard(
              icon: Icons.lightbulb_outline,
              iconBg: Color(0xFFE8F5E9),
              time: '',
              title: 'Consejo del mes',
              body: 'Revisar tus presupuestos por categoría te ayuda a identificar patrones y tomar mejores decisiones financieras.',
              accent: tokens.FarolColors.tide,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertGroup(BuildContext context, List<BudgetAlert> alerts, AlertLevel level, String label, Color color) {
    final group = alerts.where((a) => a.level == level).toList();
    if (group.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CategoryLabel(label: label, color: color),
        ...group.map((a) => _AlertCard(alert: a)),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  final BudgetAlert alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = switch (alert.level) {
      AlertLevel.exceeded => tokens.FarolColors.coral,
      AlertLevel.critical => const Color(0xFFFF6B35),
      AlertLevel.warning  => tokens.FarolColors.beam,
    };
    final icon = switch (alert.level) {
      AlertLevel.exceeded => Icons.error_outline,
      AlertLevel.critical => Icons.warning_amber_outlined,
      AlertLevel.warning  => Icons.info_outline,
    };
    final bodyText = switch (alert.level) {
      AlertLevel.exceeded => 'Superaste el límite de ${FinancialCalculatorService.formatBRL(alert.limit)} en ${alert.localizedCategoryLabel(context)}. Gastado: ${FinancialCalculatorService.formatBRL(alert.spent)}.',
      AlertLevel.critical => 'Llevas el ${alert.percentageLabel} del presupuesto de ${alert.localizedCategoryLabel(context)} (${FinancialCalculatorService.formatBRL(alert.spent)} de ${FinancialCalculatorService.formatBRL(alert.limit)}).',
      AlertLevel.warning  => 'Ya usaste el ${alert.percentageLabel} del presupuesto de ${alert.localizedCategoryLabel(context)}. Quedan ${FinancialCalculatorService.formatBRL(alert.limit - alert.spent)}.',
    };

    return Column(children: [
      _NotifCard(
        accent: color,
        icon: icon,
        iconBg: color.withValues(alpha: 0.1),
        time: alert.emoji,
        title: '${alert.localizedCategoryLabel(context)} — ${alert.percentageLabel}',
        body: bodyText,
        progressValue: alert.percentage.clamp(0.0, 1.0),
        progressColor: color,
      ),
    ]);
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(children: [
        Icon(Icons.check_circle_outline, size: 48, color: tokens.FarolColors.tide.withValues(alpha: 0.5)),
        const SizedBox(height: 16),
        Text('Todo bajo control', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: colors.onSurface)),
        const SizedBox(height: 6),
        Text('Ninguna categoría supera el 75% del presupuesto', style: TextStyle(fontSize: 13, color: colors.onSurfaceSoft), textAlign: TextAlign.center),
      ]),
    );
  }
}

class _CategoryLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _CategoryLabel({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(99)),
        child: Text(label.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title, body, time;
  final Color? accent;
  final double? progressValue;
  final Color? progressColor;

  const _NotifCard({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.body,
    required this.time,
    this.accent,
    this.progressValue,
    this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: colors.surfaceLowest, borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          if (accent != null)
            Positioned(
              left: -18, top: 0, bottom: 0,
              child: Container(width: 3, decoration: BoxDecoration(color: accent, borderRadius: const BorderRadius.horizontal(right: Radius.circular(2)))),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Icon(icon, size: 20, color: accent ?? colors.onSurfaceMuted)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Expanded(child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.3, color: colors.onSurface))),
                        if (time.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(time, style: const TextStyle(fontSize: 16)),
                        ],
                      ]),
                      const SizedBox(height: 6),
                      Text(body, style: TextStyle(fontSize: 12, color: colors.onSurfaceSoft, height: 1.5)),
                    ]),
                  ),
                ],
              ),
              if (progressValue != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 5,
                    backgroundColor: (progressColor ?? tokens.FarolColors.beam).withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(progressColor ?? tokens.FarolColors.beam),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
