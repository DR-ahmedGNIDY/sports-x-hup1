import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/club_repository_impl.dart';
import '../domain/entities/club_list_page.dart';

/// Public Clubs listing (Phase 5) — mirrors PlayerSearchController's
/// page-tracking pattern, minus filters (club listing has none in V1).
class PublicClubsController extends AsyncNotifier<ClubListPage> {
  @override
  Future<ClubListPage> build() {
    return ref.read(clubRepositoryProvider).listClubs();
  }

  Future<void> loadPage(int page) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(clubRepositoryProvider).listClubs(page: page));
  }
}

final publicClubsControllerProvider =
    AsyncNotifierProvider<PublicClubsController, ClubListPage>(PublicClubsController.new);
