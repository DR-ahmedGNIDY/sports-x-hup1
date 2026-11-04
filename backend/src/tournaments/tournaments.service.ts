import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { ClubPlayersService } from '../club-players/club-players.service';
import { ClubsService } from '../clubs/clubs.service';
import { NotificationsService } from '../notifications/notifications.service';
import {
  NotificationActorRole,
  NotificationEntityType,
  NotificationType,
} from '../notifications/schemas/notification.schema';
import { profilePhotoUrl } from '../players/players.mapper';
import { PlayersService } from '../players/players.service';
import {
  ParticipantDto,
  RecordResultDto,
  UpdateFixtureDto,
  UpsertTournamentDto,
} from './dto/tournament.dto';
import {
  ParticipantType,
  Tournament,
  TournamentDocument,
  TournamentFixture,
  TournamentFixtureDocument,
  TournamentFormat,
  TournamentParticipant,
  TournamentParticipantDocument,
  TournamentStatus,
} from './schemas/tournament.schemas';
import * as E from './tournament-engine';

// Settings that shape the draw and schedule — editable only in draft.
// Everything else (name, dates, notes, visibility) any time.
const SETTINGS = [
  'participantType',
  'format',
  'drawMode',
  'scoring',
  'league',
  'groups',
  'knockout',
  'sportId',
  'ageGroup',
] as const;
const ALWAYS = [
  'name',
  'notes',
  'startDate',
  'endDate',
  'visibleToPlayers',
] as const;
const NESTED = new Set(['scoring', 'league', 'groups', 'knockout']);

const STAGE_ORDER = { league: 0, group: 1, knockout: 2 } as const;

const isId = (v: unknown) => Types.ObjectId.isValid(String(v));

export interface TournamentPlayerView {
  userId: string;
  firstName?: string;
  lastName?: string;
  photoUrl?: string;
}

export interface TournamentDetail {
  tournament: TournamentDocument;
  participants: TournamentParticipantDocument[];
  players: TournamentPlayerView[];
  fixtures: TournamentFixtureDocument[];
  standings: Array<{ groupIndex: number | null; rows: E.StandingRow[] }>;
  myParticipantId: string | null;
}

@Injectable()
export class TournamentsService {
  private readonly logger = new Logger(TournamentsService.name);

  constructor(
    @InjectModel(Tournament.name)
    private readonly tournamentModel: Model<Tournament>,
    @InjectModel(TournamentParticipant.name)
    private readonly participantModel: Model<TournamentParticipant>,
    @InjectModel(TournamentFixture.name)
    private readonly fixtureModel: Model<TournamentFixture>,
    private readonly clubPlayers: ClubPlayersService,
    private readonly players: PlayersService,
    private readonly clubs: ClubsService,
    private readonly notifications: NotificationsService,
  ) {}

  // ------------------------------------------------------------ tournaments

  async listForClub(clubId: string) {
    const items = await this.tournamentModel
      .find({ clubUserId: clubId })
      .sort({ createdAt: -1 })
      .limit(200);
    return this.withParticipantCounts(items);
  }

  async detailForClub(clubId: string, id: string): Promise<TournamentDetail> {
    return this.buildDetail(await this.load(clubId, id));
  }

  async create(
    clubId: string,
    actorUserId: string,
    dto: UpsertTournamentDto,
  ): Promise<TournamentDocument> {
    if (!dto.name || !dto.participantType || !dto.format) {
      throw new BadRequestException(
        'name, participantType and format are required.',
      );
    }
    const t = new this.tournamentModel({
      ...this.pick(dto, [...SETTINGS, ...ALWAYS]),
      clubUserId: clubId,
      status: TournamentStatus.DRAFT,
      createdByUserId: actorUserId,
    });
    this.validateSettings(t);
    return t.save();
  }

