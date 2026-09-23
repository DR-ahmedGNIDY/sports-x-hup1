import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/admin_repository_impl.dart';
import '../domain/entities/admin_club_summary.dart';

class AdminClubsController extends AsyncNotifier<List<AdminClubSummary>> {
  int _page = 1;
  bool hasMore = false;

  @override
  Future<List<AdminClubSummary>> build() async {
    _page = 1;
    final result = await ref.read(adminRepositoryProvider).getClubs(page: _page);
    hasMore = result.hasMore;
    return result.items;
  }

  Future<void> loadMore() async {
    if (!hasMore || state.isLoading) return;
    final nextPage = _page + 1;
    final result = await ref.read(adminRepositoryProvider).getClubs(page: nextPage);
    _page = nextPage;
    hasMore = result.hasMore;
    state = AsyncData([...state.valueOrNull ?? const [], ...result.items]);
  }

  /// Grants or revokes the verification check mark. Updates the row in
  /// place rather than refetching — only one field changed, and a refetch
  /// would collapse any pages already loaded via [loadMore].
  Future<void> setVerified(String clubId, bool verified) async {
    await ref.read(adminRepositoryProvider).setClubVerified(clubId, verified);
    final current = state.valueOrNull ?? const <AdminClubSummary>[];
    state = AsyncData([
      for (final club in current)
        if (club.id == clubId)
          AdminClubSummary(
            id: club.id,
            name: club.name,
            country: club.country,
            city: club.city,
            isVerified: verified,
          )
        else
          club,
    ]);
  }

  Future<void> deleteClub(String clubId) async {
    await ref.read(adminRepositoryProvider).deleteClub(clubId);
    final current = state.valueOrNull ?? const [];
    state = AsyncData(current.where((c) => c.id != clubId).toList());
  }
}

final adminClubsControllerProvider =
    AsyncNotifierProvider<AdminClubsController, List<AdminClubSummary>>(
      AdminClubsController.new,
    );
