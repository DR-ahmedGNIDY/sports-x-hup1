import { BadRequestException, NotFoundException } from '@nestjs/common';
import { Types } from 'mongoose';
import {
  ParticipantType,
  TournamentFormat,
  TournamentStatus,
} from './schemas/tournament.schemas';
import { TournamentsService } from './tournaments.service';

const CLUB = new Types.ObjectId().toString();
const P1 = new Types.ObjectId().toString();
const P2 = new Types.ObjectId().toString();
const P3 = new Types.ObjectId().toString();

/** A query that is both awaitable and chainable, like Mongoose's. */
function query<T>(value: T) {
  const q = {
    sort: () => q,
    limit: () => q,
    select: () => q,
    then: (resolve: (v: T) => unknown, reject?: (e: unknown) => unknown) =>
      Promise.resolve(value).then(resolve, reject),
  };
  return q;
}

function tournamentDoc(fields: Record<string, unknown> = {}) {
  const doc = {
    _id: new Types.ObjectId(),
    clubUserId: CLUB,
    name: 'Winter Cup',
    participantType: ParticipantType.INDIVIDUAL,
    format: TournamentFormat.LEAGUE,
    drawMode: 'directed',
    scoring: { mode: 'goals', bestOf: 3, pointsPerSet: 11, winByTwo: true },
    league: {
      winPoints: 3,
      drawPoints: 1,
      lossPoints: 0,
      doubleRound: false,
      allowDraws: true,
    },
    groups: { count: 2, qualifiersPerGroup: 1 },
    knockout: { penaltiesEnabled: true, penaltiesCount: 5 },
    status: TournamentStatus.DRAFT,
    visibleToPlayers: true,
    save: jest.fn(),
    set: jest.fn(),
    ...fields,
  };
  doc.save.mockResolvedValue(doc);
  return doc;
}

function participantDoc(playerUserIds: string[], fields = {}) {
  return {
    _id: new Types.ObjectId(),
    name: 'x',
    playerUserIds,
    seed: null,
    groupIndex: null,
    ...fields,
  };
}

function buildService(t = tournamentDoc()) {
  // `new Model(data)` as in create(): schema defaults, then what was sent,
  // with nested settings merged over their defaults.
  const tournamentModel = Object.assign(
    jest.fn(function (this: object, data: Record<string, object>) {
      const base = tournamentDoc();
      Object.assign(this, base, data, {
        scoring: { ...base.scoring, ...data.scoring },
      });
    }),
    {
      findOne: jest.fn().mockResolvedValue(t),
      find: jest.fn().mockReturnValue(query([t])),
    },
  );
  const participantModel = {
    findOne: jest.fn().mockReturnValue(query(null)),
    find: jest.fn().mockReturnValue(query([])),
    create: jest.fn().mockImplementation((d) => Promise.resolve(d)),
    countDocuments: jest.fn().mockResolvedValue(0),
    bulkWrite: jest.fn().mockResolvedValue({}),
    aggregate: jest.fn().mockResolvedValue([]),
  };
  const fixtureModel = {
    find: jest.fn().mockResolvedValue([]),
    findOne: jest.fn().mockResolvedValue(null),
    countDocuments: jest.fn().mockResolvedValue(0),
    deleteMany: jest.fn().mockResolvedValue({}),
    insertMany: jest.fn().mockResolvedValue([]),
  };
  const clubPlayers = {
    rosterUserIds: jest.fn().mockResolvedValue([P1, P2, P3]),
    clubIdsForPlayer: jest.fn().mockResolvedValue([CLUB]),
  };
  const players = {
    findManyByUserIds: jest
      .fn()
      .mockResolvedValue([{ userId: P1, firstName: 'Omar', lastName: 'Salah' }]),
  };
  const clubs = {
    getOrCreateForUser: jest.fn().mockResolvedValue({ name: 'Zamalek' }),
  };
  const notifications = { emitFresh: jest.fn().mockResolvedValue(null) };
  const service = new TournamentsService(
    tournamentModel as never,
    participantModel as never,
    fixtureModel as never,
    clubPlayers as never,
    players as never,
    clubs as never,
    notifications as never,
  );
  return {
    service,
    t,
    tournamentModel,
    participantModel,
    fixtureModel,
    clubPlayers,
    notifications,
  };
}

const flush = () => new Promise((r) => setImmediate(r));

