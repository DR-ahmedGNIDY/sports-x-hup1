import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/notifications_controller.dart';
import '../../domain/entities/notifications_page.dart';
import 'notification_tile.dart';

/// The unread-only filter and the "mark all read" action — identical on
/// both platforms, so they live here rather than being written twice.
class NotificationsToolbar extends ConsumerWidget {
  const NotificationsToolbar({super.key, required this.page});

  final NotificationsPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.watch(notificationsListProvider.notifier);
    final unread = ref.watch(unreadNotificationsProvider).valueOrNull ?? 0;

    return Row(
      children: [
        FilterChip(
          label: Text(l10n.notificationsUnreadOnlyLabel),
          selected: controller.unreadOnly,
          onSelected: (value) => controller.applyUnreadOnly(value),
        ),
        const Spacer(),
        // Only offered when it would do something. A permanently visible
        // action that is usually a no-op teaches people to ignore it.
        if (unread > 0)
          TextButton(
            onPressed: () => controller.markAllRead(),
            child: Text(l10n.notificationsMarkAllReadLabel),
          ),
      ],
    );
  }
}

class NotificationsPagination extends ConsumerWidget {
  const NotificationsPagination({super.key, required this.page});

  final NotificationsPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (page.total <= page.pageSize) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final lastPage = ((page.total - 1) / page.pageSize).floor() + 1;
    final notifier = ref.read(notificationsListProvider.notifier);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: l10n.previousPageLabel,
            onPressed: page.page > 1 ? () => notifier.loadPage(page.page - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text(l10n.pageOfPagesLabel(page.page, lastPage)),
          IconButton(
            tooltip: l10n.nextPageLabel,
            onPressed: page.hasNextPage ? () => notifier.loadPage(page.page + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

/// The rows themselves, shared by both layouts.
List<Widget> notificationRows(NotificationsPage page) => [
  for (final notification in page.items)
    NotificationTile(notification: notification),
];
