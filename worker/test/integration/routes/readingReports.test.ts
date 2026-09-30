import { describe, expect, it, vi } from 'vitest';
import { openReport, sealReport } from '../../../src/crypto/reportPayload';
import { parseKeyring } from '../../../src/crypto/keyring';
import { ReportRepo } from '../../../src/repos/ReportRepo';
import { REPORTS_PER_DAY } from '../../../src/routes/readingReports';
import { SeqIdGenerator } from '../../fakes/SeqIdGenerator';
import {
  createHarness,
  TEST_REPORT_ENC_KEY,
  uniqueId,
  type TestHarness,
} from '../../fakes/testDeps';
import { APP_HEADERS, authedApp, errorOf } from '../../helpers/app';
import { db, seedInstall, seedReading } from '../../helpers/db';

/** Report IDs unique across the harnesses of this file (shared D1). */
class UniqueIds extends SeqIdGenerator {
  override uuidV7(): string {
    return uniqueId('rep');
  }
}

const READING = {
  title: 'The Star',
  overview: 'A calm reading.',
  cards: [{ positionId: 'single', cardId: 'maj17', text: 'Hope returns.' }],
  synthesis: 'Rest and renew.',
  reflectionPrompts: ['What gives you hope?'],
};

function setup(): TestHarness {
  const h = createHarness({ overrides: { ids: new UniqueIds() } });
  h.clock.set('2026-09-30T10:00:00.000Z');
  return h;
}

async function report(
  h: TestHarness,
  installId: string,
  clientReadingId: string,
  body: Record<string, unknown> = {},
  key: string = uniqueId('1de0'),
): Promise<Response> {
  return authedApp(h).request(`/v1/readings/${clientReadingId}/report`, {
    method: 'POST',
    headers: {
      ...APP_HEADERS,
      'content-type': 'application/json',
      'X-Test-Install': installId,
      'Idempotency-Key': key,
    },
    body: JSON.stringify({
      reason: 'harmful_advice',
      question: 'Will it work out?',
      note: 'felt pushy',
      reading: READING,
      locale: 'de',
      ...body,
    }),
  });
}

async function completedReading(installId: string) {
  const reading = await seedReading(installId, { status: 'completed' });
  await db
    .prepare(`UPDATE readings SET prompt_version = 'v1', model = ?2 WHERE id = ?1`)
    .bind(reading.id, 'anthropic/claude-sonnet-5')
    .run();
  return reading;
}

