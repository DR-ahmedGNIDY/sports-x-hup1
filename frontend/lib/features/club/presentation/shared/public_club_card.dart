import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/club_profile.dart';

class PublicClubCard extends StatelessWidget {
  const PublicClubCard({super.key, required this.club});

  final ClubProfile club;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final location = [
      club.city,
      club.country,
    ].where((v) => v != null && v.isNotEmpty).join(', ');

    return Card(
      child: InkWell(
        onTap: () => context.push('/clubs/${club.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.slate,
                  borderRadius: BorderRadius.circular(8),
                  image: club.logoUrl != null
                      ? DecorationImage(image: NetworkImage(club.logoUrl!), fit: BoxFit.cover)
                      : null,
                ),
                child: club.logoUrl == null
                    ? const Icon(Icons.shield_outlined, color: AppColors.greyLight)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      club.name?.isNotEmpty == true ? club.name! : l10n.unnamedClub,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (location.isNotEmpty)
                      Text(location, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              // Icons.chevron_right has matchTextDirection: true baked
              // into its IconData, so Flutter auto-mirrors this disclosure
              // indicator for RTL without any extra parameter here.
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
