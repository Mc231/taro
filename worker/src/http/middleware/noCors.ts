import type { MiddlewareHandler } from 'hono';
import type { AppEnv } from '../context';

/**
 * There is no CORS (03 §2.1): a request carrying a browser `Origin` header
 * (including preflights) gets `403` with no CORS headers. The app, store
 * webhooks and the AdMob callback never send `Origin`.
 *
 * The body is empty on purpose: GLOSSARY §5 defines no error code for this
 * case and a browser is not an API client.
 */
export function noCors(): MiddlewareHandler<AppEnv> {
  return async (c, next) => {
    if (c.req.header('Origin') !== undefined) {
      return c.body(null, 403);
    }
    await next();
    return undefined;
  };
}
