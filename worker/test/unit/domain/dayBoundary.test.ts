import fc from 'fast-check';
import { describe, expect, it } from 'vitest';
import {
  addDays,
  DEFAULT_TIMEZONE,
  isoSeconds,
  isValidTimeZone,
  localDate,
  nextResetUtc,
} from '../../../src/domain/dayBoundary';

/** 06 §2.1 `kBoundaryZones`; every case names its zone. */
const K_BOUNDARY_ZONES = [
  'UTC',
  'Pacific/Kiritimati',
  'Pacific/Pago_Pago',
  'Asia/Kolkata',
  'Asia/Kathmandu',
  'America/New_York',
  'Europe/Kyiv',
] as const;

/** 03 §15.2 day-boundary zones (DST gap/fold, 30-min DST, +5:45, +14). */
const SPEC_ZONES = [
  'America/Sao_Paulo',
  'Australia/Lord_Howe',
  'Asia/Kathmandu',
  'Pacific/Kiritimati',
] as const;

interface BoundaryCase {
  readonly zone: string;
  readonly now: string;
  readonly localDate: string;
  readonly nextReset: string;
  readonly note: string;
}

const CASES: readonly BoundaryCase[] = [
  {
    zone: 'UTC',
    now: '2026-09-26T10:00:00Z',
    localDate: '2026-09-26',
    nextReset: '2026-09-27T00:00:00Z',
    note: 'plain UTC',
  },
  {
    zone: 'UTC',
    now: '2026-09-26T23:59:59.999Z',
    localDate: '2026-09-26',
    nextReset: '2026-09-27T00:00:00Z',
    note: 'last millisecond of the day',
  },
  {
    zone: 'UTC',
    now: '2026-09-27T00:00:00Z',
    localDate: '2026-09-27',
    nextReset: '2026-09-28T00:00:00Z',
    note: 'exactly at midnight belongs to the new day',
  },
  {
    zone: 'Pacific/Kiritimati',
    now: '2026-09-26T10:00:00Z',
    localDate: '2026-09-27',
    nextReset: '2026-09-27T10:00:00Z',
    note: '+14: local midnight at 10:00Z',
  },
  {
    zone: 'Pacific/Kiritimati',
    now: '2026-09-26T09:59:59Z',
    localDate: '2026-09-26',
    nextReset: '2026-09-26T10:00:00Z',
    note: '+14: one second before midnight',
  },
  {
    zone: 'Pacific/Pago_Pago',
    now: '2026-09-26T10:00:00Z',
    localDate: '2026-09-25',
    nextReset: '2026-09-26T11:00:00Z',
    note: '-11: a UTC day behind',
  },
  {
    zone: 'Asia/Kolkata',
    now: '2026-09-26T10:00:00Z',
    localDate: '2026-09-26',
    nextReset: '2026-09-26T18:30:00Z',
    note: '+5:30',
  },
  {
    zone: 'Asia/Kathmandu',
    now: '2026-09-26T10:00:00Z',
    localDate: '2026-09-26',
    nextReset: '2026-09-26T18:15:00Z',
    note: '+5:45',
  },
  {
    zone: 'America/New_York',
    now: '2026-03-07T12:00:00Z',
    localDate: '2026-03-07',
    nextReset: '2026-03-08T05:00:00Z',
    note: 'EST, the day before spring-forward',
  },
  {
    zone: 'America/New_York',
    now: '2026-03-08T12:00:00Z',
    localDate: '2026-03-08',
    nextReset: '2026-03-09T04:00:00Z',
    note: 'spring-forward day has 23 h',
  },
  {
    zone: 'America/New_York',
    now: '2026-10-31T12:00:00Z',
    localDate: '2026-10-31',
    nextReset: '2026-11-01T04:00:00Z',
    note: 'EDT, the day before fall-back',
  },
  {
    zone: 'America/New_York',
    now: '2026-11-01T12:00:00Z',
    localDate: '2026-11-01',
    nextReset: '2026-11-02T05:00:00Z',
    note: 'fall-back day has 25 h',
  },
  {
    zone: 'Europe/Kyiv',
    now: '2026-09-26T10:00:00Z',
    localDate: '2026-09-26',
    nextReset: '2026-09-26T21:00:00Z',
    note: 'EEST +3',
  },
  {
    zone: 'Europe/Kyiv',
    now: '2026-10-25T12:00:00Z',
    localDate: '2026-10-25',
    nextReset: '2026-10-25T22:00:00Z',
    note: 'EU fall-back day, EET +2 after',
  },
  {
    zone: 'America/Sao_Paulo',
    now: '2018-11-03T12:00:00Z',
    localDate: '2018-11-03',
    nextReset: '2018-11-04T03:00:00Z',
    note: 'historic DST gap at midnight: the day starts at 01:00',
  },
  {
    zone: 'America/Sao_Paulo',
    now: '2019-02-16T12:00:00Z',
    localDate: '2019-02-16',
    nextReset: '2019-02-17T03:00:00Z',
    note: 'historic DST fold at midnight: 23:00-24:00 twice',
  },
  {
    zone: 'Australia/Lord_Howe',
    now: '2026-10-03T12:00:00Z',
    localDate: '2026-10-03',
    nextReset: '2026-10-03T13:30:00Z',
    note: '+10:30 before its 30-min DST',
  },
  {
    zone: 'Australia/Lord_Howe',
    now: '2026-10-04T12:00:00Z',
    localDate: '2026-10-04',
    nextReset: '2026-10-04T13:00:00Z',
    note: '+11 after its 30-min DST',
  },
];