describe('POST /v1/readings/{clientReadingId}/report (03 §9.7; CS7, RC22, RC72)', () => {
  it('stores the report AES-GCM sealed for 90 days and emits reading_reported', async () => {
    const h = setup();
    const id = await seedInstall({ timezone: 'Europe/Berlin' });
    const reading = await completedReading(id);

    const res = await report(h, id, reading.clientReadingId);
    expect(res.status).toBe(201);
    const body = await res.json<{ reportId: string; status: string }>();
    expect(body.status).toBe('received');

    const row = await new ReportRepo(db).findByReading(id, reading.clientReadingId);
    expect(row).toMatchObject({
      id: body.reportId,
      readingId: reading.id,
      reason: 'harmful_advice',
      locale: 'de',
      localDate: '2026-09-30',
      promptVersion: 'v1',
      model: 'anthropic/claude-sonnet-5',
      createdAt: '2026-09-30T10:00:00.000Z',
      expiresAt: '2026-12-29T10:00:00.000Z',
    });
    // Ciphertext only: no plaintext in the blob, and it opens with the key and the right AAD.
    const blob = row?.payloadEnc ?? new Uint8Array();
    expect(new TextDecoder().decode(blob)).not.toContain('Will it work out?');
    const keyring = parseKeyring(TEST_REPORT_ENC_KEY, 'REPORT_ENC_KEY');
    const ref = { installId: id, clientReadingId: reading.clientReadingId };
    expect(await openReport(h.deps.crypto, keyring, ref, blob)).toEqual({
      reading: READING,
      question: 'Will it work out?',
      note: 'felt pushy',
    });
    await expect(
      openReport(h.deps.crypto, keyring, { ...ref, clientReadingId: 'other' }, blob),
    ).rejects.toThrow();

    expect(h.metrics.points).toContainEqual({
      event: 'reading_reported',
      code: 'harmful_advice',
      locale: 'de',
      platform: 'ios',
      model: 'anthropic/claude-sonnet-5',
      promptVersion: 'v1',
    });
    h.logger.expectNoSensitive('Will it work out?', 'felt pushy', 'Hope returns.');
  });

  it('accepts a declined reading without question or note', async () => {
    const h = setup();
    const id = await seedInstall();
    const reading = await seedReading(id, { status: 'declined' });
    const res = await report(h, id, reading.clientReadingId, {
      reason: 'other',
      question: undefined,
      note: undefined,
      reading: { messageKey: 'refusalGeneric' },
    });
    expect(res.status).toBe(201);
    const row = await new ReportRepo(db).findByReading(id, reading.clientReadingId);
    const keyring = parseKeyring(TEST_REPORT_ENC_KEY, 'REPORT_ENC_KEY');
    expect(
      await openReport(
        h.deps.crypto,
        keyring,
        { installId: id, clientReadingId: reading.clientReadingId },
        row?.payloadEnc ?? new Uint8Array(),
      ),
    ).toEqual({ reading: { messageKey: 'refusalGeneric' } });
    expect(h.metrics.points.at(-1)).toEqual({
      event: 'reading_reported',
      code: 'other',
      locale: 'de',
      platform: 'ios',
    });
  });

  it('a second report of the same reading returns the stored 201 and changes nothing', async () => {
    const h = setup();
    const id = await seedInstall();
    const reading = await completedReading(id);
    const first = await (await report(h, id, reading.clientReadingId)).json<{ reportId: string }>();
    const again = await report(h, id, reading.clientReadingId, { reason: 'sexual' });
    expect(again.status).toBe(201);
    expect(await again.json()).toEqual({ reportId: first.reportId, status: 'received' });
    expect((await new ReportRepo(db).findByReading(id, reading.clientReadingId))?.reason).toBe(
      'harmful_advice',
    );
    expect(h.metrics.count('reading_reported')).toBe(1);
  });

  it('replays the same Idempotency-Key', async () => {
    const h = setup();
    const id = await seedInstall();
    const reading = await completedReading(id);
    const key = uniqueId('1de0');
    const first = await report(h, id, reading.clientReadingId, {}, key);
    const replay = await report(h, id, reading.clientReadingId, {}, key);
    expect(replay.headers.get('Idempotent-Replayed')).toBe('true');
    expect(await replay.json()).toEqual(await first.json());
  });

  it('404 for an unknown, other-install or not yet finished reading', async () => {
    const h = setup();
    const id = await seedInstall();
    const other = await seedInstall();
    const held = await seedReading(id, { status: 'held' });
    const foreign = await completedReading(other);
    for (const crid of [uniqueId('none'), held.clientReadingId, foreign.clientReadingId]) {
      const res = await report(h, id, crid);
      expect(res.status).toBe(404);
      expect((await errorOf(res)).code).toBe('NOT_FOUND');
    }
  });

  it(`allows ${String(REPORTS_PER_DAY)} reports per install per local day, then 429 reportLimit`, async () => {
    const h = setup();
    h.clock.set('2026-09-30T20:00:00.000Z'); // 22:00 in Berlin
    const id = await seedInstall({ timezone: 'Europe/Berlin' });
    for (let i = 0; i < REPORTS_PER_DAY; i++) {
      const reading = await completedReading(id);
      expect((await report(h, id, reading.clientReadingId)).status).toBe(201);
    }
    const reading = await completedReading(id);
    const res = await report(h, id, reading.clientReadingId);
    expect(res.status).toBe(429);
    const error = await errorOf(res);
    expect(error).toMatchObject({ code: 'RATE_LIMITED', details: { reason: 'reportLimit' } });
    expect(res.headers.get('Retry-After')).toBe('7200');
    // A limited submit is not stored for replay; the next local day accepts it.
    h.clock.set('2026-09-30T22:00:00.000Z');
    expect((await report(h, id, reading.clientReadingId)).status).toBe(201);
  });

  it('validates the body', async () => {
    const h = setup();
    const id = await seedInstall();
    const reading = await completedReading(id);
    const cases: Record<string, unknown>[] = [
      { reason: 'spam' },
      { note: 'x'.repeat(501) },
      { locale: 'xx' },
      { reading: { text: 'x'.repeat(40_000) } },
    ];
    for (const body of cases) {
      const res = await report(h, id, reading.clientReadingId, body);
      expect(res.status).toBe(400);
    }
  });

  it('answers with the stored report when a concurrent insert wins', async () => {
    const h = setup();
    const id = await seedInstall();
    const reading = await completedReading(id);
    const repo = new ReportRepo(db);
    // First lookup misses (as if the other submit had not committed yet), then the insert conflicts.
    const keyring = parseKeyring(TEST_REPORT_ENC_KEY, 'REPORT_ENC_KEY');
    await repo.insert({
      id: 'winner-report',
      installId: id,
      clientReadingId: reading.clientReadingId,
      readingId: reading.id,
      localDate: '2026-09-30',
      reason: 'other',
      locale: 'en',
      promptVersion: null,
      model: null,
      payloadEnc: await sealReport(
        h.deps.crypto,
        keyring,
        { installId: id, clientReadingId: reading.clientReadingId },
        { reading: {} },
      ),
      createdAt: '2026-09-30T09:00:00.000Z',
      expiresAt: '2026-12-29T09:00:00.000Z',
    });
    const spy = vi.spyOn(ReportRepo.prototype, 'findByReading').mockResolvedValueOnce(null);
    try {
      const res = await report(h, id, reading.clientReadingId);
      expect(await res.json()).toEqual({ reportId: 'winner-report', status: 'received' });
    } finally {
      spy.mockRestore();
    }
  });
});

describe('crypto/reportPayload', () => {
  it('rejects an unknown version or kid', async () => {
    const h = setup();
    const keyring = parseKeyring(TEST_REPORT_ENC_KEY, 'REPORT_ENC_KEY');
    const ref = { installId: 'i', clientReadingId: 'c' };
    const blob = await sealReport(h.deps.crypto, keyring, ref, { reading: { a: 1 } });
    await expect(openReport(h.deps.crypto, keyring, ref, new Uint8Array([9]))).rejects.toThrow(
      /version/,
    );
    const other = parseKeyring('zz:AwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwM', 'REPORT_ENC_KEY');
    await expect(openReport(h.deps.crypto, other, ref, blob)).rejects.toThrow(/kid/);
    const bad = Uint8Array.of(1);
    await expect(openReport(h.deps.crypto, keyring, ref, bad)).rejects.toThrow(/version/);
  });
});
