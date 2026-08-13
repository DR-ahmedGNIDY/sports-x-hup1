import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/providers/health_check_provider.dart' show apiClientProvider;

/// Raw HTTP calls to `/videos` and `/sports/categories`. Returns decoded
/// JSON (not domain entities) and throws [AppException] on any non-2xx
/// response — mapping to domain types is the repository's job.
class VideoRemoteDataSource {
  VideoRemoteDataSource(this._client);

  final ApiClient _client;

  Map<String, String> _bearer(String accessToken) => {
    'Authorization': 'Bearer $accessToken',
  };

  Future<List<dynamic>> getSkillCategories(String sport) async {
    final query = Uri(queryParameters: {'sport': sport}).query;
    final response = await _client.get('/sports/categories?$query');
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> uploadVideo(
    String accessToken, {
    required List<int> bytes,
    required String filename,
    required String category,
    required String visibility,
  }) async {
    final response = await _client.postMultipart(
      '/videos',
      headers: _bearer(accessToken),
      fileField: 'file',
      fileBytes: bytes,
      filename: filename,
      fields: {'category': category, 'visibility': visibility},
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw apiExceptionFromResponse(response);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> listMine(String accessToken, {String? category}) async {
    final query = <String, String>{'category': ?category};
    final queryString = Uri(queryParameters: query).query;
    final path = queryString.isEmpty ? '/videos/me' : '/videos/me?$queryString';
    final response = await _client.get(path, headers: _bearer(accessToken));
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as List<dynamic>;
  }

  Future<List<dynamic>> listForPlayer(String playerId, {String? category}) async {
    final query = <String, String>{'category': ?category};
    final queryString = Uri(queryParameters: query).query;
    final path = queryString.isEmpty
        ? '/videos/player/$playerId'
        : '/videos/player/$playerId?$queryString';
    final response = await _client.get(path);
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> updateVisibility(
    String accessToken,
    String videoId,
    String visibility,
  ) async {
    final response = await _client.patch(
      '/videos/$videoId/visibility',
      headers: _bearer(accessToken),
      body: {'visibility': visibility},
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> deleteVideo(String accessToken, String videoId) async {
    final response = await _client.delete('/videos/$videoId', headers: _bearer(accessToken));
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw apiExceptionFromResponse(response);
    }
  }

  Future<Map<String, dynamic>> communityFeed(
    String accessToken, {
    required String sport,
    String? category,
    int page = 1,
  }) async {
    final query = <String, String>{
      'sport': sport,
      'category': ?category,
      'page': '$page',
    };
    final queryString = Uri(queryParameters: query).query;
    final response = await _client.get(
      '/videos/community?$queryString',
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> like(String accessToken, String videoId) async {
    final response = await _client.post(
      '/videos/$videoId/like',
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw apiExceptionFromResponse(response);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> unlike(String accessToken, String videoId) async {
    final response = await _client.delete(
      '/videos/$videoId/like',
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> listComments(
    String accessToken,
    String videoId, {
    int page = 1,
  }) async {
    final response = await _client.get(
      '/videos/$videoId/comments?page=$page',
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addComment(
    String accessToken,
    String videoId,
    String text,
  ) async {
    final response = await _client.post(
      '/videos/$videoId/comments',
      headers: _bearer(accessToken),
      body: {'text': text},
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw apiExceptionFromResponse(response);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> deleteComment(String accessToken, String videoId, String commentId) async {
    final response = await _client.delete(
      '/videos/$videoId/comments/$commentId',
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw apiExceptionFromResponse(response);
    }
  }
}

final videoRemoteDataSourceProvider = Provider<VideoRemoteDataSource>(
  (ref) => VideoRemoteDataSource(ref.watch(apiClientProvider)),
);
