import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/mobile/app_scaffold_mobile.dart';
import '../../../../core/widgets/mobile/app_skeleton_list.dart';
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
  ConsumerState<EditProfilePageMobile> createState() =>
      _EditProfilePageMobileState();
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
          SkillsSection(
            isOwner: true,
            playerId: profile.id,
            sport: profile.sport!,
          ),
        ),
      (l10n.achievementsTitle, const AchievementsSection()),
      (l10n.socialLinksTitle, const SocialLinksSection()),
      (l10n.visibilityTitle, const VisibilitySection()),
    ];
    // 3 fixed rows (completion bar, photo, details form) plus one per
    // accordion section. The heading row that used to lead this list is gone
    // — the page's own app bar names it and owns the way back.
    final itemCount = accordionSections.length + 3;

    return AppScaffoldMobile(
      // Preview is a different intent from the bar's back button — see the
      // profile you are editing, rather than leave the editor — so it stays,
      // as the bar's one action.
      actions: [
        IconButton(
          tooltip: l10n.previewLabel,
          onPressed: () => context.go('/player/preview'),
          icon: const Icon(Icons.visibility_outlined),
        ),
      ],
      slivers: [
        profileAsync.when(
          data: (_) => SliverList.builder(
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (index == 0) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: ProfileCompletionBar(),
                );
              }
              if (index == 1) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: ProfilePhotoSection(),
                    ),
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
                        footballPositionEditorBuilder:
                            buildFootballPositionEditorMobile,
                        basketballPositionEditorBuilder:
                            buildBasketballPositionEditorMobile,
                      ),
                    ),
                  ),
                );
              }
              final sectionIndex = index - 2;
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
          loading: () => const SliverToBoxAdapter(
            child: AppSkeletonList(itemCount: 5, itemHeight: 88),
          ),
          error: (error, _) => SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorState(
              onRetry: () =>
                  ref.read(playerProfileControllerProvider.notifier).refresh(),
            ),
          ),
        ),
      ],
    );
  }
}
