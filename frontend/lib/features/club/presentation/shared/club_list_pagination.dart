import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../application/public_clubs_controller.dart';
import '../../domain/entities/club_list_page.dart';

class ClubListPagination extends StatelessWidget {
  const ClubListPagination({
    super.key,
    required this.page,
    required this.controller,
  });

  final ClubListPage page;
  final PublicClubsController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lastPage = ((page.total - 1) / page.pageSize).floor() + 1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: l10n.previousPageLabel,
          onPressed: page.page > 1
              ? () => controller.loadPage(page.page - 1)
              : null,
          // Icons.chevron_left/right already have matchTextDirection: true
          // baked into their IconData, so Flutter auto-mirrors them for
          // RTL without any extra parameter here.
          icon: const Icon(Icons.chevron_left),
        ),
        Text('Page ${page.page} of $lastPage'),
        IconButton(
          tooltip: l10n.nextPageLabel,
          onPressed: page.hasNextPage
              ? () => controller.loadPage(page.page + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
