import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../application/invitations_controller.dart';
import '../../domain/entities/invitations_page.dart';

/// Page-based pager, the same one every paginated list in this app uses —
/// see `ClubPlayersPagination`.
class InvitationsPagination extends ConsumerWidget {
  const InvitationsPagination({
    super.key,
    required this.page,
    required this.kind,
  });

  final InvitationsPage page;
  final InvitationsListKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (page.total <= page.pageSize) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final lastPage = ((page.total - 1) / page.pageSize).floor() + 1;
    final notifier = ref.read(invitationsListProvider(kind).notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: l10n.previousPageLabel,
          onPressed: page.page > 1 ? () => notifier.loadPage(page.page - 1) : null,
          // chevron_left/right carry matchTextDirection, so they mirror
          // themselves in RTL without anything extra here.
          icon: const Icon(Icons.chevron_left),
        ),
        Text(l10n.pageOfPagesLabel(page.page, lastPage)),
        IconButton(
          tooltip: l10n.nextPageLabel,
          onPressed: page.hasNextPage ? () => notifier.loadPage(page.page + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
