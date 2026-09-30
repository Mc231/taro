import { afterAll, describe, expect, it } from 'vitest';
import type { AiAttemptOutcome, AiAttemptRequest } from '../../../src/adapters/ai/callPolicy';
import type { BalanceDto } from '../../../src/domain/allowance';
import { callCost } from '../../../src/domain/pricing';
import type { ErrorEnvelope } from '../../../src/http/errors';
import { IdempotencyRepo } from '../../../src/repos/IdempotencyRepo';
import { ReadingRepo } from '../../../src/repos/ReadingRepo';
import { SpendRepo } from '../../../src/repos/SpendRepo';
import { READINGS_ROUTE, type ReadingResponse } from '../../../src/services/ReadingService';
import { CRON, runScheduled } from '../../../src/scheduled';
import type { CapturingLogger } from '../../fakes/CapturingLogger';
import { FAKE_USAGE, fakeReading } from '../../fakes/FakeAiProvider';
import { db, seedInstall } from '../../helpers/db';
import { ReadingDriver } from '../../helpers/readingDriver';
import {
  ackReading,
  crid,
  getReading,
  holdBody,
  postHold,
  postReading,
  readingBody,
  readingHarness,
  THREE_CARDS,
  type ReadingHarness,
} from '../../helpers/readings';

/**
 * The AI reading pipeline end to end (Sprint 8.3; 03 §9.0, §9.1; RC28, RC29,
 * RC47, RC49–RC52, RC74, RC97) with `FakeAiProvider`: hold → reading → ack,
 * declines, L3 regeneration, failures and refunds, the row state machine,
 * the stale-hold and undelivered crons. Every logger of the suite is checked
 * with `expectNoSensitive` at the end (BE13).
 */

const QUESTION = 'How can I approach the change at work?';
const loggers: CapturingLogger[] = [];
const outputs: string[] = [];

function setup(options: Parameters<typeof readingHarness>[0] = {}): ReadingHarness {
  const h = readingHarness(options);
  loggers.push(h.logger);
  return h;
}

async function json<T>(res: Response): Promise<T> {
  const text = await res.text();
  outputs.push(text);
  return JSON.parse(text) as T;
}

async function install(extra: Parameters<typeof seedInstall>[0] = {}): Promise<string> {
  return seedInstall({ timezone: 'UTC', ...extra });
}

const readings = new ReadingRepo(db);

afterAll(() => {
  // BE13: no question, reading text, token or full install ID in any log line.
  const sensitive = [QUESTION, 'This card invites you to notice', 'A quiet turning point'];
  for (const logger of loggers) {
    logger.expectNoSensitive(...sensitive);
  }
  expect(outputs.length).toBeGreaterThan(0);
});

describe('POST /v1/readings/holds + POST /v1/readings: completed (03 §9.0, §9.1)', () => {
  it('free: hold → reading → ack deletes the replay body', async () => {
    const h = setup();
    const id = await install();
    const readingId = crid();

    const held = await postHold(h, id, readingId);
    expect(held.status).toBe(201);
    const hold = await json<{ chargeSource: string; expiresAt: string; balance: BalanceDto }>(held);
    expect(hold).toMatchObject({
      clientReadingId: readingId,
      chargeSource: 'free',
      expiresAt: '2026-09-26T10:15:00Z',
    });
    expect(hold.balance.free.remaining).toBe(0);
    expect((await readings.findByClientId(id, readingId))?.status).toBe('held');

    const res = await postReading(h, id, readingId);
    expect(res.status).toBe(200);
    const body = await json<ReadingResponse>(res);
    expect(body).toMatchObject({
      status: 'completed',
      chargeSource: 'free',
      promptVersion: 'v1',
      reading: { title: 'A quiet turning point' },
    });
    expect(body.reading?.cards).toEqual([
      expect.objectContaining({ positionId: 'focus', cardId: 'major_17', reversed: false }),
    ]);
    const row = await readings.findByClientId(id, readingId);
    expect(row).toMatchObject({
      status: 'completed',
      holdState: 'consumed',
      chargeSource: 'free',
      hasQuestion: true,
      promptVersion: 'v1',
      model: 'anthropic/claude-sonnet-5',
      inputTokens: 800,
      outputTokens: 600,
      cacheReadTokens: 2900,
    });
    expect(row?.costMicroUsd).toBeGreaterThan(0);
    expect(h.metrics.points).toContainEqual(
      expect.objectContaining({ event: 'reading_completed', chargeSource: 'free' }),
    );

    // Replayed byte for byte while unacknowledged; GET returns the text.
    const replay = await postReading(h, id, readingId);
    expect(replay.headers.get('Idempotent-Replayed')).toBe('true');
    const status = await json<{ status: string; reading?: unknown }>(
      await getReading(h, id, readingId),
    );
    expect(status).toMatchObject({ status: 'completed', attempt: 1 });
    expect(status.reading).toEqual(body.reading);

    expect((await ackReading(h, id, readingId)).status).toBe(204);
    expect((await ackReading(h, id, readingId)).status).toBe(204);
    const ref = { installId: id, route: READINGS_ROUTE, key: readingId };
    expect((await new IdempotencyRepo(db).find(ref))?.responseBodyEnc).toBeNull();
    const after = await json<{ status: string; reading?: unknown }>(
      await getReading(h, id, readingId),
    );
    expect(after.status).toBe('completed');
    expect(after.reading).toBeUndefined();
    expect((await readings.findByClientId(id, readingId))?.ackedAt).not.toBeNull();
  });

  it('bonus and paid are charged in order after the free reading', async () => {
    const h = setup();
    const driver = new ReadingDriver(h);
    const id = await install();
    expect((await postReading(h, id, crid())).status).toBe(200);
    await driver.grant(id, 'bonus', 1);
    await driver.grant(id, 'paid', 1);

    const bonus = await json<ReadingResponse>(await postReading(h, id, crid()));
    expect(bonus.chargeSource).toBe('bonus');
    const paid = await json<ReadingResponse>(await postReading(h, id, crid(), undefined));
    expect(paid.chargeSource).toBe('paid');
    expect(await driver.balances(id)).toEqual({ paid: 0, bonus: 0 });
    // Paid and bonus readings are served by the paid tier (RC97).
    expect(h.ai.anthropic.requests.at(-1)?.model).toBe('claude-opus-5');
  });

  it('a three-card reading echoes the cards in position order', async () => {
    const h = setup();
    const id = await install();
    const readingId = crid();
    const res = await postReading(
      h,
      id,
      readingId,
      readingBody(readingId, {
        spread: { id: 'three_ppf', version: 1 },
        cards: [...THREE_CARDS].reverse(),
      }),
    );
    expect(res.status).toBe(200);
    const body = await json<ReadingResponse>(res);
    expect(body.reading?.cards.map((c) => c.positionId)).toEqual(['past', 'present', 'future']);
    expect(body.reading?.reflectionPrompts.length).toBeGreaterThan(0);
  });
});

