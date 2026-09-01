import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_radius.dart';

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
  // Built in initState rather than as a `late final` field. Lazily, the
  // first thing to touch the controller was `build` — and under reduced
  // motion `build` returns before reaching it, so the *first* access became
  // `dispose`. Creating a ticker there means creating it against an element
  // that is already deactivated, which throws "Looking up a deactivated
  // widget's ancestor is unsafe". A skeleton is on screen during almost
  // every load, so with the setting on that was every screen.
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.loop)
      ..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.35, end: 0.75).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = widget.borderRadius ?? BorderRadius.circular(AppRadius.xs);
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
