import { describe, expect, it } from 'vitest';
import { ipPrefixHash, utcDay } from '../../../src/http/middleware/rateLimit';
import { ApiError } from '../../../src/http/errors';
import { insufficientCreditsError } from '../../../src/services/BalanceService';
import { bindings, createHarness, uniqueId } from '../../fakes/testDeps';
import { db, seedInstall } from '../../helpers/db';
import { ReadingDriver } from '../../helpers/readingDriver';

const DAY = '2026-09-26';

function setup(start = '2026-09-26T10:00:00.000Z') {
  const h = createHarness();
  h.clock.set(start);
  return { h, driver: new ReadingDriver(h) };
}

describe('BalanceService.hold (03 §5.3 steps 1–2)', () => {
  it('consumes free → bonus → paid, one ledger entry per (reading, attempt), state_version + 1 each', async () => {
    const { driver } = setup();
    const id = await seedInstall({ timezone: 'Europe/Berlin' });
    await driver.grant(id, 'bonus', 1);
    await driver.grant(id, 'paid', 1);
    const v0 = await driver.stateVersion(id);

    const free = await driver.hold(id);
    expect(free).toMatchObject({ kind: 'held', chargeSource: 'free', attempt: 1, renewed: false });
    const bonus = await driver.hold(id);
    expect(bonus).toMatchObject({ kind: 'held', chargeSource: 'bonus' });
    const paid = await driver.hold(id, undefined, { status: 'generating' });
    expect(paid).toMatchObject({ kind: 'held', chargeSource: 'paid' });
    const none = await driver.hold(id);
    expect(none).toMatchObject({ kind: 'insufficient', reason: 'noCredits' });

    expect(await driver.stateVersion(id)).toBe(v0 + 3);
    expect(await driver.balances(id)).toEqual({ bonus: 0, paid: 0 });
    expect(await driver.usage(id, DAY)).toMatchObject({
      freeUsed: 1,
      freeLimit: 1,
      readingsTotal: 3,
    });
    const holds = (await driver.entries(id)).filter((e) => e.reason === 'reading_hold');
    expect(holds.map((e) => [e.bucket, e.delta, e.refId])).toEqual([
      ['bonus', -1, `${bonus.readingId}#1`],
      ['paid', -1, `${paid.readingId}#1`],
    ]);
    const freeRow = await driver.reading(free.readingId);
    expect(freeRow).toMatchObject({
      holdState: 'held',
      holdSource: 'free',
      holdLocalDate: DAY,
      holdExpiresAt: '2026-09-26T10:15:00Z',
      chargeSource: 'free',
      status: 'held',
    });
    expect(await driver.reading(paid.readingId)).toMatchObject({ status: 'generating' });
    expect(await driver.reading(none.readingId)).toMatchObject({
      status: 'no_credit',
      holdState: 'none',
    });
  });

  it('402 carries details.freeResetsAt and details.reason and a fresh balance', async () => {
    const { driver } = setup();
    const id = await seedInstall({ timezone: 'Europe/Berlin' });
    await driver.hold(id);
    const result = await driver.hold(id);
    if (result.kind !== 'insufficient') {
      throw new Error(`expected insufficient, got ${result.kind}`);
    }
    expect(result.freeResetsAt).toBe('2026-09-26T22:00:00Z');
    expect(result.balance).toMatchObject({ canRead: false, canReadReason: 'noCredits' });
    const error = insufficientCreditsError(result);
    expect(error).toBeInstanceOf(ApiError);
    expect(error.code).toBe('INSUFFICIENT_CREDITS');
    expect(error.options.details).toEqual({
      freeResetsAt: '2026-09-26T22:00:00Z',
      reason: 'noCredits',
    });
  });

  it('two parallel holds on the last credit → exactly one 402 (04 §15)', async () => {
    const { driver } = setup();
    const id = await seedInstall();
    await driver.hold(id); // today's free reading
    await driver.grant(id, 'paid', 1);
    const results = await Promise.all([driver.hold(id), driver.hold(id)]);
    expect(results.map((r) => r.kind).sort()).toEqual(['held', 'insufficient']);
    expect(await driver.balances(id)).toEqual({ bonus: 0, paid: 0 });
  });

  it('concurrent holds never overspend: 6 readings on 2 paid credits → 2 held, 4 × 402', async () => {
    const { driver } = setup();
    const id = await seedInstall();
    await driver.hold(id);
    await driver.grant(id, 'paid', 2);
    const results = await Promise.all(Array.from({ length: 6 }, () => driver.hold(id)));
    expect(results.filter((r) => r.kind === 'held')).toHaveLength(2);
    expect(results.filter((r) => r.kind === 'insufficient')).toHaveLength(4);
    expect(await driver.balances(id)).toEqual({ bonus: 0, paid: 0 });
  });

  it('10 parallel holds on the same clientReadingId → one hold', async () => {
    const { driver } = setup();
    const id = await seedInstall();
    await driver.grant(id, 'paid', 5);
    const v0 = await driver.stateVersion(id);
    const crid = uniqueId('crid');
    const results = await Promise.all(Array.from({ length: 10 }, () => driver.hold(id, crid)));
    expect(new Set(results.map((r) => r.readingId)).size).toBe(1);
    expect(results.every((r) => r.kind === 'held' && r.chargeSource === 'free')).toBe(true);
    expect(await driver.usage(id, DAY)).toMatchObject({ freeUsed: 1, readingsTotal: 1 });
    expect(await driver.balances(id)).toEqual({ bonus: 0, paid: 5 });
    expect(await driver.stateVersion(id)).toBe(v0 + 1);
  });

  it('10 parallel holds on the same clientReadingId with only paid credits → one ledger hold', async () => {
    const { driver } = setup();
    const id = await seedInstall();
    await driver.hold(id);
    await driver.grant(id, 'paid', 5);
    const crid = uniqueId('crid');
    const results = await Promise.all(Array.from({ length: 10 }, () => driver.hold(id, crid)));
    expect(results.every((r) => r.kind === 'held' && r.chargeSource === 'paid')).toBe(true);
    expect(await driver.balances(id)).toEqual({ bonus: 0, paid: 4 });
  });

  it('a free hold at 23:59 local refunded at 00:01 decrements the previous day’s row', async () => {
    // Europe/Berlin is UTC+2 on 2026-09-26: 23:59 local = 21:59Z.
    const { h, driver } = setup('2026-09-26T21:59:00.000Z');
    const id = await seedInstall({ timezone: 'Europe/Berlin' });
    const held = await driver.hold(id);
    expect(held).toMatchObject({ kind: 'held', chargeSource: 'free' });
    h.clock.set('2026-09-26T22:01:00.000Z');
    const today = await driver.balance.read(id);
    expect(today?.free).toMatchObject({ localDate: '2026-09-27', used: 0 });
    expect((await driver.refund(held.readingId, 'failed')).refunded).toBe(true);
    expect(await driver.usage(id, '2026-09-26')).toMatchObject({ freeUsed: 0, readingsTotal: 0 });
    expect(await driver.usage(id, '2026-09-27')).toMatchObject({ freeUsed: 0 });
    // Today's free reading is still there.
    expect(await driver.hold(id)).toMatchObject({ kind: 'held', chargeSource: 'free' });
    expect(await driver.usage(id, '2026-09-27')).toMatchObject({ freeUsed: 1 });
  });

  it('readings.freeDaily raised mid-day → the second free hold succeeds', async () => {
    const { h, driver } = setup();
    const id = await seedInstall();
    expect(await driver.hold(id)).toMatchObject({ chargeSource: 'free' });
    expect(await driver.hold(id)).toMatchObject({ kind: 'insufficient' });
    h.config.set({ 'readings.freeDaily': 2 });
    expect(await driver.hold(id)).toMatchObject({ kind: 'held', chargeSource: 'free' });
    expect(await driver.usage(id, DAY)).toMatchObject({ freeLimit: 2, freeUsed: 2 });
    // A decrease waits for tomorrow: the snapshot keeps today's 2.
    h.config.set({ 'readings.freeDaily': 1 });
    expect(await driver.usage(id, DAY)).toMatchObject({ freeLimit: 2 });
    expect(await driver.hold(id)).toMatchObject({ kind: 'insufficient', reason: 'noCredits' });
  });

  it('Android: a second install with the same device key gets no second free hold today (RC53)', async () => {
    const { h, driver } = setup();
    const deviceKeyHash = uniqueId('devk');
    const first = await seedInstall({ platform: 'android', deviceKeyHash });
    const second = await seedInstall({ platform: 'android', deviceKeyHash });
    expect(await driver.hold(first)).toMatchObject({ chargeSource: 'free' });
    const denied = await driver.hold(second);
    expect(denied).toMatchObject({ kind: 'insufficient', reason: 'noCredits' });
    expect(await driver.usage(second, DAY)).toMatchObject({ freeUsed: 0 });
    expect(await driver.device(deviceKeyHash, DAY)).toMatchObject({ freeUsed: 1 });
    // Paid credits stay per install.
    await driver.grant(second, 'paid', 1);
    expect(await driver.hold(second)).toMatchObject({ kind: 'held', chargeSource: 'paid' });
    // The next local day the device has a free reading again.
    h.clock.advance({ days: 1 });
    expect(await driver.hold(second)).toMatchObject({ kind: 'held', chargeSource: 'free' });
  });

  it('Android: parallel free holds by two installs of one device take one free reading', async () => {
    const { driver } = setup();
    const deviceKeyHash = uniqueId('devk');
    const a = await seedInstall({ platform: 'android', deviceKeyHash });
    const b = await seedInstall({ platform: 'android', deviceKeyHash });
    const results = await Promise.all([driver.hold(a), driver.hold(b), driver.hold(a)]);
    expect(results.filter((r) => r.kind === 'held')).toHaveLength(1);
    expect(await driver.device(deviceKeyHash, DAY)).toMatchObject({ freeUsed: 1 });
  });

  it('a free Android refund decrements the device row of the hold date', async () => {
    const { driver } = setup();
    const deviceKeyHash = uniqueId('devk');
    const id = await seedInstall({ platform: 'android', deviceKeyHash });
    const held = await driver.hold(id);
    expect((await driver.refund(held.readingId)).refunded).toBe(true);
    expect(await driver.device(deviceKeyHash, DAY)).toMatchObject({ freeUsed: 0 });
    expect(await driver.hold(id)).toMatchObject({ chargeSource: 'free' });
  });

  it('iOS device_reused: free starts on the next local day', async () => {
    const { h, driver } = setup();
    const id = await seedInstall({ deviceReused: true, now: '2026-09-26T08:00:00.000Z' });
    expect(await driver.hold(id)).toMatchObject({ kind: 'insufficient', reason: 'noCredits' });
    h.clock.advance({ days: 1 });
    expect(await driver.hold(id)).toMatchObject({ kind: 'held', chargeSource: 'free' });
  });

  it('free-stop tier: free is skipped, bonus is used, and with nothing else → 402 freePaused', async () => {
    const { driver } = setup();
    driver.budget.tier = 'freeStop';
    const id = await seedInstall();
    await driver.grant(id, 'bonus', 1);
    expect(await driver.hold(id)).toMatchObject({ kind: 'held', chargeSource: 'bonus' });
    const paused = await driver.hold(id);
    expect(paused).toMatchObject({ kind: 'insufficient', reason: 'freePaused' });
    expect(await driver.usage(id, DAY)).toMatchObject({ freeUsed: 0 });
    driver.budget.tier = 'normal';
    expect(await driver.hold(id)).toMatchObject({ kind: 'held', chargeSource: 'free' });
  });

  it('a hold on a committed reading returns consumed and holds nothing', async () => {
    const { driver } = setup();
    const id = await seedInstall();
    const crid = uniqueId('crid');
    const held = await driver.hold(id, crid);
    await driver.commit(held.readingId);
    const v = await driver.stateVersion(id);
    expect(await driver.hold(id, crid)).toMatchObject({ kind: 'consumed', chargeSource: 'free' });
    expect(await driver.stateVersion(id)).toBe(v);
  });

  it('renews a live hold (same attempt, TTL extended) and replaces an expired one by a new attempt', async () => {
    const { h, driver } = setup();
    const id = await seedInstall();
    await driver.grant(id, 'paid', 2);
    await driver.hold(id); // free used
    const crid = uniqueId('crid');
    const first = await driver.hold(id, crid);
    expect(first).toMatchObject({
      chargeSource: 'paid',
      attempt: 1,
      expiresAt: '2026-09-26T10:15:00Z',
    });
    h.clock.advance({ minutes: 10 });
    const renewed = await driver.hold(id, crid);
    expect(renewed).toMatchObject({ renewed: true, attempt: 1, expiresAt: '2026-09-26T10:25:00Z' });
    h.clock.advance({ minutes: 20 });
    const replaced = await driver.hold(id, crid);
    expect(replaced).toMatchObject({
      kind: 'held',
      chargeSource: 'paid',
      attempt: 2,
      renewed: false,
    });
    const refs = (await driver.entries(id))
      .filter((e) => e.refType === 'reading')
      .map((e) => [e.reason, e.refId.split('#')[1]]);
    expect(refs).toEqual([
      ['reading_hold', '1'],
      ['reading_refund', '1'],
      ['reading_hold', '2'],
    ]);
    expect(await driver.balances(id)).toEqual({ bonus: 0, paid: 1 });
    expect(driver.h.metrics.points.some((p) => p.event === 'hold_abandoned')).toBe(true);
  });

  it('rejects a reading of another install and an unknown reading', async () => {
    const { driver } = setup();
    const a = await seedInstall();
    const b = await seedInstall();
    const row = await driver.open(a);
    await expect(driver.balance.hold({ installId: b, readingId: row.id })).rejects.toThrow(
      /unknown reading/,
    );
    await expect(driver.balance.commit({ readingId: 'missing' })).rejects.toThrow(
      /unknown reading/,
    );
  });
});

