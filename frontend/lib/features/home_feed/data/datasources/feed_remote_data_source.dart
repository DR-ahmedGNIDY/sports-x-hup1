import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/providers/health_check_provider.dart' show apiClientProvider;
import '../../domain/entities/feed_item.dart';

/// Raw HTTP calls to `/feed` and the like/comment endpoints a feed item's
/// [FeedItemKind] resolves to — `/videos/:id/...` for a video, `/posts/:id/
/// ...` for a photo post (the backend keeps these as two collections; only
/// `/feed` itself merges them). Returns decoded JSON, throws
/// [AppException] on any non-2xx response — mapping to domain types is the
/// repository's job.
class FeedRemoteDataSource {
  FeedRemoteDataSource(this._client);

  final ApiClient _client;

  Map<String, String> _bearer(String accessToken) => {
    'Authorization': 'Bearer $accessToken',
  };

  String _basePath(FeedItemKind kind) => kind == FeedItemKind.video ? '/videos' : '/posts';

  Future<Map<String, dynamic>> createPost(
    String accessToken, {
    required List<int> bytes,
    required String filename,
    String? caption,
    String? sport,
  }) async {
    final response = await _client.postMultipart(
      '/posts',
      headers: _bearer(accessToken),
      fileField: 'file',
      fileBytes: bytes,
      filename: filename,
      fields: {
        if (caption != null && caption.isNotEmpty) 'caption': caption,
        if (sport != null && sport.isNotEmpty) 'sport': sport,
      },
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw apiExceptionFromResponse(response);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getFeed(
    String accessToken, {
    required String sport,
    int page = 1,
  }) async {
    final query = Uri(queryParameters: {'sport': sport, 'page': '$page'}).query;
    final response = await _client.get('/feed?$query', headers: _bearer(accessToken));
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> like(
    String accessToken,
    FeedItemKind kind,
    String id,
  ) async {
    final response = await _client.post(
      '${_basePath(kind)}/$id/like',
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw apiExceptionFromResponse(response);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> unlike(
    String accessToken,
    FeedItemKind kind,
    String id,
  ) async {
    final response = await _client.delete(
      '${_basePath(kind)}/$id/like',
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> listComments(
    String accessToken,
    FeedItemKind kind,
    String id, {
    int page = 1,
  }) async {
    final response = await _client.get(
      '${_basePath(kind)}/$id/comments?page=$page',
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addComment(
    String accessToken,
    FeedItemKind kind,
    String id,
    String text,
  ) async {
    final response = await _client.post(
      '${_basePath(kind)}/$id/comments',
      headers: _bearer(accessToken),
      body: {'text': text},
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw apiExceptionFromResponse(response);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> deleteComment(
    String accessToken,
    FeedItemKind kind,
    String id,
    String commentId,
  ) async {
    final response = await _client.delete(
      '${_basePath(kind)}/$id/comments/$commentId',
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw apiExceptionFromResponse(response);
    }
  }
}

final feedRemoteDataSourceProvider = Provider<FeedRemoteDataSource>(
  (ref) => FeedRemoteDataSource(ref.watch(apiClientProvider)),
);
