import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/feed_item.dart';

/// Mirrors videos/presentation/shared/video_like_button.dart's icon
/// language and micro-animation, just typed against [FeedItem] instead of
/// `Video` — kept as its own small widget rather than a generic
/// `<T extends {likeCount,isLikedByMe}>` since Dart has no structural
/// typing to make that generic clean.
class FeedLikeButton extends StatefulWidget {
  const FeedLikeButton({super.key, required this.item, required this.onToggle});

  final FeedItem item;
  final Future<void> Function() onToggle;

  @override
  State<FeedLikeButton> createState() => _FeedLikeButtonState();
}

class _FeedLikeButtonState extends State<FeedLikeButton> with SingleTickerProviderStateMixin {
  bool _busy = false;
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(vsync: this, duration: AppMotion.fast);
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _scaleController, curve: AppMotion.enter));
  }

  @override
  void didUpdateWidget(covariant FeedLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final justLiked = !oldWidget.item.isLikedByMe && widget.item.isLikedByMe;
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
    setState(() => _busy = true);
    try {
      await widget.onToggle();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final liked = widget.item.isLikedByMe;
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: _handleTap,
      borderRadius: BorderRadius.circular(8),
      child: Tooltip(
        message: liked ? l10n.feedUnlikeTooltip : l10n.feedLikeTooltip,
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
                    color: liked ? AppColors.error : AppColors.greyLight,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              AnimatedDefaultTextStyle(
                duration: AppMotion.fast,
                style: AppTextStyles.statNumber.copyWith(
                  color: liked ? AppColors.error : AppColors.greyLight,
                  fontSize: 13,
                ),
                child: Text('${widget.item.likeCount}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
