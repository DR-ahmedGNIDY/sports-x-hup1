import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/providers/health_check_provider.dart' show apiClientProvider;

class NotificationsRemoteDataSource {
  NotificationsRemoteDataSource(this._client);

  final ApiClient _client;

  Map<String, String> _bearer(String accessToken) => {
    'Authorization': 'Bearer $accessToken',
  };

  Future<Map<String, dynamic>> list(
    String accessToken, {
    required int page,
    required bool unreadOnly,
  }) async {
    final query = {
      'page': '$page',
      if (unreadOnly) 'unreadOnly': 'true',
    };
    final response = await _client.get(
      '/notifications?${Uri(queryParameters: query).query}',
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> summary(String accessToken) async {
    final response = await _client.get(
      '/notifications/summary',
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> markRead(String accessToken, String id) async {
    final response = await _client.post(
      '/notifications/$id/read',
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
  }

  Future<Map<String, dynamic>> markAllRead(String accessToken) async {
    final response = await _client.post(
      '/notifications/read-all',
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// `null` when the server has no VAPID keys — push is optional
  /// infrastructure, and the client must not prompt for something the
  /// backend cannot deliver.
  Future<String?> pushPublicKey(String accessToken) async {
    final response = await _client.get(
      '/notifications/push/public-key',
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['publicKey'] as String?;
  }

  /// [subscription] is the browser's own JSON, passed through untouched:
  /// its shape is the push service's, not ours, and re-modelling it here
  /// would be one more place for the two to disagree.
  Future<void> subscribePush(
    String accessToken,
    Map<String, dynamic> subscription,
  ) async {
    final response = await _client.post(
      '/notifications/push/subscribe',
      body: subscription,
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
  }

  Future<void> unsubscribePush(String accessToken, String endpoint) async {
    final response = await _client.post(
      '/notifications/push/unsubscribe',
      body: {'endpoint': endpoint},
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
  }
}

final notificationsRemoteDataSourceProvider =
    Provider<NotificationsRemoteDataSource>(
      (ref) => NotificationsRemoteDataSource(ref.watch(apiClientProvider)),
    );
