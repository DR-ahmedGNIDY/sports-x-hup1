import 'package:flutter/material.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/profile_colors.dart';

/// One button in a [FeedItemCard]'s action bar (Like / Comment / Share) —
/// icon + label, sized to fill its share of the row so the three buttons
/// read as one evenly-divided strip rather than three loose icons.
///
/// [active] drives the "selected" look (Like, once you've liked the post):
/// tinted icon + label plus a faint tinted background, so an active button
/// is distinguishable from an idle one by more than icon shape alone.
class FeedActionButton extends StatelessWidget {
  const FeedActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.tooltip,
    this.active = false,
    this.activeColor,
    this.compact = false,
  });

  /// The icon widget rather than an `IconData` so callers can wrap it in
  /// their own animation (see [FeedLikeButton]'s like-pop).
  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final String? tooltip;
  final bool active;

  /// Color for the [active] state; defaults to the theme accent.
  final Color? activeColor;

  /// Narrow-card density — tighter padding and slightly smaller label, for
  /// cards rendered at mobile widths.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.profileColors;
    final tint = activeColor ?? colors.accent;
    final foreground = active ? tint : colors.textMuted;

    final button = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        // Floor the height at a real touch target rather than letting the
        // label's line height decide it — the compact (mobile) density is
        // exactly where that would fall short.
        constraints: const BoxConstraints(minHeight: 44),
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: compact ? AppSpacing.sm : AppSpacing.md - 2,
        ),
        decoration: BoxDecoration(
          color: active ? tint.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: AppSpacing.xs + 2),
            Flexible(
              child: AnimatedDefaultTextStyle(
                duration: AppMotion.fast,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: foreground,
                  fontSize: compact ? 13 : 13.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                ),
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
        ),
      ),
    );

    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
