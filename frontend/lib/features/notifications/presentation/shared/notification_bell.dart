import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../core/widgets/mobile/app_sheet.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/application/session_controller.dart';
import '../../../auth/application/session_state.dart';
import '../../application/notifications_controller.dart';
import '../../domain/entities/app_notification.dart';
import 'notification_badge.dart';
import 'notification_tile.dart';

/// The bell in the header: the notification affordance where people already
/// look for one.
///
/// It opens a panel of the most recent few rather than navigating straight
/// to the full screen. Glancing is the common case — "is this worth
/// stopping for?" — and answering it without leaving the current screen is
/// the whole reason a bell beats a link. The panel's own footer goes to the
/// full list for the times it isn't.
///
/// Renders nothing when signed out: a bell that always says zero is chrome,
/// not information.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  /// How many the panel shows before deferring to the full screen. Enough to
  /// cover "what did I miss", short enough that the panel never becomes a
  /// scrolling list competing with the screen it links to.
  static const int _panelLimit = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    if (session.status != SessionStatus.authenticated) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      tooltip: l10n.notificationsTitle,
      onPressed: () {
        AppHaptics.light();
        _openPanel(context, ref);
      },
      icon: const NotificationBadge(child: Icon(Icons.notifications_none)),
    );
  }

  void _openPanel(BuildContext context, WidgetRef ref) {
    // Refreshed on open as well as on the badge's own timer: this is the
    // moment the count and the list actually have to agree, and the list is
    // not polled — only the count is, since that is the part that has to
    // announce itself before anyone thinks to look here.
    ref.invalidate(notificationsListProvider);
    ref.invalidate(unreadNotificationsProvider);

    AppSheet.show<void>(
      context: context,
      builder: (sheetContext) => const _NotificationPanel(limit: _panelLimit),
    );
  }
}

class _NotificationPanel extends ConsumerWidget {
  const _NotificationPanel({required this.limit});

  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final listAsync = ref.watch(notificationsListProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.notificationsTitle,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if ((ref.watch(unreadNotificationsProvider).valueOrNull ?? 0) > 0)
                TextButton(
                  onPressed: () => ref
                      .read(notificationsListProvider.notifier)
                      .markAllRead(),
                  child: Text(l10n.notificationsMarkAllReadLabel),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          listAsync.when(
            data: (page) => page.items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xl,
                    ),
                    child: Text(
                      l10n.notificationsEmpty,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final AppNotification n
                          in page.items.take(limit))
                        // The tile closes the sheet itself before navigating;
                        // leaving it open over the screen it just opened
                        // would hide the thing the tap asked for.
                        NotificationTile(
                          notification: n,
                          onTapped: () => Navigator.of(context).pop(),
                        ),
                    ],
                  ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text(
                l10n.genericErrorMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/notifications');
            },
            child: Text(l10n.notificationsSeeAll),
          ),
        ],
      ),
    );
  }
}
