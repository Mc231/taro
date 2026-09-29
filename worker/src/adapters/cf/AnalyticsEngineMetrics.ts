import type { MetricPoint, Metrics } from '../../ports/Metrics';

/**
 * `Metrics` over the Analytics Engine dataset `taro_api_events` (03 §14.1).
 * Column order is fixed; `scripts/metrics.ts` queries by position.
 */
export class AnalyticsEngineMetrics implements Metrics {
  constructor(private readonly dataset: AnalyticsEngineDataset) {}

  write(point: MetricPoint): void {
    this.dataset.writeDataPoint({
      blobs: [
        point.event,
        point.platform ?? '',
        point.locale ?? '',
        point.model ?? '',
        point.promptVersion ?? '',
        point.chargeSource ?? '',
        point.code ?? '',
      ],
      doubles: [
        point.costMicroUsd ?? 0,
        point.latencyMs ?? 0,
        point.inputTokens ?? 0,
        point.outputTokens ?? 0,
        point.credits ?? 0,
      ],
      indexes: [point.event],
    });
  }
}
