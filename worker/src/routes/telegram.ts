import type { Hono } from 'hono';
import {
  parseTelegramUrl,
  postTelegramMessage,
  type FetchFn,
  type TelegramTarget,
} from '../adapters/cf/WebhookAlerter';
import { utf8 } from '../crypto/encoding';
import type { Deps } from '../deps';
import type { Env } from '../env';
import type { AppContext, AppEnv } from '../http/context';
import { parseStatsCommand, TelegramStatsService } from '../services/TelegramStatsService';

/** The owner's stats bot webhook (GLOSSARY §4 E21, 03 §14.3). Not in the OpenAPI document. */
export const TELEGRAM_ROUTE = '/v1/admin/telegram';
/** Header Telegram sets to the `secret_token` given to `setWebhook`. */
export const TELEGRAM_SECRET_HEADER = 'X-Telegram-Bot-Api-Secret-Token';

/** What the stats bot needs from the environment (`telegramBotDeps`). */
export interface TelegramBotDeps {
  /** `TELEGRAM_WEBHOOK_SECRET`; without it every request is `401`. */
  readonly webhookSecret: string | undefined;
  /** The bot's `sendMessage` endpoint from `ALERT_WEBHOOK_URL` (holds the token; never logged). */
  readonly target: TelegramTarget | undefined;
  /** Chats allowed to ask: the `ALERT_WEBHOOK_URL` chat plus `TELEGRAM_ADMIN_CHAT_IDS`. */
  readonly adminChatIds: readonly string[];
  readonly fetch: FetchFn;
}

const CHAT_ID = /^-?\d{1,20}$/;

/**
 * Builds `TelegramBotDeps` from the Worker env: the reply target and the
 * default allowed chat come from `ALERT_WEBHOOK_URL` (a Telegram Bot API
 * URL); `TELEGRAM_ADMIN_CHAT_IDS` (comma-separated) adds chats.
 */
export function telegramBotDeps(
  env: Pick<Env, 'ALERT_WEBHOOK_URL' | 'TELEGRAM_WEBHOOK_SECRET' | 'TELEGRAM_ADMIN_CHAT_IDS'>,
  fetchFn: FetchFn,
): TelegramBotDeps {
  const target = parseTelegramUrl(env.ALERT_WEBHOOK_URL?.trim() ?? '');
  const extra = (env.TELEGRAM_ADMIN_CHAT_IDS ?? '').split(',').map((id) => id.trim());
  const ids = [target?.chatId ?? '', ...extra].filter((id) => CHAT_ID.test(id));
  const secret = env.TELEGRAM_WEBHOOK_SECRET?.trim() ?? '';
  return {
    webhookSecret: secret === '' ? undefined : secret,
    target,
    adminChatIds: [...new Set(ids)],
    fetch: fetchFn,
  };
}

/** The fields of a Telegram `Update` the bot reads; anything else is ignored. */
interface TelegramUpdate {
  readonly message?: {
    readonly chat?: { readonly id?: unknown };
    readonly text?: unknown;
  };
}

/**
 * `POST /v1/admin/telegram`: the Telegram webhook of the owner's stats bot
 * (@taro_alerts_vsh_bot), read-only (03 §14.3).
 *
 * - `X-Telegram-Bot-Api-Secret-Token` must equal `TELEGRAM_WEBHOOK_SECRET`
 *   (compared over SHA-256 digests in constant time); otherwise `401` with
 *   no body. No install token or `X-Taro-*` headers.
 * - Every other request answers `200` with no body, so Telegram never
 *   retries: updates from a chat outside `adminChatIds`, non-text updates,
 *   malformed bodies, rate-limited chats (`RL_READINGS`, key `tg:{chatId}`)
 *   and failed replies are dropped silently.
 * - The reply is sent with `sendMessage` after the response
 *   (`waitUntil`; awaited when there is no execution context).
 */
export function registerTelegramRoute(app: Hono<AppEnv>, deps: Deps): void {
  const stats = new TelegramStatsService(deps);
  app.post(TELEGRAM_ROUTE, async (c) => {
    if (!(await secretMatches(deps, c.req.header(TELEGRAM_SECRET_HEADER)))) {
      return c.body(null, 401);
    }
    const update = await c.req.json<TelegramUpdate>().catch(() => undefined);
    const work = handleUpdate(deps, stats, update);
    if (!deferred(c, work)) {
      await work;
    }
    return c.body(null, 200);
  });
}

function deferred(c: AppContext, work: Promise<void>): boolean {
  try {
    c.executionCtx.waitUntil(work);
    return true;
  } catch {
    return false;
  }
}

async function secretMatches(deps: Deps, presented: string | undefined): Promise<boolean> {
  const expected = deps.telegramBot.webhookSecret;
  if (expected === undefined || presented === undefined) {
    return false;
  }
  const [a, b] = await Promise.all([
    deps.crypto.sha256(utf8(presented)),
    deps.crypto.sha256(utf8(expected)),
  ]);
  return deps.crypto.timingSafeEqual(a, b);
}

async function handleUpdate(
  deps: Deps,
  stats: TelegramStatsService,
  update: TelegramUpdate | undefined,
): Promise<void> {
  const { target, adminChatIds } = deps.telegramBot;
  const rawChat = update?.message?.chat?.id;
  const text = update?.message?.text;
  const chatId = typeof rawChat === 'number' || typeof rawChat === 'string' ? String(rawChat) : '';
  if (target === undefined || !adminChatIds.includes(chatId) || typeof text !== 'string') {
    return;
  }
  const command = parseStatsCommand(text) ?? 'unknown';
  try {
    const { success } = await deps.rateLimiters.readings.limit({ key: `tg:${chatId}` });
    if (!success) {
      deps.logger.log('warn', 'telegram_rate_limited', { command });
      return;
    }
    const reply = await stats.reply(text);
    const res = await postTelegramMessage(deps.telegramBot.fetch, { ...target, chatId }, reply);
    deps.logger.log(res.ok ? 'info' : 'error', 'telegram_command', {
      command,
      status: res.status,
    });
  } catch (err) {
    deps.logger.log('error', 'telegram_command_failed', {
      command,
      error: err instanceof Error ? err.name : 'unknown',
    });
  }
}
