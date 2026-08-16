import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../player/domain/entities/contact_details.dart';
import '../../player/domain/entities/player_enums.dart';
import '../data/repositories/club_players_repository_impl.dart';
import '../domain/entities/club_managed_player.dart';
import '../domain/entities/club_player_credentials.dart';
import '../domain/entities/create_club_player_input.dart';

/// Owns the club's roster of directly-created player accounts. One round
/// trip on load, then local list edits on create/update/remove — mirrors
/// SavedPlayersController's approach.
class ClubPlayersController extends AsyncNotifier<List<ClubManagedPlayer>> {
  @override
  Future<List<ClubManagedPlayer>> build() {
    return ref.read(clubPlayersRepositoryProvider).listPlayers();
  }

  /// Creates the player account and returns its one-time credentials —
  /// callers show these immediately (e.g. a "Send to WhatsApp" dialog)
  /// since the plaintext password can never be fetched again afterwards.
  Future<ClubPlayerCredentials> addPlayer(CreateClubPlayerInput input) async {
    final result = await ref.read(clubPlayersRepositoryProvider).createPlayer(input);
    final current = state.value ?? const [];
    state = AsyncData([result.player, ...current]);
    return result.credentials;
  }

  /// Same field set as [CreateClubPlayerInput] minus phone/email/country
  /// (identity fields fixed at creation) — see
  /// `ClubPlayersRepository.updatePlayer`. Patches the matching roster row
  /// in place, same pattern [addPlayer] uses, and invalidates the single-
  /// player provider so a concurrently-open View/Edit page for the same
  /// player refetches instead of showing stale data.
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
    final current = state.value ?? const [];
    state = AsyncData([
      for (final p in current) if (p.userId == userId) updated else p,
    ]);
    ref.invalidate(clubManagedPlayerProvider(userId));
  }

  /// Uploads a new profile photo for a managed player — same list-patch +
  /// single-player-provider-invalidate pattern as [updatePlayer].
  Future<void> uploadPhoto(
    String userId, {
    required List<int> bytes,
    required String filename,
  }) async {
    final updated = await ref
        .read(clubPlayersRepositoryProvider)
        .uploadPhoto(userId, bytes: bytes, filename: filename);
    final current = state.value ?? const [];
    state = AsyncData([
      for (final p in current) if (p.userId == userId) updated else p,
    ]);
    ref.invalidate(clubManagedPlayerProvider(userId));
  }

  /// Removes the club's ownership of [userId] only — the player's own
  /// account/profile is untouched. See
  /// `ClubPlayersRepository.removePlayer`.
  Future<void> removePlayer(String userId) async {
    await ref.read(clubPlayersRepositoryProvider).removePlayer(userId);
    final current = state.value ?? const [];
    state = AsyncData([
      for (final p in current) if (p.userId != userId) p,
    ]);
  }

  Future<ClubPlayerCredentials> resendCredentials(String userId) =>
      ref.read(clubPlayersRepositoryProvider).resendCredentials(userId);

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(clubPlayersRepositoryProvider).listPlayers(),
    );
  }
}

final clubPlayersControllerProvider =
    AsyncNotifierProvider<ClubPlayersController, List<ClubManagedPlayer>>(
      ClubPlayersController.new,
    );

/// A single managed player, fetched fresh by id — used by the View/Edit
/// Managed Player pages so opening one doesn't depend on it already being
/// in [clubPlayersControllerProvider]'s loaded list (and stays correct if
/// that list is stale/loading).
final clubManagedPlayerProvider =
    FutureProvider.family<ClubManagedPlayer, String>((ref, userId) {
      return ref.read(clubPlayersRepositoryProvider).getPlayer(userId);
    });
