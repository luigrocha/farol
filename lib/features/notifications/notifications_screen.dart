import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: Text('Farol', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800)),
        actions: [const Icon(Icons.notifications_active_outlined, size: 22, color: AppTheme.onSurface), const SizedBox(width: 20)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notifications', style: GoogleFonts.manrope(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.7)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Manage your financial alerts', style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceSoft)),
                const Text('Mark all as read', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.secondaryColor)),
              ],
            ),

            const _CategoryLabel(label: 'Critical Alerts', color: AppTheme.errorColor),
            const _NotifCard(
              accent: AppTheme.errorColor,
              icon: Icons.error_outline,
              iconBg: Color(0xFFFFEAEA),
              time: '2h ago',
              title: 'Budget Alert: 90% of Housing budget used',
              body: 'You have reached the critical limit of your monthly housing budget. Avoid additional spending in this category.',
            ),

            const _CategoryLabel(label: 'AI Tips', color: AppTheme.secondaryColor),
            const _NotifCard(
              accent: AppTheme.secondaryColor,
              icon: Icons.lightbulb_outline,
              iconBg: AppTheme.secondaryContainer,
              time: '5h ago',
              title: 'Investment Tip: Rebalance recommended',
              body: 'Your liquidity is high, consider rebalancing. Our AI detected a diversification opportunity in ESG funds.',
              cta: 'View strategy',
            ),

            const _CategoryLabel(label: 'Updates', color: AppTheme.tertiaryColor),
            const _NotifCard(
              icon: Icons.description_outlined,
              iconBg: AppTheme.surfaceLow,
              time: 'Yesterday',
              title: 'Monthly Report ready for download',
              body: 'Your October performance summary is now available. Review your financial milestones for the month.',
            ),
            const _NotifCard(
              icon: Icons.shield_outlined,
              iconBg: AppTheme.surfaceLow,
              time: '2 days ago',
              title: 'New Privacy Policy',
              body: 'We have updated our terms to improve the security of your digital assets.',
            ),

            const SizedBox(height: 32),
            Center(
              child: Column(
                children: const [
                  Icon(Icons.check_circle_outline, size: 24, color: AppTheme.onSurfaceFaint),
                  SizedBox(height: 8),
                  Text('You are up to date with your finances', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceFaint)),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
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
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(99)),
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
  final String? cta;
  const _NotifCard({required this.icon, required this.iconBg, required this.title, required this.body, required this.time, this.accent, this.cta});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppTheme.surfaceLowest, borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          if (accent != null)
            Positioned(
              left: -18,
              top: 0,
              bottom: 0,
              child: Container(width: 3, decoration: BoxDecoration(color: accent, borderRadius: const BorderRadius.horizontal(right: Radius.circular(2)))),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                child: Center(child: Icon(icon, size: 20, color: accent ?? AppTheme.onSurfaceMuted)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.3))),
                        const SizedBox(width: 8),
                        Text(time, style: const TextStyle(fontSize: 10, color: AppTheme.onSurfaceFaint)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(body, style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceSoft, height: 1.5)),
                    if (cta != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(cta!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.secondaryColor)),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, size: 13, color: AppTheme.secondaryColor),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
