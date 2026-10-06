import { redactFields } from '../../logging/redact';
import type { Alert, Alerter } from '../../ports/Alerter';
import type { Clock } from '../../ports/Clock';
import type { LogFields, Logger } from '../../ports/Logger';

export type FetchFn = (input: string, init: RequestInit) => Promise<Response>;

/** Minimum gap between two messages of one dedupe bucket (03 §14.1). */
export const ALERT_DEDUPE_SEC = 3600;

/** `CACHE_KV` key holding the last-sent instant of a dedupe bucket (GLOSSARY §6.1). */
export function alertDedupeKey(bucket: string): string {
  return `alert:last:${bucket}`;
}

/** Telegram's `sendMessage` text limit (characters). */
export const TELEGRAM_MAX_TEXT = 4096;

/** Where a Telegram alert goes: the token stays inside `endpoint` only. */
export interface TelegramTarget {
  /** `https://api.telegram.org/bot<TOKEN>/sendMessage` (secret; never logged). */
  readonly endpoint: string;
  readonly chatId: string;
}

/**
 * Recognises a Telegram Bot API URL
 * `https://api.telegram.org/bot<TOKEN>/sendMessage?chat_id=<ID>`; anything
 * else (a Slack-style webhook) returns `undefined`.
 */
export function parseTelegramUrl(url: string): TelegramTarget | undefined {
  let parsed: URL;
  try {
    parsed = new URL(url);
  } catch {
    return undefined;
  }
  const chatId = parsed.searchParams.get('chat_id') ?? '';
  if (
    parsed.protocol !== 'https:' ||
    parsed.hostname !== 'api.telegram.org' ||
    !/^\/bot[^/]+\/sendMessage$/.test(parsed.pathname) ||
    chatId === ''
  ) {
    return undefined;
  }
  return { endpoint: `${parsed.origin}${parsed.pathname}`, chatId };
}

/** Cuts `text` to at most `max` UTF-16 units with a trailing ellipsis, never splitting a surrogate pair. */
export function truncateText(text: string, max: number): string {
  if (text.length <= max) {
    return text;
  }
  let cut = text.slice(0, max - 1);
  if (/[\uD800-\uDBFF]$/.test(cut)) {
    cut = cut.slice(0, -1);
  }
  return `${cut}…`;
}

/** The Telegram message: header with service, environment and kind, the message, then one line per (already redacted) field. */
export function formatTelegramText(
  alert: Alert,
  fields: LogFields | undefined,
  environment: string | undefined,
): string {
  const env = environment === undefined || environment === '' ? '' : ` (${environment})`;
  const lines = [`🔔 taro-api${env} — ${alert.kind}`, alert.message];
  for (const [key, value] of Object.entries(fields ?? {})) {
    if (value !== undefined) {
      lines.push(`${key}: ${String(value)}`);
    }
  }
  return truncateText(lines.join('\n'), TELEGRAM_MAX_TEXT);
}

/**
 * Posts one Telegram `sendMessage` (`{chat_id, text, disable_web_page_preview}`)
 * to `target.endpoint`; `text` is cut to `TELEGRAM_MAX_TEXT`. The endpoint
 * holds the bot token: callers must never log it. Shared by `WebhookAlerter`
 * and the stats bot (`routes/telegram.ts`).
 */
export function postTelegramMessage(
  fetchFn: FetchFn,
  target: TelegramTarget,
  text: string,
): Promise<Response> {
  return fetchFn(target.endpoint, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      chat_id: target.chatId,
      text: truncateText(text, TELEGRAM_MAX_TEXT),
      disable_web_page_preview: true,
    }),
  });
}

/** Hourly per-kind dedupe state (`CACHE_KV`, 03 §14.1). */
export interface AlertDedupe {
  readonly cache: KVNamespace;
  readonly clock: Clock;
}

/**
 * Posts alerts to `ALERT_WEBHOOK_URL` (03 §14.1). Without a URL (dev) the
 * alert is only logged. Never throws.
 *
 * A Telegram Bot API URL (`parseTelegramUrl`) gets
 * `{chat_id, text, disable_web_page_preview: true}` posted to its
 * `sendMessage` endpoint, with `environment` in the text; any other URL gets
 * the Slack-style `{text, fields}`. The URL carries the bot token, so it is
 * never logged: failures log only the kind and the HTTP status or error name.
 *
 * With `dedupe`, each bucket (`alert.dedupeKey ?? alert.kind`) is sent at
 * most once per hour: the last-sent instant lives in `CACHE_KV` under
 * `alert:last:{bucket}` (TTL one hour). The mark is written before the post,
 * so concurrent isolates rarely both send; KV is eventually consistent, so
 * a rare duplicate across colos is accepted. A KV failure fails open (the
 * alert is sent): a missed page is worse than a duplicate.
 */
export class WebhookAlerter implements Alerter {
  constructor(
    private readonly fetchFn: FetchFn,
    private readonly url: string | undefined,
    private readonly logger: Logger,
    private readonly dedupe?: AlertDedupe,
    private readonly environment?: string,
  ) {}

  async send(alert: Alert): Promise<void> {
    const bucket = alert.dedupeKey ?? alert.kind;
    if (await this.suppressed(bucket)) {
      this.logger.log('info', 'alert_suppressed', { kind: alert.kind, bucket });
      return;
    }
    const fields = redactFields(alert.fields);
    this.logger.log('warn', 'alert', { kind: alert.kind, message: alert.message });
    if (this.url === undefined || this.url === '') {
      return;
    }
    try {
      const telegram = parseTelegramUrl(this.url);
      const res =
        telegram === undefined
          ? await this.fetchFn(this.url, {
              method: 'POST',
              headers: { 'content-type': 'application/json' },
              body: JSON.stringify({ text: `[taro-api] ${alert.kind}: ${alert.message}`, fields }),
            })
          : await postTelegramMessage(
              this.fetchFn,
              telegram,
              formatTelegramText(alert, fields, this.environment),
            );
      if (!res.ok) {
        this.logger.log('error', 'alert_failed', { kind: alert.kind, status: res.status });
      }
    } catch (err) {
      this.logger.log('error', 'alert_failed', {
        kind: alert.kind,
        error: err instanceof Error ? err.name : 'unknown',
      });
    }
  }

  /** True when the bucket was sent within the last hour; otherwise marks it sent now. */
  private async suppressed(bucket: string): Promise<boolean> {
    if (this.dedupe === undefined) {
      return false;
    }
    const { cache, clock } = this.dedupe;
    const key = alertDedupeKey(bucket);
    const now = clock.now().getTime();
    try {
      const last = Date.parse((await cache.get(key)) ?? '');
      if (!Number.isNaN(last) && now - last < ALERT_DEDUPE_SEC * 1000) {
        return true;
      }
      await cache.put(key, new Date(now).toISOString(), { expirationTtl: ALERT_DEDUPE_SEC });
    } catch (err) {
      this.logger.log('warn', 'alert_dedupe_failed', {
        bucket,
        error: err instanceof Error ? err.name : 'unknown',
      });
    }
    return false;
  }
}
