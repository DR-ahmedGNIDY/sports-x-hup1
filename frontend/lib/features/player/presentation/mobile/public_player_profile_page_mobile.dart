import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_logo.dart';
import '../../application/public_player_profile_provider.dart';
import '../shared/player_profile_view.dart';
import '../shared/save_player_button.dart';
import '../shared/simple_contact_actions.dart';

class PublicPlayerProfilePageMobile extends ConsumerWidget {
  const PublicPlayerProfilePageMobile({super.key, required this.playerId});

  final String playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicPlayerProfileProvider(playerId));

    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(height: 24),
        leading: BackButton(onPressed: () => context.pop()),
        actions: [
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
              PlayerProfileView(profile: profile),
              SimpleContactActions(playerId: playerId),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('This player profile is not available.')),
      ),
    );
  }
}
