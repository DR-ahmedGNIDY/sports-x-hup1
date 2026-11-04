import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

// Every reference id in these three collections is stored as a string.
// That is how the rest of this database actually holds user ids, and the
// queries here never rely on Mongoose casting one representation into the
// other — a string filter only ever matches a string.

export enum ParticipantType {
  INDIVIDUAL = 'individual',
  TEAM = 'team',
}

export enum TournamentFormat {
  LEAGUE = 'league',
  KNOCKOUT = 'knockout',
  GROUPS_KNOCKOUT = 'groups_knockout',
}

export enum TournamentStatus {
  DRAFT = 'draft',
  RUNNING = 'running',
  FINISHED = 'finished',
}

@Schema({ _id: false })
export class ScoringSettings {
  @Prop({ enum: ['goals', 'sets'], default: 'goals' })
  mode: 'goals' | 'sets';

  /** Best of N sets — individual tournaments only, always odd. */
  @Prop({ default: 3, min: 1, max: 7 })
  bestOf: number;

  @Prop({ default: 11, min: 1, max: 100 })
  pointsPerSet: number;

  @Prop({ default: true })
  winByTwo: boolean;

  /** Optional cap, where a one-point win ends the set. */
  @Prop({ type: Number, default: null })
  maxPointsPerSet: number | null;
}

@Schema({ _id: false })
export class LeagueSettings {
  @Prop({ default: 3, min: 0, max: 10 })
  winPoints: number;

  @Prop({ default: 1, min: 0, max: 10 })
  drawPoints: number;

  @Prop({ default: 0, min: 0, max: 10 })
  lossPoints: number;

  /** Home and away. */
  @Prop({ default: false })
  doubleRound: boolean;

  @Prop({ default: true })
  allowDraws: boolean;
}

@Schema({ _id: false })
export class GroupSettings {
  @Prop({ default: 2, min: 2, max: 16 })
  count: number;

  @Prop({ default: 2, min: 1, max: 8 })
  qualifiersPerGroup: number;
}

@Schema({ _id: false })
export class KnockoutSettings {
  @Prop({ default: true })
  penaltiesEnabled: boolean;

  @Prop({ default: 5, min: 1, max: 20 })
  penaltiesCount: number;
}

export type TournamentDocument = HydratedDocument<Tournament>;

/** A league, a cup, or groups then a cup — of single players or teams. */
@Schema({ timestamps: true, collection: 'tournaments' })
export class Tournament {
  /** The club that owns it. There are no branches in this app. */
  @Prop({ type: String, required: true, index: true })
  clubUserId: string;

  @Prop({ required: true, trim: true, minlength: 2, maxlength: 150 })
  name: string;

  /** One of the app's sports, optional. */
  @Prop({ type: String, default: null })
  sportId: string | null;

  @Prop({ trim: true, default: '', maxlength: 50 })
  ageGroup: string;

  /** 'YYYY-MM-DD'. */
  @Prop({ type: String, default: null })
  startDate: string | null;

  @Prop({ type: String, default: null })
  endDate: string | null;

  @Prop({ trim: true, default: '', maxlength: 1000 })
  notes: string;

  @Prop({ required: true, enum: ParticipantType })
  participantType: ParticipantType;

  @Prop({ required: true, enum: TournamentFormat })
  format: TournamentFormat;

  /** random: the system shuffles. directed: the admin's seed order. */
  @Prop({ enum: ['random', 'directed'], default: 'random' })
  drawMode: 'random' | 'directed';

  @Prop({ type: ScoringSettings, default: () => ({}) })
  scoring: ScoringSettings;

  @Prop({ type: LeagueSettings, default: () => ({}) })
  league: LeagueSettings;

  @Prop({ type: GroupSettings, default: () => ({}) })
  groups: GroupSettings;

  @Prop({ type: KnockoutSettings, default: () => ({}) })
  knockout: KnockoutSettings;

