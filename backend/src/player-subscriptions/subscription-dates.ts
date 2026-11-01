// Calendar arithmetic on 'YYYY-MM-DD' strings in the academy's own time
// zone. Done in UTC on purpose: a date string has no time of day, and UTC
// has no daylight-saving gaps to land in.

export const ACADEMY_TIME_ZONE = 'Africa/Cairo';

/** Days before the end date when the "about to expire" notice goes out. */
export const EXPIRING_SOON_DAYS = 3;

export enum SubscriptionStatus {
  ACTIVE = 'ACTIVE',
  EXPIRING = 'EXPIRING',
  EXPIRED = 'EXPIRED',
  NONE = 'NONE',
}

/** Today's date where the academy is, whatever the server's own zone. */
export function todayInAcademy(now: Date = new Date()): string {
  // en-CA formats as YYYY-MM-DD.
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: ACADEMY_TIME_ZONE,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(now);
}

export function addDays(date: string, days: number): string {
  const d = new Date(`${date}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString().slice(0, 10);
}

/** Whole days from [from] to [to]; negative when [to] is earlier. */
export function daysBetween(from: string, to: string): number {
  const ms =
    new Date(`${to}T00:00:00Z`).getTime() -
    new Date(`${from}T00:00:00Z`).getTime();
  return Math.round(ms / 86_400_000);
}

/** The state a subscription ending on [endDate] is in on [today]. */
export function statusFor(
  endDate: string | undefined,
  today: string,
): SubscriptionStatus {
  if (!endDate) return SubscriptionStatus.NONE;
  if (endDate < today) return SubscriptionStatus.EXPIRED;
  if (endDate <= addDays(today, EXPIRING_SOON_DAYS)) {
    return SubscriptionStatus.EXPIRING;
  }
  return SubscriptionStatus.ACTIVE;
}
