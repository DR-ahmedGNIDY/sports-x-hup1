import 'package:flutter/material.dart';

import '../../../../core/theme/profile_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/player_profile.dart';
import 'player_enum_labels.dart';
import 'section_card.dart';

/// The consolidated "Player Information" card: Preferred Foot, Position,
/// Current Club (name only — the dedicated Current Club card below still
/// carries the fuller "no club" presentation), and Bio. Every row is
/// hidden individually when the underlying field is null/empty, the same
/// convention every other optional section on this page already follows
/// — nothing here is a placeholder or invented value. `Skill Level` and
/// `Join Date` are not in this list on purpose: neither field exists on
/// [PlayerProfile] today.
Widget? buildPlayerInfoCard(BuildContext context, PlayerProfile profile) {
  final l10n = AppLocalizations.of(context)!;
  final profileColors = context.profileColors;
  final rows = <_InfoRow>[
    if (profile.preferredFoot != null)
      _InfoRow(
        icon: Icons.sports_soccer_outlined,
        label: l10n.preferredFootLabel,
        value: preferredFootLabel(l10n, profile.preferredFoot!),
      ),
    if (profile.position != null && profile.position!.isNotEmpty)
      _InfoRow(icon: Icons.my_location_outlined, label: l10n.positionLabel, value: profile.position!),
    if (profile.currentClub != null && profile.currentClub!.isNotEmpty)
      _InfoRow(icon: Icons.shield_outlined, label: l10n.currentClubLabel, value: profile.currentClub!),
  ];
  final bio = profile.bio;
  final hasBio = bio != null && bio.isNotEmpty;
  if (rows.isEmpty && !hasBio) return null;

  return ProfileSectionCard(
    icon: Icons.badge_outlined,
    title: l10n.playerInformationTitle,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          rows[i],
          if (i != rows.length - 1 || hasBio) const SizedBox(height: 12),
        ],
        if (hasBio) ...[
          if (rows.isNotEmpty)
            Divider(color: profileColors.borderOnSurface.withValues(alpha: 0.08), height: 1),
          if (rows.isNotEmpty) const SizedBox(height: 12),
          Text(
            l10n.bioLabel.toUpperCase(),
            style: TextStyle(
              color: profileColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(bio, style: TextStyle(color: profileColors.text, height: 1.5)),
        ],
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final profileColors = context.profileColors;
    return Row(
      children: [
        Icon(icon, size: 17, color: profileColors.accent),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: profileColors.textMuted, fontSize: 13)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: profileColors.text, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
