import '../entities/calendar_event.dart';
import '../entities/roster_pool.dart';

/// Throws [AppException] (core/errors) on failure.
abstract class CalendarEventsRepository {
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
  });

  /// 'YYYY-MM'.
  Future<List<CalendarEvent>> listForClub(String month);

  Future<List<CalendarEvent>> listForPlayer(String month);

  Future<List<RosterPoolGroup>> rosterPool(String eventId);

  Future<CalendarEvent> updateRoster(
    String eventId, {
    required List<String> playerIds,
    Map<String, String>? positions,
  });

  Future<CalendarEvent> getById(String eventId);

  Future<CalendarEvent> updateStats(
    String eventId,
    List<CalendarEventMatchStat> entries,
  );

  Future<void> delete(String eventId);
}
