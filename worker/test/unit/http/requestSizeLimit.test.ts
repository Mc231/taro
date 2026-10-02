import { describe, expect, it } from 'vitest';
import { MAX_REQUEST_BODY_BYTES } from '../../../src/http/middleware/requestSizeLimit';
import { createHarness } from '../../fakes/testDeps';
import { testApp } from '../../helpers/app';

const oversized = 'x'.repeat(MAX_REQUEST_BODY_BYTES + 1);

function stream(text: string): ReadableStream<Uint8Array> {
  const bytes = new TextEncoder().encode(text);
  return new ReadableStream({
    start(controller) {
      for (let i = 0; i < bytes.length; i += 64 * 1024) {
        controller.enqueue(bytes.subarray(i, i + 64 * 1024));
      }
      controller.close();
    },
  });
}

describe('requestSizeLimit (Phase 19.5 security review)', () => {
  it('rejects a declared oversized body with an empty 413 before the route', async () => {
    const h = createHarness();
    const res = await testApp(h).request('/v1/webhooks/appstore', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ signedPayload: oversized }),
    });

    expect(res.status).toBe(413);
    expect(await res.text()).toBe('');
    expect(res.headers.get('X-Request-Id')).not.toBeNull();
    expect(h.logger.find('request')[0]?.fields).toMatchObject({ status: 413 });
  });

  it('rejects an oversized chunked body while it streams', async () => {
    const h = createHarness();
    const res = await testApp(h).request('/v1/installs', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: stream(oversized),
      duplex: 'half',
    } as RequestInit);

    expect(res.status).toBe(413);
  });

  it('passes a chunked body within the limit through unchanged', async () => {
    const h = createHarness();
    const app = testApp(h);
    let seen = '';
    app.post('/echo', async (c) => {
      seen = await c.req.text();
      return c.body(null, 204);
    });
    const body = 'y'.repeat(MAX_REQUEST_BODY_BYTES);
    const res = await app.request('/echo', {
      method: 'POST',
      body: stream(body),
      duplex: 'half',
    } as RequestInit);

    expect(res.status).toBe(204);
    expect(seen).toBe(body);
  });

  it('rejects a declared Content-Length over the limit without reading the body', async () => {
    const h = createHarness();
    const res = await testApp(h).request('/v1/installs', {
      method: 'POST',
      headers: { 'content-length': String(MAX_REQUEST_BODY_BYTES + 1) },
      body: 'x',
    });

    expect(res.status).toBe(413);
  });

  it('lets a body within the limit reach the route', async () => {
    const h = createHarness();
    const res = await testApp(h).request('/v1/webhooks/appstore', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ signedPayload: 'not-a-jws' }),
    });

    expect(res.status).toBe(400);
  });
});
