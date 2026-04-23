import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/app_localizations.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D2238), // primaryDeep
              AppTheme.primaryColor,
              AppTheme.primaryContainer,
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Aurora effects
            Positioned(
              top: -80,
              left: -80,
              child: _Aurora(color: const Color(0xFF71F8E4).withOpacity(0.3)),
            ),
            Positioned(
              bottom: -100,
              right: -60,
              child: _Aurora(color: const Color(0xFF9BF6BA).withOpacity(0.18)),
            ),
            
            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Logo
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.secondaryColor.withOpacity(0.35),
                                blurRadius: 28,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.wb_sunny_outlined, color: AppTheme.primaryColor, size: 26),
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
                    
                    Text(
                      'FINANÇAS COM CLAREZA',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.secondaryColor.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      AppLocalizations.of(context).translate('onboarding_title'),
                      style: GoogleFonts.manrope(
                        fontSize: 46,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1.6,
                        height: 1.02,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppLocalizations.of(context).translate('onboarding_subtitle'),
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.75),
                        height: 1.55,
                      ),
                    ),
                    
                    const SizedBox(height: 34),
                    
                    // Features
                    _FeatureRow(
                      icon: Icons.shield_outlined,
                      text: AppLocalizations.of(context).translate('onboarding_f1'),
                    ),
                    const SizedBox(height: 12),
                    _FeatureRow(
                      icon: Icons.auto_awesome_outlined,
                      text: AppLocalizations.of(context).translate('onboarding_f2'),
                    ),
                    const SizedBox(height: 12),
                    _FeatureRow(
                      icon: Icons.headset_mic_outlined,
                      text: AppLocalizations.of(context).translate('onboarding_f3'),
                    ),
                    
                    const Spacer(),
                    
                    // Buttons
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        backgroundColor: const Color(0xFF9BF6BA),
                        foregroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 0,
                      ).copyWith(
                        backgroundColor: MaterialStateProperty.all(const Color(0xFF9BF6BA)),
                      ),
                      child: Text(
                        AppLocalizations.of(context).translate('onboarding_button'),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        side: BorderSide(color: Colors.white.withOpacity(0.18)),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: Text(
                        AppLocalizations.of(context).translate('onboarding_login'),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 22, height: 4, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 6),
                          Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 6),
                          Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
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
          stops: const [0.0, 0.6],
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
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFF9BF6BA).withOpacity(0.18),
            border: Border.all(color: const Color(0xFF9BF6BA).withOpacity(0.25)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFFFCD37D), // secondaryFixed
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 16, color: AppTheme.primaryColor),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
          ),
        ),
      ],
    );
  }
}
