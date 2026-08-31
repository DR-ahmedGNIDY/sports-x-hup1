import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state_illustration.dart';
import '../../../../core/widgets/error_state.dart';
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: PlayerSearchFiltersForm(
            initialFilters: controller.filters,
            onApply: (filters) {
              controller.applyFilters(filters);
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(searchControllerProvider);
    final controller = ref.read(searchControllerProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          // The screen's name moved to the shell's app bar; what stays is its
          // action, now labelled rather than a bare icon — with no adjacent
          // title to lend it context, a lone glyph here reads as decoration.
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: () => _openFilterSheet(context, ref),
              icon: const Icon(Icons.filter_list),
              label: Text(l10n.filtersTooltip),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: PlayerSearchBox(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: resultsAsync.maybeWhen(
            data: (page) => Text(
              l10n.searchResultsCountLabel(page.total),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ),
        Expanded(
          child: resultsAsync.when(
            data: (page) => page.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const EmptyStateIllustration(
                          variant: EmptyStateVariant.noResults,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(l10n.playersNoResults),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: page.items.length,
                          itemBuilder: (context, index) =>
                              PlayerSearchResultCard(player: page.items[index]),
                        ),
                      ),
                      if (page.total > page.pageSize)
                        SearchPagination(page: page, controller: controller),
                    ],
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorState(onRetry: () => ref.invalidate(searchControllerProvider)),
          ),
        ),
      ],
    );
  }
}
