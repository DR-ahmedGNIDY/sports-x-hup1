import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/profile_colors.dart';
import '../../../../core/utils/app_image.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/player_enums.dart';
import '../../domain/entities/player_media.dart';
import '../../domain/entities/player_profile.dart';
import 'achievement_badge_card.dart';
import 'section_card.dart';
import 'skills_section.dart';
import 'traits_section.dart';

/// The Achievements card — gold-accented, `null` when the player has no
/// achievements on file (per the redesign spec: don't show an empty
/// section). Pulled out of [buildTrailingSections] into its own function
/// so the layouts can place it right after the Position section, per the
/// redesign's requested page order, instead of bundled with Gallery/
/// Skills/Traits/Social/Contact at the bottom.
Widget? buildAchievementsSection(BuildContext context, PlayerProfile profile) {
  if (profile.achievements.isEmpty) return null;
  final l10n = AppLocalizations.of(context)!;
  return ProfileSectionCard(
    icon: Icons.emoji_events_outlined,
    title: l10n.achievementsTitle,
    accentColor: context.profileColors.gold,
    child: Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [for (final achievement in profile.achievements) AchievementBadgeCard(achievement: achievement)],
    ),
  );
}

/// Gallery, skills (video gallery), traits, social links, and contact —
/// unchanged functionality from the pre-redesign profile view, just
/// restyled onto [ProfileSectionCard] and moved below the new hero/
/// quick-stats/position/achievements/info sections. Identical on desktop
/// and mobile: a stacked full-width list reads fine at any width, so
/// there's no platform-specific layout to split out here.
List<Widget> buildTrailingSections(
  BuildContext context,
  PlayerProfile profile, {
  required bool showContact,
  required bool isOwner,
}) {
  final l10n = AppLocalizations.of(context)!;
  final profileColors = context.profileColors;
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
                  backgroundColor: profileColors.bg,
                  side: BorderSide(color: profileColors.borderOnSurface.withValues(alpha: 0.1)),
                  labelStyle: TextStyle(color: profileColors.text),
                  avatar: Icon(Icons.link, size: 16, color: profileColors.accent),
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
    final profileColors = context.profileColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: profileColors.accent),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(color: profileColors.text)),
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
          // Full resolution on purpose: this is the zoomable viewer, and a
          // decode cap would put a ceiling on how far it can zoom.
          child: InteractiveViewer(
            child: Image(
              image: appImageProvider(item.secureUrl, context: context),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileColors = context.profileColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Material(
        color: profileColors.bg,
        child: InkWell(
          onTap: () => _open(context),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (item.type == PlayerMediaType.photo)
                Image(
                  image: appImageProvider(
                    item.secureUrl,
                    context: context,
                    decodeWidth: AppImageSize.thumbnail,
                  ),
                  fit: BoxFit.cover,
                )
              else
                Center(
                  child: Icon(Icons.play_circle_outline, color: profileColors.textMuted, size: 36),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
