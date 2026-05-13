import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/i18n/app_localizations.dart';
import '../../design/farol_colors.dart' as tokens;
import 'onboarding_slide_data.dart';

class OnboardingCarousel extends StatefulWidget {
  const OnboardingCarousel({super.key});

  @override
  State<OnboardingCarousel> createState() => _OnboardingCarouselState();
}

class _OnboardingCarouselState extends State<OnboardingCarousel> {
  final _pageCtrl = PageController();
  Timer? _timer;
  int _current = 0;
  bool _userInteracting = false;

  static const _autoplayInterval = Duration(milliseconds: 3500);
  static const _pageDuration = Duration(milliseconds: 420);
  static const _pageCurve = Curves.easeInOut;

  @override
  void initState() {
    super.initState();
    _startAutoplay();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _startAutoplay() {
    _timer?.cancel();
    _timer = Timer.periodic(_autoplayInterval, (_) {
      if (!_userInteracting && mounted) {
        final next = (_current + 1) % kOnboardingSlides.length;
        _pageCtrl.animateToPage(next,
            duration: _pageDuration, curve: _pageCurve);
      }
    });
  }

  void _stopAutoplay() {
    _timer?.cancel();
    _timer = null;
  }

  void _onPageChanged(int page) {
    setState(() => _current = page);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Slides ───────────────────────────────────────────────────────────
        Expanded(
          child: GestureDetector(
            onPanDown: (_) {
              _userInteracting = true;
              _stopAutoplay();
            },
            onPanEnd: (_) {
              _userInteracting = false;
              _startAutoplay();
            },
            onPanCancel: () {
              _userInteracting = false;
              _startAutoplay();
            },
            child: PageView.builder(
              controller: _pageCtrl,
              onPageChanged: _onPageChanged,
              physics: const BouncingScrollPhysics(),
              itemCount: kOnboardingSlides.length,
              itemBuilder: (context, index) => _OnboardingSlide(
                data: kOnboardingSlides[index],
                isActive: index == _current,
              ),
            ),
          ),
        ),

        // ── Dots ─────────────────────────────────────────────────────────────
        _DotsRow(current: _current, count: kOnboardingSlides.length),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Slide ─────────────────────────────────────────────────────────────────────

class _OnboardingSlide extends StatefulWidget {
  final OnboardingSlideData data;
  final bool isActive;

  const _OnboardingSlide({required this.data, required this.isActive});

  @override
  State<_OnboardingSlide> createState() => _OnboardingSlideState();
}

class _OnboardingSlideState extends State<_OnboardingSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _scale = Tween<double>(begin: 0.80, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _fade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_OnboardingSlide old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero icon ─────────────────────────────────────────────────
              Center(
                child: ScaleTransition(
                  scale: _scale,
                  child: _HeroIcon(icon: widget.data.heroIcon),
                ),
              ),
              const SizedBox(height: 28),

              // ── Eyebrow ───────────────────────────────────────────────────
              Text(
                l10n.translate(widget.data.eyebrowKey),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w700,
                  color: tokens.FarolColors.beam.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 12),

              // ── Headline ──────────────────────────────────────────────────
              Text(
                l10n.translate(widget.data.titleKey),
                style: GoogleFonts.manrope(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1.2,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: 28),

              // ── Feature rows ──────────────────────────────────────────────
              ...List.generate(widget.data.featureKeys.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _FeatureRow(
                    icon: widget.data.featureIcons[i],
                    text: l10n.translate(widget.data.featureKeys[i]),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero icon visual ──────────────────────────────────────────────────────────

class _HeroIcon extends StatelessWidget {
  final IconData icon;
  const _HeroIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: tokens.FarolColors.beam.withValues(alpha: 0.14),
        border: Border.all(
            color: tokens.FarolColors.beam.withValues(alpha: 0.28), width: 1.5),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: tokens.FarolColors.beam.withValues(alpha: 0.22),
            blurRadius: 32,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(icon, size: 40, color: tokens.FarolColors.beam),
    );
  }
}

// ── Feature row ───────────────────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.88),
                height: 1.45,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Dots row ──────────────────────────────────────────────────────────────────

class _DotsRow extends StatelessWidget {
  final int current;
  final int count;
  const _DotsRow({required this.current, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isActive ? 22 : 6,
            height: 5,
            decoration: BoxDecoration(
              color: isActive
                  ? tokens.FarolColors.beam
                  : Colors.white.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}
