import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../dashboard/presentation/shared/club_dashboard_widgets.dart';
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
            // Titled by the shell's app bar; the action stays, labelled
            // rather than a bare icon now that no adjacent title lends it
            // context.
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () => context.go('/club/edit'),
                icon: const Icon(Icons.edit_outlined),
                label: Text(l10n.dashboardEditClubProfile),
              ),
            ),
            const SizedBox(height: 8),
            ClubProfileView(profile: profile),
            const SizedBox(height: 24),
            Text(l10n.dashboardQuickActionsTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final action in clubDashboardQuickActions(l10n)) ...[
              ClubQuickActionCard(action: action),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          ErrorState(onRetry: () => ref.invalidate(clubProfileControllerProvider)),
    );
  }
}
