/// Design System Tokens — Farol Premium UI
///
/// Single source of truth for spacing, radius, shadows, durations and
/// interactive hover/press states. Import this file whenever you need
/// consistent design values across the app.
library ds_tokens;

import 'package:flutter/material.dart';

// ── Spacing ──────────────────────────────────────────────────────────────────

abstract final class DSSpacing {
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 16;
  static const double xl  = 20;
  static const double xxl = 24;
  static const double h   = 32;
  static const double hh  = 40;
  static const double p   = 48;
  static const double pp  = 64;
}

// ── Radius ────────────────────────────────────────────────────────────────────

abstract final class DSRadius {
  static const double xs  = 6;
  static const double sm  = 10;
  static const double md  = 14;
  static const double lg  = 18;
  static const double xl  = 24;
  static const double xxl = 32;
  static const double full = 999;

  static BorderRadius get xsBR  => BorderRadius.circular(xs);
  static BorderRadius get smBR  => BorderRadius.circular(sm);
  static BorderRadius get mdBR  => BorderRadius.circular(md);
  static BorderRadius get lgBR  => BorderRadius.circular(lg);
  static BorderRadius get xlBR  => BorderRadius.circular(xl);
  static BorderRadius get xxlBR => BorderRadius.circular(xxl);
  static BorderRadius get fullBR => BorderRadius.circular(full);
}

// ── Shadows ───────────────────────────────────────────────────────────────────

abstract final class DSShadow {
  /// Ultra-subtle card shadow for light mode
  static List<BoxShadow> get card => [
    BoxShadow(
      color: const Color(0xFF1B3A5C).withValues(alpha: 0.06),
      blurRadius: 16,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: const Color(0xFF1B3A5C).withValues(alpha: 0.03),
      blurRadius: 4,
      spreadRadius: 0,
      offset: const Offset(0, 1),
    ),
  ];

  /// Elevated card (hover state)
  static List<BoxShadow> get cardHover => [
    BoxShadow(
      color: const Color(0xFF1B3A5C).withValues(alpha: 0.10),
      blurRadius: 24,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: const Color(0xFF1B3A5C).withValues(alpha: 0.04),
      blurRadius: 6,
      spreadRadius: 0,
      offset: const Offset(0, 2),
    ),
  ];

  /// Dark mode card shadow
  static List<BoxShadow> get cardDark => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.25),
      blurRadius: 16,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];

  /// Dark mode hover shadow
  static List<BoxShadow> get cardDarkHover => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.40),
      blurRadius: 24,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
  ];

  /// Hero card (large prominent cards)
  static List<BoxShadow> get hero => [
    BoxShadow(
      color: const Color(0xFF1B3A5C).withValues(alpha: 0.18),
      blurRadius: 32,
      spreadRadius: -4,
      offset: const Offset(0, 12),
    ),
  ];
}

// ── Animation Durations ───────────────────────────────────────────────────────

abstract final class DSDuration {
  static const fast     = Duration(milliseconds: 120);
  static const normal   = Duration(milliseconds: 200);
  static const medium   = Duration(milliseconds: 300);
  static const slow     = Duration(milliseconds: 450);
  static const verySlow = Duration(milliseconds: 600);
}

// ── Curves ────────────────────────────────────────────────────────────────────

abstract final class DSCurve {
  static const enter = Curves.easeOut;
  static const exit  = Curves.easeIn;
  static const inOut = Curves.easeInOut;
  static const spring = Curves.elasticOut;
  static const smooth = Curves.fastOutSlowIn;
}

// ── Hover Card ────────────────────────────────────────────────────────────────
///
/// A card that elevates on hover (desktop) and scales slightly on press.
/// Wraps any child widget with animation and optional tap callback.
///
class DSCard extends StatefulWidget {
  const DSCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.color,
    this.borderColor,
    this.radius,
    this.hoverScale = 1.0,
    this.pressScale = 0.985,
    this.enableHover = true,
    this.enableShadow = true,
    this.gradient,
    this.height,
    this.width,
    this.borderWidth = 1.0,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;
  final double? radius;
  final double hoverScale;
  final double pressScale;
  final bool enableHover;
  final bool enableShadow;
  final Gradient? gradient;
  final double? height;
  final double? width;
  final double borderWidth;

  @override
  State<DSCard> createState() => _DSCardState();
}

class _DSCardState extends State<DSCard> with SingleTickerProviderStateMixin {
  bool _hovered = false;
  bool _pressed = false;

