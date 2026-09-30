import type { MiddlewareHandler } from 'hono';
import { routePath } from 'hono/route';
import { inst8 } from '../../logging/redact';
import type { Clock } from '../../ports/Clock';
import type { Logger } from '../../ports/Logger';
import type { Metrics } from '../../ports/Metrics';
import type { AppEnv } from '../context';

/**
 * One structured line per request (03 §14.1):
 * `{ts, level, requestId, route, status, latencyMs, inst8, plat, appVer, code}`.
 * `route` is the matched pattern (no path parameters), the install ID is
 * reduced to `inst8`, and nothing from the body or other headers is logged.
 * With `metrics`, every response also writes an `http_response` point
 * (`code` = status) for the `AlertService` 5xx rate.
 */
export function logging(
  clock: Clock,
  logger: Logger,
  metrics?: Metrics,
): MiddlewareHandler<AppEnv> {
  return async (c, next) => {
    const started = clock.now().getTime();
    await next();
    const status = c.res.status;
    const client = c.get('client') as AppEnv['Variables']['client'] | undefined;
    const latencyMs = clock.now().getTime() - started;
    metrics?.write({ event: 'http_response', code: String(status), latencyMs });
    logger.log(status >= 500 ? 'error' : 'info', 'request', {
      requestId: c.get('requestId'),
      route: `${c.req.method} ${routePath(c, -1)}`,
      status,
      latencyMs,
      inst8: inst8(c.get('installId')),
      plat: client?.platform,
      appVer: client?.appVersion,
      code: c.get('errorCode'),
    });
  };
}
