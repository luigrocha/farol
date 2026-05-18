/// Farol Layout System — barrel export.
///
/// Import this single file to access all layout primitives:
///
/// ```dart
/// import 'package:farol/design/layout/layout.dart';
/// ```
///
/// Available components:
///
/// **Breakpoints**
///   [FarolBreakpoints]           — single source of truth for breakpoints
///   [FarolScreenSize]            — semantic size enum (mobile/tablet/desktop/wide)
///
/// **Scroll & Page layouts**
///   [FarolScrollPage]            — standard full-page CustomScrollView scaffold
///   [FarolPageScaffold]          — scaffold for navigated (pushed) screens
///   [FarolDetailPage]            — narrow centered detail screen
///   [FarolAdaptiveScaffold]      — scaffold that switches layout by screen size
///
/// **Responsive switching**
///   [FarolResponsiveLayout]      — build different widgets by screen size
///
/// **Content constraints**
///   [FarolContentConstraint]     — max-width + centered for desktop
///   [FarolDesktopCenteredSliver] — same, but as a sliver
///
/// **Column layouts**
///   [FarolTwoColumnLayout]       — 2-column row with flex control
///   [FarolThreeColumnLayout]     — 3-column row for wide screens
///
/// **Sliver utilities**
///   [FarolSliverItems]           — correct short-list sliver (no Column hack)
///   [FarolSliverLazyList]        — lazy SliverList (no shrinkWrap)
///   [FarolSliverPadded]          — SliverPadding wrapper
///   [FarolEmptySliver]           — capped-height empty state sliver
///
/// **Spacing**
///   [FarolBottomPadding]         — dynamic FAB + nav-bar aware bottom padding
library layout;

export 'farol_breakpoints.dart';
export 'farol_layout_widgets.dart';
export 'farol_page_scaffold.dart';
