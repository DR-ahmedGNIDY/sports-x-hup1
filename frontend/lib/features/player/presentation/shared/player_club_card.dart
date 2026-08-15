import 'package:flutter/material.dart';

import '../../../../core/theme/profile_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/player_profile.dart';
import 'player_profile_data.dart';
import 'section_card.dart';

/// The Current Club card — always rendered (unlike the other optional
/// sections on this page), per the redesign spec: a player with no club
/// on file should still see a clear, professional "No Club" state rather
/// than the section vanishing outright. No logo/membership record exists
/// on the profile yet (see [currentClubInfo]), so the "has a club" state
/// only ever shows the club name and, if present, the player's status
/// there — unchanged from before.
Widget buildCurrentClubCard(BuildContext context, PlayerProfile profile) {
  final club = currentClubInfo(profile);
  final l10n = AppLocalizations.of(context)!;
  final profileColors = context.profileColors;
  return ProfileSectionCard(
    icon: Icons.shield_outlined,
    title: l10n.currentClubLabel,
    child: club == null
        ? _NoClubState(l10n: l10n)
        : Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: profileColors.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: profileColors.borderOnSurface.withValues(alpha: 0.08)),
                ),
                child: Icon(Icons.shield_outlined, color: profileColors.accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      club.name,
                      style: TextStyle(
                        color: profileColors.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (club.status != null) ...[
                      const SizedBox(height: 2),
                      Text(club.status!, style: TextStyle(color: profileColors.textMuted, fontSize: 13)),
                    ],
                  ],
                ),
              ),
            ],
          ),
  );
}

class _NoClubState extends StatelessWidget {
  const _NoClubState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final profileColors = context.profileColors;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: profileColors.bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: profileColors.borderOnSurface.withValues(alpha: 0.08),
              style: BorderStyle.solid,
            ),
          ),
          child: Icon(Icons.shield_moon_outlined, color: profileColors.textMuted, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.noClubTitle,
                style: TextStyle(color: profileColors.text, fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 2),
              Text(l10n.noClubSubtitle, style: TextStyle(color: profileColors.textMuted, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
