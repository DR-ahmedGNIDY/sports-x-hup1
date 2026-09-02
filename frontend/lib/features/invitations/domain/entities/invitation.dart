/// The invitation domain, mirroring `toInvitationView` on the backend
/// (`backend/src/invitations/invitations.mapper.ts`). Nothing here is
/// computed client-side that the server also computes: `status` already
/// accounts for expiry, and `direction` already says which side of the
/// conversation the viewer is on, so no screen has to compare ids against
/// its own session to work out what it is looking at.
library;

/// Which way the invitation was sent. A Club only ever *sends*
/// [clubToPlayer] and only ever *receives* [playerToClub]; the reverse
/// holds for a Player. Kept as data rather than inferred from
/// [Invitation.direction] because the two answer different questions —
/// this one is "who recruited whom", which is what the card's wording
/// hangs off.
enum InvitationType {
  clubToPlayer('CLUB_TO_PLAYER'),
  playerToClub('PLAYER_TO_CLUB');

  const InvitationType(this.wireValue);

  final String wireValue;

  static InvitationType fromWire(String value) =>
      InvitationType.values.firstWhere((v) => v.wireValue == value);
}

/// Which side of it *this* viewer is on — the Received/Sent tab split, and
/// which actions the card offers.
enum InvitationDirection {
  received('RECEIVED'),
  sent('SENT');

  const InvitationDirection(this.wireValue);

  final String wireValue;

  static InvitationDirection fromWire(String value) =>
      InvitationDirection.values.firstWhere((v) => v.wireValue == value);
}

/// The full state machine. Only [pending] is live; every other value is
/// terminal, and the server never transitions out of one.
///
/// [expired] never has to be derived here: the backend reports a lapsed
/// `PENDING` row as `EXPIRED` in every view whether or not its maintenance
/// sweep has run, so a client that computed expiry itself could only ever
/// disagree with the server about it.
enum InvitationStatus {
  pending('PENDING'),
  accepted('ACCEPTED'),
  rejected('REJECTED'),
  cancelled('CANCELLED'),
  expired('EXPIRED');

  const InvitationStatus(this.wireValue);

  final String wireValue;

  static InvitationStatus fromWire(String value) =>
      InvitationStatus.values.firstWhere((v) => v.wireValue == value);
}

/// Just enough club identity to render a card. The backend deliberately
/// keeps contact details out of this shape, so there is nothing here to
/// leak.
class InvitationClub {
  const InvitationClub({
    required this.id,
    this.publicCode,
    this.name,
    this.city,
    this.country,
    this.level,
    this.logoUrl,
  });

  final String id;
  final String? publicCode;
  final String? name;
  final String? city;
  final String? country;
  final String? level;
  final String? logoUrl;

  String get location =>
      [city, country].where((v) => v != null && v.isNotEmpty).join(', ');
}

/// The player counterpart of [InvitationClub] — same rule about contact
/// details, which stay behind the club-only `GET /players/:id/contact`.
class InvitationPlayer {
  const InvitationPlayer({
    required this.id,
    this.publicCode,
    this.firstName,
    this.lastName,
    this.sport,
    this.position,
    this.country,
    this.profilePhotoUrl,
  });

  final String id;
  final String? publicCode;
  final String? firstName;
  final String? lastName;
  final String? sport;
  final String? position;
  final String? country;
  final String? profilePhotoUrl;

  String get fullName =>
      [firstName, lastName].where((part) => part != null && part.isNotEmpty).join(' ');
}

class Invitation {
  const Invitation({
    required this.id,
    required this.type,
    required this.status,
    required this.direction,
    required this.canAccept,
    required this.canReject,
    required this.canCancel,
    this.message,
    this.club,
    this.player,
    this.createdAt,
    this.expiresAt,
    this.respondedAt,
  });

  final String id;
  final InvitationType type;
  final InvitationStatus status;
  final InvitationDirection direction;

  /// The sender's optional note, at most 500 characters — the only
  /// free-text field a client ever sets on an invitation.
  final String? message;

  /// Both sides are always present in practice; they are nullable because
  /// the backend's summary builders return `null` for a profile that has
  /// been deleted out from under an invitation, and a card that renders
  /// "unknown" beats one that throws.
  final InvitationClub? club;
  final InvitationPlayer? player;

  /// What the server says it will honour for this viewer in this state.
  /// A convenience for rendering only — every endpoint re-derives the same
  /// rules, so a stale `true` here costs a refused request, never an
  /// unauthorised action.
  final bool canAccept;
  final bool canReject;
  final bool canCancel;

  final DateTime? createdAt;
  final DateTime? expiresAt;
  final DateTime? respondedAt;

  bool get isPending => status == InvitationStatus.pending;
}
