import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Minimal full-screen video playback — opened from [VideoCard]'s tap
/// handler. Keeps its own controller lifecycle self-contained so callers
/// never have to think about disposal.
class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key, required this.videoUrl});

  final String videoUrl;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  late Future<void> _initialize;
  bool _muted = false;

  void _toggleMute() {
    setState(() {
      _muted = !_muted;
      _controller.setVolume(_muted ? 0 : 1);
    });
  }

  @override
  void initState() {
    super.initState();
    _createAndInitialize();
  }

  void _createAndInitialize() {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _initialize = _controller.initialize().then((_) {
      if (mounted) {
        _controller.setVolume(_muted ? 0 : 1);
        setState(() {});
        _controller.play();
      }
    });
  }

  Future<void> _retry() async {
    final oldController = _controller;
    setState(() {
      _createAndInitialize();
    });
    await oldController.dispose();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: FutureBuilder<void>(
        future: _initialize,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    l10n.videoPlaybackErrorMessage,
                    style: const TextStyle(color: AppColors.white),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _retry,
                    child: Text(l10n.videoPlaybackRetryLabel),
                  ),
                ],
              ),
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.brandBlue),
            );
          }
          return Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio == 0
                  ? 16 / 9
                  : _controller.value.aspectRatio,
              child: Stack(
                children: [
                  VideoPlayer(_controller),
                  Align(
                    child: IconButton(
                      iconSize: 56,
                      icon: Icon(
                        _controller.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      onPressed: () {
                        setState(() {
                          _controller.value.isPlaying ? _controller.pause() : _controller.play();
                        });
                      },
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: VideoProgressIndicator(_controller, allowScrubbing: true),
                  ),
                  Align(
                    alignment: AlignmentDirectional.bottomEnd,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: IconButton(
                        tooltip: _muted
                            ? l10n.videoPlaybackUnmuteTooltip
                            : l10n.videoPlaybackMuteTooltip,
                        icon: Icon(
                          _muted ? Icons.volume_off : Icons.volume_up,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        onPressed: _toggleMute,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
