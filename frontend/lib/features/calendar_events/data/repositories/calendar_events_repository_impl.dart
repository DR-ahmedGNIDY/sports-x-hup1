import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/authorized_request.dart';
import '../../../../core/storage/session_storage.dart';
import '../../../../core/storage/session_storage_provider.dart';
import '../../domain/entities/calendar_event.dart';
import '../../domain/entities/roster_pool.dart';
import '../../domain/repositories/calendar_events_repository.dart';
import '../datasources/calendar_events_remote_data_source.dart';
import '../models/calendar_event_model.dart';

class CalendarEventsRepositoryImpl implements CalendarEventsRepository {
  CalendarEventsRepositoryImpl(this._remote, this._storage, this._ref);

  final CalendarEventsRemoteDataSource _remote;
  final SessionStorage _storage;
  final Ref _ref;

  Future<T> _authorized<T>(Future<T> Function(String accessToken) call) =>
      runAuthorized(_ref, _storage, call);

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _isoDate(DateTime date) =>
      '${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)}';

  @override
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
  }) => _authorized((token) async {
    final json = await _remote.create(token, {
      'type': type.wireValue,
      'customTypeName': ?customTypeName,
      'date': _isoDate(date),
      'startTime': startTime,
      'endTime': endTime,
      'location': location,
      'recurrence': recurrence.wireValue,
      'opponentName': ?opponentName,
      'rosterBirthYear': ?rosterBirthYear,
    });
    return CalendarEventModel.listFromJson(json);
  });

  @override
  Future<List<CalendarEvent>> listForClub(String month) => _authorized((token) async {
    return CalendarEventModel.listFromJson(await _remote.list(token, month));
  });

  @override
  Future<List<CalendarEvent>> listForPlayer(String month) => _authorized((token) async {
    return CalendarEventModel.listFromJson(await _remote.listMine(token, month));
  });

  @override
  Future<List<RosterPoolGroup>> rosterPool(String eventId) => _authorized((token) async {
    return RosterPoolGroupModel.listFromJson(await _remote.rosterPool(token, eventId));
  });

  @override
  Future<CalendarEvent> updateRoster(
    String eventId, {
    required List<String> playerIds,
    Map<String, String>? positions,
  }) => _authorized((token) async {
    final json = await _remote.updateRoster(token, eventId, {
      'playerIds': playerIds,
      if (positions != null && positions.isNotEmpty) 'positions': positions,
    });
    return CalendarEventModel.fromJson(json);
  });

  @override
  Future<CalendarEvent> getById(String eventId) => _authorized((token) async {
    return CalendarEventModel.fromJson(await _remote.getById(token, eventId));
  });

  @override
  Future<CalendarEvent> updateStats(
    String eventId,
    List<CalendarEventMatchStat> entries,
  ) => _authorized((token) async {
    final json = await _remote.updateStats(token, eventId, {
      'entries': [
        for (final entry in entries)
          {
            'playerId': entry.playerId,
            'goals': entry.goals,
            'assists': entry.assists,
            'chancesCreated': entry.chancesCreated,
            'keyPasses': entry.keyPasses,
            'keyDefensiveActions': entry.keyDefensiveActions,
            'saves': entry.saves,
          },
      ],
    });
    return CalendarEventModel.fromJson(json);
  });

  @override
  Future<void> delete(String eventId) => _authorized((token) async {
    await _remote.delete(token, eventId);
  });
}

final calendarEventsRepositoryProvider = Provider<CalendarEventsRepository>(
  (ref) => CalendarEventsRepositoryImpl(
    ref.watch(calendarEventsRemoteDataSourceProvider),
    ref.watch(sessionStorageProvider),
    ref,
  ),
);