// --- helpers ------------------------------------------------------------------

async function errorBody(res: Response): Promise<ErrorEnvelope['error']> {
  return (await json<ErrorEnvelope>(res)).error;
}

/** An answered reading with `patch` applied (a scripted model answer). */
function answer(patch: Record<string, unknown> = {}) {
  return (request: AiAttemptRequest): AiAttemptOutcome => ({
    kind: 'ok',
    output: { ...fakeReading(request.prompt.expected), ...patch } as never,
    model: request.model,
    usage: FAKE_USAGE,
  });
}

function classified(classification: string) {
  return answer({
    classification,
    title: '',
    overview: '',
    cards: [],
    synthesis: '',
    reflectionPrompts: [''],
  });
}

async function freeUsed(installId: string): Promise<number> {
  const row = await db
    .prepare(`SELECT free_used, declined_count FROM daily_usage WHERE install_id = ?1`)
    .bind(installId)
    .first<{ free_used: number }>();
  return row?.free_used ?? 0;
}

async function declinedCount(installId: string): Promise<number> {
  const row = await db
    .prepare(`SELECT declined_count FROM daily_usage WHERE install_id = ?1`)
    .bind(installId)
    .first<{ declined_count: number }>();
  return row?.declined_count ?? 0;
}

/** An install whose free reading of today is already used, with `paid` credits. */
async function paidInstall(h: ReadingHarness, paid: number): Promise<string> {
  const id = await install();
  expect((await postReading(h, id, crid())).status).toBe(200);
  if (paid > 0) {
    await new ReadingDriver(h).grant(id, 'paid', paid);
  }
  return id;
}

