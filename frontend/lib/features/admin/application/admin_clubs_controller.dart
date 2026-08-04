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
    state = AsyncData([...state.value ?? const [], ...result.items]);
  }

  Future<void> deleteClub(String clubId) async {
    await ref.read(adminRepositoryProvider).deleteClub(clubId);
    final current = state.value ?? const [];
    state = AsyncData(current.where((c) => c.id != clubId).toList());
  }
}

final adminClubsControllerProvider =
    AsyncNotifierProvider<AdminClubsController, List<AdminClubSummary>>(
      AdminClubsController.new,
    );
