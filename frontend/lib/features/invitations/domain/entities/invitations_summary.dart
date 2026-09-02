/// `GET /invitations/summary` — the two pending counts, cheap enough to
/// fetch for a badge without loading either list.
///
/// Both counts already exclude lapsed invitations: the backend counts only
/// rows that are `PENDING` *and* still inside their expiry window, so a
/// badge can never advertise something the recipient can no longer act on.
class InvitationsSummary {
  const InvitationsSummary({
    required this.pendingReceived,
    required this.pendingSent,
  });

  final int pendingReceived;
  final int pendingSent;

  static const empty = InvitationsSummary(pendingReceived: 0, pendingSent: 0);
}
