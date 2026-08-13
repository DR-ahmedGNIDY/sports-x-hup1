import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/empty_state_illustration.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../marketing/presentation/shared/marketing_chrome.dart';
import '../../../player/presentation/shared/player_search_result_card.dart';
import '../../application/search_controller.dart';
import '../shared/player_search_filters_form.dart';
import '../shared/search_pagination.dart';

/// Public Players listing (Phase 5) — same search backend and result cards
/// as the authenticated Club-facing Search Players tool (`/search`), just a
/// different outer chrome (marketing nav instead of a dashboard back
/// button) so it's reachable by a cold, signed-out visitor. Both screens
/// share the same public GET /players endpoint and PlayerSearchController.
class PublicPlayersListingPageDesktop extends ConsumerWidget {
  const PublicPlayersListingPageDesktop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(searchControllerProvider);
    final controller = ref.read(searchControllerProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(height: 28),
        actions: marketingDesktopNavActions(context, ref),
      ),
      body: Row(
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
                  : Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
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
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  ErrorState(onRetry: () => ref.invalidate(searchControllerProvider)),
            ),
          ),
        ],
      ),
    );
  }
}
