import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/club_profile_controller.dart';
import '../shared/club_info_section.dart';
import '../shared/club_logo_section.dart';

class EditClubProfilePageDesktop extends ConsumerWidget {
  const EditClubProfilePageDesktop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(clubProfileControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Club Profile'),
        leading: BackButton(onPressed: () => context.go('/dashboard')),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/club/preview'),
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Preview'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: profileAsync.when(
        data: (_) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: const [ClubInfoSection()],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: const [ClubLogoSection()],
                        ),
                      ),
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