  late final AnimationController _ctrl;
  late final Animation<double> _elevation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: DSDuration.normal);
    _elevation = CurvedAnimation(parent: _ctrl, curve: DSCurve.smooth);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onHoverChange(bool val) {
    if (!widget.enableHover) return;
    setState(() => _hovered = val);
    if (val) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = widget.radius ?? DSRadius.xl;
    final bgColor = widget.color ?? (isDark
        ? const Color(0xFF1C3047)
        : Colors.white);
    final border = widget.borderColor ?? (isDark
        ? Colors.white.withValues(alpha: 0.07)
        : const Color(0xFF1B3A5C).withValues(alpha: 0.06));

    return MouseRegion(
      onEnter: (_) => _onHoverChange(true),
      onExit:  (_) => _onHoverChange(false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: widget.onTap != null
            ? (_) => setState(() => _pressed = true)
            : null,
        onTapUp: widget.onTap != null
            ? (_) => setState(() => _pressed = false)
            : null,
        onTapCancel: widget.onTap != null
            ? () => setState(() => _pressed = false)
            : null,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? widget.pressScale : 1.0,
          duration: DSDuration.fast,
          curve: DSCurve.inOut,
          child: AnimatedBuilder(
            animation: _elevation,
            builder: (context, child) {
              final shadows = widget.enableShadow
                  ? (isDark
                      ? (_hovered ? DSShadow.cardDarkHover : DSShadow.cardDark)
                      : (_hovered ? DSShadow.cardHover : DSShadow.card))
                  : <BoxShadow>[];

              return Container(
                height: widget.height,
                width: widget.width,
                padding: widget.padding ?? const EdgeInsets.all(DSSpacing.xl),
                decoration: BoxDecoration(
                  color: widget.gradient == null ? bgColor : null,
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular(r),
                  border: Border.all(color: border, width: widget.borderWidth),
                  boxShadow: shadows,
                ),
                child: child,
              );
            },
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// ── Animated Progress Bar ─────────────────────────────────────────────────────

class DSProgressBar extends StatelessWidget {
  const DSProgressBar({
    super.key,
    required this.value,
    this.color,
    this.backgroundColor,
    this.height = 6,
    this.radius,
    this.animate = true,
  });

  final double value; // 0.0 → 1.0
  final Color? color;
  final Color? backgroundColor;
  final double height;
  final double? radius;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barColor = color ?? const Color(0xFF1A7A4A);
    final bgColor = backgroundColor ?? (isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFF1B3A5C).withValues(alpha: 0.07));
    final r = radius ?? height / 2;

    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: Stack(
        children: [
          Container(height: height, color: bgColor),
          AnimatedFractionallySizedBox(
            duration: animate ? DSDuration.slow : Duration.zero,
            curve: DSCurve.smooth,
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton / Shimmer ────────────────────────────────────────────────────────

class DSSkeleton extends StatefulWidget {
  const DSSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.radius,
  });

  final double width;
  final double height;
  final double? radius;

  @override
  State<DSSkeleton> createState() => _DSSkeletonState();
}

class _DSSkeletonState extends State<DSSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : const Color(0xFF1B3A5C).withValues(alpha: 0.06);
    final highlight = isDark
        ? Colors.white.withValues(alpha: 0.13)
        : const Color(0xFF1B3A5C).withValues(alpha: 0.10);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(base, highlight, _anim.value),
          borderRadius: BorderRadius.circular(widget.radius ?? DSRadius.sm),
        ),
      ),
    );
  }
}

// ── Badge Chip ─────────────────────────────────────────────────────────────────

class DSBadge extends StatelessWidget {
  const DSBadge({
    super.key,
    required this.label,
    this.color,
    this.textColor,
  });

  final String label;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final bg = color ?? const Color(0xFF1B3A5C).withValues(alpha: 0.10);
    final fg = textColor ?? const Color(0xFF1B3A5C);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.sm,
        vertical: DSSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: DSRadius.fullBR,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────────────

class DSSectionHeader extends StatelessWidget {
  const DSSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.subtitle,
    this.icon,
  });

  final String title;
  final Widget? trailing;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceSoft = onSurface.withValues(alpha: 0.5);

    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: onSurface),
          const SizedBox(width: DSSpacing.sm),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(fontSize: 11, color: onSurfaceSoft),
                ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ── Hover Text Button ──────────────────────────────────────────────────────────

class DSTextButton extends StatefulWidget {
  const DSTextButton({
    super.key,
    required this.label,
    this.onTap,
    this.color,
    this.icon,
    this.iconSize = 14,
  });

  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final IconData? icon;
  final double iconSize;

  @override
  State<DSTextButton> createState() => _DSTextButtonState();
}

class _DSTextButtonState extends State<DSTextButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? const Color(0xFFF5A623);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedOpacity(
          opacity: _hovered ? 0.75 : 1.0,
          duration: DSDuration.fast,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              if (widget.icon != null) ...[
                const SizedBox(width: 2),
                Icon(widget.icon, size: widget.iconSize, color: color),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
