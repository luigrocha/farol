/// FarolBrand — canonical brand constants.
///
/// Single source of truth for brand identity values: name, taglines,
/// dimension constants, and semantic palette aliases.
///
/// Import this file for any branded surface. Do NOT hardcode hex values
/// inline — reference [FarolBrand] or [FarolColors] from design/farol_colors.dart.
library farol_brand;

import '../farol_colors.dart' as palette;
import 'package:flutter/material.dart';

abstract final class FarolBrand {
  // ── Identity ──────────────────────────────────────────────────────────────

  static const String appName = 'Farol';

  // ── Taglines (i18n keys — use AppLocalizations in widgets) ───────────────
  //
  // These constants are the canonical *keys* to be passed to translate().
  // The human-readable defaults below document what each key means.
  //
  //   subtitleOnTrack  → "Seu dinheiro no rumo certo."
  //   subtitleAdjust   → "Vamos ajustar o rumo."
  //   subtitleNewPeriod → "Novo período, novas metas."
  //   subtitleControlled → "Tudo sob controle."
  //   subtitleNeutral  → "Acompanhando seu dinheiro."

  static const String keySubtitleOnTrack = 'subtitle_on_track';
  static const String keySubtitleAdjust = 'subtitle_adjust';
  static const String keySubtitleNewPeriod = 'subtitle_new_period';
  static const String keySubtitleControlled = 'subtitle_controlled';
  static const String keySubtitleNeutral = 'subtitle_neutral';

  static const String keyGoodMorning = 'good_morning';
  static const String keyGoodAfternoon = 'good_afternoon';
  static const String keyGoodEvening = 'good_evening';

  // ── Palette aliases (semantic layer over raw tokens) ─────────────────────

  /// Primary brand color — deep navy. Used for the logo mark background,
  /// text on light surfaces, and structural chrome elements.
  static const Color navy = palette.FarolColors.navy;

  /// Accent / beam color — warm amber. Used for the beam ray, CTAs,
  /// active states, and anything that says "direction" or "action".
  static const Color beam = palette.FarolColors.beam;

  /// Darkest navy — used for deep dark backgrounds and text on beam surfaces.
  static const Color navyDeep = palette.FarolColors.navyDeep;

  /// Sidebar background for the desktop nav rail.
  /// Slightly warmer than navyDeep to create depth layering.
  static const Color navySidebar = Color(0xFF111827);

  /// Sidebar hover/selected row background.
  static const Color navySidebarHover = Color(0xFF1A2436);

  /// Beam at 12% opacity — used for selected state backgrounds.
  static Color get beamSubtle =>
      palette.FarolColors.beam.withValues(alpha: 0.12);

  // ── Logo mark dimensions ─────────────────────────────────────────────────

  /// Mark size in the desktop nav rail (36×36).
  static const double markSizeNavRail = 36.0;

  /// Mark size in onboarding (46×46).
  static const double markSizeOnboarding = 46.0;

  /// Mark size in auth screens — login, signup (52×52).
  static const double markSizeAuth = 52.0;

  /// Mark size in compact contexts — workspace chips, list tiles (28×28).
  static const double markSizeCompact = 28.0;

  /// Default corner radius for the mark container.
  static const double markRadius = 12.0;

  /// Corner radius for the nav rail mark (slightly tighter).
  static const double markRadiusNavRail = 10.0;

  /// Corner radius for the auth mark (slightly more open).
  static const double markRadiusAuth = 16.0;

  // ── Hero gradient colors ──────────────────────────────────────────────────

  /// Gradient colors for [PeriodBalanceHero] when balance is positive.
  static const List<Color> heroGradientPositive = [
    Color(0xFF0D2238),
    Color(0xFF1A3A5C),
    Color(0xFF0D3328),
  ];

  /// Gradient colors for [PeriodBalanceHero] when balance is negative.
  static const List<Color> heroGradientNegative = [
    Color(0xFF2A0A0A),
    Color(0xFF3D1515),
    Color(0xFF1A0808),
  ];

  /// Shadow color for the positive hero card.
  static const Color heroShadowPositive = Color(0xFF1B3A5C);

  /// Shadow color for the negative hero card.
  static const Color heroShadowNegative = Color(0xFF8B0000);

  // ── Glow effect ──────────────────────────────────────────────────────────

  /// Standard beam glow — used beneath logo marks on dark surfaces.
  static List<BoxShadow> markGlow({double opacity = 0.40}) => [
        BoxShadow(
          color: palette.FarolColors.beam.withValues(alpha: opacity),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
}
