import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Full-bleed autoplay/muted/looping background video for the marketing
/// home page hero, with a dark overlay so foreground content stays readable.
///
/// Falls back to a plain dark background if the video fails to load.
class HeroVideoBackground extends StatefulWidget {
  const HeroVideoBackground({
    super.key,
    required this.height,
    required this.child,
  });

  final double height;
  final Widget child;

  @override
  State<HeroVideoBackground> createState() => _HeroVideoBackgroundState();
}

class _HeroVideoBackgroundState extends State<HeroVideoBackground> {
  VideoPlayerController? _controller;
  bool _failed = false;
  ValueNotifier<bool>? _isScrollingNotifier;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    // Deferred to after the first frame rather than started here. The asset
    // is 1.5 MB, this is the public landing page, and a phone on mobile data
    // was fetching it in competition with the page it decorates. Waiting
    // costs nothing visually — the hero already opens on the dark background
    // this fades in over — and it takes the video off the critical path.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initVideo();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // On Flutter Web, this widget's `<video>` element is a browser platform
    // view composited separately from the canvas — while the ancestor
    // Scrollable is actively scrolling, that element has to be
    // repositioned every frame, which is what produces the tearing/color
    // flashes some mobile GPUs show during scroll. Swapping the live video
    // out for a static background while scrolling (and back in once it
    // settles) avoids repositioning it mid-scroll.
    final newNotifier = Scrollable.maybeOf(context)?.position.isScrollingNotifier;
    if (newNotifier != _isScrollingNotifier) {
      _isScrollingNotifier?.removeListener(_handleScrollingChanged);
      _isScrollingNotifier = newNotifier;
      _isScrollingNotifier?.addListener(_handleScrollingChanged);
      _handleScrollingChanged();
    }
  }

  void _handleScrollingChanged() {
    final scrolling = _isScrollingNotifier?.value ?? false;
    if (scrolling != _isScrolling && mounted) {
      setState(() => _isScrolling = scrolling);
    }
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.asset('assets/videos/panar1.mp4');
    _controller = controller;
    try {
      controller.setVolume(0);
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _isScrollingNotifier?.removeListener(_handleScrollingChanged);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final isReady =
        controller != null &&
        controller.value.isInitialized &&
        !_failed &&
        !_isScrolling;

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFF0B0E14)),
          if (isReady)
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
          Container(color: Colors.black.withValues(alpha: 0.65)),
          widget.child,
        ],
      ),
    );
  }
}
