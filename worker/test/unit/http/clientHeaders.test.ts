import { Hono } from 'hono';
import { describe, expect, it } from 'vitest';
import type { AppEnv } from '../../../src/http/context';
import { errorHandler } from '../../../src/http/errors';
import { clientHeaders, parseClientHeaders } from '../../../src/http/middleware/clientHeaders';
import { requestId } from '../../../src/http/middleware/requestId';
import { CapturingLogger } from '../../fakes/CapturingLogger';
import { SeqIdGenerator } from '../../fakes/SeqIdGenerator';
import { APP_HEADERS, errorOf } from '../../helpers/app';

function appWith(required: boolean) {
  const app = new Hono<AppEnv>();
  app.use('*', requestId(new SeqIdGenerator()));
  app.use('*', clientHeaders({ required }));
  app.onError(errorHandler(new CapturingLogger()));
  app.get('/t', (c) => c.json(c.get('client')));
  return app;
}

describe('parseClientHeaders', () => {
  it('parses the three X-Taro headers', () => {
    const { client, invalid } = parseClientHeaders(new Headers(APP_HEADERS));
    expect(client).toEqual({ platform: 'ios', appVersion: '1.2.0+14', locale: 'de' });
    expect(invalid).toEqual([]);
  });

  it('normalises case and whitespace', () => {
    const { client } = parseClientHeaders(
      new Headers({
        'X-Taro-Platform': ' Android ',
        'X-Taro-App-Version': ' 2.0.1 ',
        'X-Taro-Locale': 'PT',
      }),
    );
    expect(client).toEqual({ platform: 'android', appVersion: '2.0.1', locale: 'pt' });
  });

  it('drops invalid values and reports them', () => {
    const { client, invalid } = parseClientHeaders(
      new Headers({
        'X-Taro-Platform': 'web',
        'X-Taro-App-Version': 'latest',
        'X-Taro-Locale': 'pt-BR',
      }),
    );
    expect(client).toEqual({});
    expect(invalid).toEqual(['X-Taro-Platform', 'X-Taro-App-Version', 'X-Taro-Locale']);
  });
});

describe('clientHeaders middleware', () => {
  it('lenient mode passes requests without headers', async () => {
    const res = await appWith(false).request('/t');
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({});
  });

  it('required mode accepts complete headers', async () => {
    const res = await appWith(true).request('/t', { headers: APP_HEADERS });
    expect(await res.json()).toEqual({ platform: 'ios', appVersion: '1.2.0+14', locale: 'de' });
  });

  it('required mode rejects missing headers with 400 VALIDATION_FAILED', async () => {
    const res = await appWith(true).request('/t', {
      headers: { 'X-Taro-Platform': 'ios' },
    });
    expect(res.status).toBe(400);
    const error = await errorOf(res);
    expect(error.code).toBe('VALIDATION_FAILED');
    expect(error.details).toEqual({
      issues: [
        { path: 'X-Taro-App-Version', code: 'invalid_header', message: 'missing or invalid' },
        { path: 'X-Taro-Locale', code: 'invalid_header', message: 'missing or invalid' },
      ],
    });
  });
});
