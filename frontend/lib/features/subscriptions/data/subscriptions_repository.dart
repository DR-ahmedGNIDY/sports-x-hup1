import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/authorized_request.dart';
import '../../../core/providers/health_check_provider.dart'
    show apiClientProvider;
import '../../../core/storage/session_storage.dart';
import '../../../core/storage/session_storage_provider.dart';
import '../domain/subscription.dart';

/// `/club-subscriptions` (the club account) and `/my-subscription` (the
/// player). Small enough that the data source and repository are one class.
class SubscriptionsRepository {
  SubscriptionsRepository(this._client, this._storage, this._ref);

  final ApiClient _client;
  final SessionStorage _storage;
  final Ref _ref;

  Future<T> _authorized<T>(
    Future<T> Function(Map<String, String> headers) call,
  ) => runAuthorized(
    _ref,
    _storage,
    (token) => call({'Authorization': 'Bearer $token'}),
  );

  Object? _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw apiExceptionFromResponse(response);
    }
    return response.body.isEmpty ? null : jsonDecode(response.body);
  }

  Future<ClubSubscriptionsOverview> overview({SubscriptionStatus? status}) =>
      _authorized((headers) async {
        final query = status == null ? '' : '?status=${status.wireValue}';
        final json = _decode(
          await _client.get('/club-subscriptions$query', headers: headers),
        );
        return ClubSubscriptionsOverview.fromJson(json! as Map<String, dynamic>);
      });

  Future<PlayerSubscriptionDetail> player(String playerUserId) =>
      _authorized((headers) async {
        final json = _decode(
          await _client.get(
            '/club-subscriptions/players/$playerUserId',
            headers: headers,
          ),
        );
        return PlayerSubscriptionDetail.fromJson(
          json! as Map<String, dynamic>,
        );
      });

  Future<void> create(Map<String, dynamic> body) =>
      _authorized((headers) async {
        _decode(
          await _client.post(
            '/club-subscriptions',
            body: body,
            headers: headers,
          ),
        );
      });

  Future<void> update(String id, Map<String, dynamic> body) =>
      _authorized((headers) async {
        _decode(
          await _client.patch(
            '/club-subscriptions/$id',
            body: body,
            headers: headers,
          ),
        );
      });

  Future<void> renew(String id) => _authorized((headers) async {
    _decode(
      await _client.post('/club-subscriptions/$id/renew', headers: headers),
    );
  });

  Future<void> delete(String id) => _authorized((headers) async {
    _decode(await _client.delete('/club-subscriptions/$id', headers: headers));
  });

  Future<void> remind(String playerUserId) => _authorized((headers) async {
    _decode(
      await _client.post(
        '/club-subscriptions/players/$playerUserId/remind',
        headers: headers,
      ),
    );
  });

  Future<MySubscription> mine() => _authorized((headers) async {
    final json = _decode(
      await _client.get('/my-subscription', headers: headers),
    );
    return MySubscription.fromJson(json! as Map<String, dynamic>);
  });
}

final subscriptionsRepositoryProvider = Provider<SubscriptionsRepository>(
  (ref) => SubscriptionsRepository(
    ref.watch(apiClientProvider),
    ref.watch(sessionStorageProvider),
    ref,
  ),
);
