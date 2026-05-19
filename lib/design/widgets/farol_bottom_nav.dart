import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../farol_colors.dart' as tokens;
import '../../core/i18n/app_localizations.dart';

class FarolBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FarolBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  // Icon pairs only — labels are resolved via l10n at build time.
  static const _icons = [
    (Icons.home_outlined, Icons.home_rounded),
    (Icons.trending_up_outlined, Icons.trending_up_rounded),
    (null, null), // FAB central
    (Icons.credit_card_outlined, Icons.credit_card_rounded),
    (Icons.settings_outlined, Icons.settings_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final bgColor = isDark
        ? const Color(0xFF0E1117).withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.85);

    // Labels resolved from l10n — no hardcoded strings.
    final labels = [
      l10n.navHome,
      l10n.navInvestments,
      l10n.navAdd,
      l10n.navCards,
      l10n.navSettings,
    ];

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 72 + MediaQuery.of(context).padding.bottom,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_icons.length, (i) {
                if (i == 2)
                  return _FabItem(label: labels[i], onTap: () => onTap(i));
                final (iconOff, iconOn) = _icons[i];
                final selected = currentIndex == i;
                final color = selected
                    ? (isDark
                        ? tokens.FarolColors.beam
                        : tokens.FarolColors.navy)
                    : (isDark
                        ? tokens.FarolColors.dOnSurfaceFaint
                        : tokens.FarolColors.lOnSurfaceFaint);
                return _NavItem(
                  icon: selected ? iconOn! : iconOff!,
                  label: labels[i],
                  color: color,
                  selected: selected,
                  onTap: () => onTap(i),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FabItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FabItem({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [tokens.FarolColors.beam, tokens.FarolColors.navy],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: tokens.FarolColors.beam.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child:
                  const Icon(Icons.add_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: tokens.FarolColors.beam,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
