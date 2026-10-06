import { createExecutionContext, waitOnExecutionContext } from 'cloudflare:test';
import { beforeAll, describe, expect, it } from 'vitest';
import { buildApp, type App } from '../../../src/app';
import { TELEGRAM_ROUTE, TELEGRAM_SECRET_HEADER } from '../../../src/routes/telegram';
import {
  createHarness,
  TEST_TELEGRAM_CHAT_ID,
  TEST_TELEGRAM_ENDPOINT,
  TEST_TELEGRAM_WEBHOOK_SECRET,
  uniqueId,
  type HarnessOptions,
  type TestHarness,
} from '../../fakes/testDeps';
import { db } from '../../helpers/db';
import { json, StubFetch } from '../../helpers/stubFetch';

/**
 * `POST /v1/admin/telegram` (03 §14.3): the owner's read-only stats bot.
 * The seeded data covers 2026-09-20 … 2026-10-06 (UTC); "now" is
 * 2026-10-06T15:00Z (a Tuesday).
 */
const NOW = '2026-10-06T15:00:00.000Z';
/** A rejection reason that is not an `Error` (logged as `unknown`). */
const NOT_AN_ERROR = 'boom' as unknown as Error;
const P = 'com.vshyrochuk.taro.';
const QUESTION = 'Will my secret plan with Marta work out?';
const ids = { a: uniqueId('a'), b: uniqueId('b'), c: uniqueId('c'), d: uniqueId('d') };

async function seed(): Promise<void> {
  const install = (id: string, created: string, lastSeen: string) =>
    db
      .prepare(
        `INSERT INTO installs (id, platform, trust, created_at, last_seen_at) VALUES (?1, 'ios', 'high', ?2, ?3)`,
      )
      .bind(id, created, lastSeen);
  let n = 0;
  const reading = (
    installId: string,
    created: string,
    status: string,
    extra: { hold?: string; category?: string; cost?: number | null } = {},
  ) =>
    db
      .prepare(
        `INSERT INTO readings (id, install_id, client_reading_id, spread_id, card_count, has_question,
           locale, local_date, status, hold_state, charge_source, safety_category, cost_micro_usd, created_at)
         VALUES (?1, ?2, ?3, 'single', 1, 1, 'en', ?4, ?5, ?6, 'free', ?7, ?8, ?9)`,
      )
      .bind(
        `r-${String(++n)}`,
        installId,
        `cr-${String(n)}`,
        created.slice(0, 10),
        status,
        extra.hold ?? 'consumed',
        extra.category ?? null,
        extra.cost ?? null,
        created,
      );
  const purchase = (
    product: string,
    granted: string,
    extra: { env?: string; test?: number; revoked?: string } = {},
  ) =>
    db
      .prepare(
        `INSERT INTO purchases (id, install_id, platform, product_id, store_txn_id, credits, status,
           environment, is_test, account_token_match, purchased_at, granted_at, revoked_at)
         VALUES (?1, ?2, 'ios', ?3, ?1, 10, ?4, ?5, ?6, 1, ?7, ?7, ?8)`,
      )
      .bind(
        `p-${String(++n)}`,
        ids.a,
        `${P}${product}`,
        extra.revoked === undefined ? 'granted' : 'revoked',
        extra.env ?? 'production',
        extra.test ?? 0,
        granted,
        extra.revoked ?? null,
      );
  const reward = (status: string, at: string) =>
    db
      .prepare(
        `INSERT INTO ad_rewards (id, install_id, local_date, status, amount, issued_at, expires_at, granted_at)
         VALUES (?1, ?2, ?3, ?4, 1, ?5, ?5, ?6)`,
      )
      .bind(
        `ad-${String(++n)}`,
        ids.b,
        at.slice(0, 10),
        status,
        at,
        status === 'granted' ? at : null,
      );
  await db.batch([
    install(ids.a, '2026-10-06T08:00:00.000Z', '2026-10-06T09:00:00.000Z'),
    install(ids.b, '2026-10-06T09:00:00.000Z', '2026-10-06T10:00:00.000Z'),
    install(ids.c, '2026-10-01T09:00:00.000Z', '2026-10-05T12:00:00.000Z'),
    install(ids.d, '2026-09-20T09:00:00.000Z', '2026-10-06T11:00:00.000Z'),
    reading(ids.a, '2026-10-06T08:10:00.000Z', 'completed', { cost: 12_000 }),
    reading(ids.a, '2026-10-06T08:20:00.000Z', 'completed', { cost: 10_000 }),
    reading(ids.c, '2026-10-06T08:30:00.000Z', 'completed'),
    reading(ids.b, '2026-10-06T09:10:00.000Z', 'declined', {
      hold: 'refunded',
      category: 'self_harm',
    }),
    reading(ids.b, '2026-10-06T09:20:00.000Z', 'declined', { hold: 'none', category: 'health' }),
    reading(ids.d, '2026-10-06T11:10:00.000Z', 'failed', { hold: 'refunded' }),
    reading(ids.a, '2026-10-06T12:00:00.000Z', 'held', { hold: 'held' }),
    reading(ids.d, '2026-10-05T11:10:00.000Z', 'completed', { cost: 20_000 }),
    reading(ids.c, '2026-10-04T11:10:00.000Z', 'declined', { hold: 'none', category: 'legal' }),
    db.prepare(
      `INSERT INTO ai_spend_daily (date_utc, readings, cost_micro_usd) VALUES
         ('2026-10-06', 5, 1840000), ('2026-10-05', 1, 500000), ('2026-10-02', 1, 100000),
         ('2026-09-29', 1, 9000000)`,
    ),
    purchase('readings_10', '2026-10-06T10:00:00.000Z'),
    purchase('readings_10', '2026-10-06T10:05:00.000Z'),
    purchase('remove_ads', '2026-10-06T10:10:00.000Z'),
    purchase('remove_ads', '2026-10-06T10:15:00.000Z'),
    purchase('readings_3', '2026-10-06T10:20:00.000Z'),
    purchase('readings_30', '2026-10-06T10:25:00.000Z', { env: 'sandbox' }),
    purchase('readings_3', '2026-10-06T10:30:00.000Z', { test: 1 }),
    purchase('readings_30', '2026-10-03T10:00:00.000Z', { revoked: '2026-10-06T07:00:00.000Z' }),
    reward('granted', '2026-10-06T10:00:00.000Z'),
    reward('granted', '2026-10-06T11:00:00.000Z'),
    reward('issued', '2026-10-06T12:00:00.000Z'),
    reward('granted', '2026-10-05T10:00:00.000Z'),
  ]);
}

