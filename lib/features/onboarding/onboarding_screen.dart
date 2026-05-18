// State preserved: nav to /signup, nav to /login, i18n strings via AppLocalizations.translate,
//   aurora blobs, feature rows, page indicator dots.
// Design: navy gradient bg, beam accent, Manrope display, FarolColors tokens.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/i18n/app_localizations.dart';
import '../../design/farol_colors.dart' as tokens;
import '../../design/branding/branding.dart';
import 'onboarding_carousel.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= 800;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A1628),
              tokens.FarolColors.navy,
              Color(0xFF0F2744),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // ── Aurora blobs ─────────────────────────────────────────────────
            const Positioned(
              top: -80,
              left: -80,
              child: _Aurora(
                  color: Color(0x38F5A623)), // beam @22%
            ),
            const Positioned(
              bottom: -100,
              right: -60,
              child: _Aurora(
                  color: Color(0x241A7A4A)), // tide @14%
            ),

            // ── Content ──────────────────────────────────────────────────────
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: isWide ? 480 : double.infinity),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),

                      // ── Logo ───────────────────────────────────────────────
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: isWide ? 40 : 32),
                        child: const FarolLogo(
                          variant: FarolLogoVariant.dark,
                          markSize: FarolBrand.markSizeOnboarding,
                          showGlow: true,
                          wordmarkFontSize: 24,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Carousel ───────────────────────────────────────────
                      const Expanded(child: OnboardingCarousel()),

                      // ── CTAs ───────────────────────────────────────────────
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: isWide ? 40 : 32),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
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
                                      borderRadius:
                                          BorderRadius.circular(18)),
                                  textStyle: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15),
                                ),
                                child: Text(l10n.translate('onboarding_button')),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton(
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/login'),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                      color: Colors.white
                                          .withValues(alpha: 0.20)),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(18)),
                                  textStyle: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14),
                                ),
                                child: Text(l10n.translate('onboarding_login')),
                              ),
                            ),
                            const SizedBox(height: 28),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Aurora blob ───────────────────────────────────────────────────────────────

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
