import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/club_profile_controller.dart';
import '../shared/club_profile_view.dart';

class MyClubProfilePageMobile extends ConsumerWidget {
  const MyClubProfilePageMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(clubProfileControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return profileAsync.when(
      data: (profile) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.dashboardMyClub, style: Theme.of(context).textTheme.headlineSmall),
                IconButton(
                  tooltip: l10n.dashboardEditClubProfile,
                  onPressed: () => context.go('/club/edit'),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClubProfileView(profile: profile),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          ErrorState(onRetry: () => ref.invalidate(clubProfileControllerProvider)),
    );
  }
}
