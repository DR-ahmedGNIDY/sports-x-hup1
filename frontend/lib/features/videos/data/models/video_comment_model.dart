import '../../domain/entities/video_comment.dart';
import '../../domain/entities/video_comments_page.dart';

extension VideoCommentModel on VideoComment {
  static VideoComment fromJson(Map<String, dynamic> json) {
    return VideoComment(
      id: json['id'] as String,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      authorDisplayName: json['authorDisplayName'] as String,
      authorRole: json['authorRole'] as String,
      isMine: json['isMine'] as bool? ?? false,
    );
  }
}

extension VideoCommentsPageModel on VideoCommentsPage {
  static VideoCommentsPage fromJson(Map<String, dynamic> json) {
    return VideoCommentsPage(
      items: (json['items'] as List<dynamic>)
          .map((e) => VideoCommentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      total: json['total'] as int,
    );
  }
}