describe('declined readings: 200, never charged (03 §9.1, §9.4; MO6, RC27, RC74)', () => {
  it('L1 self_harm: crisis resources for the country, no model call, declined_count + 1', async () => {
    const h = setup();
    const id = await install();
    const readingId = crid();
    const res = await postReading(
      h,
      id,
      readingId,
      readingBody(readingId, { question: 'Should I end it all tonight?' }),
      { country: 'DE' },
    );
    expect(res.status).toBe(200);
    const body = await json<ReadingResponse>(res);
    expect(body).toMatchObject({
      status: 'declined',
      chargeSource: 'none',
      safety: { category: 'self_harm', messageKey: 'safetyDeclinedSelfHarm', canRephrase: false },
    });
    expect(body.safety?.crisisResources.length).toBeGreaterThan(0);
    expect(body.safety?.crisisResources.length).toBeLessThanOrEqual(3);
    expect(h.ai.anthropic.requests).toHaveLength(0);
    expect(await freeUsed(id)).toBe(0);
    expect(await declinedCount(id)).toBe(1);
    expect(body.balance.free.remaining).toBe(1);
    expect(await readings.findByClientId(id, readingId)).toMatchObject({
      status: 'declined',
      safetyCategory: 'self_harm',
      safetyLayer: 'L1',
      chargeSource: 'none',
      holdState: 'refunded',
    });
    // GET answers the stored declined response; a retry replays it.
    const state = await json<{ status: string; safety: { category: string } }>(
      await getReading(h, id, readingId),
    );
    expect(state).toMatchObject({ status: 'declined', safety: { category: 'self_harm' } });
    expect(
      (
        await postReading(
          h,
          id,
          readingId,
          readingBody(readingId, { question: 'Should I end it all tonight?' }),
        )
      ).headers.get('Idempotent-Replayed'),
    ).toBe('true');
  });

  it.each([
    ['health', 'safetyDeclinedHealth', true, false],
    ['harm_to_others', 'safetyDeclinedHarmToOthers', false, true],
    ['sexual_minors', 'safetyDeclinedSexualMinors', false, false],
    ['gambling', 'safetyDeclinedGambling', true, false],
  ])(
    'L2 %s → %s (canRephrase %s, crisis %s)',
    async (category, messageKey, canRephrase, crisis) => {
      const h = setup();
      const id = await install();
      h.ai.anthropic.script(classified(category));
      const readingId = crid();
      const body = await json<ReadingResponse>(await postReading(h, id, readingId));
      expect(body.safety).toMatchObject({ category, messageKey, canRephrase });
      expect((body.safety?.crisisResources.length ?? 0) > 0).toBe(crisis);
      expect(await freeUsed(id)).toBe(0);
      const row = await readings.findByClientId(id, readingId);
      expect(row).toMatchObject({
        status: 'declined',
        safetyLayer: 'L2',
        safetyCategory: category,
      });
      expect(row?.costMicroUsd).toBeGreaterThan(0);
      expect(h.metrics.points).toContainEqual(
        expect.objectContaining({ event: 'reading_declined', code: category }),
      );
    },
  );

  it('a model refusal without a category → other / refusalGeneric', async () => {
    const h = setup();
    const id = await install();
    h.ai.anthropic.script((r) => ({
      kind: 'refused',
      category: null,
      model: r.model,
      usage: FAKE_USAGE,
    }));
    const readingId = crid();
    const body = await json<ReadingResponse>(await postReading(h, id, readingId));
    expect(body.safety).toEqual({
      category: 'other',
      messageKey: 'refusalGeneric',
      crisisResources: [],
      canRephrase: false,
    });
    expect(await readings.findByClientId(id, readingId)).toMatchObject({
      safetyLayer: 'model_refusal',
      safetyCategory: 'other',
    });
    // Without the replay body, GET rebuilds the declined answer from the row.
    await new IdempotencyRepo(db).deleteBody({
      installId: id,
      route: READINGS_ROUTE,
      key: readingId,
    });
    const state = await json<{ safety: { messageKey: string } }>(
      await getReading(h, id, readingId),
    );
    expect(state.safety.messageKey).toBe('refusalGeneric');
    const again = await json<ReadingResponse>(await postReading(h, id, readingId));
    expect(again).toMatchObject({ status: 'declined', safety: { category: 'other' } });
  });

  it('a model refusal with a known category keeps it', async () => {
    const h = setup();
    const id = await install();
    h.ai.anthropic.script((r) => ({
      kind: 'refused',
      category: 'self_harm',
      model: r.model,
      usage: FAKE_USAGE,
    }));
    const body = await json<ReadingResponse>(await postReading(h, id, crid()));
    expect(body.safety?.category).toBe('self_harm');
  });

  it('provider moderation (ai.moderation.provider = openai): a flagged question is declined, an error never blocks', async () => {
    const h = setup();
    h.config.set({ 'ai.moderation.provider': 'openai' });
    const id = await install();
    h.ai.openai.moderation({ kind: 'ok', flagged: true, categories: ['self-harm/intent'] });
    const readingId = crid();
    const body = await json<ReadingResponse>(await postReading(h, id, readingId));
    expect(body.safety?.category).toBe('self_harm');
    expect(h.ai.anthropic.requests).toHaveLength(0);
    expect((await readings.findByClientId(id, readingId))?.safetyLayer).toBe('L2');

    h.ai.openai.moderation({ kind: 'error' });
    const other = await install();
    expect((await json<ReadingResponse>(await postReading(h, other, crid()))).status).toBe(
      'completed',
    );

    // A flagged answer is an L3 failure: regenerated once, then failed + refunded.
    h.ai.openai.moderation({ kind: 'ok', flagged: true, categories: ['harassment'] });
    const third = await install();
    const res = await postReading(h, third, crid(), readingBody(crid(), { question: undefined }));
    expect(res.status).toBe(400);
    const readingId3 = crid();
    const failed = await postReading(
      h,
      third,
      readingId3,
      readingBody(readingId3, { question: undefined }),
    );
    expect(failed.status).toBe(503);
    expect(await freeUsed(third)).toBe(0);
  });
});