describe('TournamentsService', () => {
  describe('participants', () => {
    it('names an individual entry after its player', async () => {
      const { service, t, participantModel } = buildService();

      await service.addParticipant(CLUB, t._id.toString(), {
        playerUserIds: [P1],
      });

      expect(participantModel.create).toHaveBeenCalledWith(
        expect.objectContaining({
          name: 'Omar Salah',
          playerUserIds: [P1],
          seed: 1,
          captainUserId: null,
        }),
      );
    });

    it('refuses a player from outside the club', async () => {
      const { service, t, participantModel } = buildService();
      const outsider = new Types.ObjectId().toString();

      await expect(
        service.addParticipant(CLUB, t._id.toString(), {
          playerUserIds: [outsider],
        }),
      ).rejects.toThrow(/not in this club/);
      expect(participantModel.create).not.toHaveBeenCalled();
    });

    it('refuses a player already entered in another participant', async () => {
      const { service, t, participantModel } = buildService(
        tournamentDoc({ participantType: ParticipantType.TEAM }),
      );
      participantModel.findOne
        .mockReturnValueOnce(query({ name: 'Lions' }))
        .mockReturnValue(query(null));

      await expect(
        service.addParticipant(CLUB, t._id.toString(), {
          playerUserIds: [P1, P2],
          name: 'Tigers',
        }),
      ).rejects.toThrow(/Lions/);
    });

    it('allows one player per individual entry', async () => {
      const { service, t } = buildService();

      await expect(
        service.addParticipant(CLUB, t._id.toString(), {
          playerUserIds: [P1, P2],
        }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('requires the captain to be on the team', async () => {
      const { service, t } = buildService(
        tournamentDoc({ participantType: ParticipantType.TEAM }),
      );

      await expect(
        service.addParticipant(CLUB, t._id.toString(), {
          playerUserIds: [P1, P2],
          name: 'Tigers',
          captainUserId: P3,
        }),
      ).rejects.toThrow(/captain/);
    });
  });

  it('cannot reach another club’s tournament', async () => {
    const { service, tournamentModel } = buildService();
    tournamentModel.findOne.mockResolvedValue(null);

    await expect(
      service.detailForClub(CLUB, new Types.ObjectId().toString()),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('refuses sets for a team tournament', async () => {
    const { service } = buildService();

    await expect(
      service.create(CLUB, CLUB, {
        name: 'Team Cup',
        participantType: ParticipantType.TEAM,
        format: TournamentFormat.KNOCKOUT,
        scoring: { mode: 'sets' },
      }),
    ).rejects.toThrow(/individual/);
  });

  describe('generate', () => {
    it('schedules a league, starts the tournament and tells its players', async () => {
      const t = tournamentDoc();
      const { service, participantModel, fixtureModel, notifications } =
        buildService(t);
      const parts = [
        participantDoc([P1], { seed: 1 }),
        participantDoc([P2], { seed: 2 }),
        participantDoc([P3], { seed: 3 }),
      ];
      participantModel.find.mockReturnValue(query(parts));

      await service.generate(CLUB, t._id.toString());
      await flush();

      const inserted = fixtureModel.insertMany.mock.calls[0][0];
      // Three players, everyone meets once.
      expect(inserted).toHaveLength(3);
      expect(inserted[0]).toMatchObject({
        tournamentId: t._id.toString(),
        stage: 'league',
      });
      expect(t.status).toBe(TournamentStatus.RUNNING);
      expect(notifications.emitFresh).toHaveBeenCalledTimes(3);
      expect(notifications.emitFresh).toHaveBeenCalledWith(
        expect.objectContaining({
          userId: P1,
          type: 'TOURNAMENT_SCHEDULED',
          params: expect.objectContaining({
            actorName: 'Zamalek',
            tournamentName: 'Winter Cup',
          }),
        }),
      );
    });

    it('stays quiet when the tournament is hidden from players', async () => {
      const t = tournamentDoc({ visibleToPlayers: false });
      const { service, participantModel, notifications } = buildService(t);
      participantModel.find.mockReturnValue(
        query([participantDoc([P1]), participantDoc([P2])]),
      );

      await service.generate(CLUB, t._id.toString());
      await flush();

      expect(notifications.emitFresh).not.toHaveBeenCalled();
    });

    it('refuses to regenerate once results are in', async () => {
      const { service, t, fixtureModel } = buildService();
      fixtureModel.countDocuments.mockResolvedValue(1);

      await expect(
        service.generate(CLUB, t._id.toString()),
      ).rejects.toThrow(/Results are already in/);
    });
  });

  describe('recordResult', () => {
    it('moves a knockout winner into the next round and tells both sides', async () => {
      const t = tournamentDoc({
        format: TournamentFormat.KNOCKOUT,
        status: TournamentStatus.RUNNING,
      });
      const { service, participantModel, fixtureModel, notifications } =
        buildService(t);
      const a = participantDoc([P1]);
      const b = participantDoc([P2]);
      const fixture = {
        _id: new Types.ObjectId(),
        tournamentId: t._id.toString(),
        stage: 'knockout',
        round: 1,
        matchNo: 1,
        aId: a._id.toString(),
        bId: b._id.toString(),
        status: 'pending',
        nextMatchNo: 1,
        nextSlot: 'a',
        winnerId: null as string | null,
        set: jest.fn(function (this: Record<string, unknown>, v: object) {
          Object.assign(this, v);
        }),
        save: jest.fn().mockResolvedValue(undefined),
      };
      const next = {
        status: 'pending',
        set: jest.fn(),
        save: jest.fn().mockResolvedValue(undefined),
      };
      fixtureModel.findOne
        .mockResolvedValueOnce(fixture)
        .mockResolvedValueOnce(next);
      participantModel.find.mockReturnValue(query([a, b]));

      await service.recordResult(CLUB, t._id.toString(), fixture._id.toString(), {
        scoreA: 1,
        scoreB: 3,
      });
      await flush();

      expect(fixture.winnerId).toBe(b._id.toString());
      expect(next.set).toHaveBeenCalledWith('aId', b._id.toString());
      expect(notifications.emitFresh).toHaveBeenCalledWith(
        expect.objectContaining({
          userId: P1,
          type: 'TOURNAMENT_RESULT',
          entityId: fixture._id.toString(),
        }),
      );
    });
  });

  describe('player portal', () => {
    it('only looks at published tournaments of the player’s clubs', async () => {
      const { service, tournamentModel } = buildService();

      await service.listForPlayer(P1);

      expect(tournamentModel.find).toHaveBeenCalledWith({
        clubUserId: { $in: [CLUB] },
        visibleToPlayers: true,
        status: { $ne: TournamentStatus.DRAFT },
      });
    });

    it('shows nothing to a player with no club', async () => {
      const { service, clubPlayers, tournamentModel } = buildService();
      clubPlayers.clubIdsForPlayer.mockResolvedValue([]);

      await expect(service.listForPlayer(P1)).resolves.toEqual([]);
      expect(tournamentModel.find).not.toHaveBeenCalled();
    });
  });
});
