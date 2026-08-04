import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/admin_repository_impl.dart';
import '../domain/entities/admin_club_summary.dart';

class AdminClubsController extends AsyncNotifier<List<AdminClubSummary>> {
  @override
  Future<List<AdminClubSummary>> build() {
    return ref.read(adminRepositoryProvider).getClubs();
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