describe('dayBoundary (03 §5.2)', () => {
  it.each(CASES)('$zone at $now: $note', (c) => {
    const now = new Date(c.now);
    expect(localDate(now, c.zone)).toBe(c.localDate);
    const next = nextResetUtc(now, c.zone);
    expect(isoSeconds(next)).toBe(c.nextReset);
    expect(localDate(next, c.zone)).toBe(addDays(c.localDate, 1));
    expect(localDate(new Date(next.getTime() - 1000), c.zone)).toBe(c.localDate);
  });

  it('covers every kBoundaryZones and 03 §15.2 zone', () => {
    const covered = new Set(CASES.map((c) => c.zone));
    for (const zone of [...K_BOUNDARY_ZONES, ...SPEC_ZONES]) {
      expect(covered, zone).toContain(zone);
    }
  });

  it('property: nextResetUtc > now and its local date is exactly the next day, for any instant × zone', () => {
    const zones = [...new Set([...K_BOUNDARY_ZONES, ...SPEC_ZONES])];
    fc.assert(
      fc.property(
        // 2000-01-01 .. 2037-12-31: no zone of the matrix skips a calendar day in this range.
        fc.integer({ min: Date.UTC(2000, 0, 1), max: Date.UTC(2037, 11, 31) }),
        fc.constantFrom(...zones),
        (ms, zone) => {
          const now = new Date(ms);
          const today = localDate(now, zone);
          const next = nextResetUtc(now, zone);
          expect(next.getTime()).toBeGreaterThan(now.getTime());
          expect(localDate(next, zone)).toBe(addDays(today, 1));
          // The day key changes exactly there (the previous second is still today).
          expect(localDate(new Date(next.getTime() - 1000), zone)).toBe(today);
          // A local day is 22-26 h long, so the next reset is always within 26 h.
          expect(next.getTime() - now.getTime()).toBeLessThanOrEqual(26 * 3_600_000);
        },
      ),
      { numRuns: 500 },
    );
  });

  it('property: the day key is monotonic in time', () => {
    fc.assert(
      fc.property(
        fc.integer({ min: Date.UTC(2000, 0, 1), max: Date.UTC(2037, 11, 31) }),
        fc.integer({ min: 0, max: 7 * 86_400_000 }),
        fc.constantFrom(...K_BOUNDARY_ZONES),
        (ms, delta, zone) => {
          expect(localDate(new Date(ms), zone) <= localDate(new Date(ms + delta), zone)).toBe(true);
        },
      ),
      { numRuns: 300 },
    );
  });

  it('validates IANA names only', () => {
    expect(isValidTimeZone('America/New_York')).toBe(true);
    expect(isValidTimeZone('America/Argentina/Buenos_Aires')).toBe(true);
    expect(isValidTimeZone('Etc/GMT+5')).toBe(true);
    expect(isValidTimeZone(DEFAULT_TIMEZONE)).toBe(true);
    expect(isValidTimeZone('Mars/Olympus_Mons')).toBe(false);
    expect(isValidTimeZone('+05:00')).toBe(false);
    expect(isValidTimeZone('')).toBe(false);
    expect(isValidTimeZone('Europe/../etc')).toBe(false);
    expect(isValidTimeZone(`Europe/${'x'.repeat(70)}`)).toBe(false);
  });

  it('addDays crosses months, years and leap days', () => {
    expect(addDays('2026-01-31', 1)).toBe('2026-02-01');
    expect(addDays('2026-12-31', 1)).toBe('2027-01-01');
    expect(addDays('2028-02-28', 1)).toBe('2028-02-29');
    expect(addDays('2026-03-01', -1)).toBe('2026-02-28');
  });

  it('isoSeconds drops milliseconds and keeps the Z suffix', () => {
    expect(isoSeconds(new Date('2026-09-26T09:12:44.987Z'))).toBe('2026-09-26T09:12:44Z');
  });
});
