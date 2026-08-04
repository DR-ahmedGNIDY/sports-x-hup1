import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/providers/health_check_provider.dart' show apiClientProvider;

class ClubRemoteDataSource {
  ClubRemoteDataSource(this._client);

  final ApiClient _client;

  Map<String, String> _bearer(String accessToken) => {
    'Authorization': 'Bearer $accessToken',
  };

  Future<Map<String, dynamic>> getMyProfile(String accessToken) async {
    final response = await _client.get('/clubs/me', headers: _bearer(accessToken));
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateMyProfile(
    String accessToken,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.patch(
      '/clubs/me',
      headers: _bearer(accessToken),
      body: body,
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadLogo(
    String accessToken, {
    required List<int> bytes,
    required String filename,
  }) async {
    final response = await _client.postMultipart(
      '/clubs/me/logo',
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

}

final clubRemoteDataSourceProvider = Provider<ClubRemoteDataSource>(
  (ref) => ClubRemoteDataSource(ref.watch(apiClientProvider)),
);
