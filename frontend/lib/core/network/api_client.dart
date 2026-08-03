import 'package:http/http.dart' as http;

import '../config/env.dart';

/// Thin wrapper around the backend base URL. Business-feature repositories
/// (added from Phase 1 onward) build on top of this rather than each owning
/// their own base-URL/header logic.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri resolve(String path) => Uri.parse('${Env.apiBaseUrl}$path');

  Future<http.Response> get(String path) => _client.get(resolve(path));
}
