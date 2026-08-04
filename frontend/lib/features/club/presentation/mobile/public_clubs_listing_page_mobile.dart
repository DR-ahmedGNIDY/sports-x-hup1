import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/widgets/app_logo.dart';
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
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(height: 24),
        actions: [
          IconButton(
            tooltip: 'Toggle dark mode',
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            icon: Icon(themeModeToggleIcon(themeMode)),
          ),
        ],
      ),
      drawer: marketingMobileDrawer(context),
      body: clubsAsync.when(
        data: (page) => page.items.isEmpty
            ? const Center(child: Text('No clubs to show yet.'))
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
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }
}