describe('L3 validation and failures (03 §9.1 steps 5–6, §9.3; RC49, RC52)', () => {
  it('an L3 violation is regenerated once with a note, then completes', async () => {
    const h = setup();
    const id = await install();
    h.ai.anthropic.script(answer({ synthesis: 'Success is guaranteed, call +1 555 123 4567.' }));
    const res = await postReading(h, id, crid());
    expect(res.status).toBe(200);
    expect(h.ai.anthropic.requests).toHaveLength(2);
    expect(h.ai.anthropic.requests[1]?.prompt.user).toContain('<regeneration_note>');
    expect(h.ai.anthropic.requests[0]?.prompt.user).not.toContain('<regeneration_note>');
  });

  it('two L3 violations → failed + refund → 503 AI_UNAVAILABLE', async () => {
    const h = setup();
    const id = await install();
    const bad = answer({ synthesis: 'Visit https://example.com for more.' });
    h.ai.anthropic.script(bad, bad);
    const readingId = crid();
    const res = await postReading(h, id, readingId);
    expect(res.status).toBe(503);
    expect((await errorBody(res)).code).toBe('AI_UNAVAILABLE');
    expect(await freeUsed(id)).toBe(0);
    expect(await declinedCount(id)).toBe(0);
    expect(await readings.findByClientId(id, readingId)).toMatchObject({
      status: 'failed',
      holdState: 'refunded',
      errorCode: 'l3_violation',
    });
    expect(h.metrics.points).toContainEqual(
      expect.objectContaining({ event: 'reading_failed', code: 'l3_violation' }),
    );
  });

  it('invalid JSON output is regenerated like an L3 violation', async () => {
    const h = setup();
    const id = await install();
    h.ai.anthropic.script((r) => ({
      kind: 'invalid_output',
      issues: ['not JSON'],
      model: r.model,
      usage: FAKE_USAGE,
    }));
    expect((await postReading(h, id, crid())).status).toBe(200);
  });

  it('timeout → refund → 503; a retry with the same id is a new attempt with one net charge', async () => {
    const h = setup();
    const id = await paidInstall(h, 1);
    const driver = new ReadingDriver(h);
    h.ai.anthropic.script({ kind: 'timeout' });
    const readingId = crid();
    const failed = await postReading(h, id, readingId);
    expect(failed.status).toBe(503);
    expect(await driver.balances(id)).toEqual({ paid: 1, bonus: 0 });
    expect((await readings.findByClientId(id, readingId))?.errorCode).toBe('timeout');

    const retry = await postReading(h, id, readingId);
    expect(retry.status).toBe(200);
    expect((await json<ReadingResponse>(retry)).chargeSource).toBe('paid');
    expect(await driver.balances(id)).toEqual({ paid: 0, bonus: 0 });
    expect((await readings.findByClientId(id, readingId))?.attempt).toBe(2);
    const refs = (await driver.entries(id))
      .filter((e) => e.refType === 'reading')
      .map((e) => `${e.reason}:${e.refId.split('#')[1] ?? ''}`);
    expect(refs).toEqual(['reading_hold:1', 'reading_refund:1', 'reading_hold:2']);
  });

  it('max_tokens: the adapter retries once at 1.5x; truncated twice → failed', async () => {
    const h = setup();
    const id = await install();
    const cut = (r: AiAttemptRequest): AiAttemptOutcome => ({
      kind: 'truncated',
      model: r.model,
      usage: FAKE_USAGE,
    });
    h.ai.anthropic.script(cut);
    expect((await postReading(h, id, crid())).status).toBe(200);
    expect(h.ai.anthropic.requests[1]?.maxTokens).toBe(Math.round(2500 * 1.5));

    const other = await install();
    h.ai.anthropic.script(cut, cut);
    const readingId = crid();
    expect((await postReading(h, other, readingId)).status).toBe(503);
    expect((await readings.findByClientId(other, readingId))?.errorCode).toBe('truncated');
  });

  it('the deadline: no regeneration with under 15 s left → failed + refund', async () => {
    const h = setup();
    const id = await install();
    h.ai.anthropic.script((r) => {
      h.clock.advance({ seconds: 45 });
      return answer({ synthesis: 'You will definitely win, guaranteed.' })(r);
    });
    const readingId = crid();
    expect((await postReading(h, id, readingId)).status).toBe(503);
    expect(h.ai.anthropic.requests).toHaveLength(1);
    expect((await readings.findByClientId(id, readingId))?.errorCode).toBe('deadline');
    expect(await freeUsed(id)).toBe(0);
  });

  it('upstream errors fall back to ai.outageFallback once (RC97)', async () => {
    const h = setup();
    h.config.set({
      'ai.outageFallback.provider': 'openai',
      'ai.outageFallback.model': 'gpt-6.1-sol',
    });
    const id = await install();
    h.ai.anthropic.script({ kind: 'upstream', retryable: false, detail: '500' });
    const readingId = crid();
    expect((await postReading(h, id, readingId)).status).toBe(200);
    expect((await readings.findByClientId(id, readingId))?.model).toBe('openai/gpt-6.1-sol');
  });

  it('prices every call of every provider into the row, the metric and ai_spend_daily (RC97)', async () => {
    const h = setup();
    // A day of its own: this test reads that day's model spend.
    h.clock.set('2027-04-02T10:00:00.000Z');
    h.config.set({
      'ai.outageFallback.provider': 'openai',
      'ai.outageFallback.model': 'gpt-6.1-sol',
    });
    const id = await install();
    h.ai.anthropic.script(
      { kind: 'truncated', model: 'claude-sonnet-5', usage: FAKE_USAGE },
      { kind: 'upstream', retryable: false, detail: '500' },
    );
    const readingId = crid();
    expect((await postReading(h, id, readingId)).status).toBe(200);
    const logger = { log: () => undefined };
    const expected =
      callCost('anthropic', 'claude-sonnet-5', FAKE_USAGE, logger).microUsd +
      callCost('openai', 'gpt-6.1-sol', FAKE_USAGE, logger).microUsd;
    const row = await readings.findByClientId(id, readingId);
    expect(row).toMatchObject({
      model: 'openai/gpt-6.1-sol',
      costMicroUsd: expected,
      inputTokens: 2 * FAKE_USAGE.inputTokens,
      outputTokens: 2 * FAKE_USAGE.outputTokens,
    });
    expect(h.metrics.points).toContainEqual(
      expect.objectContaining({
        event: 'reading_completed',
        model: 'openai/gpt-6.1-sol',
        costMicroUsd: expected,
      }),
    );
    expect((await new SpendRepo(db).get('2027-04-02')).costMicroUsd).toBe(expected);
  });
});

