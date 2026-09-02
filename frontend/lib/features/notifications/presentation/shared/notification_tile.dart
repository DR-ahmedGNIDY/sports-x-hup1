import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/application/session_controller.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/notifications_controller.dart';
import '../../domain/entities/app_notification.dart';
import 'notification_labels.dart';

/// One row. Tapping it marks it read *and* opens what it points at —
/// those are one intention, and splitting them into two taps would leave
/// people with a list of things they have read but not acted on.
class NotificationTile extends ConsumerWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    this.onTapped,
  });

  final AppNotification notification;

  /// Called before navigating. The header panel uses it to close itself —
  /// a sheet left open over the screen the tap just opened would hide the
  /// thing the tap asked for.
  final VoidCallback? onTapped;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final unread = !notification.read;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      // Unread rows sit on a tinted surface. Colour is never the only
      // signal — the leading dot carries it too, and the row is still
      // legible without either.
      color: unread ? theme.colorScheme.surfaceContainerHighest : null,
      child: ListTile(
        onTap: () => _open(context, ref),
        leading: _Leading(notification: notification, unread: unread),
        title: Text(
          notificationText(l10n, notification),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        subtitle: notification.createdAt == null
            ? null
            : Text(
                _formatDate(notification.createdAt!),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final router = GoRouter.of(context);
    final destination = _destinationFor(ref);

    // Marked read first, but the navigation does not wait on the network:
    // a slow write must not delay the screen the tap asked for.
    unawaited(
      ref.read(notificationsListProvider.notifier).markRead(notification.id),
    );
    onTapped?.call();
    if (destination != null) router.go(destination);
  }

  /// Every notification this build knows about is about an invitation, and
  /// which inbox holds it depends on who is reading — a club's invitations
  /// live at a different path from a player's.
  String? _destinationFor(WidgetRef ref) {
    if (notification.entityType != NotificationEntityType.invitation) {
      return null;
    }
    return switch (ref.read(sessionControllerProvider).user?.role) {
      UserRole.club => '/club/invitations',
      UserRole.player => '/player/invitations',
      _ => null,
    };
  }
}

class _Leading extends StatelessWidget {
  const _Leading({required this.notification, required this.unread});

  final AppNotification notification;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = switch (notification.type) {
      NotificationType.invitationReceived => Icons.mail_outline,
      NotificationType.invitationAccepted => Icons.check_circle_outline,
      NotificationType.invitationRejected => Icons.cancel_outlined,
    };

    return SizedBox(
      width: 40,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The unread marker, as shape rather than only as colour.
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: unread ? colorScheme.primary : Colors.transparent,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// Local `unawaited` so this file needn't pull in `dart:async` for one call.
void unawaited(Future<void> future) {
  future.catchError((_) {
    // A failed mark-read is not worth interrupting navigation for; the row
    // simply stays unread and the next tap tries again.
  });
}
