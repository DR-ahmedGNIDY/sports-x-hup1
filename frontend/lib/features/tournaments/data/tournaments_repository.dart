import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/authorized_request.dart';
import '../../../core/providers/health_check_provider.dart'
    show apiClientProvider;
import '../../../core/storage/session_storage.dart';
import '../../../core/storage/session_storage_provider.dart';
import '../domain/tournament.dart';

/// `/club-tournaments` — the club and its permitted coaches (the API client
/// adds X-Club-Id for a coach) — and the players' read-only
/// `/my-tournaments`.
class TournamentsRepository {
  TournamentsRepository(this._client, this._storage, this._ref);

  final ApiClient _client;
  final SessionStorage _storage;
  final Ref _ref;

  static const _base = '/club-tournaments';

  Future<T> _authorized<T>(
    Future<T> Function(Map<String, String> headers) call,
  ) => runAuthorized(
    _ref,
    _storage,
    (token) => call({'Authorization': 'Bearer $token'}),
  );

  Object? _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw apiExceptionFromResponse(response);
    }
    return response.body.isEmpty ? null : jsonDecode(response.body);
  }

  Future<Object?> _get(String path) =>
      _authorized((h) async => _decode(await _client.get(path, headers: h)));

  Future<Object?> _post(String path, [Object? body]) => _authorized(
    (h) async => _decode(await _client.post(path, body: body, headers: h)),
  );

  Future<Object?> _patch(String path, Object body) => _authorized(
    (h) async => _decode(await _client.patch(path, body: body, headers: h)),
  );

  Future<Object?> _delete(String path) =>
      _authorized((h) async => _decode(await _client.delete(path, headers: h)));

  List<Tournament> _list(Object? json) => [
    for (final t in json! as List<dynamic>)
      Tournament.fromJson(t as Map<String, dynamic>),
  ];

  TournamentDetail _detail(Object? json) =>
      TournamentDetail.fromJson(json! as Map<String, dynamic>);

  // ------------------------------------------------------------------ club

  Future<List<Tournament>> list() async => _list(await _get(_base));

  Future<TournamentDetail> detail(String id) async =>
      _detail(await _get('$_base/$id'));

  Future<Tournament> create(Map<String, dynamic> body) async =>
      Tournament.fromJson((await _post(_base, body))! as Map<String, dynamic>);

  Future<void> update(String id, Map<String, dynamic> body) =>
      _patch('$_base/$id', body);

  Future<void> delete(String id) => _delete('$_base/$id');

  Future<List<TournamentPlayer>> eligiblePlayers(String id) async => [
    for (final p
        in (await _get('$_base/$id/eligible-players'))! as List<dynamic>)
      TournamentPlayer.fromJson(p as Map<String, dynamic>),
  ];

  Future<void> addParticipant(String id, Map<String, dynamic> body) =>
      _post('$_base/$id/participants', body);

  Future<void> updateParticipant(
    String id,
    String participantId,
    Map<String, dynamic> body,
  ) => _patch('$_base/$id/participants/$participantId', body);

  Future<void> removeParticipant(String id, String participantId) =>
      _delete('$_base/$id/participants/$participantId');

  Future<void> orderParticipants(String id, List<String> order) =>
      _patch('$_base/$id/participants/order', {'order': order});

  Future<TournamentDetail> generate(String id) async =>
      _detail(await _post('$_base/$id/generate'));

  Future<void> resetSchedule(String id) => _delete('$_base/$id/fixtures');

  Future<void> updateFixture(
    String id,
    String fixtureId,
    Map<String, dynamic> body,
  ) => _patch('$_base/$id/fixtures/$fixtureId', body);

  Future<TournamentDetail> recordResult(
    String id,
    String fixtureId,
    Map<String, dynamic> body,
  ) async =>
      _detail(await _post('$_base/$id/fixtures/$fixtureId/result', body));

  Future<TournamentDetail> clearResult(String id, String fixtureId) async =>
      _detail(await _delete('$_base/$id/fixtures/$fixtureId/result'));

  // ---------------------------------------------------------------- player

  Future<List<Tournament>> mine() async => _list(await _get('/my-tournaments'));

  Future<TournamentDetail> myDetail(String id) async =>
      _detail(await _get('/my-tournaments/$id'));
}

final tournamentsRepositoryProvider = Provider<TournamentsRepository>(
  (ref) => TournamentsRepository(
    ref.watch(apiClientProvider),
    ref.watch(sessionStorageProvider),
    ref,
  ),
);

/// The club's tournaments.
final clubTournamentsProvider = FutureProvider.autoDispose<List<Tournament>>(
  (ref) => ref.watch(tournamentsRepositoryProvider).list(),
);

final tournamentDetailProvider = FutureProvider.autoDispose
    .family<TournamentDetail, String>(
      (ref, id) => ref.watch(tournamentsRepositoryProvider).detail(id),
    );

final eligiblePlayersProvider = FutureProvider.autoDispose
    .family<List<TournamentPlayer>, String>(
      (ref, id) => ref.watch(tournamentsRepositoryProvider).eligiblePlayers(id),
    );

/// The player portal.
final myTournamentsProvider = FutureProvider.autoDispose<List<Tournament>>(
  (ref) => ref.watch(tournamentsRepositoryProvider).mine(),
);

final myTournamentDetailProvider = FutureProvider.autoDispose
    .family<TournamentDetail, String>(
      (ref, id) => ref.watch(tournamentsRepositoryProvider).myDetail(id),
    );
