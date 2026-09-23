/// The counts behind the admin dashboard's overview cards.
///
/// Accounts and profiles are counted separately on purpose: an account
/// exists from the moment someone signs up, while its player/club profile
/// only exists once they fill something in — so [players] (accounts) is
/// normally >= [playerProfiles].
class AdminStats {
  const AdminStats({
    required this.totalUsers,
    required this.players,
    required this.clubs,
    required this.coaches,
    required this.admins,
    required this.suspended,
    required this.moderators,
    required this.playerProfiles,
    required this.clubProfiles,
    required this.verifiedClubs,
    required this.posts,
    required this.hiddenPosts,
  });

  final int totalUsers;
  final int players;
  final int clubs;
  final int coaches;
  final int admins;
  final int suspended;
  final int moderators;
  final int playerProfiles;
  final int clubProfiles;
  final int verifiedClubs;
  final int posts;
  final int hiddenPosts;
}
