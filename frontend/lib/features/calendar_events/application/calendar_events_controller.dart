import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/calendar_events_repository_impl.dart';
import '../domain/entities/calendar_event.dart';
import '../domain/entities/roster_pool.dart';

/// One visible calendar month, keyed by 'YYYY-MM'. Separate instances per
/// month (a `FamilyAsyncNotifier`) so paging between months never throws
/// away what was already loaded — the same shape `InvitationsListController`
/// uses per list kind.
class CalendarEventsController extends FamilyAsyncNotifier<List<CalendarEvent>, String> {
  @override
  Future<List<CalendarEvent>> build(String month) =>
      ref.read(calendarEventsRepositoryProvider).listForClub(month);

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(calendarEventsRepositoryProvider).listForClub(arg),
    );
  }
}

final calendarEventsProvider =
    AsyncNotifierProvider.family<CalendarEventsController, List<CalendarEvent>, String>(
      CalendarEventsController.new,
    );

/// The player's read-only counterpart — events they participate in.
class PlayerCalendarEventsController extends FamilyAsyncNotifier<List<CalendarEvent>, String> {
  @override
  Future<List<CalendarEvent>> build(String month) =>
      ref.read(calendarEventsRepositoryProvider).listForPlayer(month);

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(calendarEventsRepositoryProvider).listForPlayer(arg),
    );
  }
}

final playerCalendarEventsProvider =
    AsyncNotifierProvider.family<
      PlayerCalendarEventsController,
      List<CalendarEvent>,
      String
    >(PlayerCalendarEventsController.new);

/// One event's own detail — a separate provider from the month list so the
/// detail page (and everything nested under it: roster pool, stats) never
/// has to keep a whole month loaded just to show one event.
final calendarEventProvider = FutureProvider.autoDispose.family<CalendarEvent, String>(
  (ref, id) => ref.read(calendarEventsRepositoryProvider).getById(id),
);

final rosterPoolProvider = FutureProvider.autoDispose.family<List<RosterPoolGroup>, String>(
  (ref, eventId) => ref.read(calendarEventsRepositoryProvider).rosterPool(eventId),
);

/// Mutations reachable from screens with no month list mounted (the event
/// detail page, roster/position sheets, the match-rating sheet). Mirrors
/// `InvitationsActions` — kept off the list controller so reading it never
/// triggers an unwanted month fetch.
class CalendarEventActions {
  CalendarEventActions(this._ref);

  final Ref _ref;

  Future<List<CalendarEvent>> create({
    required CalendarEventType type,
    String? customTypeName,
    required DateTime date,
    required String startTime,
    required String endTime,
    required String location,
    required CalendarEventRecurrence recurrence,
    String? opponentName,
    int? rosterBirthYear,
  }) async {
    final created = await _ref
        .read(calendarEventsRepositoryProvider)
        .create(
          type: type,
          customTypeName: customTypeName,
          date: date,
          startTime: startTime,
          endTime: endTime,
          location: location,
          recurrence: recurrence,
          opponentName: opponentName,
          rosterBirthYear: rosterBirthYear,
        );
    _invalidateMonth(date);
    return created;
  }

  Future<CalendarEvent> updateRoster(
    String eventId, {
    required List<String> playerIds,
    Map<String, String>? positions,
  }) async {
    final updated = await _ref
        .read(calendarEventsRepositoryProvider)
        .updateRoster(eventId, playerIds: playerIds, positions: positions);
    _ref.invalidate(calendarEventProvider(eventId));
    _invalidateMonth(updated.date);
    return updated;
  }

  Future<CalendarEvent> updateStats(
    String eventId,
    List<CalendarEventMatchStat> entries,
  ) async {
    final updated = await _ref
        .read(calendarEventsRepositoryProvider)
        .updateStats(eventId, entries);
    _ref.invalidate(calendarEventProvider(eventId));
    return updated;
  }

  Future<void> delete(String eventId, DateTime month) async {
    await _ref.read(calendarEventsRepositoryProvider).delete(eventId);
    _ref.invalidate(calendarEventProvider(eventId));
    _invalidateMonth(month);
  }

  void _invalidateMonth(DateTime date) {
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    _ref.invalidate(calendarEventsProvider(key));
  }
}

final calendarEventActionsProvider = Provider<CalendarEventActions>(
  (ref) => CalendarEventActions(ref),
);
