import { redactFields } from '../../logging/redact';
import type { Alert, Alerter } from '../../ports/Alerter';
import type { Clock } from '../../ports/Clock';
import type { Logger } from '../../ports/Logger';

export type FetchFn = (input: string, init: RequestInit) => Promise<Response>;

/** Minimum gap between two messages of one dedupe bucket (03 §14.1). */
export const ALERT_DEDUPE_SEC = 3600;

/** `CACHE_KV` key holding the last-sent instant of a dedupe bucket (GLOSSARY §6.1). */
export function alertDedupeKey(bucket: string): string {
  return `alert:last:${bucket}`;
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
      const res = await this.fetchFn(this.url, {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ text: `[taro-api] ${alert.kind}: ${alert.message}`, fields }),
      });
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
