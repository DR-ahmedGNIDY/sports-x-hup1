import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/authorized_request.dart';
import '../../../../core/storage/session_storage.dart';
import '../../../../core/storage/session_storage_provider.dart';
import '../../../videos/data/models/video_comment_model.dart';
import '../../../videos/data/models/video_model.dart' show VideoLikeResultModel;
import '../../../videos/domain/entities/video.dart' show VideoLikeResult;
import '../../../videos/domain/entities/video_comment.dart';
import '../../../videos/domain/entities/video_comments_page.dart';
import '../../domain/entities/feed_item.dart';
import '../../domain/entities/feed_page.dart';
import '../../domain/repositories/feed_repository.dart';
import '../datasources/feed_remote_data_source.dart';
import '../models/feed_item_model.dart';

class FeedRepositoryImpl implements FeedRepository {
  FeedRepositoryImpl(this._remote, this._storage, this._ref);

  final FeedRemoteDataSource _remote;
  final SessionStorage _storage;
  final Ref _ref;

  Future<T> _authorized<T>(Future<T> Function(String accessToken) call) =>
      runAuthorized(_ref, _storage, call);

  @override
  Future<FeedPage> getFeed({required String sport, int page = 1}) =>
      _authorized((token) async {
        final json = await _remote.getFeed(token, sport: sport, page: page);
        return FeedPageModel.fromJson(json);
      });

  @override
  Future<FeedItem> createPost({
    required List<int> bytes,
    required String filename,
    String? caption,
    String? sport,
  }) => _authorized((token) async {
    final json = await _remote.createPost(
      token,
      bytes: bytes,
      filename: filename,
      caption: caption,
      sport: sport,
    );
    return FeedItemModel.fromJson(json);
  });

  @override
  Future<VideoLikeResult> like(FeedItemKind kind, String id) => _authorized((token) async {
    final json = await _remote.like(token, kind, id);
    return VideoLikeResultModel.fromJson(json);
  });

  @override
  Future<VideoLikeResult> unlike(FeedItemKind kind, String id) => _authorized((token) async {
    final json = await _remote.unlike(token, kind, id);
    return VideoLikeResultModel.fromJson(json);
  });

  @override
  Future<VideoCommentsPage> listComments(FeedItemKind kind, String id, {int page = 1}) =>
      _authorized((token) async {
        final json = await _remote.listComments(token, kind, id, page: page);
        return VideoCommentsPageModel.fromJson(json);
      });

  @override
  Future<VideoComment> addComment(FeedItemKind kind, String id, String text) =>
      _authorized((token) async {
        final json = await _remote.addComment(token, kind, id, text);
        return VideoCommentModel.fromJson(json);
      });

  @override
  Future<void> deleteComment(FeedItemKind kind, String id, String commentId) =>
      _authorized((token) => _remote.deleteComment(token, kind, id, commentId));
}

final feedRepositoryProvider = Provider<FeedRepository>(
  (ref) => FeedRepositoryImpl(
    ref.watch(feedRemoteDataSourceProvider),
    ref.watch(sessionStorageProvider),
    ref,
  ),
);
