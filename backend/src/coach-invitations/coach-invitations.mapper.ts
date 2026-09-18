import { ClubCoachMembershipDocument } from '../club-access/schemas/club-coach-membership.schema';
import { normalizePermissions } from '../club-access/coach-permission.enum';
import { ClubProfileDocument } from '../clubs/schemas/club-profile.schema';
import { CoachProfileDocument } from '../coaches/schemas/coach-profile.schema';
import { clubSummary } from '../invitations/invitations.mapper';
import { InvitationStatus } from '../invitations/schemas/club-player-invitation.schema';
import { HydratedCoachInvitation } from './coach-invitations.service';
import { ClubCoachInvitationDocument } from './schemas/club-coach-invitation.schema';

// Card-sized, and free of contact details — same rule as playerSummary.
export function coachSummary(profile: CoachProfileDocument | null) {
  if (!profile) return null;
  return {
    id: profile._id.toString(),
    publicCode: profile.publicCode,
    firstName: profile.firstName,
    lastName: profile.lastName,
    headline: profile.headline,
    sport: profile.sport,
    country: profile.country,
    profilePhotoUrl: profile.profilePhoto?.secureUrl,
  };
}

function effectiveStatus(
  invitation: ClubCoachInvitationDocument,
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

export function toCoachInvitationView(
  row: HydratedCoachInvitation,
  viewerUserId: string,
) {
  const { invitation } = row;
  const status = effectiveStatus(invitation);
  const isRecipient = invitation.recipientUserId.toString() === viewerUserId;
  const pending = status === InvitationStatus.PENDING;
  const stamps = invitation as ClubCoachInvitationDocument & {
    createdAt: Date;
    updatedAt: Date;
  };
  return {
    id: invitation._id.toString(),
    type: invitation.type,
    status,
    direction: isRecipient ? 'RECEIVED' : 'SENT',
    message: invitation.message,
    club: clubSummary(row.clubProfile),
    coach: coachSummary(row.coachProfile),
    canAccept: isRecipient && pending,
    canReject: isRecipient && pending,
    canCancel: !isRecipient && pending,
    createdAt: stamps.createdAt,
    updatedAt: stamps.updatedAt,
    expiresAt: invitation.expiresAt,
    respondedAt: invitation.respondedAt,
  };
}

// A club's view of one of its coaches.
export function toStaffMemberView(
  membership: ClubCoachMembershipDocument,
  coach: CoachProfileDocument | null,
) {
  return {
    membershipId: membership._id.toString(),
    coach: coachSummary(coach),
    permissions: normalizePermissions(membership.permissions),
    joinedAt: membership.joinedAt,
  };
}

// A coach's view of one of their clubs — also what the club switcher lists.
export function toCoachClubView(
  membership: ClubCoachMembershipDocument,
  club: ClubProfileDocument | null,
) {
  return {
    membershipId: membership._id.toString(),
    club: clubSummary(club),
    permissions: normalizePermissions(membership.permissions),
    joinedAt: membership.joinedAt,
  };
}