  @Prop({ enum: TournamentStatus, default: TournamentStatus.DRAFT })
  status: TournamentStatus;

  /** Shown in the players' portal once its schedule is published. */
  @Prop({ default: true })
  visibleToPlayers: boolean;

  @Prop({ type: String, default: null })
  createdByUserId: string | null;
}

export const TournamentSchema = SchemaFactory.createForClass(Tournament);
TournamentSchema.index({ clubUserId: 1, status: 1, createdAt: -1 });

export type TournamentParticipantDocument =
  HydratedDocument<TournamentParticipant>;

/** One side: a single player, or a team the admin picks by hand. */
@Schema({ timestamps: true, collection: 'tournament_participants' })
export class TournamentParticipant {
  @Prop({ type: String, required: true, index: true })
  tournamentId: string;

  @Prop({ required: true, trim: true, maxlength: 100 })
  name: string;

  /** Exactly one for an individual tournament; one or more for a team. */
  @Prop({ type: [String], required: true })
  playerUserIds: string[];

  @Prop({ type: String, default: null })
  captainUserId: string | null;

  /** Directed draw position; 1 is the top seed. */
  @Prop({ type: Number, default: null })
  seed: number | null;

  /** Set once groups are drawn. */
  @Prop({ type: Number, default: null })
  groupIndex: number | null;
}

export const TournamentParticipantSchema = SchemaFactory.createForClass(
  TournamentParticipant,
);
TournamentParticipantSchema.index({ playerUserIds: 1 });

export type FixtureStage = 'league' | 'group' | 'knockout';
export type FixtureStatus = 'pending' | 'played' | 'bye';

export type TournamentFixtureDocument = HydratedDocument<TournamentFixture>;

@Schema({ _id: false })
export class SetScore {
  @Prop({ required: true })
  a: number;

  @Prop({ required: true })
  b: number;
}

/** One match. Separate from calendar events. */
@Schema({ timestamps: true, collection: 'tournament_fixtures' })
export class TournamentFixture {
  @Prop({ type: String, required: true })
  tournamentId: string;

  @Prop({ required: true, enum: ['league', 'group', 'knockout'] })
  stage: FixtureStage;

  @Prop({ type: Number, default: null })
  groupIndex: number | null;

  /** From 1. */
  @Prop({ required: true })
  round: number;

  /** Order within the round, from 1. */
  @Prop({ required: true })
  matchNo: number;

  /** Participant ids; null until a knockout seat is decided. */
  @Prop({ type: String, default: null })
  aId: string | null;

  @Prop({ type: String, default: null })
  bId: string | null;

  /** Goals or points — or, with sets, sets won. */
  @Prop({ type: Number, default: null })
  scoreA: number | null;

  @Prop({ type: Number, default: null })
  scoreB: number | null;

  @Prop({ type: [SetScore], default: [] })
  sets: SetScore[];

  @Prop({ type: Number, default: null })
  penaltiesA: number | null;

  @Prop({ type: Number, default: null })
  penaltiesB: number | null;

  /** Null for a draw. */
  @Prop({ type: String, default: null })
  winnerId: string | null;

  @Prop({ enum: ['pending', 'played', 'bye'], default: 'pending' })
  status: FixtureStatus;

  // Knockout: where the winner goes next.
  @Prop({ type: Number, default: null })
  nextMatchNo: number | null;

  @Prop({ type: String, enum: ['a', 'b', null], default: null })
  nextSlot: 'a' | 'b' | null;

  /** 'YYYY-MM-DD' and 'HH:mm'. */
  @Prop({ type: String, default: null })
  date: string | null;

  @Prop({ type: String, default: null })
  time: string | null;

  @Prop({ trim: true, default: '', maxlength: 200 })
  location: string;
}

export const TournamentFixtureSchema =
  SchemaFactory.createForClass(TournamentFixture);
TournamentFixtureSchema.index({
  tournamentId: 1,
  stage: 1,
  round: 1,
  matchNo: 1,
});
