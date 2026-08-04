import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/providers/health_check_provider.dart' show apiClientProvider;

class SavedPlayersRemoteDataSource {
  SavedPlayersRemoteDataSource(this._client);

  final ApiClient _client;

  Map<String, String> _bearer(String accessToken) => {
    'Authorization': 'Bearer $accessToken',
  };

  Future<List<dynamic>> getSavedPlayers(String accessToken) async {
    final response = await _client.get('/saved-players/me', headers: _bearer(accessToken));
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as List<dynamic>;
  }

  Future<void> savePlayer(String accessToken, String playerId) async {
    final response = await _client.post(
      '/saved-players/$playerId',
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw apiExceptionFromResponse(response);
    }
  }

  Future<void> unsavePlayer(String accessToken, String playerId) async {
    final response = await _client.delete(
      '/saved-players/$playerId',
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
  }
}

final savedPlayersRemoteDataSourceProvider = Provider<SavedPlayersRemoteDataSource>(
  (ref) => SavedPlayersRemoteDataSource(ref.watch(apiClientProvider)),
);
