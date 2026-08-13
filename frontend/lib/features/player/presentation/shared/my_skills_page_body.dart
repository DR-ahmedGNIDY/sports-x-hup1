import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/player_profile_controller.dart';
import 'skills_section.dart';

/// Standalone "Skills" screen body — the same [SkillsSection] embedded in
/// the profile's trailing sections, just reachable directly from the
/// mobile bottom nav instead of scrolling the whole profile. Shared by
/// desktop/mobile; only the outer padding/max-width differs per platform.
class MySkillsPageBody extends ConsumerWidget {
  const MySkillsPageBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(playerProfileControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return profileAsync.when(
      data: (profile) {
        final sport = profile.sport;
        if (sport == null || sport.isEmpty) {
          return Center(
            child: Text(
              l10n.setSportFirstMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.greyLight),
            ),
          );
        }
        return SkillsSection(isOwner: true, playerId: profile.id, sport: sport);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorState(
        onRetry: () => ref.read(playerProfileControllerProvider.notifier).refresh(),
      ),
    );
  }
}