interface Setup {
  readonly h: TestHarness;
  readonly app: App;
  readonly telegram: StubFetch;
}

function setup(options: HarnessOptions = {}, reply: Response = json({ ok: true })): Setup {
  const telegram = new StubFetch().reply(reply);
  const base = createHarness();
  const h = createHarness({
    ...options,
    overrides: {
      telegramBot: { ...base.deps.telegramBot, fetch: telegram.fetch },
      ...options.overrides,
    },
  });
  h.clock.set(NOW);
  return { h, app: buildApp(h.deps), telegram };
}

function update(text: unknown, chatId: unknown = Number(TEST_TELEGRAM_CHAT_ID)): string {
  return JSON.stringify({
    update_id: 1,
    message: { message_id: 7, chat: { id: chatId, type: 'private' }, text },
  });
}

function post(app: App, body: string, secret: string | null = TEST_TELEGRAM_WEBHOOK_SECRET) {
  const headers: Record<string, string> = { 'content-type': 'application/json' };
  if (secret !== null) {
    headers[TELEGRAM_SECRET_HEADER] = secret;
  }
  return app.request(TELEGRAM_ROUTE, { method: 'POST', headers, body });
}

/** The single `sendMessage` the bot sent. */
function sent(telegram: StubFetch): { url: string; chatId: unknown; text: string } {
  expect(telegram.requests).toHaveLength(1);
  const request = telegram.requests[0];
  const body = JSON.parse(request?.body ?? '{}') as { chat_id: unknown; text: string };
  return { url: request?.url ?? '', chatId: body.chat_id, text: body.text };
}

async function ask(text: string): Promise<{ text: string; h: TestHarness }> {
  const { h, app, telegram } = setup();
  const res = await post(app, update(text));
  expect(res.status).toBe(200);
  return { text: sent(telegram).text, h };
}

