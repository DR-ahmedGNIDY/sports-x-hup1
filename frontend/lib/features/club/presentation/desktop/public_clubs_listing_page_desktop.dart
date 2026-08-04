import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_logo.dart';
import '../../../marketing/presentation/shared/marketing_chrome.dart';
import '../../application/public_clubs_controller.dart';
import '../shared/club_list_pagination.dart';
import '../shared/public_club_card.dart';

class PublicClubsListingPageDesktop extends ConsumerWidget {
  const PublicClubsListingPageDesktop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubsAsync = ref.watch(publicClubsControllerProvider);
    final controller = ref.read(publicClubsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(height: 28),
        actions: marketingDesktopNavActions(context, ref),
      ),
      body: clubsAsync.when(
        data: (page) => page.items.isEmpty
            ? const Center(child: Text('No clubs to show yet.'))
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Text(
                          'Clubs on Sport X Hub',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: ListView.separated(
                            itemCount: page.items.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) =>
                                PublicClubCard(club: page.items[index]),
                          ),
                        ),
                        if (page.total > page.pageSize) ...[
                          const SizedBox(height: 12),
                          ClubListPagination(page: page, controller: controller),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }
}
