import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/profile_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/feed_item.dart';
import 'feed_action_button.dart';

/// The Like control in a [FeedItemCard]'s action bar — icon + label (the
/// count itself lives in the card's engagement summary above the divider,
/// so it isn't repeated here). Keeps the like-pop micro-animation this
/// button has always had; the only structural change is that it now
/// renders as one of three equal-width action-bar buttons instead of a
/// standalone icon+count pill.
///
/// Kept as its own small widget rather than a generic
/// `<T extends {likeCount,isLikedByMe}>` since Dart has no structural
/// typing to make that generic clean.
class FeedLikeButton extends StatefulWidget {
  const FeedLikeButton({
    super.key,
    required this.item,
    required this.onToggle,
    this.compact = false,
  });

  final FeedItem item;
  final Future<void> Function() onToggle;

  /// Narrow-card density — see [FeedActionButton.compact].
  final bool compact;

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
    final activeColor = AppColors.error;
    final idleColor = context.profileColors.textMuted;

    return FeedActionButton(
      onTap: _handleTap,
      compact: widget.compact,
      active: liked,
      activeColor: activeColor,
      tooltip: liked ? l10n.feedUnlikeTooltip : l10n.feedLikeTooltip,
      label: l10n.feedLikeActionLabel,
      icon: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedSwitcher(
          duration: AppMotion.fast,
          child: Icon(
            liked ? Icons.favorite : Icons.favorite_border,
            key: ValueKey(liked),
            size: widget.compact ? 18 : 19,
            color: liked ? activeColor : idleColor,
          ),
        ),
      ),
    );
  }
}
