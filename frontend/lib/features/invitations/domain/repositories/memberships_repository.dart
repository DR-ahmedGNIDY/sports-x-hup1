import '../entities/membership.dart';

/// Throws [AppException] (core/errors) on failure.
///
/// Both reads are unauthenticated, matching the public profile pages they
/// render on. There are no writes: a membership is created by accepting an
/// invitation, and nothing in the product yet says who may end one.
abstract class MembershipsRepository {
  /// The club [playerId] currently belongs to, or `null` — having no club
  /// is an ordinary state, not a failure.
  Future<PlayerClubMembership?> findPlayerClub(String playerId);

  Future<ClubMembersPage> listClubMembers(String clubId, {int page});
}
