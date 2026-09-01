import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/mobile/app_empty_state.dart';
import '../../../../core/widgets/mobile/app_scaffold_mobile.dart';
import '../../../../core/widgets/mobile/app_skeleton_list.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../player/presentation/shared/player_search_result_card.dart';
import '../../application/saved_players_controller.dart';

class SavedPlayersPageMobile extends ConsumerWidget {
  const SavedPlayersPageMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedPlayersControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return AppScaffoldMobile(
      onRefresh: () async => ref.invalidate(savedPlayersControllerProvider),
      slivers: [
        savedAsync.when(
          // A real sliver, not a boxed list: the rows build lazily and scroll
          // under the collapsing title as one surface.
          data: (players) => players.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    message: l10n.noSavedPlayers,
                    actionLabel: l10n.dashboardSearchPlayers,
                    onAction: () => context.go('/search'),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  sliver: SliverList.builder(
                    itemCount: players.length,
                    itemBuilder: (context, index) =>
                        PlayerSearchResultCard(player: players[index]),
                  ),
                ),
          loading: () => const SliverToBoxAdapter(child: AppSkeletonList()),
          error: (error, _) => SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorState(
              onRetry: () => ref.invalidate(savedPlayersControllerProvider),
            ),
          ),
        ),
      ],
    );
  }
}
