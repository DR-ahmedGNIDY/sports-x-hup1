import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/profile_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/video_comment.dart';

/// One row in a comments list — avatar, author name + role badge +
/// timestamp, then the comment text, with an optional delete action for
/// the commenter's own comment. Shared between the Video and Home-feed
/// comment sheets (both list the same [VideoComment] shape); only the
/// state management (load/send/delete wiring) stays duplicated per-sheet,
/// since each targets a different repository.
class CommentTile extends StatelessWidget {
  const CommentTile({super.key, required this.comment, this.onDelete});

  final VideoComment comment;
  final VoidCallback? onDelete;

  String _roleLabel(AppLocalizations l10n) => switch (comment.authorRole) {
    'CLUB' => l10n.roleClub,
    'PLAYER' => l10n.rolePlayer,
    'ADMIN' => l10n.dashboardRoleAdmin,
    _ => comment.authorRole,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = comment.authorDisplayName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final colors = context.profileColors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: colors.bg,
          child: Text(
            initial,
            style: TextStyle(color: colors.textMuted, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: colors.bg,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      _roleLabel(l10n),
                      style: TextStyle(color: colors.textMuted, fontSize: 10),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('d MMM, HH:mm').format(comment.createdAt.toLocal()),
                    // Force LTR — see FeedItemCard's _AuthorRow for why an
                    // RTL layout otherwise scrambles this date string.
                    textDirection: TextDirection.ltr,
                    style: TextStyle(color: colors.textMuted, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(comment.text, style: TextStyle(color: colors.textMuted, fontSize: 14)),
            ],
          ),
        ),
        if (onDelete != null)
          IconButton(
            icon: Icon(Icons.delete_outline, size: 18, color: colors.textMuted),
            onPressed: onDelete,
          ),
      ],
    );
  }
}
