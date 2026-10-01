import { afterEach, describe, expect, it } from 'vitest';
import {
  DEFAULT_PUBLIC_CONFIG,
  DEFAULT_RUNTIME_CONFIG,
  DEFAULT_SERVER_CONFIG,
} from '../../../src/config/defaults';
import { CONFIG_KV_KEYS } from '../../../src/config/schema';
import {
  CONFIG_CACHE_TTL_MS,
  ConfigService,
  isolateConfigCache,
  parseStoredDocument,
  type ConfigCache,
} from '../../../src/services/ConfigService';
import { CapturingLogger } from '../../fakes/CapturingLogger';
import { FixedClock } from '../../fakes/FixedClock';
import { bindings } from '../../fakes/testDeps';

const kv = bindings.CONFIG_KV;

async function store(kind: 'public' | 'server', value: unknown): Promise<void> {
  await kv.put(CONFIG_KV_KEYS[kind], typeof value === 'string' ? value : JSON.stringify(value));
}

function service(cache: ConfigCache = {}, backing: KVNamespace = kv) {
  const clock = new FixedClock();
  const logger = new CapturingLogger();
  return { clock, logger, cache, config: new ConfigService(backing, clock, logger, cache) };
}

/** A KV stand-in that counts reads and can fail. */
class ScriptedKv {
  reads = 0;
  failing = false;
  values = new Map<string, string>();

  get(key: string): Promise<string | null> {
    this.reads++;
    if (this.failing) {
      return Promise.reject(new TypeError('KV unavailable'));
    }
    return Promise.resolve(this.values.get(key) ?? null);
  }

  asKv(): KVNamespace {
    return this as unknown as KVNamespace;
  }
}

afterEach(async () => {
  await kv.delete(CONFIG_KV_KEYS.public);
  await kv.delete(CONFIG_KV_KEYS.server);
});

