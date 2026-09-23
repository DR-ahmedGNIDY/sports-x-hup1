import '../../domain/entities/admin_stats.dart';

extension AdminStatsModel on AdminStats {
  static AdminStats fromJson(Map<String, dynamic> json) {
    int count(String key) => json[key] as int? ?? 0;
    return AdminStats(
      totalUsers: count('totalUsers'),
      players: count('players'),
      clubs: count('clubs'),
      coaches: count('coaches'),
      admins: count('admins'),
      suspended: count('suspended'),
      moderators: count('moderators'),
      playerProfiles: count('playerProfiles'),
      clubProfiles: count('clubProfiles'),
      verifiedClubs: count('verifiedClubs'),
      posts: count('posts'),
      hiddenPosts: count('hiddenPosts'),
    );
  }
}
