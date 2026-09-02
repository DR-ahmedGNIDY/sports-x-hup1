import {
  MembershipConflictError,
  MembershipsService,
} from './memberships.service';
import { MembershipStatus } from './schemas/club-membership.schema';

describe('MembershipsService', () => {
  function buildService(
    overrides: { create?: jest.Mock; memberRows?: unknown[] } = {},
  ) {
    const membershipModel = {
      create: overrides.create ?? jest.fn().mockResolvedValue({ _id: 'm1' }),
      findOne: jest.fn().mockResolvedValue(null),
      find: jest.fn().mockReturnValue({
        // The unpaginated roster read: find().select().sort().
        select: jest.fn().mockReturnValue({
          sort: jest.fn().mockResolvedValue(overrides.memberRows ?? []),
        }),
        // The paginated one: find().sort().skip().limit().
        sort: jest.fn().mockReturnValue({
          skip: jest.fn().mockReturnValue({
            limit: jest.fn().mockResolvedValue([]),
          }),
        }),
      }),
      countDocuments: jest.fn().mockResolvedValue(0),
      findOneAndUpdate: jest.fn().mockResolvedValue(null),
    };
    return {
      service: new MembershipsService(membershipModel as never),
      membershipModel,
    };
  }

  it('creates an ACTIVE membership carrying the invitation it came from', async () => {
    const { service, membershipModel } = buildService();

    await service.create({
      clubUserId: 'club-1',
      playerUserId: 'player-1',
      invitationId: 'inv-1',
    });

    expect(membershipModel.create).toHaveBeenCalledWith(
      expect.objectContaining({
        clubUserId: 'club-1',
        playerUserId: 'player-1',
        invitationId: 'inv-1',
        status: MembershipStatus.ACTIVE,
      }),
    );
  });

  it('turns the one-club-per-player index violation into a typed conflict', async () => {
    const { service } = buildService({
      create: jest.fn().mockRejectedValue({ code: 11000 }),
    });

    await expect(
      service.create({
        clubUserId: 'club-1',
        playerUserId: 'player-1',
        invitationId: 'inv-1',
      }),
    ).rejects.toThrow(MembershipConflictError);
  });

  it('propagates errors that are not the uniqueness violation', async () => {
    const { service } = buildService({
      create: jest.fn().mockRejectedValue(new Error('connection lost')),
    });

    await expect(
      service.create({
        clubUserId: 'club-1',
        playerUserId: 'player-1',
        invitationId: 'inv-1',
      }),
    ).rejects.toThrow('connection lost');
  });

  it('looks up a player’s club by ACTIVE status only', async () => {
    const { service, membershipModel } = buildService();

    await service.findActiveForPlayer('player-1');

    expect(membershipModel.findOne).toHaveBeenCalledWith({
      playerUserId: 'player-1',
      status: MembershipStatus.ACTIVE,
    });
  });

  it('paginates a club roster instead of returning every member', async () => {
    const { service, membershipModel } = buildService();

    const result = await service.listActiveForClub('club-1', 2);

    const chain = membershipModel.find.mock.results[0].value;
    const sorted = chain.sort.mock.results[0].value;
    expect(sorted.skip).toHaveBeenCalledWith(20);
    expect(result.pageSize).toBe(20);
  });

  it('lists every current member of a club, newest first', async () => {
    const joinedAt = new Date('2026-01-10');
    const { service, membershipModel } = buildService({
      memberRows: [
        {
          playerUserId: { toString: () => 'player-1' },
          joinedAt,
        },
      ],
    });

    const result = await service.listActiveForClubUnpaginated('club-1');

    expect(membershipModel.find).toHaveBeenCalledWith({
      clubUserId: 'club-1',
      status: MembershipStatus.ACTIVE,
    });
    // Unpaginated on purpose — the caller pages over player profiles so the
    // roster's total can honour the PUBLIC-only filter.
    expect(result).toEqual([{ playerUserId: 'player-1', joinedAt }]);
  });

  it('ends a membership only while it is still ACTIVE', async () => {
    const { service, membershipModel } = buildService();

    await service.end('m1');

    const [filter, update] = membershipModel.findOneAndUpdate.mock.calls[0];
    expect(filter).toEqual({ _id: 'm1', status: MembershipStatus.ACTIVE });
    expect(update.$set.status).toBe(MembershipStatus.ENDED);
  });
});
