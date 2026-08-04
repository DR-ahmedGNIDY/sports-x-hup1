import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/club_profile_controller.dart';
import '../shared/club_profile_view.dart';

class MyClubProfilePageDesktop extends ConsumerWidget {
  const MyClubProfilePageDesktop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(clubProfileControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Club'),
        leading: BackButton(onPressed: () => context.go('/dashboard')),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/club/edit'),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Club Profile'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: profileAsync.when(
        data: (profile) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ClubProfileView(profile: profile),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }
}
