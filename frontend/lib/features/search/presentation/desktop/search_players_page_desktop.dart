import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state_illustration.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../player/presentation/shared/player_search_result_card.dart';
import '../../application/search_controller.dart';
import '../shared/player_search_filters_form.dart';
import '../shared/search_pagination.dart';

class SearchPlayersPageDesktop extends ConsumerWidget {
  const SearchPlayersPageDesktop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(searchControllerProvider);
    final controller = ref.read(searchControllerProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Container(
          width: 280,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
            ),
          ),
          child: SingleChildScrollView(
            child: PlayerSearchFiltersForm(
              initialFilters: controller.filters,
              onApply: controller.applyFilters,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.dashboardSearchPlayers, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                Expanded(
                  child: resultsAsync.when(
                    data: (page) => page.items.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                EmptyStateIllustration(
                                  variant: EmptyStateVariant.noResults,
                                ),
                                SizedBox(height: AppSpacing.md),
                                Text('No players match these filters.'),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              Expanded(
                                child: GridView.builder(
                                  gridDelegate:
                                      const SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: 360,
                                        mainAxisExtent: 96,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                      ),
                                  itemCount: page.items.length,
                                  itemBuilder: (context, index) =>
                                      PlayerSearchResultCard(player: page.items[index]),
                                ),
                              ),
                              if (page.total > page.pageSize) ...[
                                const SizedBox(height: 12),
                                SearchPagination(page: page, controller: controller),
                              ],
                            ],
                          ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) =>
                        ErrorState(onRetry: () => ref.invalidate(searchControllerProvider)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
