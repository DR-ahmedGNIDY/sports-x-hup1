import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/mobile/app_empty_state.dart';
import '../../../../core/widgets/mobile/app_scaffold_mobile.dart';
import '../../../../core/widgets/mobile/app_skeleton_list.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/club_players_controller.dart';
import '../shared/club_managed_player_card.dart';
import '../shared/club_players_pagination.dart';
import '../shared/club_players_toolbar.dart';

class ClubPlayersPageMobile extends ConsumerWidget {
  const ClubPlayersPageMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rosterAsync = ref.watch(clubPlayersControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return AppScaffoldMobile(
      onRefresh: () =>
          ref.read(clubPlayersControllerProvider.notifier).refresh(),
      // Add Player is this screen's one action and it belongs in the bar now
      // that there is a bar to put it in — it used to sit in the content as a
      // labelled button standing in for chrome the shell didn't offer.
      actions: [
        IconButton(
          tooltip: l10n.clubPlayersAddPlayerLabel,
          onPressed: () => context.go('/club/players/new'),
          icon: const Icon(Icons.person_add_outlined),
        ),
      ],
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          sliver: SliverToBoxAdapter(child: ClubPlayersToolbar()),
        ),
        rosterAsync.when(
          data: (roster) {
            if (roster.items.isEmpty) {
              final filtersActive = clubPlayersFiltersActive(
                ref.read(clubPlayersControllerProvider.notifier).filters,
              );
              return SliverFillRemaining(
                hasScrollBody: false,
                child: AppEmptyState(
                  message: filtersActive
                      ? l10n.clubPlayersNoSearchResults
                      : l10n.clubPlayersEmptyState,
                  // No action on a filtered-empty roster: "add a player" is
                  // not the answer to "your filter matched nothing".
                  actionLabel: filtersActive
                      ? null
                      : l10n.clubPlayersAddPlayerLabel,
                  onAction: filtersActive
                      ? null
                      : () => context.go('/club/players/new'),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              sliver: SliverList.builder(
                // The pagination control rides at the end of the list rather
                // than pinned below it, so it can't eat a row's worth of a
                // phone screen on every page.
                itemCount: roster.items.length + 1,
                itemBuilder: (context, index) => index == roster.items.length
                    ? Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: ClubPlayersPagination(page: roster),
                      )
                    : ClubManagedPlayerCard(player: roster.items[index]),
              ),
            );
          },
          loading: () => const SliverToBoxAdapter(child: AppSkeletonList()),
          error: (error, _) => SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorState(
              onRetry: () =>
                  ref.read(clubPlayersControllerProvider.notifier).refresh(),
            ),
          ),
        ),
      ],
    );
  }
}