  async update(
    clubId: string,
    id: string,
    dto: UpsertTournamentDto,
  ): Promise<TournamentDocument> {
    const t = await this.load(clubId, id);
    const settings = this.pick(dto, SETTINGS);
    if (Object.keys(settings).length) this.assertDraft(t);

    if (
      settings.participantType &&
      settings.participantType !== t.participantType &&
      (await this.participantModel.countDocuments({ tournamentId: id }))
    ) {
      throw new BadRequestException(
        'Remove the participants before changing the participant type.',
      );
    }
    // Nested settings are merged field by field, so editing one leaves the
    // rest of its group alone.
    for (const [key, value] of Object.entries(settings)) {
      if (NESTED.has(key) && value && typeof value === 'object') {
        for (const [sub, v] of Object.entries(value)) {
          if (v !== undefined) t.set(`${key}.${sub}`, v);
        }
      } else {
        t.set(key, value);
      }
    }
    t.set(this.pick(dto, ALWAYS));
    this.validateSettings(t);
    return t.save();
  }

  async remove(clubId: string, id: string): Promise<void> {
    const t = await this.load(clubId, id);
    await Promise.all([
      this.fixtureModel.deleteMany({ tournamentId: id }),
      this.participantModel.deleteMany({ tournamentId: id }),
    ]);
    await t.deleteOne();
  }

  // ----------------------------------------------------------- participants

  /** The club's whole roster, for the participant picker. */
  async eligiblePlayers(
    clubId: string,
    id: string,
  ): Promise<TournamentPlayerView[]> {
    await this.load(clubId, id);
    const userIds = await this.clubPlayers.rosterUserIds(clubId);
    if (userIds.length === 0) return [];
    const profiles = await this.players.findManyByUserIds(userIds);
    return profiles.map((p) => ({
      userId: p.userId.toString(),
      firstName: p.firstName,
      lastName: p.lastName,
      photoUrl: profilePhotoUrl(p),
    }));
  }

  async addParticipant(
    clubId: string,
    id: string,
    dto: ParticipantDto,
  ): Promise<TournamentParticipantDocument> {
    const t = await this.load(clubId, id);
    this.assertDraft(t);
    const fields = await this.participantFields(t, dto);
    const last = await this.participantModel
      .findOne({ tournamentId: id })
      .sort({ seed: -1 });
    return this.participantModel.create({
      ...fields,
      tournamentId: id,
      seed: (last?.seed ?? 0) + 1,
    });
  }

  async updateParticipant(
    clubId: string,
    id: string,
    participantId: string,
    dto: ParticipantDto,
  ): Promise<TournamentParticipantDocument> {
    const t = await this.load(clubId, id);
    const p = await this.findParticipant(id, participantId);
    // Once the schedule exists only a team's name and captain may change —
    // never who plays.
    if (dto.playerUserIds !== undefined) this.assertDraft(t);
    p.set(await this.participantFields(t, dto, p));
    return p.save();
  }

  async removeParticipant(
    clubId: string,
    id: string,
    participantId: string,
  ): Promise<void> {
    const t = await this.load(clubId, id);
    this.assertDraft(t);
    const p = await this.findParticipant(id, participantId);
    await p.deleteOne();
  }

  /** The directed draw: [order] is every participant, top seed first. */
  async orderParticipants(
    clubId: string,
    id: string,
    order: string[],
  ): Promise<void> {
    const t = await this.load(clubId, id);
    this.assertDraft(t);
    const all = await this.participantModel.find({ tournamentId: id });
    const allIds = new Set(all.map((p) => p._id.toString()));
    if (
      order.length !== all.length ||
      new Set(order).size !== order.length ||
      !order.every((pid) => allIds.has(pid))
    ) {
      throw new BadRequestException(
        'The order must list every participant exactly once.',
      );
    }
    if (order.length) {
      await this.participantModel.bulkWrite(
        order.map((pid, i) => ({
          updateOne: {
            filter: { _id: new Types.ObjectId(pid) },
            update: { $set: { seed: i + 1 } },
          },
        })),
      );
    }
  }

  // ---------------------------------------------------------------- schedule