describe('the row state machine (03 §9.1 step 2; RC49–RC52)', () => {
  it('402 on hold → rewarded grant → the same clientReadingId → 200', async () => {
    const h = setup();
    const id = await paidInstall(h, 0);
    const readingId = crid();
    const refused = await postHold(h, id, readingId);
    expect(refused.status).toBe(402);
    expect(await errorBody(refused)).toMatchObject({
      code: 'INSUFFICIENT_CREDITS',
      details: { reason: 'noCredits' },
    });
    expect((await readings.findByClientId(id, readingId))?.status).toBe('no_credit');

    await new ReadingDriver(h).grant(id, 'bonus', 1);
    const res = await postReading(h, id, readingId);
    expect(res.status).toBe(200);
    expect((await json<ReadingResponse>(res)).chargeSource).toBe('bonus');
  });

  it('a new reading without credit → 402 and the row is no_credit', async () => {
    const h = setup();
    const id = await paidInstall(h, 0);
    const readingId = crid();
    const res = await postReading(h, id, readingId);
    expect(res.status).toBe(402);
    expect((await readings.findByClientId(id, readingId))?.status).toBe('no_credit');
    // No credit on an existing row → 409 HOLD_CONFLICT (S10 with the draw face-down).
    const again = await postReading(h, id, readingId);
    expect(again.status).toBe(409);
    expect((await errorBody(again)).code).toBe('HOLD_CONFLICT');
  });

  it('a hold that expired before the submit is re-held as a new attempt', async () => {
    const h = setup();
    const id = await install();
    const readingId = crid();
    expect((await postHold(h, id, readingId)).status).toBe(201);
    h.clock.advance({ minutes: 16 });
    const res = await postReading(h, id, readingId);
    expect(res.status).toBe(200);
    expect(await readings.findByClientId(id, readingId)).toMatchObject({
      attempt: 2,
      status: 'completed',
      chargeSource: 'free',
    });
    expect(await freeUsed(id)).toBe(1);
  });

  it('an expired hold whose credit went elsewhere → 409 HOLD_CONFLICT', async () => {
    const h = setup();
    const id = await install();
    const first = crid();
    expect((await postHold(h, id, first)).status).toBe(201);
    h.clock.advance({ minutes: 16 });
    await runScheduled(h.deps, CRON.quarterHourly);
    expect((await readings.findByClientId(id, first))?.status).toBe('expired_hold');
    expect(h.metrics.points).toContainEqual(
      expect.objectContaining({ event: 'hold_abandoned', chargeSource: 'free' }),
    );
    expect((await postReading(h, id, crid())).status).toBe(200);
    const res = await postReading(h, id, first);
    expect(res.status).toBe(409);
    expect((await errorBody(res)).code).toBe('HOLD_CONFLICT');
  });

  it('holds: a live hold is renewed, at most one open hold per install', async () => {
    const h = setup();
    const id = await install();
    const first = crid();
    const one = await json<{ expiresAt: string }>(await postHold(h, id, first));
    h.clock.advance({ minutes: 5 });
    const renewed = await postHold(h, id, first);
    expect(renewed.headers.get('Idempotent-Replayed')).toBeNull();
    const two = await json<{ expiresAt: string; chargeSource: string }>(renewed);
    expect(two.chargeSource).toBe('free');
    expect(Date.parse(two.expiresAt) - Date.parse(one.expiresAt)).toBe(5 * 60_000);
    expect(await freeUsed(id)).toBe(1);

    // A different draw releases the never-submitted hold first.
    const second = crid();
    expect((await postHold(h, id, second)).status).toBe(201);
    expect(await readings.findByClientId(id, first)).toMatchObject({
      status: 'expired_hold',
      holdState: 'refunded',
    });
    expect(await freeUsed(id)).toBe(1);
  });

  it('holds on a finished or running reading: 409', async () => {
    const h = setup();
    const id = await install();
    const readingId = crid();
    expect((await postReading(h, id, readingId)).status).toBe(200);
    const res = await postHold(h, id, readingId);
    expect((await errorBody(res)).code).toBe('HOLD_CONFLICT');
  });

  it('a crashed run: 409 REQUEST_IN_PROGRESS, the cron refunds once, the retry charges once (RC52)', async () => {
    const h = setup();
    const id = await paidInstall(h, 1);
    const driver = new ReadingDriver(h);
    const generate = h.ai.anthropic.generate.bind(h.ai.anthropic);
    h.ai.anthropic.generate = () => Promise.reject(new Error('isolate evicted'));
    const readingId = crid();
    expect((await postReading(h, id, readingId)).status).toBe(500);
    expect((await readings.findByClientId(id, readingId))?.status).toBe('generating');
    h.ai.anthropic.generate = generate;

    // An idempotency takeover after 120 s still finds the row generating.
    const busy = await postReading(h, id, readingId);
    expect(busy.status).toBe(409);
    expect(await errorBody(busy)).toMatchObject({ code: 'REQUEST_IN_PROGRESS', retryAfterSec: 3 });
    const state = await json<{ status: string }>(await getReading(h, id, readingId));
    expect(state.status).toBe('generating');
    const hold = await postHold(h, id, readingId);
    expect((await errorBody(hold)).code).toBe('REQUEST_IN_PROGRESS');

    h.clock.advance({ seconds: 121 });
    await runScheduled(h.deps, CRON.quarterHourly);
    await runScheduled(h.deps, CRON.quarterHourly);
    expect(await readings.findByClientId(id, readingId)).toMatchObject({
      status: 'failed',
      errorCode: 'abandoned',
      holdState: 'refunded',
    });
    expect(await driver.balances(id)).toEqual({ paid: 1, bonus: 0 });

    expect((await postReading(h, id, readingId)).status).toBe(200);
    expect(await driver.balances(id)).toEqual({ paid: 0, bonus: 0 });
    const refunds = (await driver.entries(id)).filter((e) => e.reason === 'reading_refund');
    expect(refunds).toHaveLength(1);
  });

  it('a late commit after the stale-hold cron re-takes the hold (03 §5.3 step 4)', async () => {
    const h = setup();
    const id = await paidInstall(h, 1);
    const driver = new ReadingDriver(h);
    const generate = h.ai.anthropic.generate.bind(h.ai.anthropic);
    h.ai.anthropic.generate = async (request) => {
      const start = h.clock.now();
      h.clock.advance({ seconds: 200 });
      await runScheduled(h.deps, CRON.quarterHourly);
      h.clock.set(start);
      return generate(request);
    };
    const readingId = crid();
    const res = await postReading(h, id, readingId);
    expect(res.status).toBe(200);
    expect((await json<ReadingResponse>(res)).chargeSource).toBe('paid');
    expect(await readings.findByClientId(id, readingId)).toMatchObject({
      status: 'completed',
      attempt: 2,
      holdState: 'consumed',
    });
    expect(await driver.balances(id)).toEqual({ paid: 0, bonus: 0 });
  });

  it('completed but never acknowledged: refunded exactly once after 7 days (RC51)', async () => {
    const h = setup();
    const id = await paidInstall(h, 1);
    const driver = new ReadingDriver(h);
    const readingId = crid();
    expect((await postReading(h, id, readingId)).status).toBe(200);
    expect(await driver.balances(id)).toEqual({ paid: 0, bonus: 0 });

    h.clock.advance({ days: 7, minutes: 1 });
    const gone = await getReading(h, id, readingId);
    expect(gone.status).toBe(410);
    const error = await errorBody(gone);
    expect(error.code).toBe('READING_EXPIRED_REFUNDED');
    expect((error.details?.['balance'] as BalanceDto).paid).toBe(1);
    expect(await driver.balances(id)).toEqual({ paid: 1, bonus: 0 });

    const second = await json<{ status: string }>(await getReading(h, id, readingId));
    expect(second.status).toBe('expired_refunded');
    await runScheduled(h.deps, CRON.hourly);
    expect(await driver.balances(id)).toEqual({ paid: 1, bonus: 0 });
    const undelivered = (await driver.entries(id)).filter(
      (e) => e.reason === 'reading_undelivered',
    );
    expect(undelivered).toHaveLength(1);

    // "Try again" with the same cards: a new attempt.
    const retry = await postReading(h, id, readingId);
    expect(retry.status).toBe(200);
    expect((await readings.findByClientId(id, readingId))?.attempt).toBe(2);
  });

  it('the hourly cron refunds undelivered readings once; acknowledged ones never', async () => {
    const h = setup();
    const id = await paidInstall(h, 2);
    const driver = new ReadingDriver(h);
    const kept = crid();
    const lost = crid();
    expect((await postReading(h, id, kept)).status).toBe(200);
    expect((await postReading(h, id, lost)).status).toBe(200);
    expect((await ackReading(h, id, kept)).status).toBe(204);
    h.clock.advance({ days: 7, hours: 1 });
    await runScheduled(h.deps, CRON.hourly);
    await runScheduled(h.deps, CRON.hourly);
    expect((await readings.findByClientId(id, lost))?.status).toBe('expired_refunded');
    expect((await readings.findByClientId(id, kept))?.status).toBe('completed');
    expect(await driver.balances(id)).toEqual({ paid: 1, bonus: 0 });
    expect(h.metrics.points).toContainEqual(
      expect.objectContaining({ event: 'reading_undelivered_refund', chargeSource: 'paid' }),
    );
    // A POST for the expired reading is the same "Try again" as after the 410.
    const acked = await postReading(h, id, kept);
    expect(acked.status).toBe(200);
  });

  it('an acknowledged reading answers from its row once the body is gone', async () => {
    const h = setup();
    const id = await install();
    const readingId = crid();
    expect((await postReading(h, id, readingId)).status).toBe(200);
    expect((await ackReading(h, id, readingId)).status).toBe(204);
    const res = await postReading(h, id, readingId);
    expect(res.status).toBe(200);
    const body = await json<ReadingResponse>(res);
    expect(body).toMatchObject({ status: 'completed', chargeSource: 'free' });
    expect(body.reading).toBeUndefined();
  });

  it('GET and ack of an unknown reading → 404; GET of a failed row → its status', async () => {
    const h = setup();
    const id = await install();
    expect((await getReading(h, id, crid())).status).toBe(404);
    expect((await ackReading(h, id, crid())).status).toBe(404);
    h.ai.anthropic.script({ kind: 'timeout' });
    const readingId = crid();
    expect((await postReading(h, id, readingId)).status).toBe(503);
    expect((await ackReading(h, id, readingId)).status).toBe(204);
    const state = await json<{ status: string; attempt: number }>(
      await getReading(h, id, readingId),
    );
    expect(state).toMatchObject({ status: 'failed', attempt: 1 });
  });
});

