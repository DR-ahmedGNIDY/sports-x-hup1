import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/invitations_repository_impl.dart';
import '../domain/entities/invitation.dart';
import '../domain/entities/invitations_page.dart';
import '../domain/entities/invitations_summary.dart';
import '../domain/repositories/invitations_repository.dart';

/// Which list a controller instance owns. The two inboxes are the same
/// screen with the same shape, so they are one controller keyed by this
/// rather than two near-identical classes — but they are separate
/// *instances*, so each keeps its own page and status filter.
enum InvitationsListKind {
  received,
  sent;

  InvitationsListKind get other =>
      this == received ? sent : received;
}

/// One inbox — page + status filter + the resulting page of invitations.
/// Mirrors `ClubPlayersController`: applying a filter resets to page 1,
/// [loadPage] keeps the current filter, and every read is one server round
/// trip (nothing is filtered client-side).
class InvitationsListController
    extends FamilyAsyncNotifier<InvitationsPage, InvitationsListKind> {
  int _page = 1;
  InvitationStatus? _status;

  InvitationStatus? get statusFilter => _status;

  @override
  Future<InvitationsPage> build(InvitationsListKind arg) => _fetch();

  Future<InvitationsPage> _fetch() {
    final repository = ref.read(invitationsRepositoryProvider);
    return switch (arg) {
      InvitationsListKind.received =>
        repository.listReceived(page: _page, status: _status),
      InvitationsListKind.sent =>
        repository.listSent(page: _page, status: _status),
    };
  }

  Future<void> applyStatus(InvitationStatus? status) async {
    _status = status;
    _page = 1;
    await _reload();
  }

  Future<void> loadPage(int page) async {
    _page = page;
    await _reload();
  }

  Future<void> refresh() => _reload();

  Future<void> _reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  /// Accept, reject or cancel. Each answers with the invitation's new
  /// server-side state, which is written straight back into the loaded
  /// page — the row stays where it is, now showing its terminal status,
  /// instead of vanishing mid-tap because a filter no longer matches it.
  ///
  /// The *other* list and the summary are invalidated rather than patched:
  /// accepting a request creates a membership and cancels every other
  /// pending invitation naming that player, so what the opposite tab holds
  /// can no longer be trusted. This list is patched instead of invalidated
  /// because invalidating disposes the notifier, which would silently reset
  /// the page and status filter the user is looking at.
  ///
  /// Invalidating the opposite inbox fetches it even when nobody has opened
  /// it yet — one paginated request per transition, accepted deliberately.
  /// The alternative is a "stale" flag the screen checks on tab switch,
  /// which is more moving parts guarding against a cost this size.
  Future<Invitation> accept(String id) =>
      _transition((repository) => repository.accept(id));

  Future<Invitation> reject(String id) =>
      _transition((repository) => repository.reject(id));

  Future<Invitation> cancel(String id) =>
      _transition((repository) => repository.cancel(id));

  Future<Invitation> _transition(
    Future<Invitation> Function(InvitationsRepository repository) call,
  ) async {
    final updated = await call(ref.read(invitationsRepositoryProvider));
    _patch(updated);
    ref.invalidate(invitationsListProvider(arg.other));
    ref.invalidate(invitationsSummaryProvider);
    return updated;
  }

  void _patch(Invitation updated) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      InvitationsPage(
        items: [
          for (final item in current.items)
            if (item.id == updated.id) updated else item,
        ],
        page: current.page,
        pageSize: current.pageSize,
        total: current.total,
      ),
    );
  }
}

final invitationsListProvider =
    AsyncNotifierProvider.family<
      InvitationsListController,
      InvitationsPage,
      InvitationsListKind
    >(InvitationsListController.new);

/// The two pending counts, for tab badges. Cheap enough to keep separate
/// from either list — a badge has to be right regardless of which page or
/// status filter the lists happen to have loaded.
final invitationsSummaryProvider = FutureProvider<InvitationsSummary>(
  (ref) => ref.read(invitationsRepositoryProvider).getSummary(),
);

/// Sending, reachable from screens that have no invitation list mounted —
/// a player's public profile, or the invite-by-code sheet.
///
/// Deliberately not a method on [InvitationsListController]: reading an
/// `AsyncNotifier`'s `.notifier` runs its `build()` first, so routing a
/// send through the list controller would fetch an inbox page the caller
/// doesn't need. Same split, and for the same reason, as
/// `ClubPlayersActions` in the Club Players feature.
class InvitationsActions {
  InvitationsActions(this._ref);

  final Ref _ref;

  Future<Invitation> invitePlayer({
    String? playerId,
    String? playerCode,
    String? message,
  }) async {
    final invitation = await _ref
        .read(invitationsRepositoryProvider)
        .invitePlayer(
          playerId: playerId,
          playerCode: playerCode,
          message: message,
        );
    _invalidateLists();
    return invitation;
  }

  Future<Invitation> requestToJoinClub({
    String? clubId,
    String? clubCode,
    String? message,
  }) async {
    final invitation = await _ref
        .read(invitationsRepositoryProvider)
        .requestToJoinClub(
          clubId: clubId,
          clubCode: clubCode,
          message: message,
        );
    _invalidateLists();
    return invitation;
  }

  void _invalidateLists() {
    _ref.invalidate(invitationsListProvider);
    _ref.invalidate(invitationsSummaryProvider);
  }
}

final invitationsActionsProvider = Provider<InvitationsActions>(
  (ref) => InvitationsActions(ref),
);
