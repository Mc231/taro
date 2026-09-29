import type { MetricEvent, MetricPoint, Metrics } from '../../src/ports/Metrics';

export class InMemoryMetrics implements Metrics {
  readonly points: MetricPoint[] = [];

  write(point: MetricPoint): void {
    this.points.push(point);
  }

  events(): MetricEvent[] {
    return this.points.map((p) => p.event);
  }

  count(event: MetricEvent): number {
    return this.points.filter((p) => p.event === event).length;
  }
}
