import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/providers/health_check_provider.dart' show apiClientProvider;

/// Both routes are public, like the profile pages they render on — no
/// bearer token is sent, and none is needed.
class MembershipsRemoteDataSource {
  MembershipsRemoteDataSource(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> getPlayerClub(String playerId) async {
    final response = await _client.get('/memberships/players/$playerId/club');
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
  (ref) => MembershipsRemoteDataSource(ref.watch(apiClientProvider)),
);
