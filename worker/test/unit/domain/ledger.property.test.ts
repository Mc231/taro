import fc from 'fast-check';
import { describe, expect, it } from 'vitest';
import type { RefundReason } from '../../../src/domain/ledgerRules';
import { createHarness, uniqueId } from '../../fakes/testDeps';
import { db, seedInstall } from '../../helpers/db';
import { ReadingDriver } from '../../helpers/readingDriver';

/**
 * Ledger and usage invariants under random interleavings (03 §5.3, §15.2;
 * RC52, RC67), against the real D1 batches:
 *
 * - `SUM(bonus) >= 0` for every install;
 * - `0 <= free_used <= free_limit` on `daily_usage`, and
 *   `0 <= free_used <= max(readings.freeDaily)` on `device_daily_usage`;
 * - conservation, which rules out a double free refund and a double hold:
 *   `free_used` (per install and date, and per device and date) equals the
 *   number of free holds dated that day that are still `held` or `consumed`,
 *   and `readings_total` the number of such holds of any bucket;
 * - at most one hold and one refund per `(reading, attempt)`, and the ledger
 *   net of each attempt matches its `hold_state`;
 * - `state_version` never decreases and strictly increases with every
 *   change of the install's ledger, usage counters or holds.
 *
 * Operations: hold, refund (every reason), commit, grant, revoke, the
 * stale-hold cron, an idempotency takeover (the same handler twice at
 * once), any two operations in parallel, clock ticks across local midnight
 * and `readings.freeDaily` changes.
 */

const READINGS_PER_INSTALL = 2;
const REASONS: readonly RefundReason[] = [
  'expired',
  'released',
  'abandoned',
  'failed',
  'budget',
  'declined',
  'undelivered',
];

type Op =
  | { readonly t: 'hold' | 'commit'; readonly i: number; readonly r: number }
  | { readonly t: 'refund'; readonly i: number; readonly r: number; readonly reason: RefundReason }
  | {
      readonly t: 'grant';
      readonly i: number;
      readonly bucket: 'paid' | 'bonus';
      readonly n: number;
    }
  | { readonly t: 'revoke'; readonly i: number; readonly n: number }
  | { readonly t: 'cron' }
  | { readonly t: 'tick'; readonly minutes: number }
  | { readonly t: 'freeDaily'; readonly n: number };

type Step =
  | { readonly kind: 'one'; readonly op: Op }
  | { readonly kind: 'takeover'; readonly op: Op }
  | { readonly kind: 'parallel'; readonly a: Op; readonly b: Op }
  /** Hold a reading, then race two calls on it. */
  | { readonly kind: 'race'; readonly hold: Op; readonly a: Op; readonly b: Op };

const install = fc.integer({ min: 0, max: 2 });
const reading = fc.integer({ min: 0, max: READINGS_PER_INSTALL - 1 });

const opArb: fc.Arbitrary<Op> = fc.oneof(
  { weight: 5, arbitrary: fc.record({ t: fc.constant('hold' as const), i: install, r: reading }) },
  {
    weight: 3,
    arbitrary: fc.record({ t: fc.constant('commit' as const), i: install, r: reading }),
  },
  {
    weight: 3,
    arbitrary: fc.record({
      t: fc.constant('refund' as const),
      i: install,
      r: reading,
      reason: fc.constantFrom(...REASONS),
    }),
  },
  {
    weight: 2,
    arbitrary: fc.record({
      t: fc.constant('grant' as const),
      i: install,
      bucket: fc.constantFrom('paid' as const, 'bonus' as const),
      n: fc.integer({ min: 1, max: 3 }),
    }),
  },
  {
    weight: 1,
    arbitrary: fc.record({
      t: fc.constant('revoke' as const),
      i: install,
      n: fc.integer({ min: 1, max: 2 }),
    }),
  },
  { weight: 1, arbitrary: fc.constant({ t: 'cron' as const }) },
  {
    weight: 1,
    arbitrary: fc.record({
      t: fc.constant('tick' as const),
      minutes: fc.integer({ min: 1, max: 900 }),
    }),
  },
  {
    weight: 1,
    arbitrary: fc.record({
      t: fc.constant('freeDaily' as const),
      n: fc.integer({ min: 1, max: 3 }),
    }),
  },
);

