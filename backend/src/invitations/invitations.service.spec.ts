import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { InvitationsService } from './invitations.service';
import { MembershipConflictError } from './memberships.service';
import {
  InvitationStatus,
  InvitationType,
} from './schemas/club-player-invitation.schema';

const VALID_ID = '507f1f77bcf86cd799439011';
const CLUB_USER = 'club-user-1';
const PLAYER_USER = 'player-user-1';
const OTHER_CLUB_USER = 'club-user-2';

const clubProfile = {
  _id: 'club-profile-1',
  userId: CLUB_USER,
  name: 'Al Ahly',
  publicCode: 'CLB-000001',
};
const playerProfile = {
  _id: 'player-profile-1',
  userId: PLAYER_USER,
  firstName: 'Ahmed',
  publicCode: 'PLY-000001',
  visibility: 'PUBLIC',
};

function pendingInvitation(overrides: Record<string, unknown> = {}) {
  return {
    _id: VALID_ID,
    type: InvitationType.CLUB_TO_PLAYER,
    status: InvitationStatus.PENDING,
    clubUserId: CLUB_USER,
    playerUserId: PLAYER_USER,
    senderUserId: CLUB_USER,
    recipientUserId: PLAYER_USER,
    expiresAt: new Date(Date.now() + 86_400_000),
    ...overrides,
  };
}

