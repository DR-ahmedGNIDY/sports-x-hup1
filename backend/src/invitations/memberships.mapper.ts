import { ClubProfileDocument } from '../clubs/schemas/club-profile.schema';
import { PlayerProfileDocument } from '../players/schemas/player-profile.schema';
import { clubSummary, playerSummary } from './invitations.mapper';
import { ClubMembershipDocument } from './schemas/club-membership.schema';

// Membership views reuse the invitation cards' summaries verbatim — same
// fields, same omissions. Contact details are absent here for the same
// reason they are absent there: they live behind GET /players/:id/contact,
// which has its own club-only guard.

export function toPlayerClubView(
  membership: ClubMembershipDocument,
  clubProfile: ClubProfileDocument | null,
) {
  return {
    id: membership._id.toString(),
    joinedAt: membership.joinedAt,
    club: clubSummary(clubProfile),
  };
}

// The roster row is keyed by the *profile*, not the membership: the page is
// built by querying player profiles (so the total is honest under the
// PUBLIC-only filter), and a membership row without a visible profile never
// reaches this point.
export function toClubMemberView(
  profile: PlayerProfileDocument,
  joinedAt?: Date,
) {
  return {
    ...playerSummary(profile),
    joinedAt,
  };
}
