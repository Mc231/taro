import { describe, expect, it } from 'vitest';
import { ReadingRepo } from '../../../src/repos/ReadingRepo';
import { ReportRepo, type NewReport } from '../../../src/repos/ReportRepo';
import { uniqueId } from '../../fakes/testDeps';
import { db, NOW, seedInstall, seedReading } from '../../helpers/db';

const readings = new ReadingRepo(db);
const reports = new ReportRepo(db);
const LATER = '2026-09-26T10:15:00.000Z';

describe('ReadingRepo', () => {
  it('inserts metadata only and finds by id and clientReadingId', async () => {
    const installId = await seedInstall();
    const r = await seedReading(installId, { holdExpiresAt: LATER, hasQuestion: false });
    const row = await readings.findByClientId(installId, r.clientReadingId);
    expect(row).toMatchObject({
      id: r.id,
      hasQuestion: false,
      status: 'held',
      attempt: 1,
      holdSource: null,
      holdState: 'none',
      holdExpiresAt: LATER,
      chargeSource: 'none',
      ackedAt: null,
    });
    expect(await readings.findById(r.id)).toEqual(row);
    expect(await readings.insert({ ...r, id: uniqueId('dupe') })).toBe(false);
    expect(await readings.findById('missing')).toBeNull();
    expect(await readings.findByClientId(installId, 'nope')).toBeNull();
  });

  it('runs hold → refund → re-hold → consume as compare-and-set (RC52)', async () => {
    const r = await seedReading(await seedInstall());
    const hold = (attempt: number) =>
      readings
        .holdStmt({
          id: r.id,
          attempt,
          source: 'free',
          holdLocalDate: '2026-09-26',
          holdExpiresAt: LATER,
        })
        .run();

    expect((await hold(1)).meta.changes).toBe(1);
    expect((await hold(1)).meta.changes).toBe(0);
    expect(await readings.findById(r.id)).toMatchObject({
      holdState: 'held',
      holdSource: 'free',
      chargeSource: 'free',
      holdLocalDate: '2026-09-26',
    });
    expect((await readings.refundStmt(r.id, 'expired_hold').run()).meta.changes).toBe(1);
    expect((await readings.refundStmt(r.id, 'expired_hold').run()).meta.changes).toBe(0);
    expect(await readings.findById(r.id)).toMatchObject({
      holdState: 'refunded',
      status: 'expired_hold',
    });
    expect((await hold(2)).meta.changes).toBe(1);
    expect((await readings.consumeStmt(r.id, LATER).run()).meta.changes).toBe(1);
    expect((await readings.consumeStmt(r.id, LATER).run()).meta.changes).toBe(0);
    expect(await readings.findById(r.id)).toMatchObject({
      attempt: 2,
      holdState: 'consumed',
      status: 'completed',
      completedAt: LATER,
    });
  });

  it('transitions only from the expected statuses', async () => {
    const r = await seedReading(await seedInstall());
    expect(await readings.transition(r.id, ['generating'], 'failed')).toBe(false);
    expect(await readings.transition(r.id, ['held', 'generating'], 'generating')).toBe(true);
    expect((await readings.findById(r.id))?.status).toBe('generating');
  });

  it('records result metadata and keeps earlier values it is not given', async () => {
    const r = await seedReading(await seedInstall());
    await readings.recordResult(r.id, {
      status: 'completed',
      chargeSource: 'paid',
      safetyCategory: null,
      safetyLayer: null,
      promptVersion: 'v1',
      model: 'claude-opus-5',
      inputTokens: 1200,
      cacheReadTokens: 1000,
      cacheWriteTokens: 0,
      outputTokens: 900,
      costMicroUsd: 12345,
      latencyMs: 8000,
      completedAt: LATER,
    });
    await readings.recordResult(r.id, { status: 'completed' });
    expect(await readings.findById(r.id)).toMatchObject({
      status: 'completed',
      chargeSource: 'paid',
      completedAt: LATER,
      promptVersion: null,
      errorCode: null,
    });
    await readings.recordResult(r.id, {
      status: 'declined',
      safetyCategory: 'self_harm',
      safetyLayer: 'L1',
      errorCode: 'x',
    });
    expect(await readings.findById(r.id)).toMatchObject({
      status: 'declined',
      safetyCategory: 'self_harm',
      safetyLayer: 'L1',
    });
  });

  it('acks delivery once (RC51) and lists expired holds', async () => {
    const installId = await seedInstall();
    const r = await seedReading(installId);
    expect(await readings.markAcked(installId, r.clientReadingId, LATER)).toBe(true);
    expect(await readings.markAcked(installId, r.clientReadingId, LATER)).toBe(false);
    expect((await readings.findById(r.id))?.ackedAt).toBe(LATER);

    const stale = await seedReading(installId);
    await readings
      .holdStmt({
        id: stale.id,
        attempt: 1,
        source: 'paid',
        holdLocalDate: null,
        holdExpiresAt: '2001-01-01T00:00:00.000Z',
      })
      .run();
    const due = await readings.expiredHolds('2001-01-02T00:00:00.000Z');
    expect(due.map((x) => x.id)).toEqual([stale.id]);
    expect(await readings.expiredHolds('2000-12-31T00:00:00.000Z', 10)).toEqual([]);
  });
});

