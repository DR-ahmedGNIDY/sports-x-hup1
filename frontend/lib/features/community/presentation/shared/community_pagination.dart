import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/community_feed_controller.dart';
import '../../domain/entities/community_feed_page.dart';

/// Small per-feature duplicate of [SearchPagination] — reusing that widget
/// verbatim would mean either exporting a controller-agnostic pagination
/// widget from the search feature (not worth the abstraction for one
/// extra caller) or coupling Community to Search's provider shape.
class CommunityPagination extends StatelessWidget {
  const CommunityPagination({
    super.key,
    required this.page,
    required this.controller,
  });

  final CommunityFeedPage page;
  final CommunityFeedController controller;

  @override
  Widget build(BuildContext context) {
    final lastPage = ((page.total - 1) / page.pageSize).floor() + 1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: page.page > 1
              ? () => controller.loadPage(page.page - 1)
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          AppLocalizations.of(context)!.pageOfPagesLabel(page.page, lastPage),
          style: AppTextStyles.statNumber.copyWith(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        IconButton(
          onPressed: page.hasNextPage
              ? () => controller.loadPage(page.page + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