describe('ConfigService (03 §8.1)', () => {
  it('falls back to the compiled defaults and logs config_invalid when KV is empty', async () => {
    const { config, logger } = service();
    await expect(config.snapshot()).resolves.toEqual(DEFAULT_RUNTIME_CONFIG);
    expect(logger.find('config_invalid').map((e) => [e.level, e.fields])).toEqual([
      ['warn', { document: 'public', reason: 'missing' }],
      ['warn', { document: 'server', reason: 'missing' }],
    ]);
  });

  it('serves stored documents laid over the defaults', async () => {
    await store('public', { version: 5, 'readings.freeDaily': 2, 'app.minVersion.ios': '1.4.0' });
    await store('server', {
      ...DEFAULT_SERVER_CONFIG,
      version: 9,
      'ai.model.free': 'gpt-6-luna',
    });
    const { config, logger } = service();
    const snapshot = await config.snapshot();
    expect(snapshot).toMatchObject({
      version: 5,
      serverVersion: 9,
      'readings.freeDaily': 2,
      'app.minVersion.ios': '1.4.0',
      'readings.enabled': true,
      'ai.model.free': 'gpt-6-luna',
    });
    expect(logger.entries).toEqual([]);
  });

  it('drops unknown keys written by a newer Worker', async () => {
    await store('public', { ...DEFAULT_PUBLIC_CONFIG, version: 2, 'future.flag': true });
    const snapshot = await service().config.snapshot();
    expect(snapshot.version).toBe(2);
    expect('future.flag' in snapshot).toBe(false);
  });

  it.each([
    ['not JSON', '{nope', 'json'],
    ['a JSON array', '[1,2]', 'json'],
    ['JSON null', 'null', 'json'],
    ['an out-of-range value', { version: 3, 'readings.freeDaily': 0 }, 'schema'],
    ['no version', { 'readings.freeDaily': 2 }, 'schema'],
  ])('falls back per document on %s', async (_label, value, reason) => {
    await store('public', value);
    await store('server', { ...DEFAULT_SERVER_CONFIG, version: 4 });
    const { config, logger } = service();
    const snapshot = await config.snapshot();
    expect(snapshot.version).toBe(DEFAULT_PUBLIC_CONFIG.version);
    expect(snapshot['readings.freeDaily']).toBe(1);
    expect(snapshot.serverVersion).toBe(4);
    const [entry] = logger.find('config_invalid');
    expect(entry?.level).toBe('error');
    expect(entry?.fields).toMatchObject({ document: 'public', reason });
  });

  it('names the first failing key without logging values', async () => {
    await store('server', { ...DEFAULT_SERVER_CONFIG, version: 2, 'ai.maxRetries': 99 });
    const { config, logger } = service();
    await config.snapshot();
    const entry = logger.find('config_invalid').find((e) => e.fields['document'] === 'server');
    const detail = String(entry?.fields['detail']);
    expect(detail).toContain("'ai.maxRetries'");
    expect(detail).not.toContain('99');
  });

  it('caches the parsed config for 60 s per isolate', async () => {
    const backing = new ScriptedKv();
    const { config, clock } = service({}, backing.asKv());
    await config.snapshot();
    await config.snapshot();
    expect(backing.reads).toBe(2);
    backing.values.set(CONFIG_KV_KEYS.public, JSON.stringify({ version: 8 }));
    clock.advance({ ms: CONFIG_CACHE_TTL_MS - 1 });
    expect((await config.snapshot()).version).toBe(DEFAULT_PUBLIC_CONFIG.version);
    clock.advance({ ms: 1 });
    expect((await config.snapshot()).version).toBe(8);
    expect(backing.reads).toBe(4);
  });

  it('shares the cache between service instances (one per request) and dedupes concurrent loads', async () => {
    const backing = new ScriptedKv();
    const cache: ConfigCache = {};
    const a = service(cache, backing.asKv()).config;
    const b = service(cache, backing.asKv()).config;
    const [x, y] = await Promise.all([a.snapshot(), b.snapshot()]);
    expect(x).toBe(y);
    expect(backing.reads).toBe(2);
    expect(cache.inflight).toBeUndefined();
    await b.snapshot();
    expect(backing.reads).toBe(2);
  });

  it('keeps serving the last valid document when KV itself fails', async () => {
    const backing = new ScriptedKv();
    backing.values.set(
      CONFIG_KV_KEYS.public,
      JSON.stringify({ version: 6, 'readings.enabled': false }),
    );
    const { config, clock, logger } = service({}, backing.asKv());
    expect((await config.snapshot())['readings.enabled']).toBe(false);

    backing.failing = true;
    clock.advance({ ms: CONFIG_CACHE_TTL_MS });
    const snapshot = await config.snapshot();
    expect(snapshot.version).toBe(6);
    expect(snapshot['readings.enabled']).toBe(false);
    expect(
      logger.find('config_invalid').filter((e) => e.fields['reason'] === 'kv_error'),
    ).toHaveLength(2);
    expect(logger.find('config_invalid').at(-1)?.fields).toMatchObject({ error: 'TypeError' });
  });

  it('uses the defaults when KV fails before any valid read', async () => {
    const backing = new ScriptedKv();
    backing.failing = true;
    const { config } = service({}, backing.asKv());
    await expect(config.snapshot()).resolves.toEqual(DEFAULT_RUNTIME_CONFIG);
  });

  it('logs a non-Error KV failure as unknown', async () => {
    const backing = {
      // eslint-disable-next-line @typescript-eslint/prefer-promise-reject-errors -- a non-Error rejection is the case under test
      get: () => Promise.reject('boom'),
    } as unknown as KVNamespace;
    const { config, logger } = service({}, backing);
    await config.snapshot();
    expect(logger.find('config_invalid')[0]?.fields).toMatchObject({ error: 'unknown' });
  });

  it('exports a module-level cache for production deps', () => {
    expect(isolateConfigCache).toBeTypeOf('object');
  });
});

describe('parseStoredDocument', () => {
  it('overlays the defaults and keeps the stored version', () => {
    const parsed = parseStoredDocument(
      'server',
      JSON.stringify({ version: 12 }),
      DEFAULT_SERVER_CONFIG,
    );
    expect(parsed).toEqual({ ok: true, value: { ...DEFAULT_SERVER_CONFIG, version: 12 } });
  });

  it('reports the number of issues', () => {
    const parsed = parseStoredDocument(
      'public',
      JSON.stringify({ version: -1, 'readings.freeDaily': 9 }),
      DEFAULT_PUBLIC_CONFIG,
    );
    expect(parsed.ok).toBe(false);
    expect(parsed.ok ? '' : parsed.detail).toMatch(/^2 issue\(s\); first at 'version'/);
  });
});
