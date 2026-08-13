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

  @override
  void initState() {
    super.initState();
    _initVideo();
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
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final isReady =
        controller != null && controller.value.isInitialized && !_failed;

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
