import {
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { Types } from 'mongoose';
import { CoachMembershipConflictError } from '../club-access/club-access.service';
import { InvitationStatus } from '../invitations/schemas/club-player-invitation.schema';
import { NotificationEntityType } from '../notifications/schemas/notification.schema';
import { CoachInvitationsService } from './coach-invitations.service';
import { CoachInvitationType } from './schemas/club-coach-invitation.schema';

describe('CoachInvitationsService', () => {
  const clubUserId = new Types.ObjectId();
  const coachUserId = new Types.ObjectId();
  const clubProfile = {
    _id: new Types.ObjectId(),
    userId: clubUserId,
    name: 'Nadi',
  };
  const coachProfile = {
    _id: new Types.ObjectId(),
    userId: coachUserId,
    firstName: 'Sami',
  };

  function invitationDoc(overrides: Record<string, unknown> = {}) {
    return {
      _id: new Types.ObjectId(),
      type: CoachInvitationType.CLUB_TO_COACH,
      status: InvitationStatus.PENDING,
      clubUserId,
      coachUserId,
      senderUserId: clubUserId,
      recipientUserId: coachUserId,
      expiresAt: new Date(Date.now() + 86_400_000),
      ...overrides,
    };
  }

  function build(
    opts: {
      activeMembership?: unknown;
      createError?: unknown;
      claimed?: unknown;
      visible?: unknown;
      membershipError?: unknown;
    } = {},
  ) {
    const invitationModel = {
      updateMany: jest.fn().mockResolvedValue({}),
      updateOne: jest.fn().mockResolvedValue({}),
      create: opts.createError
        ? jest.fn().mockRejectedValue(opts.createError)
        : jest
            .fn()
            .mockImplementation((doc) =>
              Promise.resolve({ _id: new Types.ObjectId(), ...doc }),
            ),
      findOneAndUpdate: jest.fn().mockResolvedValue(opts.claimed ?? null),
      findOne: jest.fn().mockResolvedValue(opts.visible ?? null),
    };
    const access = {
      findActive: jest.fn().mockResolvedValue(opts.activeMembership ?? null),
      create: opts.membershipError
        ? jest.fn().mockRejectedValue(opts.membershipError)
        : jest.fn().mockResolvedValue({}),
    };
    const clubsService = {
      getOrCreateForUser: jest.fn().mockResolvedValue(clubProfile),
      findByPublicCodeOrThrow: jest.fn().mockResolvedValue(clubProfile),
      findManyByUserIds: jest.fn().mockResolvedValue([clubProfile]),
    };
    const coachesService = {
      findPublicByCodeOrThrow: jest.fn().mockResolvedValue(coachProfile),
      getOrCreateForUser: jest.fn().mockResolvedValue(coachProfile),
      findManyByUserIds: jest.fn().mockResolvedValue([coachProfile]),
    };
    const notifications = { emit: jest.fn().mockResolvedValue(null) };
    const service = new CoachInvitationsService(
      invitationModel as never,
      access as never,
      clubsService as never,
      coachesService as never,
      notifications as never,
    );
    return { service, invitationModel, access, notifications };
  }

  it('sends a club-to-coach invitation and notifies the coach', async () => {
    const { service, invitationModel, notifications } = build();

    const row = await service.sendClubToCoach(clubUserId.toString(), {
      coachCode: 'COA-000001',
    });

    expect(invitationModel.create).toHaveBeenCalledWith(
      expect.objectContaining({
        type: CoachInvitationType.CLUB_TO_COACH,
        senderUserId: clubUserId,
        recipientUserId: coachUserId,
      }),
    );
    expect(row.coachProfile).toBe(coachProfile);
    expect(notifications.emit).toHaveBeenCalledWith(
      expect.objectContaining({
        userId: coachUserId,
        entityType: NotificationEntityType.COACH_INVITATION,
      }),
    );
  });

  it('refuses to invite a coach who is already on the staff', async () => {
    const { service } = build({ activeMembership: { _id: 'm' } });
    await expect(
      service.sendClubToCoach(clubUserId.toString(), {
        coachCode: 'COA-000001',
      }),
    ).rejects.toThrow(ConflictException);
  });

  it('turns the pending-pair index violation into a 409', async () => {
    const { service } = build({ createError: { code: 11000 } });
    await expect(
      service.sendCoachToClub(coachUserId.toString(), {
        clubCode: 'CLB-000001',
      }),
    ).rejects.toThrow('There is already a pending invitation');
  });

  it('accepting creates a membership and leaves the coach’s other invitations alone', async () => {
    const claimed = invitationDoc({ status: InvitationStatus.ACCEPTED });
    const { service, access, invitationModel } = build({ claimed });

    await service.accept(coachUserId.toString(), claimed._id.toString());

    expect(access.create).toHaveBeenCalledWith({
      clubUserId,
      coachUserId,
      invitationId: claimed._id,
    });
    // Multi-club: no sweep of the coach's other pending invitations.
    expect(invitationModel.updateMany).not.toHaveBeenCalled();
  });

  it('puts the invitation back to PENDING if the membership already exists', async () => {
    const claimed = invitationDoc({ status: InvitationStatus.ACCEPTED });
    const { service, invitationModel } = build({
      claimed,
      membershipError: new CoachMembershipConflictError('dup'),
    });

    await expect(
      service.accept(coachUserId.toString(), claimed._id.toString()),
    ).rejects.toThrow(ConflictException);
    expect(invitationModel.updateOne).toHaveBeenCalledWith(
      { _id: claimed._id, status: InvitationStatus.ACCEPTED },
      expect.anything(),
    );
  });

  it('tells the sender they cannot accept their own invitation', async () => {
    const visible = invitationDoc();
    const { service } = build({ visible });
    await expect(
      service.accept(clubUserId.toString(), visible._id.toString()),
    ).rejects.toThrow(ForbiddenException);
  });

  it('answers 404 to anyone who is not a party', async () => {
    const { service } = build();
    await expect(
      service.accept('someone-else', new Types.ObjectId().toString()),
    ).rejects.toThrow(NotFoundException);
  });
});
