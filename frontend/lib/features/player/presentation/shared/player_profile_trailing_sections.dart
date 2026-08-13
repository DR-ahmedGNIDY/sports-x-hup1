import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/player_enums.dart';
import '../../domain/entities/player_media.dart';
import '../../domain/entities/player_profile.dart';
import 'section_card.dart';
import 'skills_section.dart';
import 'traits_section.dart';

/// Gallery, achievements, social links, and contact — unchanged
/// functionality from the pre-redesign profile view, just restyled onto
/// [ProfileSectionCard] and moved below the new hero/quick-facts/pitch
/// sections. Identical on desktop and mobile: a stacked full-width list
/// reads fine at any width, so there's no platform-specific layout to
/// split out here.
List<Widget> buildTrailingSections(
  BuildContext context,
  PlayerProfile profile, {
  required bool showContact,
  required bool isOwner,
}) {
  final l10n = AppLocalizations.of(context)!;
  return [
    if (profile.media.isNotEmpty)
      ProfileSectionCard(
        icon: Icons.photo_library_outlined,
        title: l10n.galleryTitle,
        child: _MediaGallery(media: profile.media),
      ),
    if (profile.sport != null && profile.sport!.isNotEmpty)
      ProfileSectionCard(
        icon: Icons.sports_soccer_outlined,
        title: l10n.skillsSectionTitle,
        child: SkillsSection(
          isOwner: isOwner,
          playerId: profile.id,
          sport: profile.sport!,
          showHeading: false,
        ),
      ),
    if (profile.sport == 'Football')
      ProfileSectionCard(
        icon: Icons.insights_outlined,
        title: l10n.traitsTitle,
        child: TraitsSection(isOwner: isOwner, playerId: profile.id),
      ),
    if (profile.achievements.isNotEmpty)
      ProfileSectionCard(
        icon: Icons.emoji_events_outlined,
        title: l10n.achievementsTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final achievement in profile.achievements)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  iconColor: AppColors.profileAccent,
                  textColor: AppColors.profileText,
                  leading: const Icon(Icons.emoji_events_outlined),
                  title: Text('${achievement.title} (${achievement.year})'),
                  subtitle: achievement.description != null
                      ? Text(
                          achievement.description!,
                          style: const TextStyle(color: AppColors.greyLight),
                        )
                      : null,
                ),
              ),
          ],
        ),
      ),
    if (profile.socialLinks.isNotEmpty)
      ProfileSectionCard(
        icon: Icons.link,
        title: l10n.socialLinksTitle,
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          children: profile.socialLinks
              .map(
                (link) => ActionChip(
                  backgroundColor: AppColors.profileBg,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  labelStyle: const TextStyle(color: AppColors.profileText),
                  avatar: const Icon(Icons.link, size: 16, color: AppColors.profileAccent),
                  label: Text(link.platform),
                  onPressed: () => launchUrl(Uri.parse(link.url)),
                ),
              )
              .toList(),
        ),
      ),
    if (showContact && !profile.contact.isEmpty)
      ProfileSectionCard(
        icon: Icons.contact_mail_outlined,
        title: l10n.contactSectionTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (profile.contact.phone != null)
              _ContactRow(icon: Icons.phone_outlined, text: l10n.contactPhoneValue(profile.contact.phone!)),
            if (profile.contact.email != null)
              _ContactRow(icon: Icons.email_outlined, text: l10n.contactEmailValue(profile.contact.email!)),
            if (profile.contact.whatsapp != null)
              _ContactRow(
                icon: Icons.chat_outlined,
                text: l10n.contactWhatsappValue(profile.contact.whatsapp!),
              ),
          ],
        ),
      ),
  ];
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.profileAccent),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(color: AppColors.profileText)),
        ],
      ),
    );
  }
}

class _MediaGallery extends StatelessWidget {
  const _MediaGallery({required this.media});

  final List<PlayerMedia> media;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: media.length,
      itemBuilder: (context, index) => _MediaTile(item: media[index]),
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({required this.item});

  final PlayerMedia item;

  void _open(BuildContext context) {
    if (item.type == PlayerMediaType.video) {
      launchUrl(Uri.parse(item.secureUrl));
      return;
    }
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(child: Image.network(item.secureUrl, fit: BoxFit.contain)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Material(
        color: AppColors.profileBg,
        child: InkWell(
          onTap: () => _open(context),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (item.type == PlayerMediaType.photo)
                Image.network(item.secureUrl, fit: BoxFit.cover)
              else
                const Center(
                  child: Icon(Icons.play_circle_outline, color: AppColors.white, size: 36),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
