import 'package:flutter/material.dart';

import '../../application/search_controller.dart';
import '../../domain/entities/player_search_page.dart';

class SearchPagination extends StatelessWidget {
  const SearchPagination({super.key, required this.page, required this.controller});

  final PlayerSearchPage page;
  final PlayerSearchController controller;

  @override
  Widget build(BuildContext context) {
    final lastPage = ((page.total - 1) / page.pageSize).floor() + 1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: page.page > 1 ? () => controller.loadPage(page.page - 1) : null,
          // Icons.chevron_left/right already have matchTextDirection: true
          // baked into their IconData, so Flutter auto-mirrors them for
          // RTL without any extra parameter here.
          icon: const Icon(Icons.chevron_left),
        ),
        Text('Page ${page.page} of $lastPage'),
        IconButton(
          onPressed: page.hasNextPage ? () => controller.loadPage(page.page + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