  async generate(clubId: string, id: string): Promise<TournamentDetail> {
    const t = await this.load(clubId, id);
    if (await this.countPlayed(id)) {
      throw new BadRequestException(
        'Results are already in. Clear them before regenerating the schedule.',
      );
    }

    const parts = await this.participantModel
      .find({ tournamentId: id })
      .sort({ seed: 1, createdAt: 1 });
    if (parts.length < 2) {
      throw new BadRequestException('Add at least two participants first.');
    }
    const order = E.orderForDraw(
      parts.map((p) => ({ id: p._id.toString(), seed: p.seed })),
      t.drawMode,
    );
    const rr = { doubleRound: Boolean(t.league.doubleRound) };

    let docs: Array<Partial<TournamentFixture>> = [];
    const groupOf = new Map<string, number>();
    if (t.format === TournamentFormat.LEAGUE) {
      docs = E.roundRobin(order, rr).map((f) => this.fixtureDoc(id, f, 'league'));
    } else if (t.format === TournamentFormat.KNOCKOUT) {
      docs = this.knockoutDocs(id, order);
    } else {
      const groups = E.splitGroups(order, t.groups.count);
      const smallest = Math.min(...groups.map((g) => g.length));
      if (t.groups.qualifiersPerGroup >= smallest) {
        throw new BadRequestException(
          `Qualifiers per group must be fewer than ${smallest}.`,
        );
      }
      groups.forEach((g, gi) => {
        g.forEach((pid) => groupOf.set(pid, gi));
        docs.push(
          ...E.roundRobin(g, rr).map((f) => ({
            ...this.fixtureDoc(id, f, 'group'),
            groupIndex: gi,
          })),
        );
      });
    }

    await this.fixtureModel.deleteMany({ tournamentId: id });
    await this.fixtureModel.insertMany(docs);
    await this.participantModel.bulkWrite(
      parts.map((p) => ({
        updateOne: {
          filter: { _id: p._id },
          update: {
            $set: { groupIndex: groupOf.get(p._id.toString()) ?? null },
          },
        },
      })),
    );
    t.status = TournamentStatus.RUNNING;
    await t.save();

    if (t.visibleToPlayers) {
      void this.notifyPlayers(
        t,
        parts.flatMap((p) => p.playerUserIds),
        NotificationType.TOURNAMENT_SCHEDULED,
        NotificationEntityType.TOURNAMENT,
        t._id.toString(),
      );
    }
    return this.buildDetail(t);
  }

  /** Back to set-up: the schedule goes, the participants stay. */
  async resetFixtures(clubId: string, id: string): Promise<void> {
    const t = await this.load(clubId, id);
    if (await this.countPlayed(id)) {
      throw new BadRequestException(
        'Clear the match results before deleting the schedule.',
      );
    }
    await this.fixtureModel.deleteMany({ tournamentId: id });
    await this.participantModel.updateMany(
      { tournamentId: id },
      { $set: { groupIndex: null } },
    );
    t.status = TournamentStatus.DRAFT;
    await t.save();
  }

  /** A match's date, time and place — or, before any result, its sides. */
  async updateFixture(
    clubId: string,
    id: string,
    fixtureId: string,
    dto: UpdateFixtureDto,
  ): Promise<TournamentFixtureDocument> {
    const t = await this.load(clubId, id);
    const f = await this.findFixture(id, fixtureId);
    if (dto.date !== undefined) f.date = dto.date;
    if (dto.time !== undefined) f.time = dto.time;
    if (dto.location !== undefined) f.location = dto.location.slice(0, 200);

    if (dto.aId !== undefined || dto.bId !== undefined) {
      if (f.status !== 'pending') {
        throw new BadRequestException(
          'The sides of a played match or a bye cannot change.',
        );
      }
      if (f.stage === 'knockout' && f.round > 1) {
        throw new BadRequestException(
          'Later knockout rounds are decided by results.',
        );
      }
      if (await this.countPlayed(t._id.toString())) {
        throw new BadRequestException(
          'Sides cannot change once results are in.',
        );
      }
      const na = String(dto.aId ?? f.aId);
      const nb = String(dto.bId ?? f.bId);
      if (na === nb) {
        throw new BadRequestException('A participant cannot play itself.');
      }
      const ps = await this.participantModel.find({
        tournamentId: id,
        _id: { $in: [na, nb].filter(isId).map((x) => new Types.ObjectId(x)) },
      });
      if (ps.length !== 2) {
        throw new BadRequestException(
          'Both sides must be participants in this tournament.',
        );
      }
      if (
        f.stage === 'group' &&
        ps.some((p) => p.groupIndex !== f.groupIndex)
      ) {
        throw new BadRequestException('Both sides must be in the same group.');
      }
      f.aId = na;
      f.bId = nb;
    }
    return f.save();
  }

  // ---------------------------------------------------------------- results

