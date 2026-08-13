import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/env.dart';
import '../errors/app_exception.dart';

/// Extension → MIME type, matching the backend's `ALLOWED_IMAGE_MIME_TYPES`
/// / `ALLOWED_VIDEO_MIME_TYPES` (`upload.config.ts`). `http.MultipartFile`
/// doesn't infer a content type from the filename on its own — omitting it
/// defaults to `application/octet-stream`, which Multer's file filter then
/// rejects outright regardless of what the file actually is.
const Map<String, String> _extensionMimeTypes = {
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'webp': 'image/webp',
  'gif': 'image/gif',
  'mp4': 'video/mp4',
  'mov': 'video/quicktime',
  'webm': 'video/webm',
};

MediaType? _mediaTypeForFilename(String filename) {
  final dot = filename.lastIndexOf('.');
  if (dot == -1 || dot == filename.length - 1) return null;
  final extension = filename.substring(dot + 1).toLowerCase();
  final mimeType = _extensionMimeTypes[extension];
  if (mimeType == null) return null;
  return MediaType.parse(mimeType);
}

/// Transport-level timeout for a regular JSON request.
const Duration _defaultTimeout = Duration(seconds: 30);

/// Multipart uploads (video especially) need a much longer budget than a
/// JSON request — a large file over a slow connection can legitimately
/// take minutes to finish streaming.
const Duration _uploadTimeout = Duration(minutes: 3);

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
      http.MultipartFile.fromBytes(
        fileField,
        fileBytes,
        filename: filename,
        contentType: _mediaTypeForFilename(filename),
      ),
    );
    final streamed = await _client.send(request);
    return http.Response.fromStream(streamed);
  }, timeout: _uploadTimeout);

  Future<http.Response> _send(
    Future<http.Response> Function() request, {
    Duration timeout = _defaultTimeout,
  }) async {
    try {
      return await request().timeout(timeout);
    } on http.ClientException {
      // Cross-platform (Web's BrowserClient throws this too, unlike
      // dart:io's SocketException, which isn't available on Web at all).
      throw const AppException('Could not reach the server. Check your connection.');
    } on TimeoutException {
      throw const AppException('The server took too long to respond.');
    }
  }
}