describe('gates (03 §9.0 order; RC28, RC29, RC47, RC74, RC97)', () => {
  it('412 without (or below) the AI consent version', async () => {
    const h = setup();
    const id = await install();
    const readingId = crid();
    const missing = await postHold(h, id, readingId, holdBody(readingId), {
      headers: { 'X-Taro-AI-Consent': undefined },
    });
    expect(missing.status).toBe(412);
    expect(await errorBody(missing)).toMatchObject({
      code: 'AI_CONSENT_REQUIRED',
      details: { requiredVersion: 1 },
    });
    h.config.set({ 'ai.consentVersion': 2 });
    const old = await postReading(h, id, readingId);
    expect((await errorBody(old)).code).toBe('AI_CONSENT_REQUIRED');
  });

  it('503 READINGS_DISABLED and 403 AI_UNAVAILABLE_REGION', async () => {
    const h = setup();
    const id = await install();
    const readingId = crid();
    const blocked = await postHold(h, id, readingId, holdBody(readingId), { country: 'RU' });
    expect(blocked.status).toBe(403);
    expect((await errorBody(blocked)).code).toBe('AI_UNAVAILABLE_REGION');
    h.config.set({ 'readings.enabled': false });
    const off = await postReading(h, id, readingId);
    expect(off.status).toBe(503);
    expect((await errorBody(off)).code).toBe('READINGS_DISABLED');
    expect(await readings.findByClientId(id, readingId)).toBeNull();
  });

  it('503 AI_UNAVAILABLE for a tier whose provider has no key: alert, nothing charged', async () => {
    const h = setup({ overrides: { ai: {} } });
    const id = await install();
    const readingId = crid();
    const res = await postHold(h, id, readingId);
    expect(res.status).toBe(503);
    expect((await errorBody(res)).code).toBe('AI_UNAVAILABLE');
    expect(await freeUsed(id)).toBe(0);
    expect(h.alerter.alerts).toContainEqual(
      expect.objectContaining({ kind: 'ai_provider_unavailable' }),
    );
    const reading = await postReading(h, id, readingId);
    expect(reading.status).toBe(503);
    expect(await freeUsed(id)).toBe(0);
    expect((await readings.findByClientId(id, readingId))?.errorCode).toBe('ai_unavailable');
  });

  it('422 SPREAD_INVALID (unknown, disabled, cards) and 400 VALIDATION_FAILED', async () => {
    const h = setup();
    const id = await install();
    const reasonOf = async (res: Response) => (await errorBody(res)).details?.['reason'];
    const a = crid();
    expect(
      await reasonOf(
        await postHold(h, id, a, holdBody(a, { spread: { id: 'single', version: 9 } })),
      ),
    ).toBe('unknownSpread');
    const b = crid();
    expect(
      await reasonOf(
        await postReading(
          h,
          id,
          b,
          readingBody(b, { cards: [{ positionId: 'past', cardId: 'major_17', reversed: false }] }),
        ),
      ),
    ).toBe('cards');
    const c = crid();
    const long = await postReading(h, id, c, readingBody(c, { question: 'ab'.repeat(200) }));
    expect(long.status).toBe(400);
    const d = crid();
    const mismatch = await postReading(h, id, d, readingBody(d), { key: crid() });
    expect(mismatch.status).toBe(400);
    h.config.set({ 'spreads.enabled': ['three_ppf'] });
    const e = crid();
    expect(await reasonOf(await postHold(h, id, e))).toBe('disabled');
    expect(await freeUsed(id)).toBe(0);
  });

  it('429 dailyLimit, 429 declinedLimit, and the per-minute limiter', async () => {
    const h = setup();
    h.config.set({ 'readings.maxPerInstallPerDay': 5, 'safety.maxDeclinedPerDay': 1 });
    const id = await install();
    await new ReadingDriver(h).grant(id, 'paid', 10);
    for (let i = 0; i < 5; i++) {
      expect((await postReading(h, id, crid())).status).toBe(200);
    }
    const limited = await postHold(h, id, crid());
    expect(limited.status).toBe(429);
    expect(await errorBody(limited)).toMatchObject({ details: { reason: 'dailyLimit' } });
    expect(limited.headers.get('Retry-After')).toBe(String(14 * 3600));

    const other = await install();
    const declined = crid();
    await postReading(
      h,
      other,
      declined,
      readingBody(declined, { question: 'Should I end it all tonight?' }),
    );
    const next = await postReading(h, other, crid());
    expect(next.status).toBe(429);
    expect(await errorBody(next)).toMatchObject({ details: { reason: 'declinedLimit' } });

    h.readings.limitPerKey = 0;
    const burst = await postHold(h, other, crid());
    expect(await errorBody(burst)).toMatchObject({
      code: 'RATE_LIMITED',
      details: { reason: 'burst' },
    });
  });

  it('budget: hard stop → 503 tier=hard; free stop → 503 freeStop for free-only, bonus still reads; soft → free fallback model', async () => {
    const h = setup();
    const id = await install();
    const held = crid();
    expect((await postHold(h, id, held)).status).toBe(201);
    h.config.set({ 'ai.budget.dailyHardUsd': 0 });
    const hard = await postReading(h, id, held);
    expect(hard.status).toBe(503);
    expect(await errorBody(hard)).toMatchObject({
      code: 'AI_BUDGET_EXHAUSTED',
      details: { tier: 'hard' },
    });
    expect(await freeUsed(id)).toBe(0);
    expect((await postHold(h, id, crid())).status).toBe(503);

    h.config.set({
      'ai.budget.dailyHardUsd': 300,
      'ai.budget.softFloorUsd': 0,
      'ai.budget.freeStopFloorUsd': 0,
    });
    const freeStop = await postHold(h, id, crid());
    expect(await errorBody(freeStop)).toMatchObject({ details: { tier: 'freeStop' } });
    await new ReadingDriver(h).grant(id, 'bonus', 1);
    const bonus = await json<ReadingResponse>(await postReading(h, id, crid()));
    expect(bonus.chargeSource).toBe('bonus');

    h.config.set({ 'ai.budget.freeStopFloorUsd': 100 });
    const soft = await postReading(h, await install(), crid());
    expect(soft.status).toBe(200);
    expect(h.ai.anthropic.requests.at(-1)?.model).toBe('claude-haiku-4-5');
  });
});

