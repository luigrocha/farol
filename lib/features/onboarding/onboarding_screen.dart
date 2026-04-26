// State preserved: nav to /signup, nav to /login, i18n strings via AppLocalizations.translate,
//   aurora blobs, feature rows, page indicator dots.
// Design: navy gradient bg, beam accent, Manrope display, FarolColors tokens.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/i18n/app_localizations.dart';
import '../../design/farol_colors.dart' as tokens;

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A1628), // deep navy
              tokens.FarolColors.navy,
              Color(0xFF0F2744),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // ── Aurora blobs ─────────────────────────────────────────
            Positioned(
              top: -80,
              left: -80,
              child: _Aurora(
                  color: tokens.FarolColors.beam.withValues(alpha: 0.22)),
            ),
            Positioned(
              bottom: -100,
              right: -60,
              child: _Aurora(
                  color: tokens.FarolColors.tide.withValues(alpha: 0.14)),
            ),

            // ── Content ──────────────────────────────────────────────
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // ── Logo mark ─────────────────────────────────────
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: tokens.FarolColors.beam,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: tokens.FarolColors.beam.withValues(alpha: 0.40),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.anchor_rounded,
                            color: tokens.FarolColors.navy,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Farol',
                          style: GoogleFonts.manrope(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // ── Eyebrow ───────────────────────────────────────
                    Text(
                      'FINANÇAS COM CLAREZA',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.w700,
                        color: tokens.FarolColors.beam.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Headline ──────────────────────────────────────
                    Text(
                      l10n.translate('onboarding_title'),
                      style: GoogleFonts.manrope(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1.6,
                        height: 1.04,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── Subtitle ──────────────────────────────────────
                    Text(
                      l10n.translate('onboarding_subtitle'),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.72),
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Feature rows ──────────────────────────────────
                    _FeatureRow(
                      icon: Icons.shield_outlined,
                      text: l10n.translate('onboarding_f1'),
                    ),
                    const SizedBox(height: 12),
                    _FeatureRow(
                      icon: Icons.auto_awesome_outlined,
                      text: l10n.translate('onboarding_f2'),
                    ),
                    const SizedBox(height: 12),
                    _FeatureRow(
                      icon: Icons.headset_mic_outlined,
                      text: l10n.translate('onboarding_f3'),
                    ),

                    const Spacer(),

                    // ── Primary CTA ───────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/signup'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tokens.FarolColors.beam,
                          foregroundColor: tokens.FarolColors.navy,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                          textStyle: GoogleFonts.inter(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        child: Text(l10n.translate('onboarding_button')),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Secondary CTA ─────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/login'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.20)),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                          textStyle: GoogleFonts.inter(
                              fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        child: Text(l10n.translate('onboarding_login')),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Page indicator ────────────────────────────────
                    const Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _Dot(active: true),
                          SizedBox(width: 6),
                          _Dot(active: false),
                          SizedBox(width: 6),
                          _Dot(active: false),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets locais ────────────────────────────────────────────────────────────

class _Aurora extends StatelessWidget {
  final Color color;
  const _Aurora({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 320,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
          stops: const [0.0, 0.65],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: tokens.FarolColors.beam.withValues(alpha: 0.15),
            border: Border.all(
                color: tokens.FarolColors.beam.withValues(alpha: 0.22)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: tokens.FarolColors.beam),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.88),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;
  const _Dot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 22 : 6,
      height: 5,
      decoration: BoxDecoration(
        color: active
            ? tokens.FarolColors.beam
            : Colors.white.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