describe('POST /v1/admin/telegram', () => {
  beforeAll(seed);

  describe('webhook secret', () => {
    it('answers 401 with no body and no reply when the header is missing', async () => {
      const { app, telegram } = setup();
      const res = await post(app, update('/today'), null);
      expect(res.status).toBe(401);
      expect(await res.text()).toBe('');
      expect(telegram.requests).toHaveLength(0);
    });

    it('answers 401 for a wrong secret (same length and different length)', async () => {
      const { app, telegram } = setup();
      const sameLength = TEST_TELEGRAM_WEBHOOK_SECRET.replace(/.$/, 'X');
      expect((await post(app, update('/today'), sameLength)).status).toBe(401);
      expect((await post(app, update('/today'), 'short')).status).toBe(401);
      expect(telegram.requests).toHaveLength(0);
    });

    it('answers 401 to everything while TELEGRAM_WEBHOOK_SECRET is not set', async () => {
      const base = createHarness();
      const { app } = setup({
        overrides: { telegramBot: { ...base.deps.telegramBot, webhookSecret: undefined } },
      });
      expect((await post(app, update('/today'))).status).toBe(401);
    });

    it('is not an OpenAPI route and needs no X-Taro headers or install token', async () => {
      const { app } = setup();
      const res = await post(app, update('/help'));
      expect(res.status).toBe(200);
      expect(await res.text()).toBe('');
    });
  });

  describe('ignored updates (200, no reply)', () => {
    it.each([
      ['a chat outside the allowlist', update('/today', 123456789)],
      ['a chat id that is not a number', update('/today', { id: 1 })],
      ['a message without text', update(undefined)],
      ['an update without a message', JSON.stringify({ update_id: 2, edited_message: {} })],
      ['a malformed body', '{not json'],
    ])('%s', async (_name, body) => {
      const { app, telegram } = setup();
      const res = await post(app, body);
      expect(res.status).toBe(200);
      expect(telegram.requests).toHaveLength(0);
    });

    it('a configured secret without ALERT_WEBHOOK_URL (no reply target)', async () => {
      const base = createHarness();
      const { app, telegram } = setup({
        overrides: { telegramBot: { ...base.deps.telegramBot, target: undefined } },
      });
      expect((await post(app, update('/today'))).status).toBe(200);
      expect(telegram.requests).toHaveLength(0);
    });

    it('a rate-limited chat (RL_READINGS, key tg:{chatId})', async () => {
      const { h, app, telegram } = setup();
      h.readings.limitPerKey = 1;
      expect((await post(app, update('/help'))).status).toBe(200);
      expect((await post(app, update('/help'))).status).toBe(200);
      expect(telegram.requests).toHaveLength(1);
      expect(h.readings.keys).toEqual([
        `tg:${TEST_TELEGRAM_CHAT_ID}`,
        `tg:${TEST_TELEGRAM_CHAT_ID}`,
      ]);
      expect(h.logger.find('telegram_rate_limited')).toHaveLength(1);
    });
  });

  describe('replies', () => {
    it('/help lists the four commands and replies to the asking chat via sendMessage', async () => {
      const { app, telegram } = setup();
      await post(app, update('/help'));
      const reply = sent(telegram);
      expect(reply.url).toBe(TEST_TELEGRAM_ENDPOINT);
      expect(reply.chatId).toBe(TEST_TELEGRAM_CHAT_ID);
      expect(reply.text).toBe(
        [
          '🤖 Taro stats (dev), read-only',
          "/today — today's numbers (UTC day)",
          '/week — the last 7 UTC days, one line per day + totals',
          '/budget — AI budget tiers and headroom (UTC day)',
          '/help — this list',
        ].join('\n'),
      );
    });

    it('/start is /help', async () => {
      expect((await ask('/start')).text).toContain('/budget — ');
    });

    it.each(['/stats', 'hello', '/'])('unknown %j → a /help hint', async (text) => {
      expect((await ask(text)).text).toBe('Unknown command. Send /help for the list.');
    });

    it('/today (case-insensitive, with @botname)', async () => {
      const { text } = await ask('/TODAY@taro_alerts_vsh_bot please');
      expect(text).toBe(
        [
          '📊 Taro today (dev, UTC day 2026-10-06)',
          'Readings: 3 ✓ · 2 declined · 1 failed · 2 refunded · 1 crisis',
          'AI spend: $1.84 · soft $50.00 · hard $300.00 · tier: ok',
          'Avg cost: $0.011/reading',
          'Installs: 2 new · 4 active',
          'Purchases: 5 (2× readings_10, 2× remove_ads, 1× readings_3) · sandbox 2',
          'Refunds: 1',
          'Rewarded: 2',
        ].join('\n'),
      );
    });

    it('/week: one line per UTC day plus totals', async () => {
      const { text } = await ask('/week');
      expect(text).toBe(
        [
          '📅 Taro week (dev, UTC days 2026-09-30 – 2026-10-06)',
          '09-30 Wed: 0 ✓ · 0 ✗ · $0.00 · 0 new · 0 active · 0 💳',
          '10-01 Thu: 0 ✓ · 0 ✗ · $0.00 · 1 new · 0 active · 0 💳',
          '10-02 Fri: 0 ✓ · 0 ✗ · $0.10 · 0 new · 0 active · 0 💳',
          '10-03 Sat: 0 ✓ · 0 ✗ · $0.00 · 0 new · 0 active · 1 💳',
          '10-04 Sun: 0 ✓ · 1 ✗ · $0.00 · 0 new · 1 active · 0 💳',
          '10-05 Mon: 1 ✓ · 0 ✗ · $0.50 · 0 new · 2 active · 0 💳',
          '10-06 Tue: 3 ✓ · 2 ✗ · $1.84 · 2 new · 4 active · 5 💳',
          'Total:',
          'Readings: 4 ✓ · 3 declined · 1 failed · 2 refunded · 1 crisis',
          'AI spend: $2.44 · avg $0.014/reading',
          'Installs: 3 new',
          'Purchases: 6 (2× readings_10, 2× remove_ads, 1× readings_3, 1× readings_30) · sandbox 2',
          'Refunds: 1 · Rewarded: 3',
        ].join('\n'),
      );
    });

    it('/budget: tier, DAU and headroom to each threshold', async () => {
      const { text } = await ask('/budget');
      expect(text).toBe(
        [
          '💰 Taro budget (dev, UTC day 2026-10-06)',
          'Spend today: $1.84 · tier: ok',
          'DAU (yesterday): 2',
          'Soft: $50.00 · $48.16 left',
          'Free-stop: $100.00 · $98.16 left',
          'Hard: $300.00 · $298.16 left',
        ].join('\n'),
      );
    });

    it('/budget marks reached thresholds and the current tier', async () => {
      const { h, app, telegram } = setup();
      h.config.set({ 'ai.budget.softFloorUsd': 1, 'ai.budget.freeStopFloorUsd': 1.5 });
      await post(app, update('/budget'));
      const { text } = sent(telegram);
      expect(text).toContain('tier: soft');
      expect(text).toContain('Soft: $1.00 · reached');
      expect(text).toContain('Free-stop: $2.00 · $0.16 left');
    });

    it('a day without data shows zeros and no average', async () => {
      const { h, app, telegram } = setup();
      h.clock.set('2026-08-01T12:00:00.000Z');
      await post(app, update('/today'));
      const { text } = sent(telegram);
      expect(text).toContain('Readings: 0 ✓ · 0 declined · 0 failed · 0 refunded · 0 crisis');
      expect(text).toContain('Avg cost: —');
      expect(text).toContain('Purchases: 0\n');
    });

    it('never shows install IDs, questions or other personal data', async () => {
      for (const command of ['/today', '/week', '/budget', '/help']) {
        const { text } = await ask(command);
        for (const id of Object.values(ids)) {
          expect(text).not.toContain(id);
          expect(text).not.toContain(id.slice(0, 8));
        }
        expect(text).not.toContain(QUESTION);
        expect(text).not.toMatch(/@|r-\d|p-\d|ad-\d/);
      }
    });

    it('never logs the bot token, the endpoint or the chat id', async () => {
      const { h, app } = setup();
      await post(app, update('/today'));
      const logs = h.logger.lines().join('\n');
      expect(h.logger.find('telegram_command')[0]?.fields).toEqual({
        command: 'today',
        status: 200,
      });
      expect(logs).not.toContain('123456:TEST-token-abc');
      expect(logs).not.toContain('api.telegram.org');
      expect(logs).not.toContain(TEST_TELEGRAM_CHAT_ID);
      expect(logs).not.toContain(TEST_TELEGRAM_WEBHOOK_SECRET);
    });

    it('a failed sendMessage is logged by status and still answers 200', async () => {
      const { h, app } = setup({}, json({ ok: false }, 403));
      expect((await post(app, update('/help'))).status).toBe(200);
      expect(h.logger.find('telegram_command')[0]).toMatchObject({
        level: 'error',
        fields: { command: 'help', status: 403 },
      });
    });

    it('a network error is logged by error name and still answers 200', async () => {
      const base = createHarness();
      const { h, app } = setup({
        overrides: {
          telegramBot: {
            ...base.deps.telegramBot,
            fetch: () => Promise.reject(new TypeError('network')),
          },
        },
      });
      expect((await post(app, update('/nope'))).status).toBe(200);
      expect(h.logger.find('telegram_command_failed')[0]?.fields).toEqual({
        command: 'unknown',
        error: 'TypeError',
      });
    });

    it('a non-Error failure is logged as unknown', async () => {
      const base = createHarness();
      const { h, app } = setup({
        overrides: {
          telegramBot: {
            ...base.deps.telegramBot,
            fetch: () => Promise.reject(NOT_AN_ERROR),
          },
        },
      });
      await post(app, update('/help'));
      expect(h.logger.find('telegram_command_failed')[0]?.fields).toMatchObject({
        error: 'unknown',
      });
    });

    it('answers before the reply when an execution context exists (waitUntil)', async () => {
      const { app, telegram } = setup();
      const ctx = createExecutionContext();
      const res = await app.request(
        TELEGRAM_ROUTE,
        {
          method: 'POST',
          headers: { [TELEGRAM_SECRET_HEADER]: TEST_TELEGRAM_WEBHOOK_SECRET },
          body: update('/help'),
        },
        {},
        ctx,
      );
      expect(res.status).toBe(200);
      await waitOnExecutionContext(ctx);
      expect(telegram.requests).toHaveLength(1);
    });
  });
});
