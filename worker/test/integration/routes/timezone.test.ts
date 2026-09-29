import { describe, expect, it } from 'vitest';
import type { BalanceDto } from '../../../src/domain/allowance';
import { DailyUsageRepo } from '../../../src/repos/DailyUsageRepo';
import { InstallRepo } from '../../../src/repos/InstallRepo';
import { InstallService } from '../../../src/services/InstallService';
import { createHarness, uniqueId, type TestHarness } from '../../fakes/testDeps';
import { APP_HEADERS, authedApp, errorOf } from '../../helpers/app';
import { db, seedInstall } from '../../helpers/db';

async function put(
  h: TestHarness,
  installId: string,
  body: unknown,
  key: string | null = uniqueId('idem'),
): Promise<Response> {
  return await authedApp(h).request('/v1/installs/me/timezone', {
    method: 'PUT',
    headers: {
      ...APP_HEADERS,
      'X-Test-Install': installId,
      'Content-Type': 'application/json',
      ...(key === null ? {} : { 'Idempotency-Key': key }),
    },
    body: JSON.stringify(body),
  });
}

const repo = new InstallRepo(db);

describe('PUT /v1/installs/me/timezone (03 §3.5)', () => {
  it('stores a new zone, bumps state_version and returns the BalanceDto in that zone', async () => {
    const h = createHarness();
    const id = await seedInstall({ timezone: 'UTC' });
    const res = await put(h, id, { timezone: 'America/New_York' });
    expect(res.status).toBe(200);
    expect(res.headers.get('Date')).not.toBeNull();
    const b = await res.json<BalanceDto>();
    expect(b.free).toMatchObject({
      timezone: 'America/New_York',
      localDate: '2026-09-26',
      resetsAt: '2026-09-27T04:00:00Z',
    });
    expect(b.ledgerVersion).toBe(1);
    expect(await repo.findById(id)).toMatchObject({
      timezone: 'America/New_York',
      tzChangedAt: '2026-09-26T10:00:00.000Z',
      stateVersion: 1,
    });
  });

  it('the same zone is a 200 no-op (no cooldown start, no version bump)', async () => {
    const h = createHarness();
    const id = await seedInstall({ timezone: 'Europe/Kyiv' });
    const res = await put(h, id, { timezone: 'Europe/Kyiv' });
    expect(res.status).toBe(200);
    expect(await repo.findById(id)).toMatchObject({ tzChangedAt: null, stateVersion: 0 });
  });

  it('a second change inside readings.tzCooldownHours → 409 with details.allowedAfter; later → 200', async () => {
    const h = createHarness();
    const id = await seedInstall({ timezone: 'UTC' });
    expect((await put(h, id, { timezone: 'Asia/Kolkata' })).status).toBe(200);

    h.clock.advance({ hours: 23, minutes: 59 });
    const key = uniqueId('idem');
    const tooSoon = await put(h, id, { timezone: 'Asia/Kathmandu' }, key);
    expect(tooSoon.status).toBe(409);
    expect(await errorOf(tooSoon)).toMatchObject({
      code: 'TIMEZONE_CHANGE_TOO_SOON',
      retryable: false,
      details: { allowedAfter: '2026-09-27T10:00:00.000Z' },
    });

    // 409 is not a terminal outcome: the same key runs again after the cooldown (RC49).
    h.clock.advance({ minutes: 1 });
    const later = await put(h, id, { timezone: 'Asia/Kathmandu' }, key);
    expect(later.status).toBe(200);
    expect(later.headers.get('Idempotent-Replayed')).toBeNull();
    expect((await later.json<BalanceDto>()).free.timezone).toBe('Asia/Kathmandu');
  });

  it('honours a configured cooldown (range 12–168 h, RC8)', async () => {
    const h = createHarness();
    h.config.set({ 'readings.tzCooldownHours': 12 });
    const id = await seedInstall({ timezone: 'UTC' });
    expect((await put(h, id, { timezone: 'Europe/Kyiv' })).status).toBe(200);
    h.clock.advance({ hours: 12 });
    expect((await put(h, id, { timezone: 'Europe/Berlin' })).status).toBe(200);
  });

  it('moving the zone moves the free day: a new local date has its own allowance', async () => {
    const h = createHarness();
    const id = await seedInstall({ timezone: 'UTC' });
    await new DailyUsageRepo(db).takeFreeStmt({ installId: id, localDate: '2026-09-26' }, 1).run();
    const res = await put(h, id, { timezone: 'Pacific/Kiritimati' });
    const b = await res.json<BalanceDto>();
    expect(b.free).toMatchObject({ localDate: '2026-09-27', used: 0, remaining: 1 });
  });

  it('replays a completed change byte for byte with the same key', async () => {
    const h = createHarness();
    const id = await seedInstall({ timezone: 'UTC' });
    const key = uniqueId('idem');
    const first = await put(h, id, { timezone: 'Europe/Berlin' }, key);
    const firstBody = await first.text();
    h.clock.advance({ minutes: 5 });
    const replay = await put(h, id, { timezone: 'Europe/Berlin' }, key);
    expect(replay.status).toBe(200);
    expect(replay.headers.get('Idempotent-Replayed')).toBe('true');
    expect(replay.headers.get('Date')).toBe('Sat, 26 Sep 2026 10:05:00 GMT');
    expect(await replay.text()).toBe(firstBody);
  });

  it('rejects a non-IANA zone with 400 VALIDATION_FAILED (stored for replay)', async () => {
    const h = createHarness();
    const id = await seedInstall({ timezone: 'UTC' });
    for (const timezone of ['Mars/Olympus_Mons', '+05:00', '', 42]) {
      const key = uniqueId('idem');
      const res = await put(h, id, { timezone }, key);
      expect(res.status, String(timezone)).toBe(400);
      expect((await errorOf(res)).code).toBe('VALIDATION_FAILED');
      const replay = await put(h, id, { timezone }, key);
      expect(replay.headers.get('Idempotent-Replayed')).toBe('true');
    }
    expect(await repo.findById(id)).toMatchObject({ timezone: 'UTC', tzChangedAt: null });
  });

  it('requires Idempotency-Key and the install token', async () => {
    const h = createHarness();
    const id = await seedInstall({ timezone: 'UTC' });
    const noKey = await put(h, id, { timezone: 'Europe/Berlin' }, null);
    expect(noKey.status).toBe(400);
    expect((await errorOf(noKey)).code).toBe('IDEMPOTENCY_KEY_REQUIRED');

    const unknown = await put(h, uniqueId('ghost'), { timezone: 'Europe/Berlin' });
    expect(unknown.status).toBe(401);
    expect((await errorOf(unknown)).code).toBe('UNAUTHENTICATED');
  });

  it('a lost compare-and-set is decided against the winning change', async () => {
    const h = createHarness();
    const id = await seedInstall({ timezone: 'UTC' });
    const stale = await repo.findById(id);
    if (stale === null) throw new Error('seed failed');
    // A concurrent request wins first.
    expect(await new InstallService(h.deps).changeTimezone(stale, 'Asia/Kolkata')).toBe('changed');
    // Same target zone → the loser is a no-op.
    expect(await new InstallService(h.deps).changeTimezone(stale, 'Asia/Kolkata')).toBe(
      'unchanged',
    );
    // Different zone → the winner's change just started the cooldown.
    await expect(
      new InstallService(h.deps).changeTimezone(stale, 'Asia/Tokyo'),
    ).rejects.toMatchObject({
      code: 'TIMEZONE_CHANGE_TOO_SOON',
    });
    // The row vanished (never in practice) → 401.
    await expect(
      new InstallService(h.deps).changeTimezone({ ...stale, id: uniqueId('ghost') }, 'Asia/Tokyo'),
    ).rejects.toMatchObject({ code: 'UNAUTHENTICATED' });
  });
});
