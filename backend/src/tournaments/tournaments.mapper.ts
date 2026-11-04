import {
  TournamentDocument,
  TournamentFixtureDocument,
  TournamentParticipantDocument,
} from './schemas/tournament.schemas';
import { TournamentDetail } from './tournaments.service';

export function toTournamentView(t: TournamentDocument) {
  return {
    id: t._id.toString(),
    name: t.name,
    sportId: t.sportId,
    ageGroup: t.ageGroup,
    startDate: t.startDate,
    endDate: t.endDate,
    notes: t.notes,
    participantType: t.participantType,
    format: t.format,
    drawMode: t.drawMode,
    scoring: {
      mode: t.scoring.mode,
      bestOf: t.scoring.bestOf,
      pointsPerSet: t.scoring.pointsPerSet,
      winByTwo: t.scoring.winByTwo,
      maxPointsPerSet: t.scoring.maxPointsPerSet,
    },
    league: {
      winPoints: t.league.winPoints,
      drawPoints: t.league.drawPoints,
      lossPoints: t.league.lossPoints,
      doubleRound: t.league.doubleRound,
      allowDraws: t.league.allowDraws,
    },
    groups: {
      count: t.groups.count,
      qualifiersPerGroup: t.groups.qualifiersPerGroup,
    },
    knockout: {
      penaltiesEnabled: t.knockout.penaltiesEnabled,
      penaltiesCount: t.knockout.penaltiesCount,
    },
    status: t.status,
    visibleToPlayers: t.visibleToPlayers,
  };
}

export function toParticipantView(p: TournamentParticipantDocument) {
  return {
    id: p._id.toString(),
    name: p.name,
    playerUserIds: p.playerUserIds,
    captainUserId: p.captainUserId,
    seed: p.seed,
    groupIndex: p.groupIndex,
  };
}

export function toFixtureView(f: TournamentFixtureDocument) {
  return {
    id: f._id.toString(),
    stage: f.stage,
    groupIndex: f.groupIndex,
    round: f.round,
    matchNo: f.matchNo,
    aId: f.aId,
    bId: f.bId,
    scoreA: f.scoreA,
    scoreB: f.scoreB,
    sets: (f.sets ?? []).map((s) => ({ a: s.a, b: s.b })),
    penaltiesA: f.penaltiesA,
    penaltiesB: f.penaltiesB,
    winnerId: f.winnerId,
    status: f.status,
    nextMatchNo: f.nextMatchNo,
    nextSlot: f.nextSlot,
    date: f.date,
    time: f.time,
    location: f.location,
  };
}

export function toDetailView(detail: TournamentDetail) {
  return {
    tournament: toTournamentView(detail.tournament),
    participants: detail.participants.map(toParticipantView),
    players: detail.players,
    fixtures: detail.fixtures.map(toFixtureView),
    standings: detail.standings,
    myParticipantId: detail.myParticipantId,
  };
}
