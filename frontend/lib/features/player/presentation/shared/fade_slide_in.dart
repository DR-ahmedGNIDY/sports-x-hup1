import 'package:flutter/material.dart';

import '../../../../core/theme/app_motion.dart';

/// A small one-shot fade + upward-slide entrance, used to stagger the
/// Player Profile's sections in on first paint (Hero, Quick Stats,
/// Position, ...) instead of everything popping in at once. Purely
/// decorative — no layout is reserved/changed, it just animates the
/// child's opacity/offset in place. Respects
/// `MediaQuery.disableAnimations` (reduced motion) by skipping straight
/// to the settled state, and uses [AppMotion]'s shared duration/curve
/// constants rather than inventing new ones.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );
  late final Animation<double> _opacity = CurvedAnimation(parent: _controller, curve: AppMotion.enter);
  late final Animation<Offset> _offset = Tween(
    begin: const Offset(0, 0.04),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: AppMotion.enter));

  bool _started = false;

  // Not `initState`: reading MediaQuery there registers an inherited
  // dependency before the element is ready for one, which trips a framework
  // assertion in debug. `didChangeDependencies` is the first callback where
  // an inherited widget may legally be read, and the `_started` guard keeps
  // this a one-shot entrance rather than replaying it every time an ancestor
  // changes.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = 1;
      return;
    }
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}
