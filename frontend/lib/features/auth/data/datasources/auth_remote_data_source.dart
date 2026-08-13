import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/providers/health_check_provider.dart' show apiClientProvider;

/// Raw HTTP calls to the `/auth` and `/users/me` endpoints. Returns decoded
/// JSON maps (not domain entities) and throws [AppException] on any
/// non-2xx response — mapping to domain types is the repository's job.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String role,
  }) => _postForTokens('/auth/register', {
    'email': email,
    'password': password,
    'role': role,
  });

  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) => _postForTokens('/auth/login', {
    'identifier': identifier,
    'password': password,
  });

  Future<Map<String, dynamic>> refresh(String refreshToken) =>
      _postForTokens('/auth/refresh', {'refreshToken': refreshToken});

  Future<void> logout(String refreshToken) async {
    await _client.post('/auth/logout', body: {'refreshToken': refreshToken});
    // Best-effort: whether or not the server-side revoke succeeds, the
    // caller always clears local storage — see AuthRepositoryImpl.logout.
  }

  Future<void> forgotPassword(String email) async {
    final response = await _client.post(
      '/auth/forgot-password',
      body: {'email': email},
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final response = await _client.post(
      '/auth/reset-password',
      body: {'token': token, 'newPassword': newPassword},
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
  }

  Future<Map<String, dynamic>> getCurrentUser(String accessToken) async {
    final response = await _client.get(
      '/users/me',
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateCurrentUser(
    String accessToken, {
    String? email,
    String? currentPassword,
    String? newPassword,
  }) async {
    final response = await _client.patch(
      '/users/me',
      headers: _bearer(accessToken),
      body: {
        'email': ?email,
        'currentPassword': ?currentPassword,
        'newPassword': ?newPassword,
      },
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Map<String, String> _bearer(String accessToken) => {
    'Authorization': 'Bearer $accessToken',
  };

  Future<Map<String, dynamic>> _postForTokens(
    String path,
    Object body,
  ) async {
    final response = await _client.post(path, body: body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw apiExceptionFromResponse(response);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(ref.watch(apiClientProvider)),
);
