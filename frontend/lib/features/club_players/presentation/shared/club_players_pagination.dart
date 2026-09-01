import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../application/club_players_controller.dart';
import '../../domain/entities/club_roster_page.dart';

class ClubPlayersPagination extends ConsumerWidget {
  const ClubPlayersPagination({super.key, required this.page});

  final ClubRosterPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (page.total <= page.pageSize) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final lastPage = ((page.total - 1) / page.pageSize).floor() + 1;
    final notifier = ref.read(clubPlayersControllerProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: l10n.previousPageLabel,
          onPressed: page.page > 1
              ? () => notifier.loadPage(page.page - 1)
              : null,
          // Icons.chevron_left/right already have matchTextDirection: true
          // baked into their IconData, so Flutter auto-mirrors them for
          // RTL without any extra parameter here.
          icon: const Icon(Icons.chevron_left),
        ),
        Text(l10n.pageOfPagesLabel(page.page, lastPage)),
        IconButton(
          tooltip: l10n.nextPageLabel,
          onPressed: page.hasNextPage
              ? () => notifier.loadPage(page.page + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
