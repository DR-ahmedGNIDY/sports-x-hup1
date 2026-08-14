import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
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
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.profileBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.profileGold.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(color: AppColors.profileGold.withValues(alpha: 0.06), blurRadius: 16, spreadRadius: -4),
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
                  color: AppColors.profileGold.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events_outlined, size: 16, color: AppColors.profileGold),
              ),
              const SizedBox(width: 8),
              Text(
                '${achievement.year}',
                style: const TextStyle(color: AppColors.profileGold, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            achievement.title,
            style: const TextStyle(color: AppColors.profileText, fontSize: 14, fontWeight: FontWeight.w700),
          ),
          if (achievement.description != null && achievement.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              achievement.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.greyLight, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
