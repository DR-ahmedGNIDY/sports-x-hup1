import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/providers/health_check_provider.dart' show apiClientProvider;
import '../../../../core/storage/session_storage.dart';
import '../../../../core/storage/session_storage_provider.dart';

/// Both routes are public, like the profile pages they render on. The
/// player's club also sends the token when there is one, so a club sees the
/// club line on its own PRIVATE squad's profiles.
class MembershipsRemoteDataSource {
  MembershipsRemoteDataSource(this._client, [this._storage]);

  final ApiClient _client;
  final SessionStorage? _storage;

  Future<Map<String, dynamic>> getPlayerClub(String playerId) async {
    final token = await _storage?.accessToken;
    final response = await _client.get(
      '/memberships/players/$playerId/club',
      headers: token == null ? null : {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> listClubMembers(
    String clubId, {
    required int page,
  }) async {
    final response = await _client.get(
      '/memberships/clubs/$clubId/players?page=$page',
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}

final membershipsRemoteDataSourceProvider = Provider<MembershipsRemoteDataSource>(
  (ref) => MembershipsRemoteDataSource(
    ref.watch(apiClientProvider),
    ref.watch(sessionStorageProvider),
  ),
);
