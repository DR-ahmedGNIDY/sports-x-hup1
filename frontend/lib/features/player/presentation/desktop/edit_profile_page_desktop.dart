import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/player_profile_controller.dart';
import 'basketball_position_section_desktop.dart';
import 'football_position_section_desktop.dart';
import '../shared/achievements_section.dart';
import '../shared/media_section.dart';
import '../shared/profile_completion_bar.dart';
import '../shared/profile_details_form.dart';
import '../shared/profile_photo_section.dart';
import '../shared/skills_section.dart';
import '../shared/social_links_section.dart';
import '../shared/visibility_section.dart';

/// Desktop Edit Profile — immediate-action sections (photo, gallery,
/// achievements, links, visibility) up top in two columns, the deferred
/// text form (name/sport/bio/contact) as one full-width card at the end
/// with the single Save action.
class EditProfilePageDesktop extends ConsumerWidget {
  const EditProfilePageDesktop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(playerProfileControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return profileAsync.when(
        data: (profile) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.dashboardEditProfile, style: Theme.of(context).textTheme.headlineSmall),
                      TextButton.icon(
                        onPressed: () => context.go('/player/preview'),
                        icon: const Icon(Icons.visibility_outlined),
                        label: Text(l10n.previewLabel),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const ProfileCompletionBar(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _SectionCard(children: const [ProfilePhotoSection()]),
                            const SizedBox(height: 24),
                            _SectionCard(children: const [MediaSection()]),
                            if (profile.sport != null && profile.sport!.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              _SectionCard(
                                children: [
                                  SkillsSection(
                                    isOwner: true,
                                    playerId: profile.id,
                                    sport: profile.sport!,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          children: [
                            _SectionCard(children: const [AchievementsSection()]),
                            const SizedBox(height: 24),
                            _SectionCard(children: const [SocialLinksSection()]),
                            const SizedBox(height: 24),
                            _SectionCard(children: const [VisibilitySection()]),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SectionCard(
                    children: [
                      ProfileDetailsForm(
                        footballPositionEditorBuilder: buildFootballPositionEditorDesktop,
                        basketballPositionEditorBuilder: buildBasketballPositionEditorDesktop,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          onRetry: () => ref.read(playerProfileControllerProvider.notifier).refresh(),
        ),
      );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      ),
    );
  }
}
