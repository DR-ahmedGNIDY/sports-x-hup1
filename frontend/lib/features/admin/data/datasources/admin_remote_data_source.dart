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

  Future<Map<String, dynamic>> getUsers(String accessToken, {int page = 1}) async {
    final response = await _client.get(
      '/admin/users?page=$page',
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
