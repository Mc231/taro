import type { RateLimiter } from '../../src/ports/RateLimiter';

/** Counts calls per key and fails once a key exceeds `limit` (no time window). */
export class FakeRateLimiter implements RateLimiter {
  readonly keys: string[] = [];
  private readonly counts = new Map<string, number>();

  constructor(public limitPerKey = Number.POSITIVE_INFINITY) {}

  limit({ key }: { key: string }): Promise<{ success: boolean }> {
    this.keys.push(key);
    const count = (this.counts.get(key) ?? 0) + 1;
    this.counts.set(key, count);
    return Promise.resolve({ success: count <= this.limitPerKey });
  }
}
