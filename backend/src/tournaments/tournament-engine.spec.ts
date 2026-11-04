import * as E from './tournament-engine';

// Ported from the reference implementation's engine tests, case for case.

const ids = (n: number) => Array.from({ length: n }, (_, i) => `p${i + 1}`);
const pairKey = (f: E.EngineFixture) => [f.aId, f.bId].sort().join('-');

const league = { winPoints: 3, drawPoints: 1, lossPoints: 0, allowDraws: true };
const knockout = { penaltiesEnabled: true };
const rules = (scoring: Partial<E.ScoringRules>, overrides = {}) => ({
  scoring: {
    mode: 'sets' as const,
    bestOf: 3,
    pointsPerSet: 11,
    winByTwo: true,
    ...scoring,
  },
  league,
  knockout,
  ...overrides,
});

describe('tournament engine', () => {
  it('round robin: every pair meets exactly once (even and odd)', () => {
    for (const n of [2, 3, 4, 5, 8]) {
      const fx = E.roundRobin(ids(n));
      const keys = fx.map(pairKey);
      expect(keys.length).toBe((n * (n - 1)) / 2);
      expect(new Set(keys).size).toBe(keys.length);
      const rounds = new Map<number, Set<string | null>>();
      for (const f of fx) {
        const s = rounds.get(f.round) ?? new Set();
        expect(s.has(f.aId) || s.has(f.bId)).toBe(false);
        s.add(f.aId).add(f.bId);
        rounds.set(f.round, s);
      }
      expect(rounds.size).toBe(n % 2 ? n : n - 1);
    }
  });

  it('round robin double: each pair twice with swapped sides', () => {
    const fx = E.roundRobin(ids(4), { doubleRound: true });
    expect(fx).toHaveLength(12);
    expect(new Set(fx.map((f) => `${f.aId}>${f.bId}`)).size).toBe(12);
  });

  it('round robin needs at least 2', () => {
    expect(() => E.roundRobin(['x'])).toThrow(/two participants/);
  });

  it('directed draw follows seeds, unseeded last; random draw is a permutation', () => {
    const ps = [
      { id: 'a', seed: 3 },
      { id: 'b', seed: null },
      { id: 'c', seed: 1 },
      { id: 'd', seed: 2 },
    ];
    expect(E.orderForDraw(ps, 'directed')).toEqual(['c', 'd', 'a', 'b']);
    const r = E.orderForDraw(ps, 'random', () => 0.3);
    expect([...r].sort()).toEqual(['a', 'b', 'c', 'd']);
  });

  it('bracket order keeps top seeds apart', () => {
    expect(E.bracketOrder(4)).toEqual([1, 4, 2, 3]);
    expect(E.bracketOrder(8)).toEqual([1, 8, 4, 5, 2, 7, 3, 6]);
  });

  it('knockout with a power of two has no byes', () => {
    const fx = E.knockoutBracket(ids(8));
    expect(fx).toHaveLength(7);
    expect(fx.filter((f) => f.status === 'bye')).toHaveLength(0);
    expect([fx[0].aId, fx[0].bId]).toEqual(['p1', 'p8']);
  });

  it('knockout with 6: the top 2 seeds get byes into round 2', () => {
    const fx = E.knockoutBracket(ids(6));
    const byes = fx.filter((f) => f.status === 'bye');
    expect(byes.map((f) => f.winnerId).sort()).toEqual(['p1', 'p2']);
    const r2 = fx.filter((f) => f.round === 2);
    expect(r2[0].aId).toBe('p1');
    expect(r2[1].aId).toBe('p2');
    expect(fx.find((f) => f.round === 3)!.nextMatchNo).toBeNull();
  });

  it('knockout with 5 and 3', () => {
    expect(
      E.knockoutBracket(ids(5)).filter((f) => f.status === 'bye'),
    ).toHaveLength(3);
    const f3 = E.knockoutBracket(ids(3));
    expect(f3.filter((f) => f.status === 'bye')).toHaveLength(1);
    expect(f3.find((f) => f.round === 2)!.aId).toBe('p1');
  });

  it('advanceWinner moves the winner to the right slot', () => {
    const fx = E.knockoutBracket(ids(4));
    const m2 = fx.find((f) => f.round === 1 && f.matchNo === 2)!;
    m2.winnerId = m2.bId;
    E.advanceWinner(fx, m2);
    expect(fx.find((f) => f.round === 2)!.bId).toBe(m2.bId);
  });

  it('splits groups snake-wise and rejects too few', () => {
    expect(E.splitGroups(ids(8), 2)).toEqual([
      ['p1', 'p4', 'p5', 'p8'],
      ['p2', 'p3', 'p6', 'p7'],
    ]);
    expect(() => E.splitGroups(ids(3), 2)).toThrow();
  });

  it('qualifiers feed a bracket where group-mates do not meet first', () => {
    for (const groups of [2, 4]) {
      const g = Array.from({ length: groups }, (_, i) => [
        { id: `${i}-1` },
        { id: `${i}-2` },
      ]);
      const r1 = E.knockoutBracket(E.qualifiersFromGroups(g, 2)).filter(
        (f) => f.round === 1,
      );
      for (const f of r1) {
        expect(f.aId!.split('-')[0]).not.toBe(f.bId!.split('-')[0]);
      }
    }
  });

  describe('sets', () => {
    const setsT = rules({});

    it('accepts a valid best of 3', () => {
      const r = E.evaluateResult(
        { sets: [{ a: 11, b: 7 }, { a: 9, b: 11 }, { a: 13, b: 11 }] },
        setsT,
        'league',
      );
      expect(r.outcome).toBe('a');
      expect(r.scoreA).toBe(2);
      expect(r.scoreB).toBe(1);
    });

    it('rejects invalid sets and extra sets', () => {
      expect(() =>
        E.evaluateResult({ sets: [{ a: 11, b: 10 }] }, setsT, 'league'),
      ).toThrow(/two points/);
      expect(() =>
        E.evaluateResult({ sets: [{ a: 14, b: 11 }] }, setsT, 'league'),
      ).toThrow();
      expect(() =>
        E.evaluateResult({ sets: [{ a: 11, b: 3 }] }, setsT, 'league'),
      ).toThrow(/win 2 sets/);
      expect(() =>
        E.evaluateResult(
          { sets: [{ a: 11, b: 3 }, { a: 11, b: 3 }, { a: 11, b: 3 }] },
          setsT,
          'league',
        ),
      ).toThrow(/already over/);
    });

    it('a cap allows a 1-point win at the cap; no win-by-two needs the exact target', () => {
      const capped = rules({
        bestOf: 1,
        pointsPerSet: 21,
        maxPointsPerSet: 30,
      });
      expect(
        E.evaluateResult({ sets: [{ a: 30, b: 29 }] }, capped, 'league')
          .outcome,
      ).toBe('a');
      const plain = rules({ bestOf: 1, pointsPerSet: 15, winByTwo: false });
      expect(
        E.evaluateResult({ sets: [{ a: 14, b: 15 }] }, plain, 'league').outcome,
      ).toBe('b');
      expect(() =>
        E.evaluateResult({ sets: [{ a: 16, b: 14 }] }, plain, 'league'),
      ).toThrow();
    });
  });

  describe('goals', () => {
    const goalsT = rules({ mode: 'goals' });

    it('allows or forbids a league draw', () => {
      expect(
        E.evaluateResult({ scoreA: 1, scoreB: 1 }, goalsT, 'league').outcome,
      ).toBe('draw');
      const noDraw = { ...goalsT, league: { ...league, allowDraws: false } };
      expect(() =>
        E.evaluateResult({ scoreA: 1, scoreB: 1 }, noDraw, 'league'),
      ).toThrow(/Draws/);
    });

    it('a knockout draw needs penalties when they are enabled', () => {
      expect(() =>
        E.evaluateResult({ scoreA: 2, scoreB: 2 }, goalsT, 'knockout'),
      ).toThrow(/shoot-out/);
      const r = E.evaluateResult(
        { scoreA: 2, scoreB: 2, penaltiesA: 3, penaltiesB: 4 },
        goalsT,
        'knockout',
      );
      expect(r.outcome).toBe('b');
      const off = { ...goalsT, knockout: { penaltiesEnabled: false } };
      expect(() =>
        E.evaluateResult({ scoreA: 0, scoreB: 0 }, off, 'knockout'),
      ).toThrow();
    });
  });

  describe('standings', () => {
    const P = (
      aId: string,
      bId: string,
      forA: number,
      forB: number,
    ): E.StandingsFixture => ({
      aId,
      bId,
      forA,
      forB,
      status: 'played',
      outcome: forA > forB ? 'a' : forB > forA ? 'b' : 'draw',
    });

    it('counts points, draws and positions', () => {
      const fx = [
        P('x', 'y', 0, 1),
        P('x', 'z', 2, 0),
        P('y', 'z', 0, 1),
        P('z', 'w', 0, 0),
        P('x', 'w', 1, 1),
        P('y', 'w', 2, 1),
      ];
      const s = E.computeStandings(['x', 'y', 'z', 'w'], fx);
      const byId = Object.fromEntries(s.map((r) => [r.id, r]));
      expect(byId.y.points).toBe(6);
      expect(byId.x.points).toBe(4);
      expect(byId.w.drawn).toBe(2);
      expect(s[0].id).toBe('y');
      expect(s.every((r, i) => r.position === i + 1)).toBe(true);
    });

    it('breaks a full tie head-to-head', () => {
      // a and b are level on everything (3 points, diff 0, 2 scored), but b
      // beat a.
      const fx = [
        P('a', 'b', 0, 1),
        P('a', 'c', 2, 1),
        P('b', 'c', 1, 2),
        P('c', 'd', 0, 0),
      ];
      const s = E.computeStandings(['a', 'b', 'c', 'd'], fx);
      const pos = Object.fromEntries(s.map((r) => [r.id, r.position]));
      expect(pos.b).toBeLessThan(pos.a);
    });
  });
});