describe('replay bodies and edge paths (RC51, RC52)', () => {
  it('GET while the request that completed is still storing its body → generating', async () => {
    const h = setup();
    const id = await install();
    const readingId = crid();
    expect((await postReading(h, id, readingId)).status).toBe(200);
    await db
      .prepare(
        `UPDATE idempotency_keys SET state = 'in_progress', response_body_enc = NULL,
                response_status = NULL, created_at = ?3
          WHERE install_id = ?1 AND key = ?2 AND route = 'POST /v1/readings'`,
      )
      .bind(id, readingId, h.clock.now().toISOString())
      .run();
    const state = await json<{ status: string }>(await getReading(h, id, readingId));
    expect(state.status).toBe('generating');
    expect(await freeUsed(id)).toBe(1);
  });

  it('a POST for a completed, unacknowledged reading whose body is gone → 410 once', async () => {
    const h = setup();
    const id = await paidInstall(h, 1);
    const readingId = crid();
    expect((await postReading(h, id, readingId)).status).toBe(200);
    await new IdempotencyRepo(db).deleteBody({
      installId: id,
      route: READINGS_ROUTE,
      key: readingId,
    });
    const res = await postReading(h, id, readingId);
    expect(res.status).toBe(410);
    expect(await new ReadingDriver(h).balances(id)).toEqual({ paid: 1, bonus: 0 });
  });

  it('the budget hard stop between the gate and the model call refunds the hold', async () => {
    const h = setup();
    // A day of its own: this test writes that day's model spend.
    h.clock.set('2027-03-01T10:00:00.000Z');
    h.config.set({
      'ai.moderation.provider': 'openai',
      'ai.promptVersion': 'v9',
      'ai.budget.dailyHardUsd': 1,
    });
    h.ai.openai.moderate = async () => {
      await db
        .prepare(
          `INSERT INTO ai_spend_daily (date_utc, readings, cost_micro_usd) VALUES (?1, 1, ?2)`,
        )
        .bind('2027-03-01', 2_000_000)
        .run();
      return { kind: 'ok', flagged: false, categories: [] };
    };
    const id = await install();
    const readingId = crid();
    const res = await postReading(h, id, readingId);
    expect(await errorBody(res)).toMatchObject({
      code: 'AI_BUDGET_EXHAUSTED',
      details: { tier: 'hard' },
    });
    expect(await freeUsed(id)).toBe(0);
    expect(await readings.findByClientId(id, readingId)).toMatchObject({
      status: 'failed',
      errorCode: 'budget',
      promptVersion: 'v1',
    });
    expect(h.ai.anthropic.requests).toHaveLength(0);
  });
});
