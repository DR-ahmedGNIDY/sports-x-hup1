import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/widgets/app_logo.dart';
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
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(height: 24),
        actions: [
          IconButton(
            tooltip: 'Filters',
            onPressed: () => _openFilterSheet(context, ref),
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            tooltip: 'Toggle dark mode',
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            icon: Icon(themeModeToggleIcon(themeMode)),
          ),
        ],
      ),
      drawer: marketingMobileDrawer(context),
      body: resultsAsync.when(
        data: (page) => page.items.isEmpty
            ? const Center(child: Text('No players match these filters.'))
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
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }
}
