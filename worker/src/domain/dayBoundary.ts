/**
 * The free-day boundary (03 §5.2). Only the server clock is used; the client
 * clock is never trusted. A "day" is the local calendar date of the install's
 * IANA timezone.
 *
 * - `localDate(nowUtc, tz)` → `yyyy-mm-dd` from `Intl.DateTimeFormat('en-CA')`.
 * - `nextResetUtc(nowUtc, tz)` → the first UTC instant (whole second) whose
 *   local date is later than `localDate(nowUtc, tz)`. It is found by
 *   bisecting candidate instants over the next 50 hours on the local date
 *   itself, never on offset arithmetic, so DST gaps and folds, midnight
 *   transitions and 30/45-minute offsets all come out right.
 */

/** Stored installs without a timezone use UTC (registration normally sends one). */
export const DEFAULT_TIMEZONE = 'UTC';

/** IANA names only (`Area/Location[/Sub]`, `UTC`, `Etc/GMT+5`); no raw offsets such as `+05:00`. */
const IANA_SHAPE = /^(?:[A-Za-z][A-Za-z0-9_+-]*)(?:\/[A-Za-z0-9_+-]+){0,2}$/;
const MAX_TIMEZONE_LENGTH = 64;

/** Longest search window: a local day is at most 26 h, plus the offset change across it. */
const SEARCH_WINDOW_SEC = 50 * 3600;

const formatters = new Map<string, Intl.DateTimeFormat>();

function formatter(timeZone: string): Intl.DateTimeFormat {
  let f = formatters.get(timeZone);
  if (f === undefined) {
    f = new Intl.DateTimeFormat('en-CA', {
      timeZone,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    });
    formatters.set(timeZone, f);
  }
  return f;
}

/** True for an IANA zone name that `Intl.DateTimeFormat` accepts (03 §3.5). */
export function isValidTimeZone(value: string): boolean {
  if (value.length > MAX_TIMEZONE_LENGTH || !IANA_SHAPE.test(value)) {
    return false;
  }
  try {
    formatter(value);
    return true;
  } catch {
    return false;
  }
}

/** `yyyy-mm-dd` of `nowUtc` in `tz`. Throws `RangeError` for an unknown zone. */
export function localDate(nowUtc: Date, tz: string): string {
  const parts: Partial<Record<Intl.DateTimeFormatPartTypes, string>> = Object.fromEntries(
    formatter(tz)
      .formatToParts(nowUtc)
      .map((p) => [p.type, p.value]),
  );
  return `${String(parts.year)}-${String(parts.month)}-${String(parts.day)}`;
}

/** The calendar date `days` after `date` (`yyyy-mm-dd`, proleptic Gregorian). */
export function addDays(date: string, days: number): string {
  const [y, m, d] = date.split('-').map(Number) as [number, number, number];
  return new Date(Date.UTC(y, m - 1, d + days)).toISOString().slice(0, 10);
}

/** The first UTC instant whose local date in `tz` is later than today's. Always `> nowUtc`. */
export function nextResetUtc(nowUtc: Date, tz: string): Date {
  const today = localDate(nowUtc, tz);
  const after = (sec: number): boolean => localDate(new Date(sec * 1000), tz) > today;
  // Invariant: `lo` is still today, `hi` is already a later date (every zone
  // changes date within 50 h).
  let lo = Math.floor(nowUtc.getTime() / 1000);
  let hi = lo + SEARCH_WINDOW_SEC;
  while (hi - lo > 1) {
    const mid = lo + Math.floor((hi - lo) / 2);
    if (after(mid)) {
      hi = mid;
    } else {
      lo = mid;
    }
  }
  return new Date(hi * 1000);
}

/** ISO-8601 UTC with a `Z` suffix and no milliseconds (03 §2.1 wire format). */
export function isoSeconds(instant: Date): string {
  return `${instant.toISOString().slice(0, 19)}Z`;
}
