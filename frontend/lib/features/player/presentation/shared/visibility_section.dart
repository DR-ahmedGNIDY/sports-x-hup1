import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/player_profile_controller.dart';
import '../../domain/entities/player_enums.dart';

/// Binary Public/Private toggle — no tiered visibility in V1.
class VisibilitySection extends ConsumerWidget {
  const VisibilitySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(playerProfileControllerProvider).value;
    final isPublic = profile?.visibility == ProfileVisibility.public;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Profile Visibility', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          isPublic
              ? 'Your profile is visible to Clubs in search results.'
              : 'Your profile is hidden from search and public view.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Public profile'),
          value: isPublic,
          onChanged: profile == null
              ? null
              : (value) => ref
                    .read(playerProfileControllerProvider.notifier)
                    .setVisibility(
                      value ? ProfileVisibility.public : ProfileVisibility.private,
                    ),
        ),
      ],
    );
  }
}
