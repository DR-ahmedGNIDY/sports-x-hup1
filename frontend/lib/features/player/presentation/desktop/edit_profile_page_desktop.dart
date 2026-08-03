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

/// Desktop Edit Profile — a dense, multi-column sectioned form: two cards
/// side by side, each holding several sections at once.
class EditProfilePageDesktop extends ConsumerWidget {
  const EditProfilePageDesktop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(playerProfileControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: BackButton(onPressed: () => context.go('/dashboard')),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/player/preview'),
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Preview'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: profileAsync.when(
        data: (_) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _SectionCard(
                      children: const [
                        PersonalInfoSection(),
                        Divider(height: 40),
                        SportsInfoSection(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      children: [
                        _SectionCard(children: const [BioContactSection()]),
                        const SizedBox(height: 24),
                        _SectionCard(children: const [MediaSection()]),
                        const SizedBox(height: 24),
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
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
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
