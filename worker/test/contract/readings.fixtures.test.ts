import { describe, expect, it } from 'vitest';
import type { z } from '@hono/zod-openapi';
import { ErrorEnvelopeSchema } from '../../src/http/errors';
import { IdempotencyRepo } from '../../src/repos/IdempotencyRepo';
import {
  HoldRequestSchema,
  HoldSchema,
  ReadingRequestSchema,
  ReadingResponseSchema,
  ReadingStateSchema,
} from '../../src/routes/readings';
import { READINGS_ROUTE } from '../../src/services/ReadingService';
import { SeqIdGenerator } from '../fakes/SeqIdGenerator';
import { db, seedInstall } from '../helpers/db';
import { ReadingDriver } from '../helpers/readingDriver';
import {
  ackReading,
  getReading,
  postHold,
  postReading,
  readingHarness,
  THREE_CARDS,
  type ReadingHarness,
} from '../helpers/readings';

/**
 * Contract fixtures of the AI reading routes (03 §9.0, §9.1; RC30, RC49,
 * RC51), exported like `fixtures.test.ts` (`npm run contract:update`
 * rewrites them; `melos run contract:sync` copies them to the app):
 * `readings.hold.*`, `readings.create.request`, `readings.completed.response`,
 * `readings.declined.response`, `readings.status.response` and the error
 * envelopes `INSUFFICIENT_CREDITS`, `AI_UNAVAILABLE`, `HOLD_CONFLICT`,
 * `READING_EXPIRED_REFUNDED`. The ack is `204` without a body.
 *
 * Also exports one sample reading per spread size to
 * `test/fixtures/readings/<spread>.json` (the Phase 14 design brief; the
 * text is `FakeAiProvider`'s until real samples are recorded with the
 * Sprint 8.0 keys).
 */
const NOW = '2026-09-26T10:00:00.000Z';

async function exportFixture(name: string, value: unknown): Promise<void> {
  await expect(`${JSON.stringify(value, null, 2)}\n`).toMatchFileSnapshot(
    `./fixtures/${name}.json`,
  );
}

function parsed<S extends z.ZodType>(schema: S, value: unknown): z.infer<S> {
  const result = schema.safeParse(value);
  expect(result.success, JSON.stringify(result.error?.issues)).toBe(true);
  return value as z.infer<S>;
}

function harness(prefix: string): ReadingHarness {
  const h = readingHarness({ overrides: { ids: new SeqIdGenerator(prefix) } });
  h.clock.set(NOW);
  return h;
}

const rid = (name: string) => ({ headers: { 'X-Request-Id': `req-${name}` } });

async function exportError(res: Response, code: string, status: number): Promise<void> {
  expect(res.status).toBe(status);
  const body = parsed(ErrorEnvelopeSchema, await res.json());
  expect(body.error.code).toBe(code);
  await exportFixture(`errors.${code.toLowerCase()}`, body);
}

