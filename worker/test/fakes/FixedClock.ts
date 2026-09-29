import type { Clock } from '../../src/ports/Clock';

/** Deterministic clock; only moves when a test says so. */
export class FixedClock implements Clock {
  private current: number;

  constructor(start: string | Date = '2026-09-26T10:00:00.000Z') {
    this.current = new Date(start).getTime();
  }

  now(): Date {
    return new Date(this.current);
  }

  set(instant: string | Date): void {
    this.current = new Date(instant).getTime();
  }

  advance(by: {
    ms?: number;
    seconds?: number;
    minutes?: number;
    hours?: number;
    days?: number;
  }): void {
    this.current +=
      (by.ms ?? 0) +
      (by.seconds ?? 0) * 1000 +
      (by.minutes ?? 0) * 60_000 +
      (by.hours ?? 0) * 3_600_000 +
      (by.days ?? 0) * 86_400_000;
  }
}
