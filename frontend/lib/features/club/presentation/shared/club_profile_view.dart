import 'package:flutter/material.dart';


import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_image.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../invitations/presentation/shared/public_code_chip.dart';
import '../../domain/entities/club_profile.dart';
import 'club_level_labels.dart';

/// Read-only rendering of a [ClubProfile] — used by My Club Profile.
class ClubProfileView extends StatelessWidget {
  const ClubProfileView({super.key, required this.profile});

  final ClubProfile profile;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final location = [
      profile.city,
      profile.country,
    ].where((v) => v != null && v.isNotEmpty).join(', ');
    final hasDetails =
        (profile.description?.isNotEmpty ?? false) ||
        profile.foundedYear != null ||
        clubLevelDisplayValue(l10n, profile.level) != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.xs),
                image: profile.logoUrl != null
                    ? DecorationImage(
                        image: appImageProvider(profile.logoUrl!, context: context, decodeWidth: AppImageSize.avatarLarge),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: profile.logoUrl == null
                  ? Icon(Icons.shield_outlined, color: colorScheme.onSurfaceVariant)
                  : null,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name?.isNotEmpty == true ? profile.name! : l10n.unnamedClub,
                    style: textTheme.headlineSmall,
                  ),
                  if (location.isNotEmpty) Text(location, style: textTheme.bodyMedium),
                  // The code is what a player quotes to ask to join, so it
                  // sits with the club's identity rather than down among the
                  // stats. Absent until the backfill has reached a profile
                  // created before public codes existed — an empty space
                  // beats a placeholder that looks like a real code.
                  if (profile.publicCode case final code?) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: PublicCodeChip(label: l10n.clubCodeLabel, code: code),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (profile.description != null && profile.description!.isNotEmpty) ...[
          Text(l10n.sectionAboutTitle, style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(profile.description!),
          const SizedBox(height: 24),
        ],
        Wrap(
          spacing: 24,
          runSpacing: 8,
          children: [
            if (profile.foundedYear != null)
              _Stat(label: l10n.foundedStatLabel, value: '${profile.foundedYear}'),
            if (clubLevelDisplayValue(l10n, profile.level) case final level?)
              _Stat(label: l10n.levelLabel, value: level),
          ],
        ),
        // Said plainly when there is nothing to say. Every part of this view
        // below the name is conditional, so a club that has filled none of
        // it in rendered as a name floating over an empty screen — which
        // reads as a page that failed to load rather than as a profile
        // nobody has written yet.
        if (!hasDetails) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.clubProfileIncompleteNote,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(value, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}
