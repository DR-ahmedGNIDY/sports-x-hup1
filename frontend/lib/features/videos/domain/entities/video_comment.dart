class VideoComment {
  const VideoComment({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.authorDisplayName,
    required this.authorRole,
    required this.isMine,
  });

  final String id;
  final String text;
  final DateTime createdAt;
  final String authorDisplayName;
  final String authorRole;
  final bool isMine;
}
