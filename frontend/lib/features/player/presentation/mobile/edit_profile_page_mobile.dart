import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/player_profile_controller.dart';
import 'basketball_position_section_mobile.dart';
import 'football_position_section_mobile.dart';
import '../shared/achievements_section.dart';
import '../shared/media_section.dart';
import '../shared/profile_completion_bar.dart';
import '../shared/profile_details_form.dart';
import '../shared/profile_photo_section.dart';
import '../shared/skills_section.dart';
import '../shared/social_links_section.dart';
import '../shared/visibility_section.dart';

/// Mobile Edit Profile — an accordion for the immediate-action sections
/// (one open at a time), bookended by two always-visible pieces: the
/// profile photo uploader up top (so it's never hidden behind a tap-to-
/// expand tile) and the combined details form with its single Save button
/// at the end.
class EditProfilePageMobile extends ConsumerStatefulWidget {
  const EditProfilePageMobile({super.key});

  @override
  ConsumerState<EditProfilePageMobile> createState() => _EditProfilePageMobileState();
}

class _EditProfilePageMobileState extends ConsumerState<EditProfilePageMobile> {
  int? _expanded = 0;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(playerProfileControllerProvider);
    final l10n = AppLocalizations.of(context)!;
    final profile = profileAsync.value;

    final accordionSections = [
      (l10n.photosVideosTitle, const MediaSection()),
      if (profile?.sport != null && profile!.sport!.isNotEmpty)
        (
          'Skills',
          SkillsSection(isOwner: true, playerId: profile.id, sport: profile.sport!),
        ),
      (l10n.achievementsTitle, const AchievementsSection()),
      (l10n.socialLinksTitle, const SocialLinksSection()),
      (l10n.visibilityTitle, const VisibilitySection()),
    ];
    // Heading row, then 3 fixed rows (completion bar, photo, details form)
    // plus one per accordion section.
    final itemCount = accordionSections.length + 4;

    return profileAsync.when(
      data: (_) => ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              // Titled by the shell's app bar, which also owns the way back
              // to the profile; what stays here is Preview, labelled rather
              // than a bare icon now that no adjacent title lends it context.
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: () => context.go('/player/preview'),
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text(l10n.previewLabel),
                ),
              ),
            );
          }
          if (index == 1) {
            return const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: ProfileCompletionBar(),
            );
          }
          if (index == 2) {
            return const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Card(
                child: Padding(padding: EdgeInsets.all(16), child: ProfilePhotoSection()),
              ),
            );
          }
          if (index == itemCount - 1) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ProfileDetailsForm(
                    footballPositionEditorBuilder: buildFootballPositionEditorMobile,
                    basketballPositionEditorBuilder: buildBasketballPositionEditorMobile,
                  ),
                ),
              ),
            );
          }
          final sectionIndex = index - 3;
          final (title, section) = accordionSections[sectionIndex];
          return ExpansionTile(
            title: Text(title),
            initiallyExpanded: sectionIndex == _expanded,
            onExpansionChanged: (open) =>
                setState(() => _expanded = open ? sectionIndex : null),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
            children: [section],
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorState(
        onRetry: () => ref.read(playerProfileControllerProvider.notifier).refresh(),
      ),
    );
  }
}
