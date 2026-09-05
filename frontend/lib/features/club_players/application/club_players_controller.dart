import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../player/domain/entities/contact_details.dart';
import '../../player/domain/entities/player_enums.dart';
import '../data/repositories/club_players_repository_impl.dart';
import '../domain/entities/club_dashboard_summary.dart';
import '../domain/entities/club_managed_player.dart';
import '../domain/entities/club_player_credentials.dart';
import '../domain/entities/club_players_filters.dart';
import '../domain/entities/club_roster_page.dart';
import '../domain/entities/create_club_player_input.dart';

/// Owns the current search/filter/page state and the resulting roster
/// page — mirrors `PlayerSearchController` (search feature): applying a
/// filter always resets to page 1, [loadPage] keeps the current filters.
/// Every read is one server round trip; nothing here ever holds or
/// filters the club's full roster client-side.
class ClubPlayersController extends AsyncNotifier<ClubRosterPage> {
  ClubPlayersFilters _filters = const ClubPlayersFilters();

  ClubPlayersFilters get filters => _filters;

  @override
  Future<ClubRosterPage> build() {
    return ref.read(clubPlayersRepositoryProvider).listPlayers(_filters);
  }

  Future<void> applyFilters({
    String? search,
    String? sport,
    String? position,
    int? birthYear,
  }) async {
    _filters = ClubPlayersFilters.cleared(
      search: search,
      sport: sport,
      position: position,
      birthYear: birthYear,
    );
    await _reload();
  }

  Future<void> loadPage(int page) async {
    _filters = _filters.copyWith(page: page);
    await _reload();
  }

  Future<void> refresh() => _reload();

  Future<void> _reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(clubPlayersRepositoryProvider).listPlayers(_filters),
    );
  }

  void _invalidateSummary() => ref.invalidate(clubDashboardSummaryProvider);

  /// Creates the player account and returns its one-time credentials —
  /// callers show these immediately (e.g. a "Send to WhatsApp" dialog)
  /// since the plaintext password can never be fetched again afterwards.
  /// Reloads the current page afterwards (simpler and always correct
  /// under pagination/filters than trying to splice the new player into
  /// wherever it'd sort within the current page).
  Future<ClubPlayerCredentials> addPlayer(CreateClubPlayerInput input) async {
    final result = await ref.read(clubPlayersRepositoryProvider).createPlayer(input);
    await _reload();
    _invalidateSummary();
    return result.credentials;
  }

  /// Same field set as [CreateClubPlayerInput] minus phone/email/country
  /// (identity fields fixed at creation) — see
  /// `ClubPlayersRepository.updatePlayer`. Patches the matching roster row
  /// in place if it's on the currently-loaded page, and invalidates the
  /// single-player provider + Dashboard summary so a concurrently-open
  /// View/Edit page or the Dashboard refetch instead of showing stale data.
  Future<void> updatePlayer(
    String userId, {
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? nationality,
    String? country,
    String? city,
    String? sport,
    String? position,
    PreferredFoot? preferredFoot,
    num? height,
    num? weight,
    String? currentStatus,
    String? currentClub,
    String? bio,
    ContactDetails? contact,
  }) async {
    final updated = await ref
        .read(clubPlayersRepositoryProvider)
        .updatePlayer(
          userId,
          firstName: firstName,
          lastName: lastName,
          dateOfBirth: dateOfBirth,
          nationality: nationality,
          country: country,
          city: city,
          sport: sport,
          position: position,
          preferredFoot: preferredFoot,
          height: height,
          weight: weight,
          currentStatus: currentStatus,
          currentClub: currentClub,
          bio: bio,
          contact: contact,
        );
    _patchIfLoaded(userId, updated);
    ref.invalidate(clubManagedPlayerProvider(userId));
    _invalidateSummary();
  }

  /// Uploads a new profile photo for a managed player — same patch-in-
  /// place + invalidate pattern as [updatePlayer].
  Future<void> uploadPhoto(
    String userId, {
    required List<int> bytes,
    required String filename,
  }) async {
    final updated = await ref
        .read(clubPlayersRepositoryProvider)
        .uploadPhoto(userId, bytes: bytes, filename: filename);
    _patchIfLoaded(userId, updated);
    ref.invalidate(clubManagedPlayerProvider(userId));
    _invalidateSummary();
  }

  void _patchIfLoaded(String userId, ClubManagedPlayer updated) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      ClubRosterPage(
        items: [for (final p in current.items) if (p.userId == userId) updated else p],
        page: current.page,
        pageSize: current.pageSize,
        total: current.total,
      ),
    );
  }

  /// Removes the club's ownership of [userId] only — the player's own
  /// account/profile is untouched. See
  /// `ClubPlayersRepository.removePlayer`. Reloads the current page
  /// afterwards — removal can shift page boundaries/totals, so patching
  /// the list in place isn't safe the way a same-row update is.
  Future<void> removePlayer(String userId) async {
    await ref.read(clubPlayersRepositoryProvider).removePlayer(userId);
    await _reload();
    _invalidateSummary();
  }

  Future<ClubPlayerCredentials> resendCredentials(String userId) =>
      ref.read(clubPlayersRepositoryProvider).resendCredentials(userId);
}

