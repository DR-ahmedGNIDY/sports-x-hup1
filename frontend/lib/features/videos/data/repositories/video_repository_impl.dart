import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/authorized_request.dart';
import '../../../../core/storage/session_storage.dart';
import '../../../../core/storage/session_storage_provider.dart';
import '../../../community/domain/entities/community_feed_page.dart';
import '../../domain/entities/player_traits.dart';
import '../../domain/entities/skill_category.dart';
import '../../domain/entities/video.dart';
import '../../domain/entities/video_comment.dart';
import '../../domain/entities/video_comments_page.dart';
import '../../domain/repositories/video_repository.dart';
import '../datasources/video_remote_data_source.dart';
import '../models/skill_category_model.dart';
import '../models/video_comment_model.dart';
import '../models/video_model.dart';

class VideoRepositoryImpl implements VideoRepository {
  VideoRepositoryImpl(this._remote, this._storage, this._ref);

  final VideoRemoteDataSource _remote;
  final SessionStorage _storage;
  final Ref _ref;

  Future<T> _authorized<T>(Future<T> Function(String accessToken) call) =>
      runAuthorized(_ref, _storage, call);

  @override
  Future<List<SkillCategory>> getSkillCategories(String sport) async {
    final json = await _remote.getSkillCategories(sport);
    return json.map((e) => SkillCategoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Video> uploadVideo({
    required List<int> bytes,
    required String filename,
    required String category,
    required VideoVisibility visibility,
    String? title,
  }) => _authorized((token) async {
    final json = await _remote.uploadVideo(
      token,
      bytes: bytes,
      filename: filename,
      category: category,
      visibility: visibility.wireValue,
      title: title,
    );
    return VideoModel.fromJson(json);
  });

  @override
  Future<List<Video>> listMine({String? category}) => _authorized((token) async {
    final json = await _remote.listMine(token, category: category);
    return json.map((e) => VideoModel.fromJson(e as Map<String, dynamic>)).toList();
  });

  @override
  Future<List<Video>> listForPlayer(String playerId, {String? category}) async {
    final json = await _remote.listForPlayer(playerId, category: category);
    return json.map((e) => VideoModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<PlayerTraits?> getMyTraits() => _authorized((token) async {
    final json = await _remote.getMyTraits(token);
    return json == null ? null : PlayerTraitsModel.fromJson(json);
  });

  @override
  Future<PlayerTraits?> getPlayerTraits(String playerId) async {
    final json = await _remote.getPlayerTraits(playerId);
    return json == null ? null : PlayerTraitsModel.fromJson(json);
  }

  @override
  Future<Video> updateVisibility(String videoId, VideoVisibility visibility) =>
      _authorized((token) async {
        final json = await _remote.updateVisibility(token, videoId, visibility.wireValue);
        return VideoModel.fromJson(json);
      });

  @override
  Future<Video> updateTitle(String videoId, String? title) =>
      _authorized((token) async {
        final json = await _remote.updateTitle(token, videoId, title);
        return VideoModel.fromJson(json);
      });

  @override
  Future<void> deleteVideo(String videoId) =>
      _authorized((token) => _remote.deleteVideo(token, videoId));

  @override
  Future<CommunityFeedPage> communityFeed({
    required String sport,
    String? category,
    int page = 1,
  }) => _authorized((token) async {
    final json = await _remote.communityFeed(
      token,
      sport: sport,
      category: category,
      page: page,
    );
    final items = (json['items'] as List<dynamic>)
        .map((e) => VideoModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return CommunityFeedPage(
      items: items,
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      total: json['total'] as int,
    );
  });

  @override
  Future<VideoLikeResult> like(String videoId) => _authorized((token) async {
    final json = await _remote.like(token, videoId);
    return VideoLikeResultModel.fromJson(json);
  });

  @override
  Future<VideoLikeResult> unlike(String videoId) => _authorized((token) async {
    final json = await _remote.unlike(token, videoId);
    return VideoLikeResultModel.fromJson(json);
  });

  @override
  Future<VideoCommentsPage> listComments(String videoId, {int page = 1}) =>
      _authorized((token) async {
        final json = await _remote.listComments(token, videoId, page: page);
        return VideoCommentsPageModel.fromJson(json);
      });

  @override
  Future<VideoComment> addComment(String videoId, String text) => _authorized((token) async {
    final json = await _remote.addComment(token, videoId, text);
    return VideoCommentModel.fromJson(json);
  });

  @override
  Future<void> deleteComment(String videoId, String commentId) =>
      _authorized((token) => _remote.deleteComment(token, videoId, commentId));
}

final videoRepositoryProvider = Provider<VideoRepository>(
  (ref) => VideoRepositoryImpl(
    ref.watch(videoRemoteDataSourceProvider),
    ref.watch(sessionStorageProvider),
    ref,
  ),
);
