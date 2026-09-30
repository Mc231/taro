import type { Clock } from '../../src/ports/Clock';
import type {
  MetricCount,
  MetricCountQuery,
  MetricEvent,
  MetricPoint,
  Metrics,
} from '../../src/ports/Metrics';

interface Stamped {
  readonly point: MetricPoint;
  readonly at: number;
}

/**
 * Records every point. With a clock, `counts` honours the query window;
 * without one every recorded point is in the window. `queryable = false`
 * makes `counts` return null (no SQL access).
 *
 * `points` holds the domain events; the per-request `http_response` points
 * of the logging middleware go to `responses`, so assertions on `points`
 * are not affected by request bookkeeping.
 */
export class InMemoryMetrics implements Metrics {
  readonly points: MetricPoint[] = [];
  readonly responses: MetricPoint[] = [];
  private readonly stamped: Stamped[] = [];
  queryable = true;

  constructor(private readonly clock?: Clock) {}

  write(point: MetricPoint): void {
    (point.event === 'http_response' ? this.responses : this.points).push(point);
    this.stamped.push({ point, at: this.clock?.now().getTime() ?? 0 });
  }

  events(): MetricEvent[] {
    return this.points.map((p) => p.event);
  }

  count(event: MetricEvent): number {
    return this.points.filter((p) => p.event === event).length;
  }

  counts(query: MetricCountQuery): Promise<readonly MetricCount[] | null> {
    if (!this.queryable) {
      return Promise.resolve(null);
    }
    const from =
      this.clock === undefined
        ? Number.NEGATIVE_INFINITY
        : this.clock.now().getTime() - query.windowMinutes * 60_000;
    const totals = new Map<string, MetricCount>();
    for (const { point, at } of this.stamped) {
      if (at <= from || !query.events.includes(point.event)) {
        continue;
      }
      const code = point.code ?? '';
      const key = `${point.event}\u0000${code}`;
      const prev = totals.get(key)?.count ?? 0;
      totals.set(key, { event: point.event, code, count: prev + 1 });
    }
    return Promise.resolve([...totals.values()]);
  }
}
