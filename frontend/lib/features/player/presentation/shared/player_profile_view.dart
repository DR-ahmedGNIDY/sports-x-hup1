import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/player_enums.dart';
import '../../domain/entities/player_profile.dart';

/// Read-only rendering of a [PlayerProfile] — shared by My Profile Preview
/// (owner view, contact shown) and the Public Player Profile page
/// (visitor view, contact hidden — Phase 3 gates contact behind a
/// logged-in Club).
class PlayerProfileView extends StatelessWidget {
  const PlayerProfileView({super.key, required this.profile, this.showContact = false});

  final PlayerProfile profile;
  final bool showContact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final photo = profile.profilePhoto;
    final subtitle = [
      profile.sport,
      profile.position,
    ].where((v) => v != null && v.isNotEmpty).join(' · ');
    final location = [
      profile.city,
      profile.country,
    ].where((v) => v != null && v.isNotEmpty).join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.slate,
              backgroundImage: photo != null ? NetworkImage(photo.secureUrl) : null,
              child: photo == null
                  ? const Icon(Icons.person, size: 48, color: AppColors.greyLight)
                  : null,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.fullName.isEmpty ? 'Unnamed player' : profile.fullName,
                    style: textTheme.headlineSmall,
                  ),
                  if (subtitle.isNotEmpty) Text(subtitle, style: textTheme.titleMedium),
                  if (location.isNotEmpty) Text(location, style: textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (profile.bio != null && profile.bio!.isNotEmpty) ...[
          Text('About', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(profile.bio!),
          const SizedBox(height: 24),
        ],
        Text('Sports Information', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 24,
          runSpacing: 8,
          children: [
            if (profile.preferredFoot != null)
              _Stat(label: 'Preferred foot', value: profile.preferredFoot!.label),
            if (profile.height != null) _Stat(label: 'Height', value: '${profile.height} cm'),
            if (profile.weight != null) _Stat(label: 'Weight', value: '${profile.weight} kg'),
            if (profile.currentClub != null && profile.currentClub!.isNotEmpty)
              _Stat(label: 'Current club', value: profile.currentClub!),
            if (profile.currentStatus != null && profile.currentStatus!.isNotEmpty)
              _Stat(label: 'Status', value: profile.currentStatus!),
          ],
        ),
        if (profile.media.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Gallery', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: profile.media
                .map(
                  (item) => Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.slate,
                      borderRadius: BorderRadius.circular(8),
                      image: item.type == PlayerMediaType.photo
                          ? DecorationImage(
                              image: NetworkImage(item.secureUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: item.type == PlayerMediaType.video
                        ? const Icon(Icons.play_circle_outline, color: AppColors.white)
                        : null,
                  ),
                )
                .toList(),
          ),
        ],
        if (profile.achievements.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Achievements', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final achievement in profile.achievements)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.emoji_events_outlined),
              title: Text('${achievement.title} (${achievement.year})'),
              subtitle: achievement.description != null
                  ? Text(achievement.description!)
                  : null,
            ),
        ],
        if (profile.socialLinks.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Social Links', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: profile.socialLinks
                .map(
                  (link) => ActionChip(
                    avatar: const Icon(Icons.link, size: 16),
                    label: Text(link.platform),
                    onPressed: () => launchUrl(Uri.parse(link.url)),
                  ),
                )
                .toList(),
          ),
        ],
        if (showContact && !profile.contact.isEmpty) ...[
          const SizedBox(height: 24),
          Text('Contact', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          if (profile.contact.phone != null) Text('Phone: ${profile.contact.phone}'),
          if (profile.contact.email != null) Text('Email: ${profile.contact.email}'),
          if (profile.contact.whatsapp != null)
            Text('WhatsApp: ${profile.contact.whatsapp}'),
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