describe('low-trust caps (03 §2.4, RC65)', () => {
  const network = (ip: string, asn?: number) => ({ ip, asn });

  it('a low-trust free hold counts lt:ip and records the alert-only lt:bucket', async () => {
    const { h, driver } = setup();
    const id = await seedInstall({ trust: 'low', platform: 'android', appVersion: '1.0.0' });
    const ip = '203.0.113.7';
    const held = await driver.hold(id, undefined, { network: network(ip), appVersion: '1.2.0' });
    expect(held).toMatchObject({ kind: 'held', chargeSource: 'free' });
    const day = utcDay(h.clock.now());
    const hash = await ipPrefixHash(h.deps, ip);
    expect(await bindings.RL_KV.get(`lt:ip:${hash}:${day}`)).toBe('1');
    expect(await bindings.RL_KV.get(`lt:bucket:android:1.2.0:${day}`)).toBe('1');
    h.logger.expectNoSensitive(id, ip);
  });

  it('the IP-prefix cap skips free → paid, and with nothing else → 402 lowTrustCap', async () => {
    const { h, driver } = setup();
    h.config.set({ 'abuse.lowTrust.freePerIpPerDay': 1 });
    const ip = '198.51.100.9';
    const first = await seedInstall({ trust: 'low' });
    const second = await seedInstall({ trust: 'low' });
    expect(await driver.hold(first, undefined, { network: network(ip) })).toMatchObject({
      chargeSource: 'free',
    });
    const capped = await driver.hold(second, undefined, { network: network(ip) });
    expect(capped).toMatchObject({ kind: 'insufficient', reason: 'lowTrustCap' });
    await driver.grant(second, 'paid', 1);
    expect(await driver.hold(second, undefined, { network: network(ip) })).toMatchObject({
      chargeSource: 'paid',
    });
  });

  it('a CGNAT ASN gets the higher prefix cap', async () => {
    const { h, driver } = setup();
    h.config.set({
      'abuse.lowTrust.freePerIpPerDay': 1,
      'abuse.lowTrust.freePerCgnatPrefixPerDay': 3,
      'abuse.lowTrust.cgnatAsns': [64500],
    });
    const ip = '192.0.2.44';
    const results = [];
    for (let i = 0; i < 4; i++) {
      const id = await seedInstall({ trust: 'low' });
      results.push(await driver.hold(id, undefined, { network: network(ip, 64500) }));
    }
    expect(results.map((r) => r.kind)).toEqual(['held', 'held', 'held', 'insufficient']);
  });

  it('abuse.lowTrust.freeDaily = 0 → no free hold, reason lowTrustCap', async () => {
    const { h, driver } = setup();
    h.config.set({ 'abuse.lowTrust.freeDaily': 0 });
    const id = await seedInstall({ trust: 'low' });
    expect(await driver.hold(id)).toMatchObject({ kind: 'insufficient', reason: 'lowTrustCap' });
    // A low-trust free hold without a known network still records the version bucket.
    h.config.set({ 'abuse.lowTrust.freeDaily': 1 });
    expect(await driver.hold(id)).toMatchObject({ chargeSource: 'free' });
    const day = utcDay(h.clock.now());
    expect(await bindings.RL_KV.get(`lt:bucket:ios:unknown:${day}`)).not.toBeNull();
  });
});

