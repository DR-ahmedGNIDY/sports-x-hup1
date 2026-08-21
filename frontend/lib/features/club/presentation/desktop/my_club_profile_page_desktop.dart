import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../dashboard/presentation/shared/club_dashboard_widgets.dart';
import '../../application/club_profile_controller.dart';
import '../shared/club_profile_view.dart';

class MyClubProfilePageDesktop extends ConsumerWidget {
  const MyClubProfilePageDesktop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(clubProfileControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return profileAsync.when(
      data: (profile) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.dashboardMyClub, style: Theme.of(context).textTheme.headlineSmall),
                    TextButton.icon(
                      onPressed: () => context.go('/club/edit'),
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(l10n.dashboardEditClubProfile),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClubProfileView(profile: profile),
                const SizedBox(height: 28),
                Text(l10n.dashboardQuickActionsTitle, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.6,
                  children: [
                    for (final action in clubDashboardQuickActions(l10n))
                      ClubQuickActionCard(action: action),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          ErrorState(onRetry: () => ref.invalidate(clubProfileControllerProvider)),
    );
  }
}
