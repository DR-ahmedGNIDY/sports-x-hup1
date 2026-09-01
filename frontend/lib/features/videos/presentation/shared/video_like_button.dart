import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/profile_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../domain/entities/video.dart';

/// Icon + count matching this app's existing icon language (outline/filled
/// pairs, e.g. [Icons.bookmark_outline]/[Icons.bookmark] in
/// SavePlayerButton). [onToggle] is supplied by the caller rather than
/// hardcoded to one controller type — My Videos, Public Videos, and the
/// Community feed each own a different list and know how to patch
/// themselves after the server responds.
class VideoLikeButton extends StatefulWidget {
  const VideoLikeButton({
    super.key,
    required this.video,
    required this.onToggle,
  });

  final Video video;
  final Future<void> Function() onToggle;

  @override
  State<VideoLikeButton> createState() => _VideoLikeButtonState();
}

class _VideoLikeButtonState extends State<VideoLikeButton>
    with SingleTickerProviderStateMixin {
  bool _busy = false;
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Quick, subtle scale-up-then-settle (1.0 -> 1.3 -> 1.0) played when the
    // video transitions to liked. Kept short (AppMotion.fast) so it reads as
    // a crisp acknowledgement rather than a bounce.
    _scaleController = AnimationController(
      vsync: this,
      duration: AppMotion.fast,
    );
    _scaleAnimation = TweenSequence<double>(
      [
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
        TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
      ],
    ).animate(CurvedAnimation(parent: _scaleController, curve: AppMotion.enter));
  }

  @override
  void didUpdateWidget(covariant VideoLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final justLiked = !oldWidget.video.isLikedByMe && widget.video.isLikedByMe;
    if (justLiked && !MediaQuery.of(context).disableAnimations) {
      _scaleController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_busy) return;
    // Fired on the tap, not on the server's reply: the feedback acknowledges
    // the press, and a buzz that arrives after a round trip reads as a
    // second, unrelated event.
    AppHaptics.light();
    setState(() => _busy = true);
    try {
      await widget.onToggle();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final liked = widget.video.isLikedByMe;
    final unlikedColor = context.profileColors.textMuted;
    return InkWell(
      onTap: _handleTap,
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: AnimatedSwitcher(
                duration: AppMotion.fast,
                child: Icon(
                  liked ? Icons.favorite : Icons.favorite_border,
                  key: ValueKey(liked),
                  size: 18,
                  color: liked ? AppColors.error : unlikedColor,
                ),
              ),
            ),
            const SizedBox(width: 4),
            AnimatedDefaultTextStyle(
              duration: AppMotion.fast,
              style: AppTextStyles.statNumber.copyWith(
                color: liked ? AppColors.error : unlikedColor,
                fontSize: 13,
              ),
              child: Text('${widget.video.likeCount}'),
            ),
          ],
        ),
      ),
    );
  }
}
