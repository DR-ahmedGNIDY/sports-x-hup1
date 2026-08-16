import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/providers/health_check_provider.dart' show apiClientProvider;

class ClubPlayersRemoteDataSource {
  ClubPlayersRemoteDataSource(this._client);

  final ApiClient _client;

  Map<String, String> _bearer(String accessToken) => {
    'Authorization': 'Bearer $accessToken',
  };

  Future<Map<String, dynamic>> create(
    String accessToken,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post(
      '/club-players',
      headers: _bearer(accessToken),
      body: body,
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw apiExceptionFromResponse(response);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Paginated + optionally filtered roster page — server-side (see
  /// ClubPlayersService.listForClub), never the full roster.
  Future<Map<String, dynamic>> list(
    String accessToken, {
    int page = 1,
    String? search,
    String? sport,
    String? position,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'search': ?search,
      'sport': ?sport,
      'position': ?position,
    };
    final queryString = Uri(queryParameters: query).query;
    final response = await _client.get(
      '/club-players?$queryString',
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Roster summary for the Club Dashboard (GET /club-players/summary) —
  /// a handful of numbers + up to 5 recent players, not the full roster.
  Future<Map<String, dynamic>> summary(String accessToken) async {
    final response = await _client.get(
      '/club-players/summary',
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getOne(String accessToken, String userId) async {
    final response = await _client.get(
      '/club-players/$userId',
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> update(
    String accessToken,
    String userId,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.patch(
      '/club-players/$userId',
      headers: _bearer(accessToken),
      body: body,
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> remove(String accessToken, String userId) async {
    final response = await _client.delete(
      '/club-players/$userId',
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw apiExceptionFromResponse(response);
    }
  }

  Future<Map<String, dynamic>> uploadPhoto(
    String accessToken,
    String userId, {
    required List<int> bytes,
    required String filename,
  }) async {
    final response = await _client.postMultipart(
      '/club-players/$userId/photo',
      headers: _bearer(accessToken),
      fileField: 'file',
      fileBytes: bytes,
      filename: filename,
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw apiExceptionFromResponse(response);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> resendCredentials(
    String accessToken,
    String userId,
  ) async {
    final response = await _client.post(
      '/club-players/$userId/resend-credentials',
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw apiExceptionFromResponse(response);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}

final clubPlayersRemoteDataSourceProvider = Provider<ClubPlayersRemoteDataSource>(
  (ref) => ClubPlayersRemoteDataSource(ref.watch(apiClientProvider)),
);
