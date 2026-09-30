import { describe, expect, it } from 'vitest';
import {
  daysBeforeDate,
  monthsBefore,
  reportExpiry,
  RETENTION,
} from '../../../src/domain/retention';

describe('domain/retention (03 §13)', () => {
  it('holds the 03 §13 periods', () => {
    expect(RETENTION).toEqual({
      readingsMonths: 13,
      adRewardsMonths: 13,
      usageDays: 90,
      reportDays: 90,
      inactiveInstallMonths: 24,
    });
  });

  it('subtracts calendar months in UTC, clamping to the month end', () => {
    expect(monthsBefore(new Date('2026-09-30T03:30:00.000Z'), 13)).toBe('2025-08-30T03:30:00.000Z');
    expect(monthsBefore(new Date('2026-09-30T03:30:00.000Z'), 24)).toBe('2024-09-30T03:30:00.000Z');
    expect(monthsBefore(new Date('2026-03-31T00:00:00.000Z'), 1)).toBe('2026-02-28T00:00:00.000Z');
    expect(monthsBefore(new Date('2024-03-31T00:00:00.000Z'), 1)).toBe('2024-02-29T00:00:00.000Z');
    expect(monthsBefore(new Date('2026-01-15T12:00:00.000Z'), 13)).toBe('2024-12-15T12:00:00.000Z');
  });

  it('dates 90 days back and report expiry 90 days ahead', () => {
    expect(daysBeforeDate(new Date('2026-09-30T03:30:00.000Z'), 90)).toBe('2026-07-02');
    expect(reportExpiry(new Date('2026-09-30T10:00:00.000Z'))).toBe('2026-12-29T10:00:00.000Z');
  });
});
