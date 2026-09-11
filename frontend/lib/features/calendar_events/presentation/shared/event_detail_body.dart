import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../player/application/public_player_profile_provider.dart';
import '../../../player/domain/entities/football_position.dart';
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

    return SingleChildScrollView(
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
        ],
      ),
    );
  }

  void _openRatingPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
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
                    Navigator.of(context).pop();
                    showMatchStatSheet(
                      context,
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

    final profileFutures = [
      for (final participant in event.participants)
        ref.watch(publicPlayerProfileProvider(participant.playerId)),
    ];
    final loaded = profileFutures.every((p) => p.hasValue || p.hasError);
    if (!loaded) {
      return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    }

    final names = <String, String>{};
    String? primarySport;
    for (var i = 0; i < event.participants.length; i++) {
      final profile = profileFutures[i].value;
      if (profile == null) continue;
      names[event.participants[i].playerId] =
          '${profile.firstName ?? ''} ${profile.lastName ?? ''}'.trim();
      primarySport ??= profile.sport;
    }

    return SizedBox(
      height: 480,
      child: EventLineupPitch(
        participants: event.participants,
        participantNames: names,
        isBasketball: !isFootballSport(primarySport) && (primarySport?.toLowerCase().contains('basket') ?? false),
      ),
    );
  }
}