/** Two money calls on one (usually held) reading at once: hold, commit, refund in any pairing. */
const raceArb: fc.Arbitrary<Step> = fc
  .record({
    i: install,
    r: reading,
    a: fc.constantFrom('hold' as const, 'commit' as const, 'refund' as const),
    b: fc.constantFrom('hold' as const, 'commit' as const, 'refund' as const),
    reason: fc.constantFrom(...REASONS),
  })
  .map(({ i, r, a, b, reason }) => {
    const op = (t: 'hold' | 'commit' | 'refund'): Op =>
      t === 'refund' ? { t, i, r, reason } : { t, i, r };
    return { kind: 'race' as const, hold: op('hold'), a: op(a), b: op(b) };
  });

const stepArb: fc.Arbitrary<Step> = fc.oneof(
  { weight: 5, arbitrary: fc.record({ kind: fc.constant('one' as const), op: opArb }) },
  { weight: 3, arbitrary: raceArb },
  { weight: 2, arbitrary: fc.record({ kind: fc.constant('takeover' as const), op: opArb }) },
  {
    weight: 2,
    arbitrary: fc.record({ kind: fc.constant('parallel' as const), a: opArb, b: opArb }),
  },
);

interface World {
  readonly driver: ReadingDriver;
  readonly installs: readonly string[];
  readonly deviceKeyHash: string;
  readonly crids: readonly (readonly string[])[];
  maxFreeDaily: number;
  readonly versions: Map<string, { version: number; fingerprint: string }>;
}

interface RawReading {
  id: string;
  install_id: string;
  attempt: number;
  hold_source: string | null;
  hold_state: string;
  hold_local_date: string | null;
}

async function setupWorld(start: string): Promise<World> {
  const h = createHarness();
  h.clock.set(start);
  const driver = new ReadingDriver(h);
  const deviceKeyHash = uniqueId('devk');
  // Two Android installs share one device key (RC53); one iOS install in another zone.
  const installs = [
    await seedInstall({ platform: 'android', deviceKeyHash, timezone: 'Asia/Kathmandu' }),
    await seedInstall({ platform: 'android', deviceKeyHash, timezone: 'Asia/Kathmandu' }),
    await seedInstall({ platform: 'ios', timezone: 'America/Sao_Paulo' }),
  ];
  const crids = installs.map(() =>
    Array.from({ length: READINGS_PER_INSTALL }, () => uniqueId('crid')),
  );
  return { driver, installs, deviceKeyHash, crids, maxFreeDaily: 1, versions: new Map() };
}

async function readingId(world: World, i: number, r: number): Promise<string | null> {
  const row = await db
    .prepare(`SELECT id FROM readings WHERE install_id = ?1 AND client_reading_id = ?2`)
    .bind(world.installs[i], world.crids[i]?.[r])
    .first<{ id: string }>();
  return row?.id ?? null;
}