  async recordResult(
    clubId: string,
    id: string,
    fixtureId: string,
    dto: RecordResultDto,
  ): Promise<TournamentDetail> {
    const t = await this.load(clubId, id);
    if (t.status === TournamentStatus.DRAFT) {
      throw new BadRequestException('Generate the schedule first.');
    }
    const f = await this.findFixture(id, fixtureId);
    if (f.status === 'bye') {
      throw new BadRequestException('A bye has no result.');
    }
    if (!f.aId || !f.bId) {
      throw new BadRequestException('Both sides of this match are not set yet.');
    }
    const next = await this.nextOf(f);
    if (next && next.status === 'played') {
      throw new BadRequestException('Clear the next match’s result first.');
    }

    const r = E.evaluateResult(dto, t, f.stage);
    await this.guardGroupChange(t, f);

    f.set({
      scoreA: r.scoreA,
      scoreB: r.scoreB,
      sets: r.sets,
      penaltiesA: r.penaltiesA,
      penaltiesB: r.penaltiesB,
      winnerId: r.outcome === 'a' ? f.aId : r.outcome === 'b' ? f.bId : null,
      status: 'played',
    });
    await f.save();
    if (next) {
      next.set(f.nextSlot === 'a' ? 'aId' : 'bId', f.winnerId);
      await next.save();
    }
    await this.afterResultChange(t);

    if (t.visibleToPlayers) {
      const sides = await this.participantModel.find({
        _id: { $in: [f.aId, f.bId].map((x) => new Types.ObjectId(x!)) },
      });
      void this.notifyPlayers(
        t,
        sides.flatMap((p) => p.playerUserIds),
        NotificationType.TOURNAMENT_RESULT,
        NotificationEntityType.TOURNAMENT_FIXTURE,
        f._id.toString(),
      );
    }
    return this.buildDetail(t);
  }

  async clearResult(
    clubId: string,
    id: string,
    fixtureId: string,
  ): Promise<TournamentDetail> {
    const t = await this.load(clubId, id);
    const f = await this.findFixture(id, fixtureId);
    if (f.status !== 'played') {
      throw new BadRequestException('There is no result to clear.');
    }
    const next = await this.nextOf(f);
    if (next && next.status === 'played') {
      throw new BadRequestException('Clear the next match’s result first.');
    }
    await this.guardGroupChange(t, f);

    f.set({
      scoreA: null,
      scoreB: null,
      sets: [],
      penaltiesA: null,
      penaltiesB: null,
      winnerId: null,
      status: 'pending',
    });
    await f.save();
    if (next) {
      next.set(f.nextSlot === 'a' ? 'aId' : 'bId', null);
      await next.save();
    }
    await this.afterResultChange(t);
    return this.buildDetail(t);
  }

  // ------------------------------------------------------------ player view

  /**
   * Published tournaments of every club the player is on the roster of,
   * read-only, each flagged when the player takes part.
   */
  async listForPlayer(playerUserId: string) {
    const clubIds = await this.clubPlayers.clubIdsForPlayer(playerUserId);
    if (clubIds.length === 0) return [];
    const items = await this.tournamentModel
      .find(this.playerFilter(clubIds))
      .sort({ createdAt: -1 })
      .limit(100);
    const mine = await this.participantModel
      .find({
        tournamentId: { $in: items.map((t) => t._id.toString()) },
        playerUserIds: playerUserId,
      })
      .select('tournamentId');
    const mineSet = new Set(mine.map((p) => p.tournamentId));
    const counted = await this.withParticipantCounts(items);
    return counted.map((row) => ({
      ...row,
      isParticipant: mineSet.has(row.tournament._id.toString()),
    }));
  }

  async detailForPlayer(
    playerUserId: string,
    id: string,
  ): Promise<TournamentDetail> {
    const clubIds = await this.clubPlayers.clubIdsForPlayer(playerUserId);
    const t = isId(id)
      ? await this.tournamentModel.findOne({
          _id: new Types.ObjectId(id),
          ...this.playerFilter(clubIds),
        })
      : null;
    if (!t) throw new NotFoundException('Tournament not found.');
    return this.buildDetail(t, playerUserId);
  }

  // ---------------------------------------------------------------- helpers

  private playerFilter(clubIds: string[]) {
    return {
      clubUserId: { $in: clubIds },
      visibleToPlayers: true,
      status: { $ne: TournamentStatus.DRAFT },
    };
  }

