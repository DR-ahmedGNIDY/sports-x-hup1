import 'club_managed_player.dart';

/// One page of `GET /club-players` — named `ClubRosterPage` (not
/// `ClubPlayersPage`) to avoid colliding with the screen widget of that
/// name in `presentation/club_players_page.dart`.
class ClubRosterPage {
  const ClubRosterPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  final List<ClubManagedPlayer> items;
  final int page;
  final int pageSize;
  final int total;

  bool get hasNextPage => page * pageSize < total;

  static const empty = ClubRosterPage(items: [], page: 1, pageSize: 20, total: 0);
}
