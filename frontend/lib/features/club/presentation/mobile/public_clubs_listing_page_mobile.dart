import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../marketing/presentation/shared/marketing_chrome.dart';
import '../../application/public_clubs_controller.dart';
import '../shared/club_list_pagination.dart';
import '../shared/public_club_card.dart';

class PublicClubsListingPageMobile extends ConsumerWidget {
  const PublicClubsListingPageMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubsAsync = ref.watch(publicClubsControllerProvider);
    final controller = ref.read(publicClubsControllerProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: marketingHeaderAppBar(
        context,
        title: const AppLogo(height: 24),
        actions: marketingMobileAppBarActions(context, ref),
      ),
      drawer: marketingMobileDrawer(context),
      body: clubsAsync.when(
        data: (page) => page.items.isEmpty
            ? Center(child: Text(l10n.clubsNoResults))
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: page.items.length,
                      itemBuilder: (context, index) =>
                          PublicClubCard(club: page.items[index]),
                    ),
                  ),
                  if (page.total > page.pageSize)
                    ClubListPagination(page: page, controller: controller),
                ],
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            ErrorState(onRetry: () => ref.invalidate(publicClubsControllerProvider)),
      ),
    );
  }
}
