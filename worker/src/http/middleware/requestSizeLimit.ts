import type { MiddlewareHandler } from 'hono';
import type { AppEnv } from '../context';

/**
 * Largest request body the Worker reads (Phase 19.5 security review): the
 * biggest legitimate bodies are the store webhooks (`signedPayload` and the
 * Pub/Sub `data`, each at most 100 000 characters by schema) and the App
 * Attest registration object, all far below this.
 */
export const MAX_REQUEST_BODY_BYTES = 256 * 1024;

/**
 * Rejects a larger body with an empty `413` before any handler, validator
 * or attestation check buffers or parses it. A declared `Content-Length`
 * (without `Transfer-Encoding`) is checked up front. A chunked body is
 * counted on a clone while it streams, so at most `maxBytes` plus one chunk
 * is buffered. The original request is never replaced: replacing it (as
 * hono's `bodyLimit` does) would drop `request.cf`, which the region gate
 * reads. Like `noCors`, the body is empty: GLOSSARY §5 has no code for it
 * and no app build ever sends such a body.
 */
export function requestSizeLimit(
  maxBytes: number = MAX_REQUEST_BODY_BYTES,
): MiddlewareHandler<AppEnv> {
  return async (c, next) => {
    const raw = c.req.raw;
    if (raw.body === null) {
      await next();
      return undefined;
    }
    const declared = raw.headers.get('content-length');
    const tooLarge =
      declared !== null && !raw.headers.has('transfer-encoding')
        ? Number(declared) > maxBytes
        : await streamExceeds(raw.clone(), maxBytes);
    if (tooLarge) {
      return c.body(null, 413);
    }
    await next();
    return undefined;
  };
}

async function streamExceeds(request: Request, maxBytes: number): Promise<boolean> {
  const reader = (request.body as ReadableStream<Uint8Array>).getReader();
  let size = 0;
  for (;;) {
    const { done, value } = await reader.read();
    if (done) {
      return false;
    }
    size += value.byteLength;
    if (size > maxBytes) {
      await reader.cancel();
      return true;
    }
  }
}
