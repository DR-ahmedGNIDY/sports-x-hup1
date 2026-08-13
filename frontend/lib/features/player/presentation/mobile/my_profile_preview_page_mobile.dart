import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/player_profile_controller.dart';
import '../shared/share_profile_button.dart';
import 'player_profile_scouting_layout_mobile.dart';

class MyProfilePreviewPageMobile extends ConsumerWidget {
  const MyProfilePreviewPageMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(playerProfileControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return ColoredBox(
      color: AppColors.profileBg,
      child: profileAsync.when(
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.myProfileTitle,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: AppColors.profileText),
                  ),
                  Row(
                    children: [
                      ShareProfileButton(playerId: profile.id, compact: true),
                      IconButton(
                        tooltip: l10n.dashboardEditProfile,
                        onPressed: () => context.go('/player/edit'),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              PlayerProfileScoutingLayoutMobile(
                profile: profile,
                showContact: true,
                isOwner: true,
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          onRetry: () => ref.read(playerProfileControllerProvider.notifier).refresh(),
        ),
      ),
    );
  }
}
