import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/club_profile.dart';
import 'club_level_labels.dart';

/// Read-only rendering of a [ClubProfile] — used by My Club Profile.
class ClubProfileView extends StatelessWidget {
  const ClubProfileView({super.key, required this.profile});

  final ClubProfile profile;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final location = [
      profile.city,
      profile.country,
    ].where((v) => v != null && v.isNotEmpty).join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.slate,
                borderRadius: BorderRadius.circular(8),
                image: profile.logoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(profile.logoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: profile.logoUrl == null
                  ? const Icon(Icons.shield_outlined, color: AppColors.greyLight)
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
