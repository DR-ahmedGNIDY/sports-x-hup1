import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Full-bleed autoplay/muted/looping video panel for the Desktop auth
/// screens' left-hand split. Video only — no logo, text, or overlay
/// content; a subtle dark scrim sits above it purely for visual polish.
///
/// Falls back to a plain dark panel if the video fails to load.
class AuthVideoPanel extends StatefulWidget {
  const AuthVideoPanel({super.key, required this.assetPath});

  final String assetPath;

  @override
  State<AuthVideoPanel> createState() => _AuthVideoPanelState();
}

class _AuthVideoPanelState extends State<AuthVideoPanel> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.asset(widget.assetPath);
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

    return ClipRect(
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
          Container(color: Colors.black.withValues(alpha: 0.25)),
        ],
      ),
    );
  }
}