async function run(world: World, op: Op): Promise<void> {
  const { driver } = world;
  switch (op.t) {
    case 'hold':
      await driver.hold(world.installs[op.i] ?? '', world.crids[op.i]?.[op.r]);
      return;
    case 'commit': {
      const id = await readingId(world, op.i, op.r);
      if (id !== null) {
        await driver.commit(id);
      }
      return;
    }
    case 'refund': {
      const id = await readingId(world, op.i, op.r);
      if (id !== null) {
        await driver.refund(id, op.reason);
      }
      return;
    }
    case 'grant':
      await driver.grant(world.installs[op.i] ?? '', op.bucket, op.n);
      return;
    case 'revoke':
      await driver.revoke(world.installs[op.i] ?? '', op.n);
      return;
    case 'cron': {
      // `releaseExpiredHolds` / `refundStaleHolds`: refund every expired hold (03 §9.1).
      const placeholders = world.installs.map((_, k) => `?${String(k + 2)}`).join(', ');
      const { results } = await db
        .prepare(
          `SELECT id FROM readings WHERE hold_state = 'held' AND hold_expires_at <= ?1
              AND install_id IN (${placeholders})`,
        )
        .bind(driver.h.clock.now().toISOString(), ...world.installs)
        .all<{ id: string }>();
      for (const row of results) {
        await driver.refund(row.id, 'expired');
      }
      return;
    }
    case 'tick':
      driver.h.clock.advance({ minutes: op.minutes });
      return;
    case 'freeDaily':
      world.maxFreeDaily = Math.max(world.maxFreeDaily, op.n);
      driver.h.config.set({ 'readings.freeDaily': op.n });
      return;
  }
}

async function step(world: World, s: Step): Promise<void> {
  if (s.kind === 'one') {
    await run(world, s.op);
  } else if (s.kind === 'takeover') {
    await Promise.all([run(world, s.op), run(world, s.op)]);
  } else {
    if (s.kind === 'race') {
      await run(world, s.hold);
    }
    await Promise.all([run(world, s.a), run(world, s.b)]);
  }
}

function inList(world: World): string {
  return world.installs.map((id) => `'${id}'`).join(', ');
}

