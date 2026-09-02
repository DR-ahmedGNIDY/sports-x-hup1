import { NotFoundException } from '@nestjs/common';
import { MembershipsController } from './memberships.controller';

// The two public read routes. What matters here is not that they return
// rows, but *which* rows: a roster must not become a way to read a player
// who set their profile to private, and a missing membership must not read
// as an error on a profile page.

function playerProfile(overrides: Record<string, unknown> = {}) {
  return {
    _id: { toString: () => 'player-profile-1' },
    userId: { toString: () => 'player-user-1' },
    publicCode: 'PLY-000001',
    firstName: 'Omar',
    lastName: 'Hassan',
    sport: 'Football',
    position: 'CM',
    country: 'Egypt',
    ...overrides,
  };
}

function clubProfile(overrides: Record<string, unknown> = {}) {
  return {
    _id: { toString: () => 'club-profile-1' },
    userId: { toString: () => 'club-user-1' },
    publicCode: 'CLB-000001',
    name: 'Al Ahly',
    city: 'Cairo',
    country: 'Egypt',
    ...overrides,
  };
}

function build(
  overrides: {
    memberships?: Partial<Record<string, jest.Mock>>;
    players?: Partial<Record<string, jest.Mock>>;
    clubs?: Partial<Record<string, jest.Mock>>;
  } = {},
) {
  const memberships = {
    listActiveForClubUnpaginated: jest.fn().mockResolvedValue([]),
    findActiveForPlayer: jest.fn().mockResolvedValue(null),
    ...overrides.memberships,
  };
  const players = {
    findManyPublicByUserIds: jest
      .fn()
      .mockResolvedValue({ items: [], page: 1, pageSize: 20, total: 0 }),
    findPublicByIdOrThrow: jest.fn().mockResolvedValue(playerProfile()),
    ...overrides.players,
  };
  const clubs = {
    findByIdOrThrow: jest.fn().mockResolvedValue(clubProfile()),
    findByUserId: jest.fn().mockResolvedValue(clubProfile()),
    ...overrides.clubs,
  };
  return {
    controller: new MembershipsController(
      memberships as never,
      players as never,
      clubs as never,
    ),
    memberships,
    players,
    clubs,
  };
}

describe('MembershipsController', () => {
  describe('GET /memberships/clubs/:clubId/players', () => {
    it('pages over player profiles, so the total honours the PUBLIC filter', async () => {
      const { controller, players } = build({
        memberships: {
          listActiveForClubUnpaginated: jest.fn().mockResolvedValue([
            { playerUserId: 'player-user-1', joinedAt: new Date('2026-01-01') },
            { playerUserId: 'player-user-2', joinedAt: new Date('2026-02-01') },
          ]),
        },
        players: {
          // Two members, one public: the count must be the one the page
          // could show, never the membership count.
          findManyPublicByUserIds: jest.fn().mockResolvedValue({
            items: [playerProfile()],
            page: 1,
            pageSize: 20,
            total: 1,
          }),
        },
      });

      const result = await controller.clubMembers('club-profile-1', {});

      expect(players.findManyPublicByUserIds).toHaveBeenCalledWith(
        ['player-user-1', 'player-user-2'],
        1,
      );
      expect(result.total).toBe(1);
      expect(result.items).toHaveLength(1);
    });

    it('attaches each member the date they actually joined', async () => {
      const joinedAt = new Date('2026-01-15');
      const { controller } = build({
        memberships: {
          listActiveForClubUnpaginated: jest
            .fn()
            .mockResolvedValue([{ playerUserId: 'player-user-1', joinedAt }]),
        },
        players: {
          findManyPublicByUserIds: jest.fn().mockResolvedValue({
            items: [playerProfile()],
            page: 1,
            pageSize: 20,
            total: 1,
          }),
        },
      });

      const result = await controller.clubMembers('club-profile-1', {});

      expect(result.items[0].joinedAt).toBe(joinedAt);
      expect(result.items[0].publicCode).toBe('PLY-000001');
    });

    it('never exposes contact details on a roster row', async () => {
      const { controller } = build({
        memberships: {
          listActiveForClubUnpaginated: jest.fn().mockResolvedValue([
            { playerUserId: 'player-user-1', joinedAt: new Date() },
          ]),
        },
        players: {
          findManyPublicByUserIds: jest.fn().mockResolvedValue({
            items: [
              playerProfile({
                contact: { phone: '+201000000000', email: 'a@b.test' },
              }),
            ],
            page: 1,
            pageSize: 20,
            total: 1,
          }),
        },
      });

      const result = await controller.clubMembers('club-profile-1', {});

      const serialized = JSON.stringify(result);
      expect(serialized).not.toContain('+201000000000');
      expect(serialized).not.toContain('a@b.test');
    });

    it('answers an empty page without querying profiles at all', async () => {
      const { controller, players } = build();

      const result = await controller.clubMembers('club-profile-1', {});

      expect(result.items).toEqual([]);
      expect(result.total).toBe(0);
      expect(players.findManyPublicByUserIds).not.toHaveBeenCalled();
    });

    it('404s on an unknown club rather than answering an empty roster', async () => {
      const { controller } = build({
        clubs: {
          findByIdOrThrow: jest
            .fn()
            .mockRejectedValue(new NotFoundException('Club not found.')),
        },
      });

      await expect(controller.clubMembers('nope', {})).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('GET /memberships/players/:playerId/club', () => {
    it('returns the club a player currently belongs to', async () => {
      const joinedAt = new Date('2026-01-20');
      const { controller, clubs } = build({
        memberships: {
          findActiveForPlayer: jest.fn().mockResolvedValue({
            _id: { toString: () => 'membership-1' },
            clubUserId: { toString: () => 'club-user-1' },
            joinedAt,
          }),
        },
      });

      const result = await controller.playerClub('player-profile-1');

      expect(clubs.findByUserId).toHaveBeenCalledWith('club-user-1');
      expect(result.membership?.club?.name).toBe('Al Ahly');
      expect(result.membership?.club?.publicCode).toBe('CLB-000001');
      expect(result.membership?.joinedAt).toBe(joinedAt);
    });

    it('answers null for a player with no club — that is not an error', async () => {
      const { controller } = build();

      // A profile page renders "no club" as ordinary content; a 404 here
      // would force every caller to treat a normal state as a failure.
      await expect(controller.playerClub('player-profile-1')).resolves.toEqual({
        membership: null,
      });
    });

    it('is scoped to public players, so a code cannot bypass visibility', async () => {
      const { controller, memberships } = build({
        players: {
          findPublicByIdOrThrow: jest
            .fn()
            .mockRejectedValue(new NotFoundException('Player not found.')),
        },
      });

      await expect(controller.playerClub('private-player')).rejects.toThrow(
        NotFoundException,
      );
      // And it never got as far as reading the membership, so nothing about
      // the private account was touched.
      expect(memberships.findActiveForPlayer).not.toHaveBeenCalled();
    });
  });
});
