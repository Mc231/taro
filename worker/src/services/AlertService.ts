import type { RuntimeConfig } from '../config/schema';
import type { Alert, Alerter } from '../ports/Alerter';
import type { Logger } from '../ports/Logger';
import type { MetricCount, MetricEvent, Metrics } from '../ports/Metrics';

/**
 * Metric alerts of the 15-minute cron (03 §12, §14.1): Analytics Engine is
 * read through the `Metrics` port over the last 15 minutes and compared with
 * `alerts.*`:
 *
 * - 5xx rate (`http_response` with a `5xx` code over all) > `alerts.error5xxRatePct`;
 * - `reading_failed` over all finished readings (`completed`, `declined`,
 *   `failed`) > `alerts.readingFailedRatePct`;
 * - `webhook_sig_failed` > `alerts.webhookSigFailuresPer15m`.
 *
 * A rate needs at least `ALERT_MIN_EVENTS` numerator events so a single error
 * at night does not page. The `Alerter` keeps at most one message per kind
 * per hour (`alert:last:{kind}` in `CACHE_KV`).
 */
export const ALERT_WINDOW_MINUTES = 15;
export const ALERT_MIN_EVENTS = 3;

const EVENTS: readonly MetricEvent[] = [
  'http_response',
  'reading_completed',
  'reading_declined',
  'reading_failed',
  'webhook_sig_failed',
];

export interface AlertServiceDeps {
  readonly metrics: Metrics;
  readonly alerter: Alerter;
  readonly logger: Logger;
}

export class AlertService {
  constructor(private readonly deps: AlertServiceDeps) {}

  /** The alerts a set of counts triggers (pure; exported for tests and the runbook). */
  static evaluate(counts: readonly MetricCount[], config: RuntimeConfig): Alert[] {
    const sum = (event: MetricEvent, code?: (c: string) => boolean): number =>
      counts
        .filter((c) => c.event === event && (code === undefined || code(c.code)))
        .reduce((total, c) => total + c.count, 0);
    const alerts: Alert[] = [];
    const window = `${String(ALERT_WINDOW_MINUTES)} min`;

    const responses = sum('http_response');
    const errors = sum('http_response', (code) => code.startsWith('5'));
    if (breached(errors, responses, config['alerts.error5xxRatePct'])) {
      alerts.push({
        kind: 'error_rate',
        message: `5xx rate ${pct(errors, responses)} % (${String(errors)}/${String(responses)}) over ${window}`,
        fields: { errors, total: responses },
      });
    }

    const failed = sum('reading_failed');
    const readings = failed + sum('reading_completed') + sum('reading_declined');
    if (breached(failed, readings, config['alerts.readingFailedRatePct'])) {
      alerts.push({
        kind: 'reading_failed_rate',
        message: `reading_failed ${pct(failed, readings)} % (${String(failed)}/${String(readings)}) over ${window}`,
        fields: { failed, total: readings },
      });
    }

    const sigFailures = sum('webhook_sig_failed');
    if (sigFailures > config['alerts.webhookSigFailuresPer15m']) {
      alerts.push({
        kind: 'webhook_sig_failures',
        message: `${String(sigFailures)} webhook signature failures over ${window}`,
        fields: { failures: sigFailures },
      });
    }
    return alerts;
  }

  /** `AlertService.check` (cron): returns the number of alerts handed to the `Alerter`. */
  async check(config: RuntimeConfig): Promise<number> {
    const counts = await this.deps.metrics.counts({
      events: EVENTS,
      windowMinutes: ALERT_WINDOW_MINUTES,
    });
    if (counts === null) {
      this.deps.logger.log('info', 'alert_check_skipped', { reason: 'metrics_unavailable' });
      return 0;
    }
    const alerts = AlertService.evaluate(counts, config);
    for (const alert of alerts) {
      await this.deps.alerter.send(alert);
    }
    return alerts.length;
  }
}

function breached(numerator: number, total: number, maxPct: number): boolean {
  return numerator >= ALERT_MIN_EVENTS && numerator * 100 > maxPct * total;
}

function pct(numerator: number, total: number): string {
  return ((numerator * 100) / total).toFixed(1);
}
