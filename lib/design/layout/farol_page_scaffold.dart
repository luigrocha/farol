/// FarolPageScaffold — Standard page shell for navigated screens.
///
/// Use this for screens reached via `Navigator.push` (not main nav tabs).
/// Examples: HealthScreen, InstallmentsScreen, RecurringScreen, SettingsScreen,
///           PatrimonioScreen, ThirteenthSalaryScreen, etc.
///
/// Features:
///   - Correct SliverAppBar with back button
///   - Optional FAB with correct positioning
///   - Content max-width on desktop
///   - Correct bottom padding (FarolBottomPadding)
///   - Desktop centered layout option
///   - Background color from design system
library farol_page_scaffold;

import 'package:flutter/material.dart';
import '../ds_tokens.dart';
import 'farol_breakpoints.dart';
import 'farol_layout_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FarolPageScaffold
// ─────────────────────────────────────────────────────────────────────────────

class FarolPageScaffold extends StatelessWidget {
  const FarolPageScaffold({
    super.key,
    required this.title,
    required this.slivers,
    this.leading,
    this.actions,
    this.fab,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.toolbarHeight,
    this.desktopMaxWidth = FarolBreakpoints.contentNarrow,
    this.centerContentOnDesktop = false,
    this.floatingAppBar = true,
    this.snapAppBar = true,
    this.bottomBorder = true,
    this.topSliver,
  });

  /// AppBar title text or widget.
  final Widget title;

  /// Page content slivers. [FarolBottomPadding] is automatically appended.
  final List<Widget> slivers;

  /// AppBar leading override. Defaults to back button.
  final Widget? leading;

  /// AppBar trailing actions.
  final List<Widget>? actions;

  /// Optional FAB. Positioned above bottom padding.
  final Widget? fab;

  /// FAB location in the Scaffold.
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// Scaffold/AppBar background color.
  final Color? backgroundColor;

  /// Toolbar height override.
  final double? toolbarHeight;

  /// Max content width on desktop (≥ 800px). Default: [FarolBreakpoints.contentNarrow].
  final double desktopMaxWidth;

  /// Whether to center and constrain content on desktop.
  final bool centerContentOnDesktop;

  /// Whether the SliverAppBar floats.
  final bool floatingAppBar;

  /// Whether the SliverAppBar snaps.
  final bool snapAppBar;

  /// Show bottom border on AppBar.
  final bool bottomBorder;

  /// Optional widget above AppBar (e.g. ConnectivityBanner).
  final Widget? topSliver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = backgroundColor ?? theme.colorScheme.surface;

    final appBarBorder = bottomBorder
        ? PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFF1B3A5C).withValues(alpha: 0.06),
            ),
          )
        : null;

    final isDesktop = FarolBreakpoints.isDesktop(context);
    final hasFab = fab != null;

    final effectiveSlivers = [
      SliverAppBar(
        floating: floatingAppBar,
        snap: floatingAppBar && snapAppBar,
        automaticallyImplyLeading: leading == null,
        leading: leading,
        title: title,
        actions: actions,
        toolbarHeight: toolbarHeight ?? kToolbarHeight,
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        bottom: appBarBorder,
      ),
      // On desktop with centerContentOnDesktop, wrap slivers in a constrained box
      if (centerContentOnDesktop && isDesktop) ...[
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: desktopMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Inner slivers rendered as box widgets inside the constraint
                  // Note: for complex sliver needs, don't use centerContentOnDesktop
                ],
              ),
            ),
          ),
        ),
      ] else
        ...slivers,
      SliverToBoxAdapter(child: FarolBottomPadding(hasFab: hasFab)),
    ];

    Widget scrollView = CustomScrollView(slivers: effectiveSlivers);

    Widget body = scrollView;
    if (topSliver != null) {
      body = Column(
        children: [
          topSliver!,
          Expanded(child: scrollView),
        ],
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: body,
      floatingActionButton: fab,
      floatingActionButtonLocation:
          floatingActionButtonLocation ?? FloatingActionButtonLocation.endFloat,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FarolDetailPage
// ─────────────────────────────────────────────────────────────────────────────
//
// Simplified version of [FarolPageScaffold] for detail/secondary screens
// that need a narrow centered layout on desktop.
//
// The content is always centered and constrained to [FarolBreakpoints.contentNarrow].
//
// Usage:
// ```dart
// return FarolDetailPage(
//   title: Text('Saúde Financeira'),
//   child: _HealthContent(),
// );
// ```

class FarolDetailPage extends StatelessWidget {
  const FarolDetailPage({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.fab,
    this.backgroundColor,
    this.horizontalPadding = DSSpacing.lg,
    this.maxWidth = FarolBreakpoints.contentNarrow,
  });

  final Widget title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? fab;
  final Color? backgroundColor;
  final double horizontalPadding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasFab = fab != null;

    return Scaffold(
      backgroundColor: backgroundColor ?? theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: title,
            actions: actions,
            backgroundColor: backgroundColor ?? theme.colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFF1B3A5C).withValues(alpha: 0.06),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FarolContentConstraint(
              maxWidth: maxWidth,
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: child,
            ),
          ),
          SliverToBoxAdapter(child: FarolBottomPadding(hasFab: hasFab)),
        ],
      ),
      floatingActionButton: fab,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FarolAdaptiveScaffold
// ─────────────────────────────────────────────────────────────────────────────
//
// Advanced scaffold that renders different layouts based on screen size.
// Useful for screens with distinct mobile vs desktop UX (not just column count).
//
// Usage:
// ```dart
// return FarolAdaptiveScaffold(
//   mobile: _MobileLayout(),
//   desktop: _DesktopLayout(),
// );
// ```

class FarolAdaptiveScaffold extends StatelessWidget {
  const FarolAdaptiveScaffold({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.wide,
    this.backgroundColor,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? wide;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final size = FarolBreakpoints.of(context);

    final child = switch (size) {
      FarolScreenSize.wide => wide ?? desktop ?? tablet ?? mobile,
      FarolScreenSize.desktop => desktop ?? tablet ?? mobile,
      FarolScreenSize.tablet => tablet ?? mobile,
      FarolScreenSize.mobile => mobile,
    };

    return Scaffold(
      backgroundColor: backgroundColor,
      body: child,
    );
  }
}
