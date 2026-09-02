import { effectiveStatus, toInvitationView } from './invitations.mapper';
import {
  InvitationStatus,
  InvitationType,
} from './schemas/club-player-invitation.schema';

const CLUB_USER = 'club-user-1';
const PLAYER_USER = 'player-user-1';

function invitation(overrides: Record<string, unknown> = {}) {
  return {
    _id: 'invitation-1',
    type: InvitationType.CLUB_TO_PLAYER,
    status: InvitationStatus.PENDING,
    clubUserId: CLUB_USER,
    playerUserId: PLAYER_USER,
    senderUserId: CLUB_USER,
    recipientUserId: PLAYER_USER,
    expiresAt: new Date(Date.now() + 86_400_000),
    ...overrides,
  } as never;
}

const clubProfile = {
  _id: 'club-profile-1',
  userId: CLUB_USER,
  name: 'Al Ahly',
  publicCode: 'CLB-000001',
  logo: { publicId: 'x', secureUrl: 'https://cdn/logo.png' },
} as never;

const playerProfile = {
  _id: 'player-profile-1',
  userId: PLAYER_USER,
  firstName: 'Ahmed',
  lastName: 'Ali',
  sport: 'Football',
  position: 'GK',
  publicCode: 'PLY-000001',
  contact: { phone: '+201111111111', email: 'a@b.c' },
  profilePhoto: { publicId: 'y', secureUrl: 'https://cdn/photo.png' },
} as never;

function row(overrides: Record<string, unknown> = {}) {
  return {
    invitation: invitation(overrides),
    clubProfile,
    playerProfile,
  };
}

describe('effectiveStatus', () => {
  it('reports a lapsed PENDING invitation as EXPIRED even before the sweep runs', () => {
    expect(
      effectiveStatus(invitation({ expiresAt: new Date(Date.now() - 1) })),
    ).toBe(InvitationStatus.EXPIRED);
  });

  it('leaves a terminal status alone regardless of expiry', () => {
    expect(
      effectiveStatus(
        invitation({
          status: InvitationStatus.ACCEPTED,
          expiresAt: new Date(Date.now() - 1),
        }),
      ),
    ).toBe(InvitationStatus.ACCEPTED);
  });
});

describe('toInvitationView', () => {
  it('offers accept/reject to the recipient of a pending invitation', () => {
    const view = toInvitationView(row(), PLAYER_USER);

    expect(view.direction).toBe('RECEIVED');
    expect(view.canAccept).toBe(true);
    expect(view.canReject).toBe(true);
    expect(view.canCancel).toBe(false);
  });

  it('offers only cancel to the sender', () => {
    const view = toInvitationView(row(), CLUB_USER);

    expect(view.direction).toBe('SENT');
    expect(view.canAccept).toBe(false);
    expect(view.canCancel).toBe(true);
  });

  it('offers no action once the invitation is resolved', () => {
    const view = toInvitationView(
      row({ status: InvitationStatus.REJECTED }),
      PLAYER_USER,
    );

    expect(view.canAccept).toBe(false);
    expect(view.canReject).toBe(false);
    expect(view.canCancel).toBe(false);
  });

  it('offers no action on an expired invitation', () => {
    const view = toInvitationView(
      row({ expiresAt: new Date(Date.now() - 1) }),
      PLAYER_USER,
    );

    expect(view.status).toBe(InvitationStatus.EXPIRED);
    expect(view.canAccept).toBe(false);
  });

  it('never exposes the player’s contact details', () => {
    const view = toInvitationView(row(), CLUB_USER);

    expect(JSON.stringify(view)).not.toContain('+201111111111');
    expect(JSON.stringify(view)).not.toContain('a@b.c');
  });

  it('carries both public codes so either side can be looked up', () => {
    const view = toInvitationView(row(), CLUB_USER);

    expect(view.club?.publicCode).toBe('CLB-000001');
    expect(view.player?.publicCode).toBe('PLY-000001');
  });

  it('survives a counterpart profile that no longer exists', () => {
    const view = toInvitationView(
      { invitation: invitation(), clubProfile: null, playerProfile: null },
      PLAYER_USER,
    );

    expect(view.club).toBeNull();
    expect(view.player).toBeNull();
  });
});