async function checkInvariants(world: World): Promise<void> {
  const ids = inList(world);
  const [ledger, usage, device, readings, installs] = await db.batch<Record<string, unknown>>([
    db.prepare(
      `SELECT install_id, bucket, delta, reason, ref_type, ref_id FROM ledger
        WHERE install_id IN (${ids}) ORDER BY id`,
    ),
    db.prepare(
      `SELECT * FROM daily_usage WHERE install_id IN (${ids}) ORDER BY install_id, local_date`,
    ),
    db
      .prepare(`SELECT * FROM device_daily_usage WHERE device_key_hash = ?1 ORDER BY local_date`)
      .bind(world.deviceKeyHash),
    db.prepare(
      `SELECT id, install_id, attempt, hold_source, hold_state, hold_local_date FROM readings
        WHERE install_id IN (${ids}) ORDER BY id`,
    ),
    db.prepare(`SELECT id, state_version FROM installs WHERE id IN (${ids})`),
  ]);
  const ledgerRows = (ledger?.results ?? []) as unknown as {
    install_id: string;
    bucket: string;
    delta: number;
    reason: string;
    ref_type: string;
    ref_id: string;
  }[];
  const usageRows = (usage?.results ?? []) as unknown as {
    install_id: string;
    local_date: string;
    free_limit: number;
    free_used: number;
    readings_total: number;
    declined_count: number;
  }[];
  const deviceRows = (device?.results ?? []) as unknown as {
    local_date: string;
    free_used: number;
  }[];
  const readingRows = (readings?.results ?? []) as unknown as RawReading[];
  const live = readingRows.filter((r) => r.hold_state === 'held' || r.hold_state === 'consumed');

  // SUM(bonus) >= 0.
  for (const id of world.installs) {
    const bonus = ledgerRows
      .filter((e) => e.install_id === id && e.bucket === 'bonus')
      .reduce((sum, e) => sum + e.delta, 0);
    expect(bonus).toBeGreaterThanOrEqual(0);
  }

  // Usage bounds and conservation.
  for (const row of usageRows) {
    expect(row.free_used).toBeGreaterThanOrEqual(0);
    expect(row.free_used).toBeLessThanOrEqual(row.free_limit);
    const sameDay = live.filter(
      (r) => r.install_id === row.install_id && r.hold_local_date === row.local_date,
    );
    expect(row.free_used).toBe(sameDay.filter((r) => r.hold_source === 'free').length);
    expect(row.readings_total).toBe(sameDay.length);
  }
  for (const r of live) {
    const row = usageRows.find(
      (u) => u.install_id === r.install_id && u.local_date === r.hold_local_date,
    );
    expect(row).toBeDefined();
  }
  const androidIds = world.installs.slice(0, 2);
  for (const row of deviceRows) {
    expect(row.free_used).toBeGreaterThanOrEqual(0);
    expect(row.free_used).toBeLessThanOrEqual(world.maxFreeDaily);
    const count = live.filter(
      (r) =>
        androidIds.includes(r.install_id) &&
        r.hold_source === 'free' &&
        r.hold_local_date === row.local_date,
    ).length;
    expect(row.free_used).toBe(count);
  }

  // At most one hold and one refund per (reading, attempt); nets match hold_state.
  const byRef = new Map<string, typeof ledgerRows>();
  for (const e of ledgerRows.filter((x) => x.ref_type === 'reading')) {
    byRef.set(e.ref_id, [...(byRef.get(e.ref_id) ?? []), e]);
  }
  for (const [ref, entries] of byRef) {
    const holds = entries.filter((e) => e.reason === 'reading_hold');
    const refunds = entries.filter((e) => e.reason !== 'reading_hold');
    expect(holds.length, ref).toBeLessThanOrEqual(1);
    expect(refunds.length, ref).toBeLessThanOrEqual(1);
    if (refunds.length === 1) {
      expect(holds[0]?.bucket).toBe(refunds[0]?.bucket);
    }
  }
  for (const r of readingRows) {
    for (let attempt = 1; attempt <= r.attempt; attempt++) {
      const net = (byRef.get(`${r.id}#${String(attempt)}`) ?? []).reduce((s, e) => s + e.delta, 0);
      const current = attempt === r.attempt;
      const charged =
        current &&
        (r.hold_state === 'held' || r.hold_state === 'consumed') &&
        r.hold_source !== 'free';
      expect(net, `${r.id}#${String(attempt)} ${r.hold_state}`).toBe(charged ? -1 : 0);
    }
  }

  // state_version: never decreases; strictly increases on every balance change.
  for (const row of (installs?.results ?? []) as unknown as {
    id: string;
    state_version: number;
  }[]) {
    const fingerprint = JSON.stringify([
      ledgerRows.filter((e) => e.install_id === row.id).length,
      usageRows
        .filter((u) => u.install_id === row.id)
        .filter((u) => u.free_used + u.readings_total + u.declined_count > 0)
        .map((u) => [u.local_date, u.free_used, u.readings_total, u.declined_count]),
      // A new row (`none`) or a status-only change (`no_credit`) is not a balance change.
      readingRows
        .filter((r) => r.install_id === row.id && r.hold_state !== 'none')
        .map((r) => [r.id, r.attempt, r.hold_state, r.hold_source]),
    ]);
    const previous = world.versions.get(row.id);
    if (previous !== undefined) {
      expect(row.state_version).toBeGreaterThanOrEqual(previous.version);
      if (previous.fingerprint !== fingerprint) {
        expect(row.state_version).toBeGreaterThan(previous.version);
      }
    }
    world.versions.set(row.id, { version: row.state_version, fingerprint });
  }
}

describe('ledger invariants under interleavings (fast-check, 03 §5.3)', () => {
  it('hold / refund / commit / grant / revoke / cron / takeover keep every invariant', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.array(stepArb, { minLength: 1, maxLength: 40 }),
        fc.integer({ min: 0, max: 23 * 60 }),
        async (steps, startMinute) => {
          const start = new Date(Date.parse('2026-09-26T00:00:00.000Z') + startMinute * 60_000);
          const world = await setupWorld(start.toISOString());
          await checkInvariants(world);
          for (const s of steps) {
            await step(world, s);
            await checkInvariants(world);
          }
        },
      ),
      { numRuns: 250 },
    );
  }, 120_000);
});
