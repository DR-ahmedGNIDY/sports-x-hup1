import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/providers/health_check_provider.dart' show apiClientProvider;

class CalendarEventsRemoteDataSource {
  CalendarEventsRemoteDataSource(this._client);

  final ApiClient _client;

  Map<String, String> _bearer(String accessToken) => {
    'Authorization': 'Bearer $accessToken',
  };

  Future<Map<String, dynamic>> create(
    String accessToken,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post(
      '/calendar-events',
      headers: _bearer(accessToken),
      body: body,
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw apiExceptionFromResponse(response);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> list(String accessToken, String month) =>
      _get(accessToken, '/calendar-events?month=$month');

  Future<Map<String, dynamic>> listMine(String accessToken, String month) =>
      _get(accessToken, '/calendar-events/mine?month=$month');

  Future<Map<String, dynamic>> rosterPool(String accessToken, String id) =>
      _get(accessToken, '/calendar-events/$id/roster-pool');

  Future<Map<String, dynamic>> getById(String accessToken, String id) =>
      _get(accessToken, '/calendar-events/$id');

  Future<Map<String, dynamic>> updateRoster(
    String accessToken,
    String id,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.patch(
      '/calendar-events/$id/roster',
      headers: _bearer(accessToken),
      body: body,
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateStats(
    String accessToken,
    String id,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.patch(
      '/calendar-events/$id/stats',
      headers: _bearer(accessToken),
      body: body,
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> delete(String accessToken, String id) async {
    final response = await _client.delete(
      '/calendar-events/$id',
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw apiExceptionFromResponse(response);
    }
  }

  Future<Map<String, dynamic>> _get(String accessToken, String path) async {
    final response = await _client.get(path, headers: _bearer(accessToken));
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}

final calendarEventsRemoteDataSourceProvider = Provider<CalendarEventsRemoteDataSource>(
  (ref) => CalendarEventsRemoteDataSource(ref.watch(apiClientProvider)),
);
