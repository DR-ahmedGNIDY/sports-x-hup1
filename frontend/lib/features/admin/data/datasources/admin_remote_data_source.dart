import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/providers/health_check_provider.dart' show apiClientProvider;

class AdminRemoteDataSource {
  AdminRemoteDataSource(this._client);

  final ApiClient _client;

  Map<String, String> _bearer(String accessToken) => {
    'Authorization': 'Bearer $accessToken',
  };

  Future<Map<String, dynamic>> getUsers(
    String accessToken, {
    int page = 1,
    String? role,
  }) async {
    final roleQuery = role == null ? '' : '&role=$role';
    final response = await _client.get(
      '/admin/users?page=$page$roleQuery',
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> setUserStatus(String accessToken, String userId, String status) async {
    final response = await _client.patch(
      '/admin/users/$userId/status',
      headers: _bearer(accessToken),
      body: {'status': status},
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
  }

  Future<Map<String, dynamic>> getStats(String accessToken) async {
    final response = await _client.get('/admin/stats', headers: _bearer(accessToken));
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> suspendUser(
    String accessToken,
    String userId,
    String duration,
    String? reason,
  ) async {
    final response = await _client.post(
      '/admin/users//suspend',
      headers: _bearer(accessToken),
      body: {'duration': duration, 'reason': ?reason},
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw apiExceptionFromResponse(response);
    }
  }

  Future<void> reactivateUser(String accessToken, String userId) async {
    final response = await _client.post(
      '/admin/users//reactivate',
      headers: _bearer(accessToken),
      body: const <String, dynamic>{},
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw apiExceptionFromResponse(response);
    }
  }

  Future<void> setUserModerator(
    String accessToken,
    String userId,
    bool isModerator,
  ) async {
    final response = await _client.patch(
      '/admin/users//moderator',
      headers: _bearer(accessToken),
      body: {'isModerator': isModerator},
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
  }

  Future<void> setClubVerified(
    String accessToken,
    String clubId,
    bool verified,
  ) async {
    final response = await _client.patch(
      '/admin/clubs//verification',
      headers: _bearer(accessToken),
      body: {'verified': verified},
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
  }

  Future<void> deleteUser(String accessToken, String userId) async {
    final response = await _client.delete(
      '/admin/users/$userId',
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
  }

  Future<Map<String, dynamic>> getPlayers(String accessToken, {int page = 1}) async {
    final response = await _client.get(
      '/admin/players?page=$page',
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> deletePlayer(String accessToken, String playerId) async {
    final response = await _client.delete(
      '/admin/players/$playerId',
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
  }

  Future<Map<String, dynamic>> getClubs(String accessToken, {int page = 1}) async {
    final response = await _client.get(
      '/admin/clubs?page=$page',
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> deleteClub(String accessToken, String clubId) async {
    final response = await _client.delete(
      '/admin/clubs/$clubId',
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
  }
}

final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>(
  (ref) => AdminRemoteDataSource(ref.watch(apiClientProvider)),
);
