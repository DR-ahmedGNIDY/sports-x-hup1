import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state_illustration.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/mobile/app_empty_state.dart';
import '../../../../core/widgets/mobile/app_scaffold_mobile.dart';
import '../../../../core/widgets/mobile/app_sheet.dart';
import '../../../../core/widgets/mobile/app_skeleton_list.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../player/presentation/shared/player_search_result_card.dart';
import '../../application/search_controller.dart';
import '../shared/player_search_box.dart';
import '../shared/player_search_filters_form.dart';
import '../shared/search_pagination.dart';

class SearchPlayersPageMobile extends ConsumerWidget {
  const SearchPlayersPageMobile({super.key});

  void _openFilterSheet(BuildContext context, WidgetRef ref) {
    final controller = ref.read(searchControllerProvider.notifier);
    // The hand-rolled keyboard inset this used to carry is AppSheet's job
    // now, and it applies it to every sheet rather than only the two that
    // remembered to.
    AppSheet.show<void>(
      context: context,
      title: AppLocalizations.of(context)!.filtersTooltip,
      builder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: PlayerSearchFiltersForm(
          initialFilters: controller.filters,
          onApply: (filters) {
            controller.applyFilters(filters);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(searchControllerProvider);
    final controller = ref.read(searchControllerProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    return AppScaffoldMobile(
      // Filters is this screen's action, and the app bar is where a screen's
      // action goes now that the screen has a bar of its own. It used to be a
      // labelled button in the content, standing in for chrome that wasn't
      // there.
      actions: [
        IconButton(
          tooltip: l10n.filtersTooltip,
          onPressed: () => _openFilterSheet(context, ref),
          icon: const Icon(Icons.filter_list),
        ),
      ],
      slivers: [
        // Pinned: on a search screen the field *is* the screen, and scrolling
        // through results should never be a reason to lose it.
        const _PinnedSearchBox(),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: resultsAsync.maybeWhen(
              data: (page) => Text(
                l10n.searchResultsCountLabel(page.total),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ),
        ),
        resultsAsync.when(
          data: (page) => page.items.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    message: l10n.playersNoResults,
                    variant: EmptyStateVariant.noResults,
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  sliver: SliverList.builder(
                    itemCount:
                        page.items.length +
                        (page.total > page.pageSize ? 1 : 0),
                    itemBuilder: (context, index) => index == page.items.length
                        ? SearchPagination(page: page, controller: controller)
                        : PlayerSearchResultCard(player: page.items[index]),
                  ),
                ),
          loading: () => const SliverToBoxAdapter(child: AppSkeletonList()),
          error: (error, _) => SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorState(
              onRetry: () => ref.invalidate(searchControllerProvider),
            ),
          ),
        ),
      ],
    );
  }
}

/// Keeps the search field on screen while results scroll under it.
class _PinnedSearchBox extends StatelessWidget {
  const _PinnedSearchBox();

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SearchBoxDelegate(
        background: Theme.of(context).scaffoldBackgroundColor,
      ),
    );
  }
}

class _SearchBoxDelegate extends SliverPersistentHeaderDelegate {
  const _SearchBoxDelegate({required this.background});

  /// Opaque, unlike the app bar above it: results sliding under a *second*
  /// translucent layer would leave two blurred bands stacked at the top.
  final Color background;

  static const double _height = 72;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: background,
      child: const Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: PlayerSearchBox(),
      ),
    );
  }

  @override
  bool shouldRebuild(_SearchBoxDelegate oldDelegate) =>
      oldDelegate.background != background;
}
