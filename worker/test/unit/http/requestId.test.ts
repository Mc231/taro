import { describe, expect, it } from 'vitest';
import { createHarness } from '../../fakes/testDeps';
import { testApp } from '../../helpers/app';

describe('requestId middleware (03 §2.1)', () => {
  it('generates an ID via IdGenerator and exposes it on the response and context', async () => {
    const h = createHarness();
    let seen: string | undefined;
    const app = testApp(h, (a) =>
      a.get('/t/id', (c) => {
        seen = c.get('requestId');
        return c.text('ok');
      }),
    );
    const res = await app.request('/t/id');

    expect(res.headers.get('X-Request-Id')).toBe('00000000-0000-4000-8000-000000000001');
    expect(seen).toBe('00000000-0000-4000-8000-000000000001');
  });

  it('echoes a well-formed client ID', async () => {
    const h = createHarness();
    const id = '9f0c1e2d-aaaa-4bbb-8ccc-123456789abc';
    const res = await testApp(h).request('/v1/health', { headers: { 'X-Request-Id': id } });

    expect(res.headers.get('X-Request-Id')).toBe(id);
  });

  it.each(['short', 'has spaces in it', 'x'.repeat(65), 'semi;colon-12345'])(
    'replaces a malformed client ID %j',
    async (bad) => {
      const h = createHarness();
      const res = await testApp(h).request('/v1/health', { headers: { 'X-Request-Id': bad } });

      expect(res.headers.get('X-Request-Id')).toBe('00000000-0000-4000-8000-000000000001');
    },
  );

  it('is present on error and 404 responses', async () => {
    const h = createHarness();
    const res = await testApp(h).request('/nowhere');

    expect(res.status).toBe(404);
    expect(res.headers.get('X-Request-Id')).not.toBeNull();
  });
});
