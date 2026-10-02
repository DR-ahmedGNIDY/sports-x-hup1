import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/authorized_request.dart';
import '../../../../core/providers/health_check_provider.dart'
    show apiClientProvider;
import '../../../../core/storage/session_storage_provider.dart';
import '../../domain/entities/site_settings.dart';

/// `/admin/site-settings` — the public website's links and contact details.
class AdminSiteSettingsDataSource {
  AdminSiteSettingsDataSource(this._client, this._ref);

  final ApiClient _client;
  final Ref _ref;

  Future<T> _authorized<T>(
    Future<T> Function(Map<String, String> headers) call,
  ) => runAuthorized(
    _ref,
    _ref.read(sessionStorageProvider),
    (token) => call({'Authorization': 'Bearer $token'}),
  );

  Future<SiteSettings> get() => _authorized((headers) async {
    final response = await _client.get(
      '/admin/site-settings',
      headers: headers,
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return SiteSettings.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  });

  Future<SiteSettings> save(SiteSettings settings) => _authorized((
    headers,
  ) async {
    final response = await _client.patch(
      '/admin/site-settings',
      headers: headers,
      body: settings.toJson(),
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return SiteSettings.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  });
}

final adminSiteSettingsDataSourceProvider =
    Provider<AdminSiteSettingsDataSource>(
      (ref) => AdminSiteSettingsDataSource(ref.watch(apiClientProvider), ref),
    );
