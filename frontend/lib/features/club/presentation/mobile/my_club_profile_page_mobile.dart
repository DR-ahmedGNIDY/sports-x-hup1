import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/mobile/app_scaffold_mobile.dart';
import '../../../../core/widgets/mobile/app_skeleton_list.dart';
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

    return AppScaffoldMobile(
      onRefresh: () async => ref.invalidate(clubProfileControllerProvider),
      // Edit is the screen's action; it moved from a labelled button in the
      // content to the bar, now that the screen has one.
      actions: [
        IconButton(
          tooltip: l10n.dashboardEditClubProfile,
          onPressed: () => context.go('/club/edit'),
          icon: const Icon(Icons.edit_outlined),
        ),
      ],
      slivers: [
        profileAsync.when(
          data: (profile) => SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList.list(
              children: [
                ClubProfileView(profile: profile),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.dashboardQuickActionsTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final action in clubDashboardQuickActions(l10n)) ...[
                  ClubQuickActionCard(action: action),
                  const SizedBox(height: AppSpacing.sm + 2),
                ],
              ],
            ),
          ),
          loading: () => const SliverToBoxAdapter(
            child: AppSkeletonList(itemCount: 4, itemHeight: 120),
          ),
          error: (error, _) => SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorState(
              onRetry: () => ref.invalidate(clubProfileControllerProvider),
            ),
          ),
        ),
      ],
    );
  }
}
