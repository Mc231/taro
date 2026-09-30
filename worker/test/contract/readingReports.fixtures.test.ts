import { describe, expect, it } from 'vitest';
import { ReadingReportRequestSchema, ReadingReportSchema } from '../../src/routes/readingReports';
import { SeqIdGenerator } from '../fakes/SeqIdGenerator';
import { createHarness } from '../fakes/testDeps';
import { APP_HEADERS, authedApp } from '../helpers/app';
import { seedInstall, seedReading } from '../helpers/db';

/**
 * Contract fixtures of `POST /v1/readings/{clientReadingId}/report` (03 §9.7,
 * RC72): `readings.report.request.json` and `readings.report.response.json`,
 * exported like `fixtures.test.ts` (`npm run contract:update` rewrites them).
 */
const INSTALL_ID = '0f0f0f0f-0000-4000-8000-000000000001';
const CLIENT_READING_ID = '0f0f0f0f-0000-4000-8000-0000000000c1';

async function exportFixture(name: string, value: unknown): Promise<void> {
  await expect(`${JSON.stringify(value, null, 2)}\n`).toMatchFileSnapshot(
    `./fixtures/${name}.json`,
  );
}

describe('contract fixtures: readings.report', () => {
  it('exports the report request and its 201 response', async () => {
    const h = createHarness({ overrides: { ids: new SeqIdGenerator('rp') } });
    h.clock.set('2026-09-30T10:00:00.000Z');
    await seedInstall({ id: INSTALL_ID });
    await seedReading(INSTALL_ID, { clientReadingId: CLIENT_READING_ID, status: 'completed' });
    const request = ReadingReportRequestSchema.parse({
      reason: 'harmful_advice',
      note: 'The reading told me to stop my medication.',
      question: 'Should I change my treatment?',
      reading: {
        title: 'A time to listen',
        overview: 'The cards point to patience and to asking for good advice.',
        cards: [
          {
            positionId: 'focus',
            cardId: 'major_02',
            reversed: false,
            interpretation: 'Quiet knowing asks you to listen before acting.',
          },
        ],
        synthesis: 'Take time to gather advice you trust.',
        reflectionPrompts: ['Who could you talk this through with?'],
      },
      locale: 'de',
    });
    const res = await authedApp(h).request(`/v1/readings/${CLIENT_READING_ID}/report`, {
      method: 'POST',
      headers: {
        ...APP_HEADERS,
        'content-type': 'application/json',
        'X-Test-Install': INSTALL_ID,
        'Idempotency-Key': '0f0f0f0f-0000-4000-8000-0000000000a1',
      },
      body: JSON.stringify(request),
    });
    expect(res.status).toBe(201);
    const body = ReadingReportSchema.parse(await res.json());
    await exportFixture('readings.report.request', request);
    await exportFixture('readings.report.response', body);
  });
});