describe('contract fixtures: readings', () => {
  it('exports the hold request, its 201 and the 402', async () => {
    const h = harness('0e0e0e01');
    const installId = '0e0e0e0e-0000-4000-8000-000000000001';
    await seedInstall({ id: installId, timezone: 'Europe/Berlin' });
    const clientReadingId = '0e0e0e0e-0000-4000-8000-0000000000c1';
    const request = parsed(HoldRequestSchema, {
      clientReadingId,
      spread: { id: 'three_ppf', version: 1 },
      locale: 'de',
    });
    const res = await postHold(h, installId, clientReadingId, request, rid('hold'));
    expect(res.status).toBe(201);
    await exportFixture('readings.hold.request', request);
    await exportFixture('readings.hold.response', parsed(HoldSchema, await res.json()));

    // The free reading is held; another draw without credit → 402.
    const other = '0e0e0e0e-0000-4000-8000-0000000000c2';
    await postReading(h, installId, clientReadingId, {
      ...request,
      cards: THREE_CARDS,
      locale: 'en',
      drawnAt: '2026-09-26T09:59:00Z',
    });
    await exportError(
      await postHold(h, installId, other, { ...request, clientReadingId: other }, rid('no-credit')),
      'INSUFFICIENT_CREDITS',
      402,
    );
  });

  it('exports the reading request, completed, status, declined and failure responses', async () => {
    const h = harness('0e0e0e02');
    const installId = '0e0e0e0e-0000-4000-8000-000000000002';
    await seedInstall({ id: installId, timezone: 'Europe/Berlin' });
    await new ReadingDriver(h).grant(installId, 'paid', 3);
    const clientReadingId = '0e0e0e0e-0000-4000-8000-0000000000d1';
    const request = parsed(ReadingRequestSchema, {
      clientReadingId,
      spread: { id: 'three_ppf', version: 1 },
      cards: THREE_CARDS,
      question: 'How can I approach the change at work?',
      locale: 'en',
      drawnAt: '2026-09-26T09:59:00Z',
    });
    const res = await postReading(h, installId, clientReadingId, request, rid('reading'));
    expect(res.status).toBe(200);
    await exportFixture('readings.create.request', request);
    await exportFixture(
      'readings.completed.response',
      parsed(ReadingResponseSchema, await res.json()),
    );
    const status = await getReading(h, installId, clientReadingId);
    await exportFixture(
      'readings.status.response',
      parsed(ReadingStateSchema, await status.json()),
    );
    expect((await ackReading(h, installId, clientReadingId)).status).toBe(204);

    const declinedId = '0e0e0e0e-0000-4000-8000-0000000000d2';
    const declined = await postReading(
      h,
      installId,
      declinedId,
      { ...request, clientReadingId: declinedId, question: 'Should I end it all tonight?' },
      { country: 'DE' },
    );
    await exportFixture(
      'readings.declined.response',
      parsed(ReadingResponseSchema, await declined.json()),
    );

    const failedId = '0e0e0e0e-0000-4000-8000-0000000000d3';
    h.ai.anthropic.script({ kind: 'timeout' });
    await exportError(
      await postReading(
        h,
        installId,
        failedId,
        { ...request, clientReadingId: failedId },
        rid('ai-unavailable'),
      ),
      'AI_UNAVAILABLE',
      503,
    );
  });

  it('exports HOLD_CONFLICT and READING_EXPIRED_REFUNDED', async () => {
    const h = harness('0e0e0e03');
    const installId = '0e0e0e0e-0000-4000-8000-000000000003';
    await seedInstall({ id: installId, timezone: 'Europe/Berlin' });
    const lost = '0e0e0e0e-0000-4000-8000-0000000000e1';
    const body = {
      clientReadingId: lost,
      spread: { id: 'single', version: 1 },
      cards: [{ positionId: 'focus', cardId: 'major_17', reversed: false }],
      locale: 'en',
      drawnAt: '2026-09-26T09:59:00Z',
    };
    // No credit on an existing row (the paywall was shown before the draw).
    await postHold(h, installId, '0e0e0e0e-0000-4000-8000-0000000000e0', {
      clientReadingId: '0e0e0e0e-0000-4000-8000-0000000000e0',
      spread: body.spread,
      locale: 'en',
    });
    await postHold(h, installId, lost, {
      clientReadingId: lost,
      spread: body.spread,
      locale: 'en',
    });
    await postReading(h, installId, '0e0e0e0e-0000-4000-8000-0000000000e0', {
      ...body,
      clientReadingId: '0e0e0e0e-0000-4000-8000-0000000000e0',
    });
    await exportError(
      await postReading(h, installId, lost, body, rid('hold-conflict')),
      'HOLD_CONFLICT',
      409,
    );

    const expired = '0e0e0e0e-0000-4000-8000-0000000000e2';
    await new ReadingDriver(h).grant(installId, 'paid', 1);
    expect(
      (await postReading(h, installId, expired, { ...body, clientReadingId: expired })).status,
    ).toBe(200);
    await new IdempotencyRepo(db).deleteBody({
      installId,
      route: READINGS_ROUTE,
      key: expired,
    });
    const res = await h.app.request(`/v1/readings/${expired}`, {
      headers: {
        'X-Taro-Platform': 'ios',
        'X-Taro-App-Version': '1.2.0+14',
        'X-Taro-Locale': 'de',
        'X-Test-Install': installId,
        'X-Request-Id': 'req-expired',
      },
    });
    await exportError(res, 'READING_EXPIRED_REFUNDED', 410);
  });

  it.each([
    ['single', ['focus']],
    ['three_ppf', ['past', 'present', 'future']],
    ['relationship', ['you', 'other', 'connection', 'challenge', 'potential']],
    [
      'celtic_cross',
      [
        'present',
        'challenge',
        'foundation',
        'recent_past',
        'potential',
        'near_future',
        'self',
        'environment',
        'hopes_fears',
        'outcome',
      ],
    ],
  ])('exports a sample %s reading (Phase 14 brief)', async (spread, positions) => {
    const h = harness(`0e0e0e1${String(positions.length % 10)}`);
    const installId = `0e0e0e0e-0000-4000-8000-00000000010${String(positions.length % 10)}`;
    await seedInstall({ id: installId, timezone: 'UTC' });
    const deck = ['major_00', 'major_01', 'cups_02', 'wands_03', 'swords_04', 'pentacles_05'];
    const more = ['major_06', 'cups_07', 'wands_08', 'swords_09'];
    const cards = positions.map((positionId, i) => ({
      positionId,
      cardId: [...deck, ...more][i] ?? 'major_21',
      reversed: i % 3 === 1,
    }));
    const clientReadingId = `0e0e0e0e-0000-4000-8000-0000000002${String(positions.length).padStart(2, '0')}`;
    const res = await postReading(h, installId, clientReadingId, {
      clientReadingId,
      spread: { id: spread, version: 1 },
      cards,
      question: 'What should I keep in mind this week?',
      locale: 'en',
      drawnAt: '2026-09-26T09:59:00Z',
    });
    expect(res.status, await res.clone().text()).toBe(200);
    const body = parsed(ReadingResponseSchema, await res.json());
    await expect(`${JSON.stringify(body.reading, null, 2)}\n`).toMatchFileSnapshot(
      `../fixtures/readings/${spread}.json`,
    );
  });
});
