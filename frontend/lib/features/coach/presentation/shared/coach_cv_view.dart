import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_image.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../invitations/presentation/shared/public_code_chip.dart';
import '../../../player/presentation/shared/section_card.dart';
import '../../../videos/presentation/shared/video_player_screen.dart';
import '../../domain/coach_models.dart';
import 'coach_widgets.dart';

/// A coach's profile laid out as a CV: identity, about, current clubs,
/// career history, qualifications, skills, achievements, media and links.
/// Sections with nothing in them are left out rather than shown empty —
/// a CV with blank headings reads as unfinished.
///
/// Used for both the coach's own preview and the public profile; [header]
/// carries whatever actions the context needs (Edit, Invite…).
class CoachCvView extends StatelessWidget {
  const CoachCvView({super.key, required this.profile, this.header});

  final CoachProfile profile;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = profile;
    final gap = const SizedBox(height: AppSpacing.lg);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Hero(profile: p),
        if (header != null) ...[const SizedBox(height: AppSpacing.md), header!],
        if (p.bio != null) ...[
          gap,
          ProfileSectionCard(
            icon: Icons.person_outline,
            title: l10n.coachAboutTitle,
            child: Text(p.bio!),
          ),
        ],
        if (p.currentClubs.isNotEmpty) ...[
          gap,
          ProfileSectionCard(
            icon: Icons.shield_outlined,
            title: l10n.coachCurrentClubsTitle,
            child: Column(
              children: [
                for (final club in p.currentClubs)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CoachAvatar(
                      url: club.logoUrl,
                      fallbackIcon: Icons.shield_outlined,
                    ),
                    title: Text(club.name ?? l10n.coachUnnamedClub),
                    subtitle: club.publicCode == null
                        ? null
                        : Text(club.publicCode!),
                    onTap: () => context.push('/clubs/${club.id}'),
                  ),
              ],
            ),
          ),
        ],
        if (p.experience.isNotEmpty) ...[
          gap,
          ProfileSectionCard(
            icon: Icons.timeline,
            title: l10n.coachExperienceTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final e in p.experience)
                  _TimelineEntry(
                    title: e.role,
                    subtitle: e.clubName,
                    period:
                        '${e.startYear} – ${e.endYear?.toString() ?? l10n.coachToDate}',
                    description: e.description,
                  ),
              ],
            ),
          ),
        ],
        if (p.certifications.isNotEmpty || p.education != null) ...[
          gap,
          ProfileSectionCard(
            icon: Icons.workspace_premium_outlined,
            title: l10n.coachQualificationsTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final c in p.certifications)
                  _TimelineEntry(
                    title: c.name,
                    subtitle: c.issuer,
                    period: c.year?.toString(),
                  ),
                if (p.education != null)
                  _TimelineEntry(
                    title: l10n.coachEducationLabel,
                    subtitle: p.education,
                  ),
              ],
            ),
          ),
        ],
        if (p.specialties.isNotEmpty ||
            p.preferredFormations.isNotEmpty ||
            p.languages.isNotEmpty) ...[
          gap,
          ProfileSectionCard(
            icon: Icons.psychology_outlined,
            title: l10n.coachSkillsTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ChipGroup(
                  label: l10n.coachSpecialtiesLabel,
                  values: p.specialties,
                ),
                _ChipGroup(
                  label: l10n.coachFormationsLabel,
                  values: p.preferredFormations,
                ),
                _ChipGroup(
                  label: l10n.coachLanguagesLabel,
                  values: p.languages,
                ),
              ],
            ),
          ),
        ],
        if (p.achievements.isNotEmpty) ...[
          gap,
          ProfileSectionCard(
            icon: Icons.emoji_events_outlined,
            title: l10n.achievementsTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final a in p.achievements)
                  _TimelineEntry(
                    title: a.title,
                    period: '${a.year}',
                    description: a.description,
                  ),
              ],
            ),
          ),
        ],
        if (p.media.isNotEmpty) ...[
          gap,
          ProfileSectionCard(
            icon: Icons.perm_media_outlined,
            title: l10n.photosVideosTitle,
            child: CoachMediaGrid(media: p.media),
          ),
        ],
        if (p.socialLinks.isNotEmpty) ...[
          gap,
          ProfileSectionCard(
            icon: Icons.link,
            title: l10n.socialLinksTitle,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final link in p.socialLinks)
                  ActionChip(
                    avatar: const Icon(Icons.open_in_new, size: 16),
                    label: Text(link.platform),
                    onPressed: () => launchUrl(Uri.parse(link.url)),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.profile});

  final CoachProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final p = profile;
    final facts = [
      if (p.sport != null) p.sport!,
      if (p.location.isNotEmpty) p.location,
      if (p.yearsOfExperience != null)
        l10n.coachYearsOfExperience(p.yearsOfExperience!),
      if (p.nationality != null) p.nationality!,
    ];

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            CoachAvatar(url: p.profilePhotoUrl, radius: 52),
            const SizedBox(height: AppSpacing.md),
            Text(
              p.fullName.isEmpty ? l10n.coachUnnamed : p.fullName,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              p.headline ?? l10n.roleCoach,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            if (facts.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                facts.join(' · '),
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            if (p.publicCode != null) ...[
              const SizedBox(height: AppSpacing.md),
              PublicCodeChip(label: l10n.coachCodeLabel, code: p.publicCode!),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.title,
    this.subtitle,
    this.period,
    this.description,
  });

  final String title;
  final String? subtitle;
  final String? period;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(
              Icons.circle,
              size: 8,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(subtitle!, style: theme.textTheme.bodyMedium),
                if (period != null)
                  Text(period!, style: theme.textTheme.bodySmall),
                if (description != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(description!, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({required this.label, required this.values});

  final String label;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [for (final v in values) Chip(label: Text(v))],
          ),
        ],
      ),
    );
  }
}

/// Photo/video tiles. Tapping a photo opens it full size, a video plays.
/// [onDelete] adds a remove button to each tile (the owner's editor).
class CoachMediaGrid extends StatelessWidget {
  const CoachMediaGrid({super.key, required this.media, this.onDelete});

  final List<CoachMedia> media;
  final void Function(CoachMedia item)? onDelete;

  void _open(BuildContext context, CoachMedia item) {
    if (item.isVideo) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => VideoPlayerScreen(videoUrl: item.secureUrl),
        ),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: InteractiveViewer(
          child: Image(
            image: appImageProvider(
              item.secureUrl,
              context: context,
              decodeWidth: AppImageSize.fullWidth,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final item in media)
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  child: Material(
                    color: colorScheme.surfaceContainerHighest,
                    child: InkWell(
                      onTap: () => _open(context, item),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image(
                            image: appImageProvider(
                              item.thumbnailUrl,
                              context: context,
                              decodeWidth: AppImageSize.thumbnail,
                            ),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Icon(
                              item.isVideo ? Icons.movie_outlined : Icons.image,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (item.isVideo)
                            const Center(
                              child: Icon(
                                Icons.play_circle_fill,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (onDelete != null)
                  PositionedDirectional(
                    top: 4,
                    end: 4,
                    child: InkWell(
                      onTap: () => onDelete!(item),
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: colorScheme.error,
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: colorScheme.onError,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
