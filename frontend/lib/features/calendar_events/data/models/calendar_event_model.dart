import '../../domain/entities/calendar_event.dart';
import '../../domain/entities/roster_pool.dart';

extension CalendarEventModel on CalendarEvent {
  static CalendarEvent fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as String,
      clubUserId: json['clubUserId'] as String? ?? '',
      type: CalendarEventType.fromWire(json['type'] as String),
      customTypeName: json['customTypeName'] as String?,
      date: DateTime.parse(json['date'] as String),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      location: json['location'] as String? ?? '',
      recurrence: CalendarEventRecurrence.fromWire(json['recurrence'] as String),
      recurrenceGroupId: json['recurrenceGroupId'] as String?,
      opponentName: json['opponentName'] as String?,
      rosterBirthYear: json['rosterBirthYear'] as int?,
      participants: (json['participants'] as List<dynamic>? ?? const [])
          .map((e) => _participantFromJson(e as Map<String, dynamic>))
          .toList(),
      confirmedAt: _dateFromJson(json['confirmedAt']),
      matchStats: (json['matchStats'] as List<dynamic>? ?? const [])
          .map((e) => _matchStatFromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static List<CalendarEvent> listFromJson(Map<String, dynamic> json) {
    return (json['items'] as List<dynamic>? ?? const [])
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

CalendarEventParticipant _participantFromJson(Map<String, dynamic> json) {
  return CalendarEventParticipant(
    playerId: json['playerId'] as String,
    position: json['position'] as String?,
  );
}

CalendarEventMatchStat _matchStatFromJson(Map<String, dynamic> json) {
  return CalendarEventMatchStat(
    playerId: json['playerId'] as String,
    goals: json['goals'] as int? ?? 0,
    assists: json['assists'] as int? ?? 0,
    chancesCreated: json['chancesCreated'] as int? ?? 0,
    keyPasses: json['keyPasses'] as int? ?? 0,
    keyDefensiveActions: json['keyDefensiveActions'] as int? ?? 0,
    saves: json['saves'] as int? ?? 0,
  );
}

DateTime? _dateFromJson(Object? value) {
  if (value is! String) return null;
  return DateTime.tryParse(value);
}

extension RosterPoolGroupModel on RosterPoolGroup {
  static List<RosterPoolGroup> listFromJson(Map<String, dynamic> json) {
    return (json['groups'] as List<dynamic>? ?? const [])
        .map((e) => _groupFromJson(e as Map<String, dynamic>))
        .toList();
  }
}

RosterPoolGroup _groupFromJson(Map<String, dynamic> json) {
  return RosterPoolGroup(
    birthYear: json['birthYear'] as int?,
    players: (json['players'] as List<dynamic>? ?? const [])
        .map((e) => _rosterPlayerFromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

RosterPoolPlayer _rosterPlayerFromJson(Map<String, dynamic> json) {
  return RosterPoolPlayer(
    id: json['id'] as String,
    firstName: json['firstName'] as String?,
    lastName: json['lastName'] as String?,
    position: json['position'] as String?,
    dateOfBirth: _dateFromJson(json['dateOfBirth']),
  );
}
