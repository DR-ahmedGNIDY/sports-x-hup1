import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/notifications_controller.dart';

/// A small unread count over whatever it wraps.
///
/// This is the single piece that makes the whole feature work. Before it,
/// the pending count existed but only rendered on the screen that showed
/// the invitations — the one moment you no longer needed telling. A badge
/// on the account slot is the first thing that says "something happened"
/// to someone who was not already looking for it.
///
/// It is a count, not a dot: "3" tells you whether to open it now, and a
/// dot does not. Capped at 9+ because past that the exact number stops
/// changing anyone's behaviour and starts costing width.
class NotificationBadge extends ConsumerWidget {
  const NotificationBadge({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // valueOrNull, not value — a failed count must cost the badge, not the
    // navigation bar it sits in.
    final unread = ref.watch(unreadNotificationsProvider).valueOrNull ?? 0;
    if (unread == 0) return child;

    final colorScheme = Theme.of(context).colorScheme;
    final label = unread > 9 ? '9+' : '$unread';

    return Semantics(
      // Announced instead of the raw glyph: a screen reader saying "nine
      // plus" is not a sentence.
      label: AppLocalizations.of(context)!.notificationsUnreadLabel(unread),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          PositionedDirectional(
            top: -2,
            end: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16),
              decoration: BoxDecoration(
                color: colorScheme.error,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                // A ring in the bar's own colour, so the badge reads as
                // sitting *on* the avatar rather than merging into it.
                border: Border.all(color: colorScheme.surface, width: 1.5),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onError,
                  fontSize: 10,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
