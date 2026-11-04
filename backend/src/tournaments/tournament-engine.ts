import { BadRequestException } from '@nestjs/common';

// The tournament rules as pure functions — draw, schedule, result checks and
// standings — with no database in sight, so every rule is testable on its
// own. Ids are plain strings throughout.

export type DrawMode = 'random' | 'directed';
export type Stage = 'league' | 'group' | 'knockout';
export type Outcome = 'a' | 'b' | 'draw';

export interface EngineFixture {
  round: number;
  matchNo: number;
  aId: string | null;
  bId: string | null;
  status: 'pending' | 'played' | 'bye';
  winnerId?: string | null;
  nextMatchNo?: number | null;
  nextSlot?: 'a' | 'b' | null;
}

export interface ScoringRules {
  mode: 'goals' | 'sets';
  bestOf: number;
  pointsPerSet: number;
  winByTwo: boolean;
  maxPointsPerSet?: number | null;
}

export interface LeagueRules {
  winPoints: number;
  drawPoints: number;
  lossPoints: number;
  allowDraws: boolean;
}

export interface KnockoutRules {
  penaltiesEnabled: boolean;
}

export interface ResultInput {
  scoreA?: number;
  scoreB?: number;
  sets?: Array<{ a: number; b: number }>;
  penaltiesA?: number;
  penaltiesB?: number;
}

export interface EvaluatedResult {
  outcome: Outcome;
  scoreA: number;
  scoreB: number;
  sets: Array<{ a: number; b: number }>;
  penaltiesA: number | null;
  penaltiesB: number | null;
}

export interface StandingsFixture {
  aId: string | null;
  bId: string | null;
  status: string;
  forA: number;
  forB: number;
  outcome: Outcome;
}

export interface StandingRow {
  id: string;
  played: number;
  won: number;
  drawn: number;
  lost: number;
  for: number;
  against: number;
  diff: number;
  points: number;
  position: number;
}

const bad = (message: string) => new BadRequestException(message);

