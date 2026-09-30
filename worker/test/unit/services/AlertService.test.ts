import { env } from 'cloudflare:workers';
import { describe, expect, it } from 'vitest';
import { WebhookAlerter } from '../../../src/adapters/cf/WebhookAlerter';
import { DEFAULT_RUNTIME_CONFIG } from '../../../src/config/defaults';
import type { RuntimeConfig } from '../../../src/config/schema';
import type { Env } from '../../../src/env';
import type { MetricPoint } from '../../../src/ports/Metrics';
import {
  ALERT_MIN_EVENTS,
  ALERT_WINDOW_MINUTES,
  AlertService,
} from '../../../src/services/AlertService';
import { CapturingAlerter } from '../../fakes/CapturingAlerter';
import { CapturingLogger } from '../../fakes/CapturingLogger';
import { FixedClock } from '../../fakes/FixedClock';
import { InMemoryMetrics } from '../../fakes/InMemoryMetrics';

const config: RuntimeConfig = {
  ...DEFAULT_RUNTIME_CONFIG,
  'alerts.error5xxRatePct': 2,
  'alerts.readingFailedRatePct': 10,
  'alerts.webhookSigFailuresPer15m': 5,
};

function setup() {
  const clock = new FixedClock('2026-09-30T10:00:00.000Z');
  const metrics = new InMemoryMetrics(clock);
  const alerter = new CapturingAlerter();
  const logger = new CapturingLogger();
  return {
    clock,
    metrics,
    alerter,
    logger,
    service: new AlertService({ metrics, alerter, logger }),
  };
}

function write(metrics: InMemoryMetrics, point: MetricPoint, times: number): void {
  for (let i = 0; i < times; i++) {
    metrics.write(point);
  }
}

describe('AlertService.check (03 §14.1)', () => {
  it('sends nothing on a quiet window', async () => {
    const { metrics, alerter, service } = setup();
    write(metrics, { event: 'http_response', code: '200' }, 500);
    write(metrics, { event: 'http_response', code: '503' }, 2);
    write(metrics, { event: 'reading_completed' }, 20);
    write(metrics, { event: 'webhook_sig_failed' }, 5);
    expect(await service.check(config)).toBe(0);
    expect(alerter.alerts).toEqual([]);
  });

  it('alerts on a 5xx rate above alerts.error5xxRatePct', async () => {
    const { metrics, alerter, service } = setup();
    write(metrics, { event: 'http_response', code: '200' }, 90);
    write(metrics, { event: 'http_response', code: '500' }, 6);
    write(metrics, { event: 'http_response', code: '404' }, 4);
    expect(await service.check(config)).toBe(1);
    expect(alerter.alerts).toEqual([
      {
        kind: 'error_rate',
        message: '5xx rate 6.0 % (6/100) over 15 min',
        fields: { errors: 6, total: 100 },
      },
    ]);
  });

  it('alerts on the reading_failed rate over completed + declined + failed', async () => {
    const { metrics, alerter, service } = setup();
    write(metrics, { event: 'reading_completed' }, 20);
    write(metrics, { event: 'reading_declined' }, 4);
    write(metrics, { event: 'reading_failed', code: 'timeout' }, 3);
    write(metrics, { event: 'reading_failed', code: 'upstream' }, 3);
    await service.check(config);
    expect(alerter.alerts.map((a) => [a.kind, a.message])).toEqual([
      ['reading_failed_rate', 'reading_failed 20.0 % (6/30) over 15 min'],
    ]);
  });

  it('alerts on webhook signature failures above the per-15-minute limit', async () => {
    const { metrics, alerter, service } = setup();
    write(metrics, { event: 'webhook_sig_failed', code: 'apple' }, 4);
    write(metrics, { event: 'webhook_sig_failed', code: 'google' }, 2);
    await service.check(config);
    expect(alerter.alerts).toEqual([
      {
        kind: 'webhook_sig_failures',
        message: '6 webhook signature failures over 15 min',
        fields: { failures: 6 },
      },
    ]);
  });

  it(`needs ${String(ALERT_MIN_EVENTS)} numerator events before a rate alert`, () => {
    const counts = [
      { event: 'http_response' as const, code: '500', count: ALERT_MIN_EVENTS - 1 },
      { event: 'reading_failed' as const, code: '', count: ALERT_MIN_EVENTS - 1 },
    ];
    expect(AlertService.evaluate(counts, config)).toEqual([]);
  });

  it('only counts the last 15 minutes', async () => {
    const { clock, metrics, alerter, service } = setup();
    write(metrics, { event: 'webhook_sig_failed' }, 10);
    clock.advance({ minutes: ALERT_WINDOW_MINUTES });
    expect(await service.check(config)).toBe(0);
    expect(alerter.alerts).toEqual([]);
  });

  it('skips (and logs) when the metrics read side is unavailable', async () => {
    const { metrics, alerter, logger, service } = setup();
    write(metrics, { event: 'webhook_sig_failed' }, 10);
    metrics.queryable = false;
    expect(await service.check(config)).toBe(0);
    expect(alerter.alerts).toEqual([]);
    expect(logger.find('alert_check_skipped').map((e) => e.fields)).toEqual([
      { reason: 'metrics_unavailable' },
    ]);
  });

  it('sends at most one alert per kind per hour through the WebhookAlerter dedupe', async () => {
    const clock = new FixedClock('2026-09-30T11:00:00.000Z');
    const metrics = new InMemoryMetrics(clock);
    const logger = new CapturingLogger();
    const posted: string[] = [];
    const alerter = new WebhookAlerter(
      (_url, init) => {
        posted.push(init.body as string);
        return Promise.resolve(new Response(null, { status: 200 }));
      },
      'https://alerts.test.invalid/hook',
      logger,
      { cache: (env as unknown as Env).CACHE_KV, clock },
    );
    const service = new AlertService({ metrics, alerter, logger });
    write(metrics, { event: 'webhook_sig_failed' }, 10);
    await service.check(config);
    clock.advance({ minutes: 15 });
    write(metrics, { event: 'webhook_sig_failed' }, 10);
    await service.check(config);
    expect(posted).toHaveLength(1);
    clock.advance({ minutes: 46 });
    write(metrics, { event: 'webhook_sig_failed' }, 10);
    await service.check(config);
    expect(posted).toHaveLength(2);
    expect(logger.find('alert_suppressed')).toHaveLength(1);
  });
});
