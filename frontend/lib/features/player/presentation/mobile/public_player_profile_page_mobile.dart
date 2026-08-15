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
import 'player_profile_scouting_layout_mobile.dart';

class PublicPlayerProfilePageMobile extends ConsumerWidget {
  const PublicPlayerProfilePageMobile({super.key, required this.playerId});

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
        leading: BackButton(onPressed: () => context.go('/players'), color: profileColors.text),
        title: Text(l10n.backToPlayersLabel, style: TextStyle(color: profileColors.text, fontSize: 16)),
        actions: [
          ShareProfileButton(playerId: playerId, compact: true),
          profileAsync.maybeWhen(
            data: (profile) => SavePlayerButton(profile: profile),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PlayerProfileScoutingLayoutMobile(
                profile: profile,
                showContact: false,
                isOwner: false,
              ),
              const SizedBox(height: 16),
              SimpleContactActions(playerId: playerId),
            ],
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
