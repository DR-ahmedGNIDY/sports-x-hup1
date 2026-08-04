import 'club_profile.dart';

class ClubListPage {
  const ClubListPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  final List<ClubProfile> items;
  final int page;
  final int pageSize;
  final int total;

  bool get hasNextPage => page * pageSize < total;
}