  private async load(clubId: string, id: string): Promise<TournamentDocument> {
    const t = isId(id)
      ? await this.tournamentModel.findOne({
          _id: new Types.ObjectId(id),
          clubUserId: clubId,
        })
      : null;
    if (!t) throw new NotFoundException('Tournament not found.');
    return t;
  }

  private assertDraft(t: TournamentDocument) {
    if (t.status !== TournamentStatus.DRAFT) {
      throw new BadRequestException(
        'This cannot change once the schedule exists. Delete the schedule first.',
      );
    }
  }

  private validateSettings(t: TournamentDocument) {
    if (
      t.format === TournamentFormat.GROUPS_KNOCKOUT &&
      t.groups.count < 2
    ) {
      throw new BadRequestException('Groups need at least two groups.');
    }
    if (t.scoring.mode === 'sets') {
      if (t.participantType !== ParticipantType.INDIVIDUAL) {
        throw new BadRequestException(
          'Scoring by sets is for individual tournaments.',
        );
      }
      if (t.scoring.bestOf % 2 === 0) {
        throw new BadRequestException('The number of sets must be odd.');
      }
      if (
        t.scoring.maxPointsPerSet &&
        t.scoring.maxPointsPerSet < t.scoring.pointsPerSet
      ) {
        throw new BadRequestException(
          'The set cap must be above the points per set.',
        );
      }
    }
    if (t.startDate && t.endDate && t.endDate < t.startDate) {
      throw new BadRequestException('endDate must not be before startDate.');
    }
  }

  private pick<K extends string>(
    src: object,
    keys: readonly K[],
  ): Partial<Record<K, unknown>> {
    const record = src as Record<string, unknown>;
    return Object.fromEntries(
      keys
        .filter((k) => record[k] !== undefined)
        .map((k) => [k, record[k]]),
    ) as Partial<Record<K, unknown>>;
  }

  private async participantFields(
    t: TournamentDocument,
    dto: ParticipantDto,
    existing?: TournamentParticipantDocument,
  ) {
    const requested = dto.playerUserIds ?? existing?.playerUserIds ?? [];
    const ids = [...new Set(requested.map(String))];
    if (ids.length === 0) {
      throw new BadRequestException('Pick at least one player.');
    }
    if (t.participantType === ParticipantType.INDIVIDUAL && ids.length !== 1) {
      throw new BadRequestException(
        'In an individual tournament each participant is one player.',
      );
    }

    // Only this club's own players.
    const roster = new Set(
      await this.clubPlayers.rosterUserIds(t.clubUserId),
    );
    if (!ids.every((pid) => roster.has(pid))) {
      throw new BadRequestException('Some players are not in this club.');
    }

    // A player is in at most one participant per tournament.
    const clash = await this.participantModel.findOne({
      tournamentId: t._id.toString(),
      playerUserIds: { $in: ids },
      ...(existing ? { _id: { $ne: existing._id } } : {}),
    });
    if (clash) {
      throw new BadRequestException(
        `A player is already entered in "${clash.name}".`,
      );
    }

    let name = (dto.name ?? existing?.name ?? '').trim();
    if (t.participantType === ParticipantType.INDIVIDUAL) {
      const [profile] = await this.players.findManyByUserIds(ids);
      name =
        [profile?.firstName, profile?.lastName]
          .filter(Boolean)
          .join(' ')
          .trim() || name || 'Player';
    }
    if (!name) throw new BadRequestException('A team name is required.');
    if (name.length > 100) {
      throw new BadRequestException('The name is too long.');
    }

    const captain =
      dto.captainUserId !== undefined
        ? dto.captainUserId
        : (existing?.captainUserId ?? null);
    if (captain && !ids.includes(String(captain))) {
      throw new BadRequestException('The captain must be one of the team.');
    }
    return {
      name,
      playerUserIds: ids,
      captainUserId:
        t.participantType === ParticipantType.TEAM ? captain || null : null,
    };
  }

  private async findParticipant(
    tournamentId: string,
    participantId: string,
  ): Promise<TournamentParticipantDocument> {
    const p = isId(participantId)
      ? await this.participantModel.findOne({
          _id: new Types.ObjectId(participantId),
          tournamentId,
        })
      : null;
    if (!p) throw new NotFoundException('Participant not found.');
    return p;
  }