describe('BalanceService.refund (03 §5.3 step 3)', () => {
  it('bonus → reading_refund +1 for {readingId}#{attempt}; a second refund is a no-op', async () => {
    const { driver } = setup();
    const id = await seedInstall();
    await driver.hold(id);
    await driver.grant(id, 'bonus', 1);
    const held = await driver.hold(id);
    const v = await driver.stateVersion(id);
    expect(await driver.refund(held.readingId, 'failed')).toEqual({
      refunded: true,
      source: 'bonus',
      attempt: 1,
    });
    expect(await driver.refund(held.readingId, 'failed')).toEqual({
      refunded: false,
      source: null,
      attempt: 1,
    });
    expect(await driver.stateVersion(id)).toBe(v + 1);
    expect(await driver.balances(id)).toEqual({ bonus: 1, paid: 0 });
    expect(await driver.reading(held.readingId)).toMatchObject({
      holdState: 'refunded',
      status: 'failed',
    });
    expect(await driver.usage(id, DAY)).toMatchObject({ readingsTotal: 1 });
  });

  it('undelivered paid → reading_undelivered, status expired_refunded, metric', async () => {
    const { h, driver } = setup();
    const id = await seedInstall();
    await driver.hold(id);
    await driver.grant(id, 'paid', 1);
    const held = await driver.hold(id);
    await driver.refund(held.readingId, 'undelivered');
    const last = (await driver.entries(id)).at(-1);
    expect(last).toMatchObject({ reason: 'reading_undelivered', delta: 1, bucket: 'paid' });
    expect(await driver.reading(held.readingId)).toMatchObject({ status: 'expired_refunded' });
    expect(h.metrics.points.map((p) => p.event)).toContain('reading_undelivered_refund');
  });

  it('declined → free back and declined_count + 1 today', async () => {
    const { driver } = setup();
    const id = await seedInstall();
    const held = await driver.hold(id);
    await driver.refund(held.readingId, 'declined');
    expect(await driver.usage(id, DAY)).toMatchObject({ freeUsed: 0, declinedCount: 1 });
    expect(await driver.reading(held.readingId)).toMatchObject({ status: 'declined' });
  });

  it('refunds a free hold whose day row was erased without breaking the batch', async () => {
    const { h, driver } = setup();
    const id = await seedInstall();
    const held = await driver.hold(id);
    h.clock.advance({ days: 1 });
    await db.prepare(`DELETE FROM daily_usage WHERE install_id = ?1`).bind(id).run();
    const v = await driver.stateVersion(id);
    expect((await driver.refund(held.readingId, 'abandoned')).refunded).toBe(true);
    expect(await driver.stateVersion(id)).toBe(v + 1);
    expect(await driver.usage(id, DAY)).toMatchObject({ freeUsed: 0, readingsTotal: 0 });
  });

  it('refund of a reading that is not held, of another attempt or unknown → false', async () => {
    const { driver } = setup();
    const id = await seedInstall();
    const row = await driver.open(id);
    expect((await driver.refund(row.id)).refunded).toBe(false);
    const held = await driver.hold(id);
    expect(
      (await driver.balance.refund({ readingId: held.readingId, reason: 'failed', attempt: 2 }))
        .refunded,
    ).toBe(false);
    expect(await driver.refund('missing')).toEqual({
      refunded: false,
      source: null,
      attempt: null,
    });
  });
});