describe('InvitationsService', () => {
  function buildService(
    overrides: {
      activeMembership?: Record<string, unknown> | null;
      managedPlayer?: Record<string, unknown> | null;
      createResult?: unknown;
      createRejection?: unknown;
      transitionResult?: unknown;
      visibleInvitation?: Record<string, unknown> | null;
      membershipRejection?: unknown;
      listItems?: Array<Record<string, unknown>>;
    } = {},
  ) {
    const invitationModel = {
      create: jest.fn(),
      findOne: jest
        .fn()
        .mockResolvedValue(
          overrides.visibleInvitation === undefined
            ? null
            : overrides.visibleInvitation,
        ),
      findOneAndUpdate: jest
        .fn()
        .mockResolvedValue(overrides.transitionResult ?? null),
      updateOne: jest.fn().mockResolvedValue({ modifiedCount: 1 }),
      updateMany: jest.fn().mockResolvedValue({ modifiedCount: 2 }),
      countDocuments: jest.fn().mockResolvedValue(3),
      find: jest.fn().mockReturnValue({
        sort: jest.fn().mockReturnValue({
          skip: jest.fn().mockReturnValue({
            limit: jest.fn().mockResolvedValue(overrides.listItems ?? []),
          }),
        }),
      }),
    };
    if (overrides.createRejection) {
      invitationModel.create.mockRejectedValue(overrides.createRejection);
    } else {
      invitationModel.create.mockResolvedValue(
        overrides.createResult ?? pendingInvitation(),
      );
    }

    const clubManagedPlayerModel = {
      findOne: jest.fn().mockResolvedValue(overrides.managedPlayer ?? null),
    };
    const memberships = {
      findActiveForPlayer: jest
        .fn()
        .mockResolvedValue(overrides.activeMembership ?? null),
      create: overrides.membershipRejection
        ? jest.fn().mockRejectedValue(overrides.membershipRejection)
        : jest.fn().mockResolvedValue({ _id: 'membership-1' }),
    };
    const playersService = {
      getOrCreateForUser: jest.fn().mockResolvedValue(playerProfile),
      findPublicByCodeOrThrow: jest.fn().mockResolvedValue(playerProfile),
      findPublicByIdOrThrow: jest.fn().mockResolvedValue(playerProfile),
      findManyByUserIds: jest.fn().mockResolvedValue([playerProfile]),
    };
    const clubsService = {
      getOrCreateForUser: jest.fn().mockResolvedValue(clubProfile),
      findByPublicCodeOrThrow: jest.fn().mockResolvedValue(clubProfile),
      findByIdOrThrow: jest.fn().mockResolvedValue(clubProfile),
      findManyByUserIds: jest.fn().mockResolvedValue([clubProfile]),
    };

    const service = new InvitationsService(
      invitationModel as never,
      clubManagedPlayerModel as never,
      memberships as never,
      playersService as never,
      clubsService as never,
    );
    return {
      service,
      invitationModel,
      clubManagedPlayerModel,
      memberships,
      playersService,
      clubsService,
    };
  }

  describe('sending', () => {
    it('creates a CLUB_TO_PLAYER invitation with the sender/recipient derived server-side', async () => {
      const { service, invitationModel, playersService } = buildService();

      await service.sendClubToPlayer(CLUB_USER, { playerCode: 'PLY-000001' });

      expect(playersService.findPublicByCodeOrThrow).toHaveBeenCalledWith(
        'PLY-000001',
      );
      expect(invitationModel.create).toHaveBeenCalledWith(
        expect.objectContaining({
          type: InvitationType.CLUB_TO_PLAYER,
          status: InvitationStatus.PENDING,
          clubUserId: CLUB_USER,
          playerUserId: PLAYER_USER,
          senderUserId: CLUB_USER,
          recipientUserId: PLAYER_USER,
        }),
      );
    });

    it('creates a PLAYER_TO_CLUB invitation with the direction reversed', async () => {
      const { service, invitationModel } = buildService();

      await service.sendPlayerToClub(PLAYER_USER, { clubCode: 'CLB-000001' });

      expect(invitationModel.create).toHaveBeenCalledWith(
        expect.objectContaining({
          type: InvitationType.PLAYER_TO_CLUB,
          senderUserId: PLAYER_USER,
          recipientUserId: CLUB_USER,
        }),
      );
    });

    it('sets an expiry on every invitation', async () => {
      const { service, invitationModel } = buildService();
      await service.sendClubToPlayer(CLUB_USER, { playerId: VALID_ID });

      const created = invitationModel.create.mock.calls[0][0];
      expect(created.expiresAt.getTime()).toBeGreaterThan(Date.now());
    });

    it('frees the pair’s pending slot from a lapsed invitation before creating a new one', async () => {
      const { service, invitationModel } = buildService();

      await service.sendClubToPlayer(CLUB_USER, { playerCode: 'PLY-000001' });

      const [filter, update] = invitationModel.updateMany.mock.calls[0];
      expect(filter).toEqual(
        expect.objectContaining({
          clubUserId: CLUB_USER,
          playerUserId: PLAYER_USER,
          status: InvitationStatus.PENDING,
        }),
      );
      expect(filter.expiresAt.$lte).toBeInstanceOf(Date);
      expect(update).toEqual({
        $set: { status: InvitationStatus.EXPIRED },
      });
      // Only the lapsed ones — a live invitation still blocks a duplicate.
      expect(invitationModel.create).toHaveBeenCalled();
    });

    it('rejects a request naming neither a code nor an id', async () => {
      const { service, invitationModel } = buildService();

      await expect(service.sendClubToPlayer(CLUB_USER, {})).rejects.toThrow(
        BadRequestException,
      );
      expect(invitationModel.create).not.toHaveBeenCalled();
    });

    it('turns the duplicate-pending index violation into a conflict', async () => {
      const { service } = buildService({ createRejection: { code: 11000 } });

      await expect(
        service.sendClubToPlayer(CLUB_USER, { playerCode: 'PLY-000001' }),
      ).rejects.toThrow(ConflictException);
    });

    it('refuses to invite a player who already belongs to another club', async () => {
      const { service, invitationModel } = buildService({
        activeMembership: { clubUserId: OTHER_CLUB_USER },
      });

      await expect(
        service.sendClubToPlayer(CLUB_USER, { playerCode: 'PLY-000001' }),
      ).rejects.toThrow(ConflictException);
      expect(invitationModel.create).not.toHaveBeenCalled();
    });

    it('refuses to invite a player who is already a member of the inviting club', async () => {
      const { service } = buildService({
        activeMembership: { clubUserId: CLUB_USER },
      });

      await expect(
        service.sendClubToPlayer(CLUB_USER, { playerCode: 'PLY-000001' }),
      ).rejects.toThrow(/already a member of your club/);
    });

    it('refuses to invite a club-created (club-managed) account', async () => {
      const { service, invitationModel } = buildService({
        managedPlayer: { clubId: OTHER_CLUB_USER },
      });

      await expect(
        service.sendClubToPlayer(CLUB_USER, { playerCode: 'PLY-000001' }),
      ).rejects.toThrow(ConflictException);
      expect(invitationModel.create).not.toHaveBeenCalled();
    });

    it('refuses an invitation where both sides are the same account', async () => {
      const { service, clubsService, invitationModel } = buildService();
      clubsService.getOrCreateForUser.mockResolvedValue({
        ...clubProfile,
        userId: PLAYER_USER,
      });

      await expect(
        service.sendClubToPlayer(PLAYER_USER, { playerCode: 'PLY-000001' }),
      ).rejects.toThrow(BadRequestException);
      expect(invitationModel.create).not.toHaveBeenCalled();
    });

    it('never reaches the database for a player it cannot resolve', async () => {
      const { service, playersService, invitationModel } = buildService();
      playersService.findPublicByCodeOrThrow.mockRejectedValue(
        new NotFoundException('Player not found.'),
      );

      await expect(
        service.sendClubToPlayer(CLUB_USER, { playerCode: 'PLY-999999' }),
      ).rejects.toThrow(NotFoundException);
      expect(invitationModel.create).not.toHaveBeenCalled();
    });
  });

  describe('accept', () => {
    it('claims the invitation atomically as the recipient, and only while pending and unexpired', async () => {
      const invitation = pendingInvitation();
      const { service, invitationModel } = buildService({
        transitionResult: invitation,
      });

      await service.accept(PLAYER_USER, VALID_ID);

      const [filter, update] = invitationModel.findOneAndUpdate.mock.calls[0];
      expect(filter).toEqual(
        expect.objectContaining({
          _id: VALID_ID,
          recipientUserId: PLAYER_USER,
          status: InvitationStatus.PENDING,
        }),
      );
      expect(filter.expiresAt.$gt).toBeInstanceOf(Date);
      expect(update.$set.status).toBe(InvitationStatus.ACCEPTED);
    });

    it('creates the membership from the accepted invitation', async () => {
      const invitation = pendingInvitation();
      const { service, memberships } = buildService({
        transitionResult: invitation,
      });

      await service.accept(PLAYER_USER, VALID_ID);

      expect(memberships.create).toHaveBeenCalledWith({
        clubUserId: CLUB_USER,
        playerUserId: PLAYER_USER,
        invitationId: VALID_ID,
      });
    });

    it('cancels the player’s other pending invitations once they have a club', async () => {
      const { service, invitationModel } = buildService({
        transitionResult: pendingInvitation(),
      });

      await service.accept(PLAYER_USER, VALID_ID);

      expect(invitationModel.updateMany).toHaveBeenCalledWith(
        {
          playerUserId: PLAYER_USER,
          status: InvitationStatus.PENDING,
          _id: { $ne: VALID_ID },
        },
        expect.objectContaining({
          $set: expect.objectContaining({
            status: InvitationStatus.CANCELLED,
          }),
        }),
      );
    });

    it('rolls the invitation back to PENDING when another club wins the membership race', async () => {
      const { service, invitationModel } = buildService({
        transitionResult: pendingInvitation(),
        membershipRejection: new MembershipConflictError(
          'This player already belongs to a club.',
        ),
      });

      await expect(service.accept(PLAYER_USER, VALID_ID)).rejects.toThrow(
        ConflictException,
      );
      expect(invitationModel.updateOne).toHaveBeenCalledWith(
        { _id: VALID_ID, status: InvitationStatus.ACCEPTED },
        expect.objectContaining({
          $set: { status: InvitationStatus.PENDING },
        }),
      );
      // The player is not left with every other invitation cancelled on the
      // strength of an accept that did not take effect.
      expect(invitationModel.updateMany).not.toHaveBeenCalled();
    });

    it('forbids the sender from accepting their own invitation', async () => {
      const { service, memberships } = buildService({
        transitionResult: null,
        visibleInvitation: pendingInvitation(),
      });

      await expect(service.accept(CLUB_USER, VALID_ID)).rejects.toThrow(
        ForbiddenException,
      );
      expect(memberships.create).not.toHaveBeenCalled();
    });

    it('answers 404 for an invitation the caller is not party to', async () => {
      const { service } = buildService({
        transitionResult: null,
        visibleInvitation: null,
      });

      await expect(service.accept('stranger', VALID_ID)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('scopes even the failure diagnosis to invitations the caller is party to', async () => {
      const { service, invitationModel } = buildService({
        transitionResult: null,
        visibleInvitation: null,
      });

      await expect(service.accept('stranger', VALID_ID)).rejects.toThrow(
        NotFoundException,
      );
      expect(invitationModel.findOne).toHaveBeenCalledWith({
        _id: VALID_ID,
        $or: [{ senderUserId: 'stranger' }, { recipientUserId: 'stranger' }],
      });
    });

    it('answers 404 for a malformed id without touching the database', async () => {
      const { service, invitationModel } = buildService();

      await expect(service.accept(PLAYER_USER, 'not-an-id')).rejects.toThrow(
        NotFoundException,
      );
      expect(invitationModel.findOneAndUpdate).not.toHaveBeenCalled();
      expect(invitationModel.findOne).not.toHaveBeenCalled();
    });

    it('rejects a second accept of an already-resolved invitation', async () => {
      const { service } = buildService({
        transitionResult: null,
        visibleInvitation: pendingInvitation({
          status: InvitationStatus.ACCEPTED,
        }),
      });

      await expect(service.accept(PLAYER_USER, VALID_ID)).rejects.toThrow(
        /already been resolved/,
      );
    });

    it('rejects accepting an expired invitation', async () => {
      const { service } = buildService({
        transitionResult: null,
        visibleInvitation: pendingInvitation({
          expiresAt: new Date(Date.now() - 1000),
        }),
      });

      await expect(service.accept(PLAYER_USER, VALID_ID)).rejects.toThrow(
        /expired/,
      );
    });
  });

  describe('reject', () => {
    it('is scoped to the recipient', async () => {
      const { service, invitationModel } = buildService({
        transitionResult: pendingInvitation(),
      });

      await service.reject(PLAYER_USER, VALID_ID);

      const [filter, update] = invitationModel.findOneAndUpdate.mock.calls[0];
      expect(filter.recipientUserId).toBe(PLAYER_USER);
      expect(update.$set.status).toBe(InvitationStatus.REJECTED);
    });

    it('forbids the sender from rejecting their own invitation', async () => {
      const { service } = buildService({
        transitionResult: null,
        visibleInvitation: pendingInvitation(),
      });

      await expect(service.reject(CLUB_USER, VALID_ID)).rejects.toThrow(
        ForbiddenException,
      );
    });

    it('creates no membership', async () => {
      const { service, memberships } = buildService({
        transitionResult: pendingInvitation(),
      });

      await service.reject(PLAYER_USER, VALID_ID);
      expect(memberships.create).not.toHaveBeenCalled();
    });
  });

  describe('cancel', () => {
    it('is scoped to the sender', async () => {
      const { service, invitationModel } = buildService({
        transitionResult: pendingInvitation(),
      });

      await service.cancel(CLUB_USER, VALID_ID);

      const [filter, update] = invitationModel.findOneAndUpdate.mock.calls[0];
      expect(filter.senderUserId).toBe(CLUB_USER);
      expect(update.$set.status).toBe(InvitationStatus.CANCELLED);
    });

    it('forbids the recipient from cancelling an invitation they received', async () => {
      const { service } = buildService({
        transitionResult: null,
        visibleInvitation: pendingInvitation(),
      });

      await expect(service.cancel(PLAYER_USER, VALID_ID)).rejects.toThrow(
        ForbiddenException,
      );
    });
  });

  describe('reading', () => {
    it('pins the inbox query to the caller as recipient', async () => {
      const { service, invitationModel } = buildService();

      await service.listReceived(PLAYER_USER, {
        status: InvitationStatus.PENDING,
      });

      expect(invitationModel.find).toHaveBeenCalledWith({
        recipientUserId: PLAYER_USER,
        status: InvitationStatus.PENDING,
      });
    });

    it('pins the outbox query to the caller as sender', async () => {
      const { service, invitationModel } = buildService();

      await service.listSent(CLUB_USER, {});

      expect(invitationModel.find).toHaveBeenCalledWith({
        senderUserId: CLUB_USER,
      });
    });

    it('paginates rather than returning every invitation', async () => {
      const { service, invitationModel } = buildService();

      const result = await service.listReceived(PLAYER_USER, { page: 3 });

      const chain = invitationModel.find.mock.results[0].value;
      const sorted = chain.sort.mock.results[0].value;
      expect(sorted.skip).toHaveBeenCalledWith(40);
      expect(sorted.skip.mock.results[0].value.limit).toHaveBeenCalledWith(20);
      expect(result.pageSize).toBe(20);
    });

    it('resolves both counterparts in one query each, not per row', async () => {
      const { service, playersService, clubsService } = buildService({
        listItems: [pendingInvitation(), pendingInvitation({ _id: 'other' })],
      });

      const result = await service.listReceived(PLAYER_USER, {});

      expect(playersService.findManyByUserIds).toHaveBeenCalledTimes(1);
      expect(clubsService.findManyByUserIds).toHaveBeenCalledTimes(1);
      expect(result.items).toHaveLength(2);
      expect(result.items[0].clubProfile).toEqual(clubProfile);
    });

    it('scopes a single lookup to the caller as either party', async () => {
      const { service, invitationModel } = buildService({
        visibleInvitation: pendingInvitation(),
      });

      await service.findByIdForParty(PLAYER_USER, VALID_ID);

      expect(invitationModel.findOne).toHaveBeenCalledWith({
        _id: VALID_ID,
        $or: [{ senderUserId: PLAYER_USER }, { recipientUserId: PLAYER_USER }],
      });
    });

    it('answers 404 for an invitation belonging to somebody else', async () => {
      const { service } = buildService({ visibleInvitation: null });

      await expect(
        service.findByIdForParty('stranger', VALID_ID),
      ).rejects.toThrow(NotFoundException);
    });

    it('counts only unexpired pending invitations in the summary', async () => {
      const { service, invitationModel } = buildService();

      await service.summary(PLAYER_USER);

      const [receivedFilter] = invitationModel.countDocuments.mock.calls[0];
      expect(receivedFilter.recipientUserId).toBe(PLAYER_USER);
      expect(receivedFilter.status).toBe(InvitationStatus.PENDING);
      expect(receivedFilter.expiresAt.$gt).toBeInstanceOf(Date);
    });
  });

  describe('markExpired', () => {
    it('only touches pending invitations whose expiry has passed', async () => {
      const { service, invitationModel } = buildService();
      const now = new Date('2026-01-01T00:00:00Z');

      await expect(service.markExpired(now)).resolves.toBe(2);
      expect(invitationModel.updateMany).toHaveBeenCalledWith(
        { status: InvitationStatus.PENDING, expiresAt: { $lte: now } },
        { $set: { status: InvitationStatus.EXPIRED } },
      );
    });
  });
});