function report(
  installId: string,
  clientReadingId: string,
  overrides: Partial<NewReport> = {},
): NewReport {
  return {
    id: uniqueId('rprt'),
    installId,
    clientReadingId,
    readingId: null,
    localDate: '2026-09-26',
    reason: 'harmful_advice',
    locale: 'de',
    promptVersion: 'v1',
    model: 'claude-sonnet-5',
    payloadEnc: new Uint8Array([1, 2, 3, 4]),
    createdAt: NOW,
    expiresAt: '2026-12-25T10:00:00.000Z',
    ...overrides,
  };
}

describe('ReportRepo (RC22)', () => {
  it('stores one encrypted report per reading and counts per day', async () => {
    const installId = await seedInstall();
    const r = await seedReading(installId);
    const first = report(installId, r.clientReadingId, { readingId: r.id });
    expect(await reports.insert(first)).toBe(true);
    expect(await reports.insert({ ...first, id: uniqueId('again'), reason: 'other' })).toBe(false);
    expect(await reports.findByReading(installId, r.clientReadingId)).toEqual(first);
    expect(await reports.findByReading(installId, 'nope')).toBeNull();
    await reports.insert(report(installId, uniqueId('crid')));
    expect(await reports.countForDay(installId, '2026-09-26')).toBe(2);
    expect(await reports.countForDay(installId, '2026-09-27')).toBe(0);
  });

  it('rejects an unknown reason', async () => {
    const installId = await seedInstall();
    await expect(
      reports.insert(report(installId, 'c', { reason: 'spam' as never })),
    ).rejects.toThrow(/CHECK/i);
  });

  it('lists reports by creation window and purges expired ones', async () => {
    const installId = await seedInstall();
    const old = report(installId, uniqueId('crid'), {
      createdAt: '2001-01-01T00:00:00.000Z',
      expiresAt: '2001-04-01T00:00:00.000Z',
    });
    await reports.insert(old);
    const listed = await reports.listCreatedBetween(
      '2001-01-01T00:00:00.000Z',
      '2001-01-02T00:00:00.000Z',
    );
    expect(listed.map((x) => x.id)).toEqual([old.id]);
    expect(await reports.purgeExpired('2001-05-01T00:00:00.000Z')).toBe(1);
    expect(
      await reports.listCreatedBetween('2001-01-01T00:00:00.000Z', '2001-01-02T00:00:00.000Z', 5),
    ).toEqual([]);
  });
});

describe('erasure and retention across readings and reports (RC37)', () => {
  it('erases reports before readings in one batch', async () => {
    const installId = await seedInstall();
    const r = await seedReading(installId);
    await reports.insert(report(installId, r.clientReadingId, { readingId: r.id }));
    await db.batch([reports.eraseStmt(installId), readings.eraseStmt(installId)]);
    expect(await readings.findById(r.id)).toBeNull();
    expect(await reports.findByReading(installId, r.clientReadingId)).toBeNull();
  });

  it('keeps an old reading while a live report references it', async () => {
    const installId = await seedInstall();
    const old = '2001-01-01T00:00:00.000Z';
    const referenced = await seedReading(installId, { createdAt: old });
    const plain = await seedReading(installId, { createdAt: old });
    await reports.insert(
      report(installId, referenced.clientReadingId, { readingId: referenced.id }),
    );
    expect(await readings.purgeCreatedBefore('2002-01-01T00:00:00.000Z')).toBe(1);
    expect(await readings.findById(plain.id)).toBeNull();
    expect(await readings.findById(referenced.id)).not.toBeNull();
  });
});
