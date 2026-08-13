import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// A subtly animated placeholder box for whole-screen/whole-section loading
/// states — an opacity pulse over a tinted [Container], no external shimmer
/// package. Sizes itself to [width]/[height] when given, otherwise expands
/// to fill its parent (handy inside a `GridView`/`Row`/`Column` slot that
/// already constrains it).
///
/// Respects `MediaQuery.disableAnimations`: when the platform/user has
/// reduced-motion enabled, this renders as a static tinted box instead of
/// pulsing.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({super.key, this.width, this.height, this.borderRadius});

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.loop,
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(
    begin: 0.35,
    end: 0.75,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = widget.borderRadius ?? BorderRadius.circular(8);
    final baseColor = colorScheme.surfaceContainerHighest;

    if (MediaQuery.of(context).disableAnimations) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(color: baseColor, borderRadius: radius),
      );
    }

    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: baseColor.withValues(alpha: _opacity.value),
          borderRadius: radius,
        ),
      ),
    );
  }
}
