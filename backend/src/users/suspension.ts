// The fixed menu of suspension terms the admin dashboard offers. Kept as a
// closed set rather than a free-form date so the client cannot invent a
// term the product never agreed to, and so the wire value stays readable
// in logs ("3M" rather than an opaque timestamp).
export enum SuspensionDuration {
  ONE_MONTH = '1M',
  THREE_MONTHS = '3M',
  ONE_YEAR = '1Y',
  PERMANENT = 'PERMANENT',
}

const MONTHS_BY_DURATION: Record<string, number> = {
  [SuspensionDuration.ONE_MONTH]: 1,
  [SuspensionDuration.THREE_MONTHS]: 3,
  [SuspensionDuration.ONE_YEAR]: 12,
};

/**
 * The instant a suspension of this length ends, or `undefined` for
 * PERMANENT (which has no end date — see `User.suspendedUntil`).
 *
 * Calendar months, not fixed 30-day blocks: a one-month suspension issued
 * on 15 Jan ends on 15 Feb. `setMonth` clamps the overflow case for us
 * (31 Jan + 1 month lands on 28/29 Feb rather than spilling into March).
 */
export function suspensionEndDate(
  duration: SuspensionDuration,
  from: Date = new Date(),
): Date | undefined {
  const months = MONTHS_BY_DURATION[duration];
  if (months === undefined) return undefined;

  const end = new Date(from.getTime());
  const targetMonth = end.getMonth() + months;
  const dayOfMonth = end.getDate();
  end.setDate(1);
  end.setMonth(targetMonth);
  const lastDayOfTargetMonth = new Date(
    end.getFullYear(),
    end.getMonth() + 1,
    0,
  ).getDate();
  end.setDate(Math.min(dayOfMonth, lastDayOfTargetMonth));
  return end;
}
