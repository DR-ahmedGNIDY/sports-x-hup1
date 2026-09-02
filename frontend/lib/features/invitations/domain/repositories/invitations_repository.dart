import '../entities/invitation.dart';
import '../entities/invitations_page.dart';
import '../entities/invitations_summary.dart';

/// Throws [AppException] (core/errors) on failure.
///
/// The send methods take the counterpart either by public code (how a user
/// finds someone: "PLY-000123") or by profile id (how a profile page
/// already on screen links to it) — exactly as the backend DTOs accept
/// them, so nothing is translated in between.
abstract class InvitationsRepository {
  Future<Invitation> invitePlayer({
    String? playerId,
    String? playerCode,
    String? message,
  });

  Future<Invitation> requestToJoinClub({
    String? clubId,
    String? clubCode,
    String? message,
  });

  Future<InvitationsPage> listReceived({int page, InvitationStatus? status});

  Future<InvitationsPage> listSent({int page, InvitationStatus? status});

  Future<InvitationsSummary> getSummary();

  Future<Invitation> accept(String id);

  Future<Invitation> reject(String id);

  Future<Invitation> cancel(String id);
}
