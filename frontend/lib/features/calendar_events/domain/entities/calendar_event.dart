/// The calendar-events domain, mirroring `toCalendarEventView` on the
/// backend (`backend/src/calendar-events/calendar-events.mapper.ts`).
library;

enum CalendarEventType {
  match('MATCH'),
  training('TRAINING'),
  other('OTHER');

  const CalendarEventType(this.wireValue);

  final String wireValue;

  static CalendarEventType fromWire(String value) =>
      CalendarEventType.values.firstWhere((v) => v.wireValue == value);
}

enum CalendarEventRecurrence {
  none('NONE'),
  weekly('WEEKLY'),
  monthly('MONTHLY');

  const CalendarEventRecurrence(this.wireValue);

  final String wireValue;

  static CalendarEventRecurrence fromWire(String value) =>
      CalendarEventRecurrence.values.firstWhere((v) => v.wireValue == value);
}

class CalendarEventParticipant {
  const CalendarEventParticipant({required this.playerId, this.position});

  final String playerId;
  final String? position;
}

class CalendarEventMatchStat {
  const CalendarEventMatchStat({
    required this.playerId,
    this.goals = 0,
    this.assists = 0,
    this.chancesCreated = 0,
    this.keyPasses = 0,
    this.keyDefensiveActions = 0,
    this.saves = 0,
  });

  final String playerId;
  final int goals;
  final int assists;
  final int chancesCreated;
  final int keyPasses;
  final int keyDefensiveActions;
  final int saves;
}

class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.clubUserId,
    required this.type,
    this.customTypeName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.recurrence,
    this.recurrenceGroupId,
    this.opponentName,
    this.rosterBirthYear,
    this.participants = const [],
    this.confirmedAt,
    this.matchStats = const [],
  });

  final String id;
  final String clubUserId;
  final CalendarEventType type;
  final String? customTypeName;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String location;
  final CalendarEventRecurrence recurrence;
  final String? recurrenceGroupId;
  final String? opponentName;
  final int? rosterBirthYear;
  final List<CalendarEventParticipant> participants;
  final DateTime? confirmedAt;
  final List<CalendarEventMatchStat> matchStats;

  bool get isConfirmed => confirmedAt != null;

  /// The moment the event actually starts, combining [date] with
  /// [startTime] ('HH:mm') in local time — used to gate the match-rating
  /// flow, which only opens once the event has started.
  DateTime get startsAt {
    final parts = startTime.split(':');
    final hours = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
    final minutes = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
    return DateTime(date.year, date.month, date.day, hours, minutes);
  }

  bool get hasStarted => DateTime.now().isAfter(startsAt);

  String displayName({String Function(CalendarEventType)? typeLabel}) {
    if (type == CalendarEventType.other && customTypeName != null && customTypeName!.isNotEmpty) {
      return customTypeName!;
    }
    if (type == CalendarEventType.match && opponentName != null && opponentName!.isNotEmpty) {
      return opponentName!;
    }
    return typeLabel?.call(type) ?? type.wireValue;
  }
}
