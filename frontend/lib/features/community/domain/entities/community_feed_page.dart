import '../../../videos/domain/entities/video.dart';

/// A single page of `GET /videos/community` — feed items are [Video]s with
/// [Video.author] populated (community is the only endpoint that returns
/// author info alongside the video itself).
class CommunityFeedPage {
  const CommunityFeedPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  final List<Video> items;
  final int page;
  final int pageSize;
  final int total;

  bool get hasNextPage => page * pageSize < total;
}