describe('BalanceService.commit (03 §5.3 step 4)', () => {
  it('held → consumed/completed; a second commit is already_committed', async () => {
    const { driver } = setup();
    const id = await seedInstall();
    const held = await driver.hold(id);
    const v = await driver.stateVersion(id);
    expect(await driver.commit(held.readingId)).toEqual({
      outcome: 'committed',
      chargeSource: 'free',
      attempt: 1,
    });
    expect(await driver.stateVersion(id)).toBe(v + 1);
    expect(await driver.commit(held.readingId)).toMatchObject({ outcome: 'already_committed' });
    expect(await driver.reading(held.readingId)).toMatchObject({
      holdState: 'consumed',
      status: 'completed',
      completedAt: '2026-09-26T10:00:00.000Z',
    });
    // A refund after the commit changes nothing.
    expect((await driver.refund(held.readingId)).refunded).toBe(false);
  });

  it('a commit without a hold is no_hold', async () => {
    const { driver } = setup();
    const id = await seedInstall();
    const row = await driver.open(id);
    expect(await driver.commit(row.id)).toMatchObject({ outcome: 'no_hold', chargeSource: 'none' });
  });

  it('stale-hold cron refunded first → the late commit re-holds a new attempt and consumes it', async () => {
    const { driver } = setup();
    const id = await seedInstall();
    await driver.hold(id);
    await driver.grant(id, 'paid', 1);
    const held = await driver.hold(id);
    await driver.refund(held.readingId, 'abandoned');
    expect(await driver.commit(held.readingId)).toEqual({
      outcome: 'reheld',
      chargeSource: 'paid',
      attempt: 2,
    });
    expect(await driver.balances(id)).toEqual({ bonus: 0, paid: 0 });
    expect(await driver.reading(held.readingId)).toMatchObject({
      holdState: 'consumed',
      status: 'completed',
      attempt: 2,
    });
  });

  it('re-hold after refund takes today’s free reading when one is left', async () => {
    const { driver } = setup();
    const id = await seedInstall();
    const held = await driver.hold(id);
    await driver.refund(held.readingId, 'abandoned');
    expect(await driver.commit(held.readingId)).toMatchObject({
      outcome: 'reheld',
      chargeSource: 'free',
    });
    expect(await driver.usage(id, DAY)).toMatchObject({ freeUsed: 1 });
  });

  it('refunded and no credit left → delivered uncharged, logged commit_after_refund', async () => {
    const { h, driver } = setup();
    const id = await seedInstall();
    const held = await driver.hold(id);
    await driver.refund(held.readingId, 'abandoned');
    await driver.hold(id); // another reading takes the free one
    expect(await driver.commit(held.readingId)).toEqual({
      outcome: 'commit_after_refund',
      chargeSource: 'none',
      attempt: 1,
    });
    expect(await driver.reading(held.readingId)).toMatchObject({
      holdState: 'refunded',
      status: 'completed',
      chargeSource: 'none',
    });
    expect(h.logger.find('commit_after_refund')).toHaveLength(1);
    h.logger.expectNoSensitive(id);
  });

  it('a commit racing the stale-hold refund still settles exactly once', async () => {
    const { driver } = setup();
    const id = await seedInstall();
    await driver.hold(id);
    await driver.grant(id, 'paid', 3);
    for (let i = 0; i < 5; i++) {
      const held = await driver.hold(id);
      await Promise.all([
        driver.commit(held.readingId),
        driver.refund(held.readingId, 'abandoned'),
      ]);
    }
    const paid = (await driver.balances(id)).paid;
    const refs = (await driver.entries(id)).filter((e) => e.refType === 'reading');
    const holds = refs.filter((e) => e.reason === 'reading_hold').length;
    const refunds = refs.filter((e) => e.reason === 'reading_refund').length;
    expect(paid).toBe(3 - holds + refunds);
    expect(paid).toBeGreaterThanOrEqual(0);
  });
});
