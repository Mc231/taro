import type { MiddlewareHandler } from 'hono';
import type { Clock } from '../../ports/Clock';
import type { AppEnv } from '../context';

/**
 * `Date` on every response (02 §6.3, 03 Cross-spec): the client derives its
 * `ServerClockOffset` from it, so it comes from the server `Clock` (IMF-fixdate,
 * RFC 9110 §5.6.7), error responses and idempotent replays included.
 * Registered outermost, next to the request ID.
 */
export function dateHeader(clock: Clock): MiddlewareHandler<AppEnv> {
  return async (c, next) => {
    await next();
    c.res.headers.set('Date', clock.now().toUTCString());
  };
}
