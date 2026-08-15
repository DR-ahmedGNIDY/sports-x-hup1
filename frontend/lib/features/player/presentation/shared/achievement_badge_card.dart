import 'package:flutter/material.dart';

import '../../../../core/theme/profile_colors.dart';
import '../../domain/entities/achievement.dart';

/// A single achievement rendered as a small gold-accented card (icon +
/// title + year, optional description) instead of a plain `ListTile` —
/// used inside the Achievements section's `Wrap`. Same fields as before
/// ([Achievement.title]/`.year`/`.description`), just restyled.
class AchievementBadgeCard extends StatelessWidget {
  const AchievementBadgeCard({super.key, required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final profileColors = context.profileColors;
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: profileColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: profileColors.gold.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(color: profileColors.gold.withValues(alpha: 0.06), blurRadius: 16, spreadRadius: -4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: profileColors.gold.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.emoji_events_outlined, size: 16, color: profileColors.gold),
              ),
              const SizedBox(width: 8),
              Text(
                '${achievement.year}',
                style: TextStyle(color: profileColors.gold, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            achievement.title,
            style: TextStyle(color: profileColors.text, fontSize: 14, fontWeight: FontWeight.w700),
          ),
          if (achievement.description != null && achievement.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              achievement.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: profileColors.textMuted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
