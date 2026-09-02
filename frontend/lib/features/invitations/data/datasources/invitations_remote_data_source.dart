import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/providers/health_check_provider.dart' show apiClientProvider;

class InvitationsRemoteDataSource {
  InvitationsRemoteDataSource(this._client);

  final ApiClient _client;

  Map<String, String> _bearer(String accessToken) => {
    'Authorization': 'Bearer $accessToken',
  };

  Future<Map<String, dynamic>> invitePlayer(
    String accessToken, {
    String? playerId,
    String? playerCode,
    String? message,
  }) => _send(
    accessToken,
    '/invitations/club-to-player',
    body: {
      'playerId': ?playerId,
      'playerCode': ?playerCode,
      if (message != null && message.isNotEmpty) 'message': message,
    },
  );

  Future<Map<String, dynamic>> requestToJoinClub(
    String accessToken, {
    String? clubId,
    String? clubCode,
    String? message,
  }) => _send(
    accessToken,
    '/invitations/player-to-club',
    body: {
      'clubId': ?clubId,
      'clubCode': ?clubCode,
      if (message != null && message.isNotEmpty) 'message': message,
    },
  );

  Future<Map<String, dynamic>> listReceived(
    String accessToken, {
    required int page,
    String? status,
  }) => _list(accessToken, '/invitations/received', page: page, status: status);

  Future<Map<String, dynamic>> listSent(
    String accessToken, {
    required int page,
    String? status,
  }) => _list(accessToken, '/invitations/sent', page: page, status: status);

  Future<Map<String, dynamic>> getSummary(String accessToken) async {
    final response = await _client.get(
      '/invitations/summary',
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> accept(String accessToken, String id) =>
      _send(accessToken, '/invitations/$id/accept');

  Future<Map<String, dynamic>> reject(String accessToken, String id) =>
      _send(accessToken, '/invitations/$id/reject');

  Future<Map<String, dynamic>> cancel(String accessToken, String id) =>
      _send(accessToken, '/invitations/$id/cancel');

  Future<Map<String, dynamic>> _list(
    String accessToken,
    String path, {
    required int page,
    String? status,
  }) async {
    final query = {'page': '$page', 'status': ?status};
    final response = await _client.get(
      '$path?${Uri(queryParameters: query).query}',
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // Every write here answers with the same invitation view, so one helper
  // covers send/accept/reject/cancel. Sends answer 201, the transitions 200.
  Future<Map<String, dynamic>> _send(
    String accessToken,
    String path, {
    Object? body,
  }) async {
    final response = await _client.post(
      path,
      body: body,
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw apiExceptionFromResponse(response);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}

final invitationsRemoteDataSourceProvider = Provider<InvitationsRemoteDataSource>(
  (ref) => InvitationsRemoteDataSource(ref.watch(apiClientProvider)),
);
