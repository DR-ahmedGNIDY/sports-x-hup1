import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/profile_colors.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/public_player_profile_provider.dart';
import '../shared/save_player_button.dart';
import '../shared/share_profile_button.dart';
import '../shared/simple_contact_actions.dart';
import 'player_profile_scouting_layout_desktop.dart';

class PublicPlayerProfilePageDesktop extends ConsumerWidget {
  const PublicPlayerProfilePageDesktop({super.key, required this.playerId});

  final String playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicPlayerProfileProvider(playerId));
    final l10n = AppLocalizations.of(context)!;

    final profileColors = context.profileColors;
    return Scaffold(
      backgroundColor: profileColors.bg,
      appBar: AppBar(
        backgroundColor: profileColors.surface,
        automaticallyImplyLeading: false,
        leadingWidth: 200,
        leading: Padding(
          padding: const EdgeInsetsDirectional.only(start: 8),
          child: TextButton.icon(
            onPressed: () => context.go('/players'),
            icon: const BackButtonIcon(),
            label: Text(l10n.backToPlayersLabel),
          ),
        ),
        title: const SizedBox.shrink(),
        actions: [
          ShareProfileButton(playerId: playerId),
          const SizedBox(width: 8),
          profileAsync.maybeWhen(
            data: (profile) => SavePlayerButton(profile: profile),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: profileAsync.when(
        data: (profile) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PlayerProfileScoutingLayoutDesktop(
                    profile: profile,
                    showContact: false,
                    isOwner: false,
                  ),
                  const SizedBox(height: 16),
                  SimpleContactActions(playerId: playerId),
                ],
              ),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ErrorState(
          message: l10n.playerProfileNotAvailable,
          onRetry: () => ref.invalidate(publicPlayerProfileProvider(playerId)),
        ),
      ),
    );
  }
}
