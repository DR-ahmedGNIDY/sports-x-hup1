import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/providers/health_check_provider.dart' show apiClientProvider;

/// Raw HTTP calls to `/players`, `/sports`, and `/countries`. Returns
/// decoded JSON (not domain entities) and throws [AppException] on any
/// non-2xx response — mapping to domain types is the repository's job.
class PlayerRemoteDataSource {
  PlayerRemoteDataSource(this._client);

  final ApiClient _client;

  Map<String, String> _bearer(String accessToken) => {
    'Authorization': 'Bearer $accessToken',
  };

  Future<Map<String, dynamic>> getMyProfile(String accessToken) async {
    final response = await _client.get('/players/me', headers: _bearer(accessToken));
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateMyProfile(
    String accessToken,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.patch(
      '/players/me',
      headers: _bearer(accessToken),
      body: body,
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateVisibility(
    String accessToken,
    String visibility,
  ) async {
    final response = await _client.patch(
      '/players/me/visibility',
      headers: _bearer(accessToken),
      body: {'visibility': visibility},
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadMedia(
    String accessToken, {
    required List<int> bytes,
    required String filename,
    required String type,
    required bool isProfilePhoto,
  }) async {
    final response = await _client.postMultipart(
      '/players/me/media',
      headers: _bearer(accessToken),
      fileField: 'file',
      fileBytes: bytes,
      filename: filename,
      fields: {'type': type, 'isProfilePhoto': isProfilePhoto.toString()},
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw apiExceptionFromResponse(response);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deleteMedia(String accessToken, String mediaId) async {
    final response = await _client.delete(
      '/players/me/media/$mediaId',
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addAchievement(
    String accessToken,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post(
      '/players/me/achievements',
      headers: _bearer(accessToken),
      body: body,
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw apiExceptionFromResponse(response);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateAchievement(
    String accessToken,
    String id,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.patch(
      '/players/me/achievements/$id',
      headers: _bearer(accessToken),
      body: body,
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deleteAchievement(String accessToken, String id) async {
    final response = await _client.delete(
      '/players/me/achievements/$id',
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addSocialLink(
    String accessToken,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post(
      '/players/me/social-links',
      headers: _bearer(accessToken),
      body: body,
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw apiExceptionFromResponse(response);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateSocialLink(
    String accessToken,
    String id,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.patch(
      '/players/me/social-links/$id',
      headers: _bearer(accessToken),
      body: body,
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deleteSocialLink(String accessToken, String id) async {
    final response = await _client.delete(
      '/players/me/social-links/$id',
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getPublicProfile(String id) async {
    final response = await _client.get('/players/$id');
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Simple Contact (Phase 3) — CLUB-only, returns phone/email/WhatsApp.
  Future<Map<String, dynamic>> getContact(String accessToken, String id) async {
    final response = await _client.get(
      '/players/$id/contact',
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> getSports() async {
    final response = await _client.get('/sports');
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as List<dynamic>;
  }

  Future<List<dynamic>> getCountries() async {
    final response = await _client.get('/countries');
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as List<dynamic>;
  }
}

final playerRemoteDataSourceProvider = Provider<PlayerRemoteDataSource>(
  (ref) => PlayerRemoteDataSource(ref.watch(apiClientProvider)),
);