/** Fisher–Yates; [rng] is injectable for tests. */
export function shuffle<T>(list: T[], rng: () => number = Math.random): T[] {
  const a = [...list];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

/**
 * The draw order. Directed: lowest seed first, unseeded last, ties in the
 * order given. Random: shuffled.
 */
export function orderForDraw(
  participants: Array<{ id: string; seed?: number | null }>,
  drawMode: DrawMode,
  rng?: () => number,
): string[] {
  if (drawMode === 'random') return shuffle(participants.map((p) => p.id), rng);
  return participants
    .map((p, i) => ({ ...p, i }))
    .sort(
      (x, y) =>
        (x.seed ?? Infinity) - (y.seed ?? Infinity) || x.i - y.i,
    )
    .map((p) => p.id);
}

/**
 * Everyone plays everyone (circle method). An odd count rests one side each
 * round. Home and away alternate so no one is always the first side.
 */
export function roundRobin(
  ids: string[],
  { doubleRound = false }: { doubleRound?: boolean } = {},
): EngineFixture[] {
  if (ids.length < 2) throw bad('At least two participants are needed.');
  const list: Array<string | null> = [...ids];
  if (list.length % 2) list.push(null);
  const n = list.length;
  const rounds: Array<Array<[string, string]>> = [];
  let arr = list;
  for (let r = 0; r < n - 1; r++) {
    const pairs: Array<[string, string]> = [];
    for (let i = 0; i < n / 2; i++) {
      const x = arr[i];
      const y = arr[n - 1 - i];
      if (x === null || y === null) continue;
      pairs.push(r % 2 === 0 ? [x, y] : [y, x]);
    }
    rounds.push(pairs);
    arr = [arr[0], arr[n - 1], ...arr.slice(1, n - 1)];
  }
  if (doubleRound) {
    rounds.push(
      ...rounds.map((pairs) => pairs.map(([x, y]) => [y, x] as [string, string])),
    );
  }
  const fixtures: EngineFixture[] = [];
  rounds.forEach((pairs, r) =>
    pairs.forEach(([a, b], m) =>
      fixtures.push({
        round: r + 1,
        matchNo: m + 1,
        aId: a,
        bId: b,
        status: 'pending',
      }),
    ),
  );
  return fixtures;
}

/** Snake distribution, so the seeds spread evenly across the groups. */
export function splitGroups(ids: string[], count: number): string[][] {
  if (!Number.isInteger(count) || count < 1) {
    throw bad('Invalid number of groups.');
  }
  if (ids.length < count * 2) {
    throw bad('Too few participants for this many groups.');
  }
  const groups: string[][] = Array.from({ length: count }, () => []);
  ids.forEach((id, i) => {
    const row = Math.floor(i / count);
    const col = i % count;
    groups[row % 2 === 0 ? col : count - 1 - col].push(id);
  });
  return groups;
}

/** Standard bracket seating: seed 1 meets the last, 1 and 2 only in the final. */
export function bracketOrder(size: number): number[] {
  let order = [1];
  while (order.length < size) {
    const len = order.length * 2;
    order = order.flatMap((s) => [s, len + 1 - s]);
  }
  return order;
}

/** Moves a knockout winner into their seat in the next round. */
export function advanceWinner(
  fixtures: EngineFixture[],
  f: EngineFixture,
): EngineFixture | null {
  if (!f.nextMatchNo) return null;
  const next = fixtures.find(
    (x) => x.round === f.round + 1 && x.matchNo === f.nextMatchNo,
  );
  if (next) next[f.nextSlot === 'a' ? 'aId' : 'bId'] = f.winnerId ?? null;
  return next ?? null;
}

/**
 * A knockout bracket for [ids] in strength order (or shuffled). A count that
 * is not a power of two gives the top seeds a bye.
 */
export function knockoutBracket(ids: string[]): EngineFixture[] {
  if (ids.length < 2) throw bad('At least two participants are needed.');
  let size = 2;
  while (size < ids.length) size *= 2;
  const order = bracketOrder(size);
  const slot = (seed: number) => (seed <= ids.length ? ids[seed - 1] : null);

  const totalRounds = Math.log2(size);
  const fixtures: EngineFixture[] = [];
  for (let r = 1; r <= totalRounds; r++) {
    const count = size / 2 ** r;
    for (let m = 1; m <= count; m++) {
      fixtures.push({
        round: r,
        matchNo: m,
        aId: null,
        bId: null,
        status: 'pending',
        winnerId: null,
        nextMatchNo: r < totalRounds ? Math.ceil(m / 2) : null,
        nextSlot: r < totalRounds ? (m % 2 ? 'a' : 'b') : null,
      });
    }
  }
  fixtures
    .filter((f) => f.round === 1)
    .forEach((f, i) => {
      f.aId = slot(order[i * 2]);
      f.bId = slot(order[i * 2 + 1]);
      if (!f.aId || !f.bId) {
        f.status = 'bye';
        f.winnerId = f.aId || f.bId;
        advanceWinner(fixtures, f);
      }
    });
  return fixtures;
}

/** Checks one set against the tournament's rules; returns its winner. */
export function setWinner(
  { a, b }: { a: number; b: number },
  s: ScoringRules,
): 'a' | 'b' {
  if (!Number.isInteger(a) || !Number.isInteger(b) || a < 0 || b < 0) {
    throw bad('Invalid set score.');
  }
  const hi = Math.max(a, b);
  const lo = Math.min(a, b);
  if (hi === lo) throw bad('A set cannot end level.');
  const target = s.pointsPerSet;
  const cap = s.maxPointsPerSet || null;
  if (hi < target) throw bad(`A set ends at ${target} points.`);
  if (cap && hi > cap) throw bad(`A set is capped at ${cap} points.`);
  if (s.winByTwo) {
    const reachedCap = cap && hi === cap;
    if (!reachedCap) {
      if (hi - lo < 2) throw bad('A set must be won by two points.');
      // Past the target, a set only goes on until the gap is exactly two.
      if (hi > target && hi - lo !== 2) throw bad('Impossible set score.');
    }
  } else if (hi !== target) {
    throw bad(`A set ends at ${target} points.`);
  }
  return a > b ? 'a' : 'b';
}

/** Validates and scores one match for its [stage]. */
export function evaluateResult(
  input: ResultInput,
  rules: {
    scoring: ScoringRules;
    league: LeagueRules;
    knockout: KnockoutRules;
  },
  stage: Stage,
): EvaluatedResult {
  const { scoring } = rules;
  const isKnockout = stage === 'knockout';

  if (scoring.mode === 'sets') {
    const sets = input.sets ?? [];
    const need = Math.ceil(scoring.bestOf / 2);
    let wa = 0;
    let wb = 0;
    sets.forEach((set, i) => {
      if (wa === need || wb === need) {
        throw bad(`The match was already over before set ${i + 1}.`);
      }
      if (setWinner(set, scoring) === 'a') wa++;
      else wb++;
    });
    if (wa !== need && wb !== need) {
      throw bad(`One side must win ${need} sets.`);
    }
    return {
      outcome: wa > wb ? 'a' : 'b',
      scoreA: wa,
      scoreB: wb,
      sets: sets.map((s) => ({ a: s.a, b: s.b })),
      penaltiesA: null,
      penaltiesB: null,
    };
  }

  const { scoreA, scoreB } = input;
  if (
    !Number.isInteger(scoreA) ||
    !Number.isInteger(scoreB) ||
    scoreA! < 0 ||
    scoreB! < 0
  ) {
    throw bad('Invalid score.');
  }
  const result: EvaluatedResult = {
    outcome: 'draw',
    scoreA: scoreA!,
    scoreB: scoreB!,
    sets: [],
    penaltiesA: null,
    penaltiesB: null,
  };
  if (scoreA !== scoreB) {
    result.outcome = scoreA! > scoreB! ? 'a' : 'b';
  } else if (!isKnockout) {
    if (!rules.league.allowDraws) {
      throw bad('Draws are not allowed in this tournament.');
    }
  } else {
    if (!rules.knockout.penaltiesEnabled) {
      throw bad('A knockout match cannot end in a draw.');
    }
    const { penaltiesA, penaltiesB } = input;
    if (
      !Number.isInteger(penaltiesA) ||
      !Number.isInteger(penaltiesB) ||
      penaltiesA! < 0 ||
      penaltiesB! < 0 ||
      penaltiesA === penaltiesB
    ) {
      throw bad('Enter a penalty shoot-out score with a clear winner.');
    }
    result.penaltiesA = penaltiesA!;
    result.penaltiesB = penaltiesB!;
    result.outcome = penaltiesA! > penaltiesB! ? 'a' : 'b';
  }
  return result;
}

/**
 * The table from played matches: points, then goal (or set) difference,
 * then scored; exact ties broken by head-to-head, then by draw order.
 */
export function computeStandings(
  ids: string[],
  fixtures: StandingsFixture[],
  rules: Partial<LeagueRules> = {},
): StandingRow[] {
  const win = rules.winPoints ?? 3;
  const draw = rules.drawPoints ?? 1;
  const loss = rules.lossPoints ?? 0;
  const blank = (id: string): StandingRow => ({
    id,
    played: 0,
    won: 0,
    drawn: 0,
    lost: 0,
    for: 0,
    against: 0,
    diff: 0,
    points: 0,
    position: 0,
  });
  const rowsOf = (subset: string[]) => {
    const rows = new Map(subset.map((id) => [id, blank(id)]));
    for (const f of fixtures) {
      if (f.status !== 'played' || !f.aId || !f.bId) continue;
      const A = rows.get(f.aId);
      const B = rows.get(f.bId);
      if (!A || !B) continue;
      A.played++;
      B.played++;
      A.for += f.forA;
      A.against += f.forB;
      B.for += f.forB;
      B.against += f.forA;
      if (f.outcome === 'a') {
        A.won++;
        B.lost++;
        A.points += win;
        B.points += loss;
      } else if (f.outcome === 'b') {
        B.won++;
        A.lost++;
        B.points += win;
        A.points += loss;
      } else {
        A.drawn++;
        B.drawn++;
        A.points += draw;
        B.points += draw;
      }
    }
    for (const r of rows.values()) r.diff = r.for - r.against;
    return rows;
  };

  const cmp = (x: StandingRow, y: StandingRow) =>
    y.points - x.points || y.diff - x.diff || y.for - x.for;
  const sorted = [...rowsOf(ids).values()].sort(cmp);

  const result: StandingRow[] = [];
  for (let i = 0; i < sorted.length; ) {
    let j = i + 1;
    while (j < sorted.length && cmp(sorted[i], sorted[j]) === 0) j++;
    const tied = sorted.slice(i, j);
    if (tied.length > 1) {
      const h2h = rowsOf(tied.map((r) => r.id));
      tied.sort(
        (x, y) =>
          cmp(h2h.get(x.id)!, h2h.get(y.id)!) ||
          ids.indexOf(x.id) - ids.indexOf(y.id),
      );
    }
    result.push(...tied);
    i = j;
  }
  return result.map((r, i) => ({ ...r, position: i + 1 }));
}

/**
 * Group qualifiers as one seeded list — every group winner, then every
 * runner-up. With bracket seating (1 v last) two from one group cannot meet
 * in the first knockout round.
 */
export function qualifiersFromGroups(
  groupStandings: Array<Array<{ id: string }>>,
  perGroup: number,
): string[] {
  const out: string[] = [];
  for (let place = 0; place < perGroup; place++) {
    out.push(
      ...groupStandings
        .map((rows) => rows[place])
        .filter(Boolean)
        .map((r) => r.id),
    );
  }
  return out;
}
