import { ClubProfileDocument } from '../clubs/schemas/club-profile.schema';
import { profilePhotoUrl } from '../players/players.mapper';
import { PlayerProfileDocument } from '../players/schemas/player-profile.schema';
import { HydratedInvitation } from './invitations.service';
import {
  ClubPlayerInvitationDocument,
  InvitationStatus,
} from './schemas/club-player-invitation.schema';

// A PENDING invitation past its expiry reads as EXPIRED everywhere, whether
// or not the maintenance sweep has run — the stored status is the sweep's
// business, this is what every client sees. Keeping the two in one function
// means no view can disagree about it.
export function effectiveStatus(
  invitation: ClubPlayerInvitationDocument,
  now: Date = new Date(),
): InvitationStatus {
  if (
    invitation.status === InvitationStatus.PENDING &&
    invitation.expiresAt <= now
  ) {
    return InvitationStatus.EXPIRED;
  }
  return invitation.status;
}

// Just enough to render a card: who it is, what they play, and the code to
// look them up by. Deliberately excludes contact details — those stay behind
// GET /players/:id/contact, which has its own club-only guard.
//
// Exported because the membership views render the same two cards. One
// definition of "what a counterpart card needs" means a field can never be
// safe to show in an invitation and leak in a roster.
export function clubSummary(profile: ClubProfileDocument | null) {
  if (!profile) return null;
  return {
    id: profile._id.toString(),
    publicCode: profile.publicCode,
    name: profile.name,
    city: profile.city,
    country: profile.country,
    level: profile.level,
    logoUrl: profile.logo?.secureUrl,
  };
}

export function playerSummary(profile: PlayerProfileDocument | null) {
  if (!profile) return null;
  return {
    id: profile._id.toString(),
    publicCode: profile.publicCode,
    firstName: profile.firstName,
    lastName: profile.lastName,
    sport: profile.sport,
    position: profile.position,
    country: profile.country,
    profilePhotoUrl: profilePhotoUrl(profile),
  };
}

// `direction` tells the caller which side of this invitation they are on
// without the client having to compare ids to its own session — the tabs and
// the available actions both hang off it.
export function toInvitationView(
  row: HydratedInvitation,
  viewerUserId: string,
) {
  const { invitation } = row;
  const status = effectiveStatus(invitation);
  const isRecipient = invitation.recipientUserId.toString() === viewerUserId;

  return {
    id: invitation._id.toString(),
    type: invitation.type,
    status,
    direction: isRecipient ? 'RECEIVED' : 'SENT',
    message: invitation.message,
    club: clubSummary(row.clubProfile),
    player: playerSummary(row.playerProfile),
    // The only actions the server will actually honour for this viewer in
    // this state. The client uses it to render buttons; the client's copy of
    // it is never trusted — every endpoint re-derives the same rules.
    canAccept: isRecipient && status === InvitationStatus.PENDING,
    canReject: isRecipient && status === InvitationStatus.PENDING,
    canCancel: !isRecipient && status === InvitationStatus.PENDING,
    createdAt: (
      invitation as ClubPlayerInvitationDocument & { createdAt: Date }
    ).createdAt,
    updatedAt: (
      invitation as ClubPlayerInvitationDocument & { updatedAt: Date }
    ).updatedAt,
    expiresAt: invitation.expiresAt,
    respondedAt: invitation.respondedAt,
  };
}
