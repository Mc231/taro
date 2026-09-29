import type { MiddlewareHandler } from 'hono';
import type { IdGenerator } from '../../ports/IdGenerator';
import type { AppEnv } from '../context';

export const REQUEST_ID_HEADER = 'X-Request-Id';

/** Accepted client request IDs: UUID-like tokens, no free text (they are logged). */
const VALID_REQUEST_ID = /^[A-Za-z0-9-]{8,64}$/;

/**
 * `X-Request-Id` (03 §2.1): echoes a well-formed client value, otherwise
 * generates one. Every response carries it, error responses included.
 */
export function requestId(ids: IdGenerator): MiddlewareHandler<AppEnv> {
  return async (c, next) => {
    const incoming = c.req.header(REQUEST_ID_HEADER);
    const id = incoming !== undefined && VALID_REQUEST_ID.test(incoming) ? incoming : ids.uuid();
    c.set('requestId', id);
    await next();
    c.res.headers.set(REQUEST_ID_HEADER, id);
  };
}
