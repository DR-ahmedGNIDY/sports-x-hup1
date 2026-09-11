import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../player/application/public_player_profile_provider.dart';
import '../../../player/domain/entities/football_position.dart';
import '../../application/calendar_events_controller.dart';
import '../../domain/entities/calendar_event.dart';
import 'event_card.dart';
import 'event_lineup_pitch.dart';
import 'match_stat_sheet.dart';
import 'roster_pool_sheet.dart';

/// Platform-agnostic event detail content — every field plus (once a
/// roster is confirmed) the sport-aware lineup pitch and, once the event
/// has started, the match-rating flow. Desktop and mobile wrap this
/// identically; only the surrounding chrome differs.
class EventDetailBody extends ConsumerWidget {
  const EventDetailBody({super.key, required this.event, required this.isClub});

  final CalendarEvent event;
  final bool isClub;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canRateMatch =
        isClub && event.type == CalendarEventType.match && event.hasStarted && event.isConfirmed;

    // Deliberately not a scroll view: the pages that mount this already
    // scroll, and nesting a second scrollable inside them made the page
    // spring back on its own and put the actions below out of reach.
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            event.displayName(typeLabel: calendarEventTypeLabel),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text('${event.date.year}/${event.date.month}/${event.date.day}'),
          Text('${event.startTime} - ${event.endTime}'),
          Text(event.location),
          if (event.opponentName != null) Text('ضد: ${event.opponentName}'),
          const SizedBox(height: 16),
          if (isClub && !event.isConfirmed)
            FilledButton(
              onPressed: () => showRosterPoolSheet(context, ref: ref, event: event),
              child: const Text('أكمل التسجيل'),
            ),
          if (event.isConfirmed) ...[
            const Text('التشكيلة', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _LineupSection(event: event),
          ],
          if (canRateMatch) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _openRatingPicker(context, ref),
              icon: const Icon(Icons.star_outline),
              label: const Text('تقييم المباراة'),
            ),
          ],
          if (isClub) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => _confirmDelete(context, ref),
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              label: const Text('حذف الحدث', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: const Text('حذف الحدث'),
        content: const Text('سيُحذف هذا الحدث نهائيًا. هل أنت متأكد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(calendarEventActionsProvider).delete(event.id, event.date);
      if (context.mounted) Navigator.of(context).maybePop();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
      }
    }
  }

  void _openRatingPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          for (final participant in event.participants)
            Consumer(
              builder: (context, ref, _) {
                final profileAsync = ref.watch(publicPlayerProfileProvider(participant.playerId));
                final name = profileAsync.value != null
                    ? '${profileAsync.value!.firstName ?? ''} ${profileAsync.value!.lastName ?? ''}'.trim()
                    : participant.playerId;
                return ListTile(
                  title: Text(name.isEmpty ? participant.playerId : name),
                  subtitle: participant.position != null ? Text(participant.position!) : null,
                  onTap: () {
                    final navigator = Navigator.of(context, rootNavigator: true);
                    navigator.pop();
                    showMatchStatSheet(
                      navigator.context,
                      ref: ref,
                      event: event,
                      participant: participant,
                      participantName: name.isEmpty ? participant.playerId : name,
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class _LineupSection extends ConsumerWidget {
  const _LineupSection({required this.event});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (event.participants.isEmpty) {
      return const Text('لم يتم تحديد التشكيلة بعد.', style: TextStyle(color: AppColors.greyLight));
    }

    // The pitch draws as soon as the roster is known and fills each name in
    // as its profile arrives: gating the whole diagram on every profile
    // resolving left it spinning forever whenever one of them didn't.
    final profileFutures = [
      for (final participant in event.participants)
        ref.watch(publicPlayerProfileProvider(participant.playerId)),
    ];

    final lineupPlayers = <String, LineupPlayer>{};
    String? primarySport;
    for (var i = 0; i < event.participants.length; i++) {
      final playerId = event.participants[i].playerId;
      final profile = profileFutures[i].value;
      final name = profile == null
          ? ''
          : '${profile.firstName ?? ''} ${profile.lastName ?? ''}'.trim();
      lineupPlayers[playerId] = LineupPlayer(
        id: playerId,
        name: name.isEmpty ? '...' : name,
        photoUrl: profile?.profilePhoto?.secureUrl,
      );
      primarySport ??= profile?.sport;
    }

    return SizedBox(
      height: 480,
      child: EventLineupPitch(
        participants: event.participants,
        players: lineupPlayers,
        isBasketball: !isFootballSport(primarySport) && (primarySport?.toLowerCase().contains('basket') ?? false),
      ),
    );
  }
}