final clubPlayersControllerProvider =
    AsyncNotifierProvider<ClubPlayersController, ClubRosterPage>(
      ClubPlayersController.new,
    );

/// A single managed player, fetched fresh by id — used by the View/Edit
/// Managed Player pages so opening one doesn't depend on it already being
/// on the roster controller's currently-loaded page.
final clubManagedPlayerProvider =
    FutureProvider.family<ClubManagedPlayer, String>((ref, userId) {
      return ref.read(clubPlayersRepositoryProvider).getPlayer(userId);
    });

/// The Club Dashboard's roster summary — see [ClubDashboardSummary]. A
/// separate provider from [clubPlayersControllerProvider] on purpose: the
/// Dashboard needs a whole-roster summary regardless of whatever page/
/// filters the roster screen currently has loaded (and vice versa).
final clubDashboardSummaryProvider = FutureProvider<ClubDashboardSummary>((ref) {
  return ref.read(clubPlayersRepositoryProvider).getSummary();
});

/// Create/edit/remove for a single managed player, reachable directly by
/// route (Add Player, Edit Player) without the roster list necessarily
/// being mounted anywhere. Deliberately *not* methods on
/// [ClubPlayersController]: reading an [AsyncNotifier]'s `.notifier` — the
/// only way to call a method on it — always runs its `build()` first, so
/// routing these through the paginated list controller would fetch a
/// roster page neither screen needs just to create/edit/remove one
/// player. Invalidates the roster list + Dashboard summary afterwards so
/// both are correct next time either is actually viewed.
///
/// The roster card (already inside the list, so the controller is already
/// built) still calls [ClubPlayersController]'s own methods directly —
/// those patch/reload in place and preserve the current page/filters,
/// which a blind invalidate here can't (it disposes the notifier, so its
/// in-memory `_filters` resets). Two call paths for the same backend
/// endpoints, kept apart on purpose: one that's already paying for a live
/// controller and can update it precisely, one that isn't and shouldn't
/// have to.
class ClubPlayersActions {
  ClubPlayersActions(this._ref);

  final Ref _ref;

  void _invalidateLists() {
    _ref.invalidate(clubPlayersControllerProvider);
    _ref.invalidate(clubDashboardSummaryProvider);
  }

  Future<ClubPlayerCredentials> addPlayer(CreateClubPlayerInput input) async {
    final result = await _ref.read(clubPlayersRepositoryProvider).createPlayer(input);
    _invalidateLists();
    return result.credentials;
  }

  Future<ClubManagedPlayer> updatePlayer(
    String userId, {
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? nationality,
    String? country,
    String? city,
    String? sport,
    String? position,
    PreferredFoot? preferredFoot,
    num? height,
    num? weight,
    String? currentStatus,
    String? currentClub,
    String? bio,
    ContactDetails? contact,
  }) async {
    final updated = await _ref
        .read(clubPlayersRepositoryProvider)
        .updatePlayer(
          userId,
          firstName: firstName,
          lastName: lastName,
          dateOfBirth: dateOfBirth,
          nationality: nationality,
          country: country,
          city: city,
          sport: sport,
          position: position,
          preferredFoot: preferredFoot,
          height: height,
          weight: weight,
          currentStatus: currentStatus,
          currentClub: currentClub,
          bio: bio,
          contact: contact,
        );
    _ref.invalidate(clubManagedPlayerProvider(userId));
    _invalidateLists();
    return updated;
  }

  Future<ClubManagedPlayer> uploadPhoto(
    String userId, {
    required List<int> bytes,
    required String filename,
  }) async {
    final updated = await _ref
        .read(clubPlayersRepositoryProvider)
        .uploadPhoto(userId, bytes: bytes, filename: filename);
    _ref.invalidate(clubManagedPlayerProvider(userId));
    _invalidateLists();
    return updated;
  }
}

final clubPlayersActionsProvider = Provider<ClubPlayersActions>(
  (ref) => ClubPlayersActions(ref),
);
