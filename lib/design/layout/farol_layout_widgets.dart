/// Farol Responsive Layout Widgets
///
/// Composable, reusable layout primitives for every screen in the app.
///
/// Key components:
///   - [FarolScrollPage]          → Standard full-page scroll layout
///   - [FarolResponsiveLayout]    → LayoutBuilder-based responsive switcher
///   - [FarolContentConstraint]   → Max-width container, centered on desktop
///   - [FarolBottomPadding]       → Dynamic FAB + nav-bar aware bottom padding
///   - [FarolTwoColumnLayout]     → Standard 2-column desktop row
///   - [FarolThreeColumnLayout]   → Standard 3-column wide-desktop row
///   - [FarolSliverList]          → Correct lazy SliverList (no shrinkWrap)
///   - [FarolSliverItems]         → Short known list as SliverList (no Column hack)
library farol_layout_widgets;

import 'package:flutter/material.dart';
import 'farol_breakpoints.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FarolScrollPage
// ─────────────────────────────────────────────────────────────────────────────
//
// Drop-in replacement for:
//   Scaffold(body: CustomScrollView(slivers: [...]))
//
// Features:
//   - Correct SliverAppBar with Farol defaults
//   - Optional FAB slot (positioned correctly above nav bar)
//   - Optional ConnectivityBanner slot (via top sliver)
//   - Bottom padding that respects FAB + NavigationBar
//   - Content max-width on desktop
//
// Usage:
// ```dart
// return FarolScrollPage(
//   title: Text('Transacciones'),
//   actions: [_AddButton()],
//   slivers: [_MyList(), _MyCards()],
//   fab: _MyFab(),
// );
// ```

class FarolScrollPage extends StatelessWidget {
  const FarolScrollPage({
    super.key,
    required this.slivers,
    this.title,
    this.leading,
    this.actions,
    this.fab,
    this.floatingAppBar = true,
    this.snapAppBar = true,
    this.toolbarHeight,
    this.backgroundColor,
    this.bottomBorder = true,
    this.topSliver,
    this.constrainContent = false,
    this.floatingActionButtonLocation,
  });

  /// Slivers that make up the page content (after the AppBar).
  final List<Widget> slivers;

  /// AppBar title widget.
  final Widget? title;

  /// AppBar leading widget (overrides default back button).
  final Widget? leading;

  /// AppBar action widgets.
  final List<Widget>? actions;

  /// Floating action button — positioned correctly above nav bar + safe area.
  final Widget? fab;

  /// Whether the SliverAppBar floats.
  final bool floatingAppBar;

  /// Whether the SliverAppBar snaps when floating.
  final bool snapAppBar;

  /// AppBar toolbar height override.
  final double? toolbarHeight;

  /// Scaffold background color.
  final Color? backgroundColor;

  /// Show bottom border on AppBar.
  final bool bottomBorder;

  /// Widget placed above the SliverAppBar (e.g. ConnectivityBanner).
  /// Must be a box widget (not a sliver).
  final Widget? topSliver;

  /// Wrap content in [FarolContentConstraint] on desktop.
  final bool constrainContent;

  /// FAB location in the Scaffold.
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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

    final sliverAppBar = SliverAppBar(
      floating: floatingAppBar,
      snap: floatingAppBar && snapAppBar,
      automaticallyImplyLeading: leading == null,
      leading: leading,
      title: title,
      actions: actions,
      toolbarHeight: toolbarHeight ?? kToolbarHeight,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      bottom: appBarBorder,
    );

    final effectiveSlivers = [
      sliverAppBar,
      ...slivers,
      const SliverToBoxAdapter(child: FarolBottomPadding()),
    ];

    Widget scrollView = CustomScrollView(slivers: effectiveSlivers);

    // Optionally constrain content to max desktop width
    if (constrainContent) {
      scrollView = Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: FarolBreakpoints.contentMaxWidth),
          child: scrollView,
        ),
      );
    }

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
      backgroundColor: backgroundColor,
      body: body,
      floatingActionButton: fab,
      floatingActionButtonLocation:
          floatingActionButtonLocation ?? FloatingActionButtonLocation.endFloat,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FarolResponsiveLayout
