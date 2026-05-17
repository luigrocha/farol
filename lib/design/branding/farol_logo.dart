/// FarolLogo — canonical logo widget system.
///
/// This is the single source of truth for how the Farol brand mark
/// appears in the UI. Every branded surface must use [FarolMark] or
/// [FarolLogo] instead of building its own inline Container + Icon.
///
/// Usage:
/// ```dart
/// // Mark only (icon square) — nav rail, compact chips
/// FarolMark(size: FarolBrand.markSizeNavRail)
///
/// // Mark + wordmark — onboarding, auth screens
/// FarolLogo(variant: FarolLogoVariant.dark, showGlow: true)
///
/// // On light background
/// FarolLogo(variant: FarolLogoVariant.light)
/// ```
library farol_logo;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'farol_brand.dart';
import '../farol_colors.dart' as palette;

// ── Logo variant ──────────────────────────────────────────────────────────────

/// Controls the color scheme of [FarolLogo] and [FarolMark].
enum FarolLogoVariant {
  /// Navy mark + navy wordmark — for use on white/light surfaces.
  light,

  /// Navy mark + white wordmark — for use on dark/navy surfaces (onboarding, splash).
  dark,

  /// All-white mark + white wordmark — for use embedded in navy containers.
  mono,
}

// ── FarolMark ─────────────────────────────────────────────────────────────────

/// The Farol icon mark — a rounded square with the beam symbol inside.
///
/// This is the smallest atomic branding unit. Use it wherever a compact
/// brand presence is needed: nav rail, app bar chips, list tiles.
///
/// The beam symbol is currently rendered as [Icons.anchor_rounded] as a
/// placeholder. TODO(branding): replace with custom BeamPainter once the
/// vector asset is available.
class FarolMark extends StatelessWidget {
  const FarolMark({
    super.key,
    this.size = FarolBrand.markSizeNavRail,
    this.radius,
    this.variant = FarolLogoVariant.light,
    this.showGlow = false,
    this.glowOpacity = 0.35,
  });

  /// The width and height of the mark container.
  final double size;

  /// Corner radius. Defaults to a proportional value based on [size].
  final double? radius;

  /// Controls foreground/background colors.
  final FarolLogoVariant variant;

  /// Whether to render the amber glow beneath the mark.
  /// Recommended only on dark backgrounds (onboarding, splash).
  final bool showGlow;

  /// Opacity of the glow shadow. Only meaningful when [showGlow] is true.
  final double glowOpacity;

  double get _radius => radius ?? _defaultRadius(size);

  static double _defaultRadius(double size) {
    if (size <= 30) return 8;
    if (size <= 40) return 10;
    if (size <= 50) return 12;
    return 14;
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors(variant);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: showGlow ? FarolBrand.markGlow(opacity: glowOpacity) : null,
      ),
      child: Icon(
        // TODO(branding): replace with custom BeamPainter asset
        Icons.anchor_rounded,
        color: fg,
        size: size * 0.54,
      ),
    );
  }

  static (Color bg, Color fg) _colors(FarolLogoVariant variant) {
    return switch (variant) {
      FarolLogoVariant.light => (palette.FarolColors.navy, Colors.white),
      FarolLogoVariant.dark  => (palette.FarolColors.beam, palette.FarolColors.navyDeep),
      FarolLogoVariant.mono  => (Colors.white.withValues(alpha: 0.15), Colors.white),
    };
  }
}

// ── FarolLogo ─────────────────────────────────────────────────────────────────

/// The full Farol logo: [FarolMark] + "Farol" wordmark side by side.
///
/// Use this in hero contexts where the brand needs full identification:
/// onboarding, auth screens, splash screens, marketing surfaces.
class FarolLogo extends StatelessWidget {
  const FarolLogo({
    super.key,
    this.variant = FarolLogoVariant.light,
    this.markSize = FarolBrand.markSizeOnboarding,
    this.showWordmark = true,
    this.showGlow = false,
    this.wordmarkFontSize = 24.0,
    this.spacing = 12.0,
  });

  final FarolLogoVariant variant;

  /// Size of the [FarolMark] within this logo.
  final double markSize;

  /// Whether to show the "Farol" text wordmark.
  final bool showWordmark;

  /// Whether to show the amber glow under the mark.
  final bool showGlow;

  /// Font size of the wordmark text. Defaults to 24.
  final double wordmarkFontSize;

  /// Horizontal gap between mark and wordmark.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final wordmarkColor = _wordmarkColor(variant);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FarolMark(
          size: markSize,
          variant: variant,
          showGlow: showGlow,
        ),
        if (showWordmark) ...[
          SizedBox(width: spacing),
          Text(
            FarolBrand.appName,
            style: GoogleFonts.manrope(
              fontSize: wordmarkFontSize,
              fontWeight: FontWeight.w800,
              color: wordmarkColor,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ],
    );
  }

  static Color _wordmarkColor(FarolLogoVariant variant) {
    return switch (variant) {
      FarolLogoVariant.light => palette.FarolColors.navy,
      FarolLogoVariant.dark  => Colors.white,
      FarolLogoVariant.mono  => Colors.white,
    };
  }
}

// ── FarolLogoStack ────────────────────────────────────────────────────────────

/// Stacked layout: mark on top, wordmark below.
/// Used in contexts where horizontal space is constrained (e.g. narrow nav rail).
class FarolLogoStack extends StatelessWidget {
  const FarolLogoStack({
    super.key,
    this.variant = FarolLogoVariant.light,
    this.markSize = FarolBrand.markSizeNavRail,
    this.showGlow = false,
  });

  final FarolLogoVariant variant;
  final double markSize;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final wordmarkColor = FarolLogo._wordmarkColor(variant);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FarolMark(size: markSize, variant: variant, showGlow: showGlow),
        const SizedBox(height: 6),
        Text(
          FarolBrand.appName,
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: wordmarkColor,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
