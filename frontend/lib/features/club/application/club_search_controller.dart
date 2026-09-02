import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/club_repository_impl.dart';
import '../domain/entities/club_list_page.dart';

/// Clubs, searched by name.
///
/// Separate from [PublicClubsController] rather than a search parameter
/// added to it: that one backs the marketing site's "all clubs" page, which
/// has no query and should not acquire one just because another screen
/// needs it. Both read the same endpoint; only this one narrows it.
///
/// An empty term is the whole list, not an empty result — a search screen
/// that shows nothing until you type gives no sense of what is there.
class ClubSearchController extends AsyncNotifier<ClubListPage> {
  String _search = '';
  int _page = 1;

  String get search => _search;

  @override
  Future<ClubListPage> build() => _fetch();

  Future<ClubListPage> _fetch() => ref
      .read(clubRepositoryProvider)
      .listClubs(page: _page, search: _search.isEmpty ? null : _search);

  /// Applying a term always returns to page 1 — the results are paginated,
  /// so searching from page 3 would silently mean "matches on page 3".
  Future<void> applySearch(String value) async {
    _search = value.trim();
    _page = 1;
    await _reload();
  }

  Future<void> loadPage(int page) async {
    _page = page;
    await _reload();
  }

  Future<void> _reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final clubSearchControllerProvider =
    AsyncNotifierProvider<ClubSearchController, ClubListPage>(
      ClubSearchController.new,
    );