// ─────────────────────────────────────────────────────────────────────────────
//
// Layout switcher that builds different widgets based on screen size.
// Uses [FarolBreakpoints] as the single source of truth.
//
// Usage:
// ```dart
// FarolResponsiveLayout(
//   mobile: (context) => _MobileLayout(),
//   desktop: (context) => _DesktopLayout(),
//   wide: (context) => _WideLayout(),   // optional, falls back to desktop
// )
// ```

class FarolResponsiveLayout extends StatelessWidget {
  const FarolResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.wide,
  });

  final WidgetBuilder mobile;

  /// Optional tablet layout (600–799px). Falls back to [mobile] if null.
  final WidgetBuilder? tablet;

  /// Optional desktop layout (800–1199px). Falls back to [tablet] → [mobile].
  final WidgetBuilder? desktop;

  /// Optional wide layout (≥1200px). Falls back to [desktop] → [tablet] → [mobile].
  final WidgetBuilder? wide;

  @override
  Widget build(BuildContext context) {
    final size = FarolBreakpoints.of(context);

    return switch (size) {
      FarolScreenSize.wide => (wide ?? desktop ?? tablet ?? mobile)(context),
      FarolScreenSize.desktop => (desktop ?? tablet ?? mobile)(context),
      FarolScreenSize.tablet => (tablet ?? mobile)(context),
      FarolScreenSize.mobile => mobile(context),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FarolContentConstraint
// ─────────────────────────────────────────────────────────────────────────────
//
// Constrains content to [maxWidth] and centers it horizontally.
// Use inside SliverToBoxAdapter for sliver context, or directly for box context.
//
// Usage:
// ```dart
// SliverToBoxAdapter(
//   child: FarolContentConstraint(
//     child: MyContent(),
//   ),
// )
// ```

class FarolContentConstraint extends StatelessWidget {
  const FarolContentConstraint({
    super.key,
    required this.child,
    this.maxWidth = FarolBreakpoints.contentMaxWidth,
    this.padding,
    this.applyOnMobile = false,
  });

  final Widget child;

  /// Maximum content width. Defaults to [FarolBreakpoints.contentMaxWidth].
  final double maxWidth;

  /// Optional padding around the constrained content.
  final EdgeInsetsGeometry? padding;

  /// If false (default), only applies constraints on desktop (≥800px).
  /// On mobile, just passes the child through.
  final bool applyOnMobile;

  @override
  Widget build(BuildContext context) {
    final shouldConstrain =
        applyOnMobile || FarolBreakpoints.isDesktop(context);

    Widget result = shouldConstrain
        ? Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          )
        : child;

    if (padding != null) {
      result = Padding(padding: padding!, child: result);
    }

    return result;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FarolBottomPadding
// ─────────────────────────────────────────────────────────────────────────────
//
// Dynamic bottom padding that accounts for:
//   - FAB presence (56px + 16px margin = 72px baseline)
//   - NavigationBar height (when inside MainShell on mobile)
//   - System bottom safe area
//
// Replaces all hardcoded `SizedBox(height: 80)` / `SizedBox(height: 100)`.
//
// Usage:
// ```dart
// // At the end of a SliverList:
// const SliverToBoxAdapter(child: FarolBottomPadding()),
//
// // Or with extra padding:
// SliverToBoxAdapter(child: FarolBottomPadding(extra: 24)),
// ```

class FarolBottomPadding extends StatelessWidget {
  const FarolBottomPadding({
    super.key,
    this.hasFab = true,
    this.extra = 0,
  });

  /// Whether a FAB is present on this screen.
  final bool hasFab;

  /// Extra padding on top of the calculated amount.
  final double extra;

  /// Approximate height of the M3 NavigationBar.
  static const double _navBarHeight = 80.0;

  /// FAB size + its margin from the bottom edge.
  static const double _fabClearance = 88.0;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.padding.bottom;

    // On desktop (tablet+), no FAB clearance needed — FAB doesn't overlap content.
    // On mobile inside MainShell, the NavigationBar is rendered by the outer
    // Scaffold, so MediaQuery.padding.bottom already includes it after Flutter
    // applies the nav bar geometry. We add FAB clearance on top of that.
    final isDesktop = FarolBreakpoints.isTablet(context);

    final double height;
    if (isDesktop) {
      height = extra + bottomInset + 24;
    } else {
      // Mobile: account for FAB (if any) + extra + system inset.
      // The NavigationBar of MainShell raises the MediaQuery.padding.bottom,
      // so we just add FAB clearance.
      height = extra + (hasFab ? _fabClearance : 24) + bottomInset;
    }

    return SizedBox(height: height);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FarolTwoColumnLayout
// ─────────────────────────────────────────────────────────────────────────────
//
// Standard two-column layout for desktop screens (≥ [FarolBreakpoints.desktop]).
// Each column is an independent [Column] with [CrossAxisAlignment.stretch].
//
// Usage:
// ```dart
// SliverToBoxAdapter(
//   child: FarolTwoColumnLayout(
//     leftFlex: 55,
//     rightFlex: 45,
//     left: [PeriodBalanceHero(), InsightsPanel()],
//     right: [HealthGaugeCard(), KpiGrid()],
//   ),
// )
// ```

class FarolTwoColumnLayout extends StatelessWidget {
  const FarolTwoColumnLayout({
    super.key,
    required this.left,
    required this.right,
    this.leftFlex = 1,
    this.rightFlex = 1,
    this.gap = 24,
    this.padding,
    this.maxWidth = FarolBreakpoints.contentMaxWidth,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final List<Widget> left;
  final List<Widget> right;
  final int leftFlex;
  final int rightFlex;
  final double gap;
  final EdgeInsetsGeometry? padding;
  final double maxWidth;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    Widget row = Row(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Expanded(
          flex: leftFlex,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: left,
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          flex: rightFlex,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: right,
          ),
        ),
      ],
    );

    row = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: row,
      ),
    );

    if (padding != null) {
      row = Padding(padding: padding!, child: row);
    }

    return row;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FarolThreeColumnLayout
// ─────────────────────────────────────────────────────────────────────────────
//
// Standard three-column layout for wide desktop screens (≥ [FarolBreakpoints.wide]).
//
// Usage:
// ```dart
// SliverToBoxAdapter(
//   child: FarolThreeColumnLayout(
//     leftFlex: 28, centerFlex: 42, rightFlex: 30,
//     left: [LiquidityAlertCard(), KpiGrid()],
//     center: [PeriodBalanceHero(), ExpenseBreakdown()],
//     right: [HealthGaugeCard(), InstallmentsSummaryCard()],
//   ),
// )
// ```

class FarolThreeColumnLayout extends StatelessWidget {
  const FarolThreeColumnLayout({
    super.key,
    required this.left,
    required this.center,
    required this.right,
    this.leftFlex = 28,
    this.centerFlex = 42,
    this.rightFlex = 30,
    this.gap = 24,
    this.padding,
    this.maxWidth = FarolBreakpoints.contentMaxWidth,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final List<Widget> left;
  final List<Widget> center;
  final List<Widget> right;
  final int leftFlex;
  final int centerFlex;
  final int rightFlex;
  final double gap;
  final EdgeInsetsGeometry? padding;
  final double maxWidth;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    Widget row = Row(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Expanded(
          flex: leftFlex,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: left,
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          flex: centerFlex,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: center,
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          flex: rightFlex,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: right,
          ),
        ),
      ],
    );

    row = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: row,
      ),
    );

    if (padding != null) {
      row = Padding(padding: padding!, child: row);
    }

    return row;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FarolSliverItems
// ─────────────────────────────────────────────────────────────────────────────
//
// Correct way to render a short known list inside a CustomScrollView.
//
// This replaces the anti-pattern:
//   SliverToBoxAdapter(child: Column(children: items.map(...)))
//
// Which forces all items to be built at once and can cause unbounded height.
//
// Usage:
// ```dart
// FarolSliverItems(
//   items: rules.map((r) => _RuleTile(rule: r)).toList(),
// )
// ```

class FarolSliverItems extends StatelessWidget {
  const FarolSliverItems({
    super.key,
    required this.items,
    this.addSemanticIndexes = true,
  });

  final List<Widget> items;
  final bool addSemanticIndexes;

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate(
        items,
        addSemanticIndexes: addSemanticIndexes,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FarolSliverLazyList
// ─────────────────────────────────────────────────────────────────────────────
//
// Correct lazy SliverList for potentially long lists.
// Replaces ListView.builder(shrinkWrap: true, ...) patterns.
//
// Usage:
// ```dart
// FarolSliverLazyList(
//   itemCount: rules.length,
//   itemBuilder: (context, i) => _RuleTile(rule: rules[i]),
// )
// ```

class FarolSliverLazyList extends StatelessWidget {
  const FarolSliverLazyList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.separatorBuilder,
    this.findChildIndexCallback,
  });

  final int itemCount;
  final NullableIndexedWidgetBuilder itemBuilder;

  /// Optional separator between items.
  final NullableIndexedWidgetBuilder? separatorBuilder;

  final ChildIndexGetter? findChildIndexCallback;

  @override
  Widget build(BuildContext context) {
    if (separatorBuilder != null) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final itemIndex = index ~/ 2;
            if (index.isEven) {
              return itemBuilder(context, itemIndex);
            }
            return separatorBuilder!(context, itemIndex);
          },
          childCount: itemCount == 0 ? 0 : itemCount * 2 - 1,
          findChildIndexCallback: findChildIndexCallback,
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        itemBuilder,
        childCount: itemCount,
        findChildIndexCallback: findChildIndexCallback,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FarolSliverPadded
// ─────────────────────────────────────────────────────────────────────────────
//
// Sliver-aware padding wrapper. Correctly applies horizontal padding to a
// SliverList while keeping the scroll physics in the CustomScrollView.
//
// Usage:
// ```dart
// FarolSliverPadded(
//   horizontal: 16,
//   sliver: FarolSliverItems(items: [...]),
// )
// ```

class FarolSliverPadded extends StatelessWidget {
  const FarolSliverPadded({
    super.key,
    required this.sliver,
    this.horizontal = 16.0,
    this.top = 0.0,
    this.bottom = 0.0,
    this.padding,
  });

  final Widget sliver;
  final double horizontal;
  final double top;
  final double bottom;

  /// Overrides [horizontal], [top], [bottom] when provided.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final effectivePadding =
        padding ?? EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom);
    return SliverPadding(
      padding: effectivePadding,
      sliver: sliver,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FarolDesktopCenteredSliver
// ─────────────────────────────────────────────────────────────────────────────
//
// Standard sliver wrapper for desktop content with max-width constraint.
// Use when you want to put any Box widget (Row, Column, Card, etc.) in a
// sliver context on desktop and keep it centered with max width.
//
// Usage:
// ```dart
// FarolDesktopCenteredSliver(
//   padding: EdgeInsets.fromLTRB(24, 16, 24, 80),
//   child: FarolTwoColumnLayout(left: [...], right: [...]),
// )
// ```

class FarolDesktopCenteredSliver extends StatelessWidget {
  const FarolDesktopCenteredSliver({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth = FarolBreakpoints.contentMaxWidth,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    Widget content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );

    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    return SliverToBoxAdapter(child: content);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FarolEmptySliver
// ─────────────────────────────────────────────────────────────────────────────
//
// Empty state for sliver contexts. Fills remaining space and centers the
// content, but caps the height to avoid giant empty areas on desktop.
//
// Usage:
// ```dart
// FarolEmptySliver(
//   child: FarolEmptyState(type: FarolEmptyStateType.transactions),
// )
// ```

class FarolEmptySliver extends StatelessWidget {
  const FarolEmptySliver({
    super.key,
    required this.child,
    this.maxHeight = 480,
  });

  final Widget child;

  /// Max height of the empty state container. Prevents giant gray areas on desktop.
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: 240,
          maxHeight: maxHeight,
        ),
        child: Center(child: child),
      ),
    );
  }
}