  private async findFixture(
    tournamentId: string,
    fixtureId: string,
  ): Promise<TournamentFixtureDocument> {
    const f = isId(fixtureId)
      ? await this.fixtureModel.findOne({
          _id: new Types.ObjectId(fixtureId),
          tournamentId,
        })
      : null;
    if (!f) throw new NotFoundException('Match not found.');
    return f;
  }

  private fixtureDoc(
    tournamentId: string,
    f: E.EngineFixture,
    stage: 'league' | 'group' | 'knockout',
  ): Partial<TournamentFixture> {
    return {
      tournamentId,
      stage,
      round: f.round,
      matchNo: f.matchNo,
      aId: f.aId,
      bId: f.bId,
      status: f.status,
      winnerId: f.winnerId ?? null,
      nextMatchNo: f.nextMatchNo ?? null,
      nextSlot: f.nextSlot ?? null,
    };
  }

  private knockoutDocs(tournamentId: string, ids: string[]) {
    return E.knockoutBracket(ids).map((f) =>
      this.fixtureDoc(tournamentId, f, 'knockout'),
    );
  }

  private countPlayed(tournamentId: string) {
    return this.fixtureModel.countDocuments({ tournamentId, status: 'played' });
  }

  private nextOf(f: TournamentFixtureDocument) {
    return f.stage === 'knockout' && f.nextMatchNo
      ? this.fixtureModel.findOne({
          tournamentId: f.tournamentId,
          stage: 'knockout',
          round: f.round + 1,
          matchNo: f.nextMatchNo,
        })
      : Promise.resolve(null);
  }

  /**
   * A group result changing after the knockout bracket was drawn: redraw it
   * if none of it has been played, refuse otherwise.
   */
  private async guardGroupChange(
    t: TournamentDocument,
    f: TournamentFixtureDocument,
  ) {
    if (f.stage !== 'group') return;
    const tournamentId = t._id.toString();
    const ko = await this.fixtureModel.find({
      tournamentId,
      stage: 'knockout',
    });
    if (!ko.length) return;
    if (ko.some((k) => k.status === 'played')) {
      throw new BadRequestException(
        'The knockout stage has started — group results can no longer change.',
      );
    }
    await this.fixtureModel.deleteMany({ tournamentId, stage: 'knockout' });
  }

  /**
   * After any result change: draw the knockout stage once every group match
   * is in, and move the tournament between running and finished.
   */
  private async afterResultChange(t: TournamentDocument) {
    const tournamentId = t._id.toString();
    const fixtures: Array<Partial<TournamentFixture>> =
      await this.fixtureModel.find({ tournamentId });
    const done = (list: Array<Partial<TournamentFixture>>) =>
      list.length > 0 && list.every((f) => f.status !== 'pending');

    if (t.format === TournamentFormat.GROUPS_KNOCKOUT) {
      const groupFx = fixtures.filter((f) => f.stage === 'group');
      if (done(groupFx) && !fixtures.some((f) => f.stage === 'knockout')) {
        const parts = await this.participantModel.find({ tournamentId });
        const standings = this.standingsFor(
          t,
          parts,
          fixtures as TournamentFixtureDocument[],
        ).map((g) => g.rows);
        const docs = this.knockoutDocs(
          tournamentId,
          E.qualifiersFromGroups(standings, t.groups.qualifiersPerGroup),
        );
        await this.fixtureModel.insertMany(docs);
        fixtures.push(...docs);
      }
    }

    let finished: boolean;
    if (t.format === TournamentFormat.LEAGUE) {
      finished = done(fixtures);
    } else {
      const ko = fixtures.filter((f) => f.stage === 'knockout');
      const finalRound = Math.max(0, ...ko.map((f) => f.round ?? 0));
      finished = done(ko.filter((f) => f.round === finalRound));
    }
    const status = finished
      ? TournamentStatus.FINISHED
      : TournamentStatus.RUNNING;
    if (t.status !== status) {
      t.status = status;
      await t.save();
    }
  }

  private toEngine(f: TournamentFixtureDocument): E.StandingsFixture {
    return {
      aId: f.aId,
      bId: f.bId,
      status: f.status,
      forA: f.scoreA ?? 0,
      forB: f.scoreB ?? 0,
      outcome: !f.winnerId ? 'draw' : f.winnerId === f.aId ? 'a' : 'b',
    };
  }

