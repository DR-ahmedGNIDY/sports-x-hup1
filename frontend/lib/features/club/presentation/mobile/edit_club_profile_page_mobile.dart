import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/club_profile_controller.dart';
import '../shared/club_info_section.dart';
import '../shared/club_logo_section.dart';

class EditClubProfilePageMobile extends ConsumerWidget {
  const EditClubProfilePageMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(clubProfileControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Club Profile'),
        leading: BackButton(onPressed: () => context.go('/dashboard')),
        actions: [
          IconButton(
            tooltip: 'Preview',
            onPressed: () => context.go('/club/preview'),
            icon: const Icon(Icons.visibility_outlined),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (_) => ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            ClubLogoSection(),
            SizedBox(height: 24),
            ClubInfoSection(),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }
}
