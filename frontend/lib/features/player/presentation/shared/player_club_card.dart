import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/player_profile.dart';
import 'player_profile_data.dart';
import 'section_card.dart';

/// The Current Club card content — `null` when the player hasn't set a
/// club. No logo/membership record exists on the profile yet (see
/// [currentClubInfo]), so this only ever shows the club name and, if
/// present, the player's status there.
Widget? buildCurrentClubCard(BuildContext context, PlayerProfile profile) {
  final club = currentClubInfo(profile);
  if (club == null) return null;
  final l10n = AppLocalizations.of(context)!;
  return ProfileSectionCard(
    icon: Icons.shield_outlined,
    title: l10n.currentClubLabel,
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.profileBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: const Icon(Icons.shield_outlined, color: AppColors.profileAccent, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                club.name,
                style: const TextStyle(color: AppColors.profileText, fontWeight: FontWeight.w600, fontSize: 15),
              ),
              if (club.status != null) ...[
                const SizedBox(height: 2),
                Text(club.status!, style: const TextStyle(color: AppColors.greyLight, fontSize: 13)),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
