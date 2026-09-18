import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { Types } from 'mongoose';
import { ClubsService } from '../clubs/clubs.service';
import { UserRole } from '../users/schemas/user.schema';
import { ClubAccessService } from './club-access.service';
import { CoachPermission } from './coach-permission.enum';

describe('ClubAccessService.resolve', () => {
  const clubUserId = new Types.ObjectId().toString();
  const clubProfileId = new Types.ObjectId().toString();
  const otherClubProfileId = new Types.ObjectId().toString();
  const coachUserId = new Types.ObjectId().toString();

  const coach = { sub: coachUserId, role: UserRole.COACH };

  function build(membership: Record<string, unknown> | null) {
    const membershipModel = {
      findOne: jest.fn().mockResolvedValue(membership),
    };
    const clubsService = {
      findByIdOrThrow: jest.fn().mockImplementation((id: string) => {
        if (id === clubProfileId) {
          return Promise.resolve({ userId: new Types.ObjectId(clubUserId) });
        }
        return Promise.reject(new NotFoundException('Club not found.'));
      }),
    } as unknown as ClubsService;
    const service = new ClubAccessService(
      membershipModel as never,
      clubsService,
    );
    return { service, membershipModel };
  }

  function activeMembership(permissions: CoachPermission[]) {
    return {
      clubUserId: new Types.ObjectId(clubUserId),
      coachUserId: new Types.ObjectId(coachUserId),
      permissions,
    };
  }

  it('lets a club act for itself with every permission, ignoring the header', async () => {
    const { service, membershipModel } = build(null);

    const actor = await service.resolve(
      { sub: clubUserId, role: UserRole.CLUB },
      otherClubProfileId,
      CoachPermission.EDIT_CLUB_PROFILE,
    );

    expect(actor.clubUserId).toBe(clubUserId);
    expect(actor.actorRole).toBe(UserRole.CLUB);
    expect(membershipModel.findOne).not.toHaveBeenCalled();
  });

  it('refuses a player outright', async () => {
    const { service } = build(null);
    await expect(
      service.resolve(
        { sub: 'p', role: UserRole.PLAYER },
        clubProfileId,
        undefined,
      ),
    ).rejects.toThrow(ForbiddenException);
  });

  it('refuses a coach who sent no club header', async () => {
    const { service } = build(activeMembership([]));
    await expect(service.resolve(coach, undefined)).rejects.toThrow(
      ForbiddenException,
    );
  });

  it('answers a malformed or unknown club id with the same 403 as "not staff"', async () => {
    const { service } = build(activeMembership([]));
    await expect(service.resolve(coach, 'not-an-id')).rejects.toThrow(
      'You do not have access to this club.',
    );
    await expect(service.resolve(coach, otherClubProfileId)).rejects.toThrow(
      'You do not have access to this club.',
    );
  });

  it('refuses a coach who is not on that club’s staff', async () => {
    const { service } = build(null);
    await expect(service.resolve(coach, clubProfileId)).rejects.toThrow(
      'You do not have access to this club.',
    );
  });

  it('lets a staff coach act with the implicit VIEW_SQUAD only', async () => {
    const { service } = build(activeMembership([]));

    const actor = await service.resolve(
      coach,
      clubProfileId,
      CoachPermission.VIEW_SQUAD,
    );

    expect(actor.clubUserId).toBe(clubUserId);
    expect(actor.actorRole).toBe(UserRole.COACH);
    expect(actor.permissions).toEqual([CoachPermission.VIEW_SQUAD]);
  });

  it('refuses a staff coach a permission they were not granted', async () => {
    const { service } = build(
      activeMembership([CoachPermission.MANAGE_CALENDAR]),
    );
    await expect(
      service.resolve(coach, clubProfileId, CoachPermission.CREATE_PLAYERS),
    ).rejects.toThrow('You do not have permission to do this for this club.');
  });

  it('allows a staff coach a permission they hold', async () => {
    const { service, membershipModel } = build(
      activeMembership([CoachPermission.CREATE_PLAYERS]),
    );

    const actor = await service.resolve(
      coach,
      clubProfileId,
      CoachPermission.CREATE_PLAYERS,
    );

    expect(actor.clubUserId).toBe(clubUserId);
    // The membership is looked up for this coach at this club — never by
    // club alone, so another coach's grant can't leak across.
    expect(membershipModel.findOne).toHaveBeenCalledWith(
      expect.objectContaining({ clubUserId, coachUserId }),
    );
  });
});

describe('ClubAccessService membership management', () => {
  function build(updated: unknown) {
    const membershipModel = {
      findOneAndUpdate: jest.fn().mockResolvedValue(updated),
    };
    const service = new ClubAccessService(
      membershipModel as never,
      {} as ClubsService,
    );
    return { service, membershipModel };
  }

  it('scopes a permission change to the calling club and keeps VIEW_SQUAD', async () => {
    const id = new Types.ObjectId().toString();
    const { service, membershipModel } = build({ _id: id });

    await service.setPermissions('club-1', id, [
      CoachPermission.MANAGE_LINEUP,
      CoachPermission.MANAGE_LINEUP,
    ]);

    expect(membershipModel.findOneAndUpdate).toHaveBeenCalledWith(
      expect.objectContaining({ _id: id, clubUserId: 'club-1' }),
      {
        $set: {
          permissions: [
            CoachPermission.VIEW_SQUAD,
            CoachPermission.MANAGE_LINEUP,
          ],
        },
      },
      { new: true },
    );
  });

  it('answers 404 for another club’s membership', async () => {
    const { service } = build(null);
    await expect(
      service.setPermissions('club-1', new Types.ObjectId().toString(), []),
    ).rejects.toThrow(NotFoundException);
  });

  it('answers 404 for a malformed membership id without querying', async () => {
    const { service, membershipModel } = build(null);
    await expect(service.end({ coachUserId: 'c' }, 'nope')).rejects.toThrow(
      NotFoundException,
    );
    expect(membershipModel.findOneAndUpdate).not.toHaveBeenCalled();
  });
});
