import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/profile_colors.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/player_profile_controller.dart';
import '../shared/share_profile_button.dart';
import 'player_profile_scouting_layout_desktop.dart';

class MyProfilePreviewPageDesktop extends ConsumerWidget {
  const MyProfilePreviewPageDesktop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(playerProfileControllerProvider);
    final l10n = AppLocalizations.of(context)!;
    final accent = context.profileColors.accent;

    return ColoredBox(
      color: context.profileColors.bg,
      child: profileAsync.when(
        data: (profile) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: PlayerProfileScoutingLayoutDesktop(
                profile: profile,
                showContact: true,
                isOwner: true,
                heroActions: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => context.go('/player/edit'),
                      icon: Icon(Icons.edit_outlined, size: 18, color: accent),
                      label: Text(
                        l10n.dashboardEditProfile,
                        style: TextStyle(color: accent),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: accent.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ShareProfileButton(playerId: profile.id),
                  ],
                ),
              ),
            ),
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
