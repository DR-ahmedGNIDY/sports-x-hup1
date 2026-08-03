import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_logo.dart';
import '../../application/public_player_profile_provider.dart';
import '../shared/player_profile_view.dart';

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
      ),
      body: profileAsync.when(
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: PlayerProfileView(profile: profile),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('This player profile is not available.')),
      ),
    );
  }
}
