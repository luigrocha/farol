/// Farol Responsive Breakpoints — single source of truth.
///
/// All layout decisions in the app MUST reference these constants.
/// Do NOT hardcode pixel values in individual screens.
///
/// Usage:
/// ```dart
/// import '../../design/layout/layout.dart';
///
/// final isDesktop = MediaQuery.sizeOf(context).width >= FarolBreakpoints.desktop;
/// ```
library farol_breakpoints;

import 'package:flutter/widgets.dart';

// ── Screen width thresholds ───────────────────────────────────────────────────

abstract final class FarolBreakpoints {
  /// Mobile — default, single-column. 0 → 599px
  static const double mobile = 0;

  /// Tablet / small desktop — shell switches from BottomNav to NavigationRail.
  /// 600px → 799px
  static const double tablet = 600;

  /// Desktop — two-column layouts activate. 800px → 1199px
  static const double desktop = 800;

  /// Wide desktop — three-column layouts activate. ≥ 1200px
  static const double wide = 1200;

  // ── Content widths ────────────────────────────────────────────────────────

  /// Maximum content width — prevents content from stretching on ultrawides.
  static const double contentMaxWidth = 1440;

  /// Narrow centered column — single-column detail screens on desktop.
  static const double contentNarrow = 680;

  /// Medium content width — used for two-column layouts.
  static const double contentMedium = 960;

  /// Desktop navigation rail width.
  static const double sidebarWidth = 212;

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns true if the screen width is at least [tablet].
  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet;

  /// Returns true if the screen width is at least [desktop].
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;

  /// Returns true if the screen width is at least [wide].
  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= wide;

  /// Returns the current [FarolScreenSize] for the given context.
  static FarolScreenSize of(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= wide) return FarolScreenSize.wide;
    if (w >= desktop) return FarolScreenSize.desktop;
    if (w >= tablet) return FarolScreenSize.tablet;
    return FarolScreenSize.mobile;
  }
}

/// Semantic screen size category.
enum FarolScreenSize { mobile, tablet, desktop, wide }

extension FarolScreenSizeX on FarolScreenSize {
  bool get isMobile => this == FarolScreenSize.mobile;
  bool get isTablet => this == FarolScreenSize.tablet;
  bool get isDesktop =>
      this == FarolScreenSize.desktop || this == FarolScreenSize.wide;
  bool get isWide => this == FarolScreenSize.wide;

  /// True for tablet and above.
  bool get isTabletOrLarger => index >= FarolScreenSize.tablet.index;

  /// True for desktop and above (≥ 800px).
  bool get isDesktopOrLarger => index >= FarolScreenSize.desktop.index;
}
