import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../errors/app_exception.dart';

/// Thin wrapper around the backend base URL. Feature repositories build on
/// top of this rather than each owning their own base-URL/header/encoding
/// logic. It has no knowledge of auth tokens — callers pass whatever
/// headers a request needs (see AuthRepositoryImpl for the 401-retry logic
/// that layers Bearer auth on top of this).
///
/// Transport-level failures (server unreachable, DNS failure, timeout) are
/// normalized to [AppException] here — the one place every request funnels
/// through — so every caller can catch a single exception type instead of
/// each repository needing its own try/catch for connectivity errors.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri resolve(String path) => Uri.parse('${Env.apiBaseUrl}$path');

  Map<String, String> _jsonHeaders(Map<String, String>? extra) => {
    'Content-Type': 'application/json',
    ...?extra,
  };

  Future<http.Response> get(String path, {Map<String, String>? headers}) =>
      _send(() => _client.get(resolve(path), headers: headers));

  Future<http.Response> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) => _send(
    () => _client.post(
      resolve(path),
      headers: _jsonHeaders(headers),
      body: body == null ? null : jsonEncode(body),
    ),
  );

  Future<http.Response> patch(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) => _send(
    () => _client.patch(
      resolve(path),
      headers: _jsonHeaders(headers),
      body: body == null ? null : jsonEncode(body),
    ),
  );

  Future<http.Response> delete(String path, {Map<String, String>? headers}) =>
      _send(() => _client.delete(resolve(path), headers: headers));

  /// Multipart upload (a single file field plus optional string fields).
  /// Used for Cloudinary media uploads — the only endpoint that isn't JSON.
  Future<http.Response> postMultipart(
    String path, {
    required List<int> fileBytes,
    required String filename,
    required String fileField,
    Map<String, String>? fields,
    Map<String, String>? headers,
  }) => _send(() async {
    final request = http.MultipartRequest('POST', resolve(path));
    if (headers != null) request.headers.addAll(headers);
    if (fields != null) request.fields.addAll(fields);
    request.files.add(
      http.MultipartFile.fromBytes(fileField, fileBytes, filename: filename),
    );
    final streamed = await _client.send(request);
    return http.Response.fromStream(streamed);
  });

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request();
    } on http.ClientException {
      // Cross-platform (Web's BrowserClient throws this too, unlike
      // dart:io's SocketException, which isn't available on Web at all).
      throw const AppException('Could not reach the server. Check your connection.');
    } on TimeoutException {
      throw const AppException('The server took too long to respond.');
    }
  }
}
