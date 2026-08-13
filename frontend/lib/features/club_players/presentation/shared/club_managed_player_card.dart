import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/club_managed_player.dart';
import 'whatsapp_send_button.dart';

class ClubManagedPlayerCard extends StatelessWidget {
  const ClubManagedPlayerCard({super.key, required this.player});

  final ClubManagedPlayer player;

  @override
  Widget build(BuildContext context) {
    final profile = player.profile;
    final fullName = profile.fullName.isEmpty ? profile.contact.phone ?? '' : profile.fullName;
    final subtitle = [
      profile.sport,
      profile.position,
    ].where((v) => v != null && v.isNotEmpty).join(' · ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.slate,
              backgroundImage: profile.profilePhoto != null
                  ? NetworkImage(profile.profilePhoto!.secureUrl)
                  : null,
              child: profile.profilePhoto == null
                  ? const Icon(Icons.person, color: AppColors.greyLight)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fullName, style: Theme.of(context).textTheme.titleMedium),
                  if (subtitle.isNotEmpty)
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  if (profile.contact.phone != null)
                    Text(
                      profile.contact.phone!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ResendCredentialsWhatsAppButton(player: player),
          ],
        ),
      ),
    );
  }
}
