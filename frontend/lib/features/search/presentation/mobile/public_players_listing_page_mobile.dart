import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/branded_app_bar_title.dart';
import '../../../../core/widgets/mobile/app_sheet.dart';
import '../../../../core/locale/language_toggle_button.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/widgets/empty_state_illustration.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../marketing/presentation/shared/marketing_chrome.dart';
import '../../../player/presentation/shared/player_search_result_card.dart';
import '../../application/search_controller.dart';
import '../shared/player_search_filters_form.dart';
import '../shared/search_pagination.dart';

/// Public Players listing (Phase 5) — mobile counterpart to
/// PublicPlayersListingPageDesktop; see that file for the reuse rationale.
class PublicPlayersListingPageMobile extends ConsumerWidget {
  const PublicPlayersListingPageMobile({super.key});

  void _openFilterSheet(BuildContext context, WidgetRef ref) {
    final controller = ref.read(searchControllerProvider.notifier);
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
    final themeMode = ref.watch(themeModeProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const BrandedAppBarTitle(),
        actions: [
          IconButton(
            tooltip: l10n.filtersTooltip,
            onPressed: () => _openFilterSheet(context, ref),
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            tooltip: l10n.themeToggleTooltip,
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            icon: Icon(themeModeToggleIcon(themeMode)),
          ),
          const LanguageToggleButton(),
        ],
      ),
      drawer: marketingMobileDrawer(context),
      body: resultsAsync.when(
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
    );
  }
}
