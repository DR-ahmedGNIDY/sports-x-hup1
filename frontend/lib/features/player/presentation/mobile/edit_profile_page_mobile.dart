import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/player_profile_controller.dart';
import '../shared/achievements_section.dart';
import '../shared/bio_contact_section.dart';
import '../shared/media_section.dart';
import '../shared/personal_info_section.dart';
import '../shared/social_links_section.dart';
import '../shared/sports_info_section.dart';
import '../shared/visibility_section.dart';

/// Mobile Edit Profile — an accordion: one section expanded at a time,
/// each collapsible via ExpansionTile.
class EditProfilePageMobile extends ConsumerStatefulWidget {
  const EditProfilePageMobile({super.key});

  @override
  ConsumerState<EditProfilePageMobile> createState() => _EditProfilePageMobileState();
}

class _EditProfilePageMobileState extends ConsumerState<EditProfilePageMobile> {
  int? _expanded = 0;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(playerProfileControllerProvider);

    final sections = const [
      ('Personal Information', PersonalInfoSection()),
      ('Sports Information', SportsInfoSection()),
      ('About & Contact', BioContactSection()),
      ('Photos & Videos', MediaSection()),
      ('Achievements', AchievementsSection()),
      ('Social Links', SocialLinksSection()),
      ('Visibility', VisibilitySection()),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: BackButton(onPressed: () => context.go('/dashboard')),
        actions: [
          IconButton(
            tooltip: 'Preview',
            onPressed: () => context.go('/player/preview'),
            icon: const Icon(Icons.visibility_outlined),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (_) => ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: sections.length,
          itemBuilder: (context, index) {
            final (title, section) = sections[index];
            return ExpansionTile(
              title: Text(title),
              initiallyExpanded: index == _expanded,
              onExpansionChanged: (open) =>
                  setState(() => _expanded = open ? index : null),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
              children: [section],
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }
}
