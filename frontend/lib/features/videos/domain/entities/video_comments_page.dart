import 'video_comment.dart';

class VideoCommentsPage {
  const VideoCommentsPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  final List<VideoComment> items;
  final int page;
  final int pageSize;
  final int total;

  bool get hasNextPage => page * pageSize < total;
}
