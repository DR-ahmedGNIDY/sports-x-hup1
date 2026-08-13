import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/player_profile.dart';
import 'section_card.dart';

/// The About card content — `null` when the player hasn't written a bio,
/// so callers can skip the card (or its half of a side-by-side row)
/// entirely instead of showing an empty box.
Widget? buildAboutCard(BuildContext context, PlayerProfile profile) {
  final bio = profile.bio;
  if (bio == null || bio.isEmpty) return null;
  final l10n = AppLocalizations.of(context)!;
  return ProfileSectionCard(
    icon: Icons.info_outline,
    title: l10n.sectionAboutTitle,
    child: Text(bio, style: const TextStyle(color: AppColors.profileText, height: 1.5)),
  );
}
