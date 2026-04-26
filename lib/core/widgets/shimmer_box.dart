import 'package:flutter/material.dart';
import '../../core/theme/farol_colors.dart';

class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  const ShimmerBox({super.key, required this.width, required this.height, this.borderRadius = 12});

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          color: Color.lerp(colors.surfaceLow, colors.surfaceLowest, _anim.value),
        ),
      ),
    );
  }
}

/// Full-card skeleton for dashboard sections
class DashboardCardSkeleton extends StatelessWidget {
  final double height;
  const DashboardCardSkeleton({super.key, this.height = 120});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerBox(width: 100, height: 12),
            const SizedBox(height: 12),
            ShimmerBox(width: double.infinity, height: height - 60),
            const SizedBox(height: 12),
            const ShimmerBox(width: 160, height: 10),
          ],
        ),
      ),
    );
  }
}