  private standingsFor(
    t: TournamentDocument,
    participants: TournamentParticipantDocument[],
    fixtures: TournamentFixtureDocument[],
  ) {
    if (t.format === TournamentFormat.LEAGUE) {
      return [
        {
          groupIndex: null,
          rows: E.computeStandings(
            participants.map((p) => p._id.toString()),
            fixtures.filter((f) => f.stage === 'league').map((f) => this.toEngine(f)),
            t.league,
          ),
        },
      ];
    }
    if (t.format === TournamentFormat.GROUPS_KNOCKOUT) {
      const groups = [
        ...new Set(
          participants
            .map((p) => p.groupIndex)
            .filter((g): g is number => g !== null && g !== undefined),
        ),
      ].sort((a, b) => a - b);
      return groups.map((g) => ({
        groupIndex: g,
        rows: E.computeStandings(
          participants
            .filter((p) => p.groupIndex === g)
            .map((p) => p._id.toString()),
          fixtures
            .filter((f) => f.stage === 'group' && f.groupIndex === g)
            .map((f) => this.toEngine(f)),
          t.league,
        ),
      }));
    }
    return [];
  }

  private async buildDetail(
    t: TournamentDocument,
    forPlayer?: string,
  ): Promise<TournamentDetail> {
    const tournamentId = t._id.toString();
    const [participants, fixtures] = await Promise.all([
      this.participantModel
        .find({ tournamentId })
        .sort({ seed: 1, createdAt: 1 }),
      this.fixtureModel.find({ tournamentId }),
    ]);
    fixtures.sort(
      (a, b) =>
        STAGE_ORDER[a.stage] - STAGE_ORDER[b.stage] ||
        (a.groupIndex ?? 0) - (b.groupIndex ?? 0) ||
        a.round - b.round ||
        a.matchNo - b.matchNo,
    );
    const playerIds = [
      ...new Set(participants.flatMap((p) => p.playerUserIds)),
    ];
    const profiles = playerIds.length
      ? await this.players.findManyByUserIds(playerIds)
      : [];
    const mine = forPlayer
      ? participants.find((p) => p.playerUserIds.includes(forPlayer))
      : null;
    return {
      tournament: t,
      participants,
      players: profiles.map((p) => ({
        userId: p.userId.toString(),
        firstName: p.firstName,
        lastName: p.lastName,
        photoUrl: profilePhotoUrl(p),
      })),
      fixtures,
      standings: this.standingsFor(t, participants, fixtures),
      myParticipantId: mine ? mine._id.toString() : null,
    };
  }

  private async withParticipantCounts(items: TournamentDocument[]) {
    const counts = await this.participantModel.aggregate<{
      _id: string;
      n: number;
    }>([
      { $match: { tournamentId: { $in: items.map((t) => t._id.toString()) } } },
      { $group: { _id: '$tournamentId', n: { $sum: 1 } } },
    ]);
    const byId = new Map(counts.map((c) => [c._id, c.n]));
    return items.map((t) => ({
      tournament: t,
      participantsCount: byId.get(t._id.toString()) ?? 0,
    }));
  }

  /**
   * Tells each player once — a player can sit in only one participant, but
   * de-duplicating costs nothing. Never throws: the schedule or result is
   * already saved.
   */
  private async notifyPlayers(
    t: TournamentDocument,
    playerUserIds: string[],
    type: NotificationType,
    entityType: NotificationEntityType,
    entityId: string,
  ): Promise<void> {
    try {
      const club = await this.clubs.getOrCreateForUser(t.clubUserId);
      await Promise.all(
        [...new Set(playerUserIds)].map((userId) =>
          // Fresh, not plain emit: a regenerated schedule or a corrected
          // result is news again.
          this.notifications.emitFresh({
            userId,
            type,
            entityType,
            entityId,
            params: {
              actorName: club.name,
              actorRole: NotificationActorRole.CLUB,
              tournamentName: t.name,
              tournamentId: t._id.toString(),
            },
          }),
        ),
      );
    } catch {
      this.logger.error(
        `Failed to notify players of tournament ${t._id.toString()}.`,
      );
    }
  }
}
