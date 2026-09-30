import { describe, expect, it } from 'vitest';
import committedSchema from '../../../config/remote_config.schema.json';
import defaultsFile from '../../../config/remote_config.default.json';
import {
  remoteConfigJsonSchema,
  renderRemoteConfigJsonSchema,
} from '../../../src/admin/configSchemaExport';
import {
  DEFAULT_CONFIG_FILE,
  DEFAULT_PUBLIC_CONFIG,
  DEFAULT_RUNTIME_CONFIG,
  DEFAULT_SERVER_CONFIG,
} from '../../../src/config/defaults';
import {
  mergeConfig,
  PUBLIC_CONFIG_KEYS,
  PublicConfigReadSchema,
  PublicConfigSchema,
  RemoteConfigFileSchema,
  SERVER_CONFIG_KEYS,
  ServerConfigReadSchema,
  ServerConfigSchema,
  SPREAD_IDS,
  toPublicConfig,
} from '../../../src/config/schema';
import spreadsFeed from '../../../src/generated/deck/spreads.json';

function publicWith(overrides: Record<string, unknown>) {
  return PublicConfigSchema.safeParse({ ...DEFAULT_PUBLIC_CONFIG, ...overrides });
}

function serverWith(overrides: Record<string, unknown>) {
  return ServerConfigSchema.safeParse({ ...DEFAULT_SERVER_CONFIG, ...overrides });
}

function firstIssue(result: {
  success: boolean;
  error?: { issues: { path: PropertyKey[]; message: string }[] };
}) {
  const issue = result.error?.issues[0];
  return issue === undefined ? undefined : `${issue.path.map(String).join('.')}: ${issue.message}`;
}

describe('config/remote_config.default.json', () => {
  it('passes the one schema (RC8) with the 03 §8.2 defaults', () => {
    expect(DEFAULT_CONFIG_FILE.public).toEqual(defaultsFile.public);
    expect(DEFAULT_PUBLIC_CONFIG['readings.freeDaily']).toBe(1);
    expect(DEFAULT_PUBLIC_CONFIG['spreads.enabled']).toEqual([...SPREAD_IDS]);
    expect(DEFAULT_SERVER_CONFIG['ai.maxTokensBySpread']).toMatchObject({
      celtic_cross: 8000,
      '*': 4000,
    });
    expect(DEFAULT_SERVER_CONFIG['abuse.lowTrust.cgnatAsns'].length).toBeGreaterThan(0);
    expect(DEFAULT_SERVER_CONFIG['rewarded.allowedAdUnitIds'].length).toBeGreaterThan(0);
  });

  it('holds exactly the schema keys in both documents', () => {
    expect(Object.keys(defaultsFile.public).sort()).toEqual([...PUBLIC_CONFIG_KEYS].sort());
    expect(Object.keys(defaultsFile.server).sort()).toEqual([...SERVER_CONFIG_KEYS].sort());
    const shared = PUBLIC_CONFIG_KEYS.filter(
      (k) => k !== 'version' && SERVER_CONFIG_KEYS.includes(k as never),
    );
    expect(shared).toEqual([]);
  });

  it('names the spread IDs of the generated deck feed (GLOSSARY §2)', () => {
    const ids = (spreadsFeed as { spreads: { id: string }[] }).spreads.map((s) => s.id);
    expect([...SPREAD_IDS].sort()).toEqual([...ids].sort());
  });
});

describe('PublicConfigSchema ranges (03 §8.2, 04 §13)', () => {
  it.each([
    ['readings.freeDaily', 0],
    ['readings.freeDaily', 6],
    ['readings.freeDaily', 1.5],
    ['readings.maxPerInstallPerDay', 4],
    ['readings.tzCooldownHours', 169],
    ['rewarded.amount', 3],
    ['rewarded.dailyCap', 11],
    ['rewarded.cooldownSec', 3601],
    ['rewarded.intentTtlSec', 299],
    ['rewarded.loadTimeoutSec', 4],
    ['rewarded.grantPollTimeoutSec', 61],
    ['ads.bannerMinCompletedReadings', 11],
    ['store.verifyRetryWindowHours', 23],
    ['store.pendingHoldMinutes', 241],
    ['balance.staleAfterSec', 29],
    ['balance.resumeSyncThrottleSec', 601],
    ['review.promptAfterPositiveReadings', 0],
    ['ai.consentVersion', 0],
    ['app.minVersion.ios', '1.0'],
    ['legal.termsUrl', 'http://taro.vshyrochuk.com/terms'],
    ['support.email', 'not-an-email'],
    ['spreads.enabled', ['single', 'daily_card']],
    ['ads.bannerScreens', ['home', 'reading']],
    ['store.packs', []],
    ['readings.enabled', 'yes'],
  ])('rejects %s = %j', (key, value) => {
    expect(publicWith({ [key]: value }).success).toBe(false);
  });

  it('accepts the range edges', () => {
    const result = publicWith({
      'readings.freeDaily': 5,
      'rewarded.dailyCap': 0,
      'spreads.enabled': [],
      'app.minVersion.android': '2.10.3+120',
    });
    expect(firstIssue(result)).toBeUndefined();
  });

  it('rejects unknown keys on push, e.g. a per-spread cost (RC62)', () => {
    expect(firstIssue(publicWith({ 'spreads.costOverrides': { celtic_cross: 3 } }))).toContain(
      'Unrecognized key',
    );
  });

  it('rejects Worker-injected credits, unknown or duplicate packs (RC3)', () => {
    const pack = { productId: 'com.vshyrochuk.taro.readings_3', enabled: true, sortOrder: 0 };
    expect(publicWith({ 'store.packs': [{ ...pack, credits: 3 }] }).success).toBe(false);
    expect(
      publicWith({ 'store.packs': [{ ...pack, productId: 'com.vshyrochuk.taro.remove_ads' }] })
        .success,
    ).toBe(false);
    expect(firstIssue(publicWith({ 'store.packs': [pack, pack] }))).toContain('duplicate');
    expect(publicWith({ 'store.packs': [{ ...pack, sortOrder: 10 }] }).success).toBe(false);
    expect(publicWith({ 'store.packs': Array.from({ length: 5 }, () => pack) }).success).toBe(
      false,
    );
  });

  it('rejects duplicate spreads and banner screens', () => {
    expect(firstIssue(publicWith({ 'spreads.enabled': ['single', 'single'] }))).toContain(
      'duplicate single',
    );
    expect(firstIssue(publicWith({ 'ads.bannerScreens': ['home', 'home'] }))).toContain(
      'duplicate home',
    );
  });

  it('drops unknown keys on read instead of failing', () => {
    const result = PublicConfigReadSchema.safeParse({ ...DEFAULT_PUBLIC_CONFIG, 'future.key': 1 });
    expect(result.success && 'future.key' in result.data).toBe(false);
  });
});

describe('ServerConfigSchema', () => {
  it.each([
    ['ai.model.paid', 'gpt-5'],
    ['ai.effort', 'extreme'],
    ['ai.promptVersion', '1'],
    ['ai.maxTokensBySpread', { single: 2500 }],
    ['ai.blockedCountries', ['usa']],
    ['ai.timeoutMs', 100],
    ['ai.maxRetries', 4],
    ['ai.budget.freeUsdPerDau', -1],
    ['readings.holdTtlSec', 30],
    ['rewarded.allowedAdUnitIds', []],
    ['attest.allowedAppIds', ['']],
    ['purchases.allowedBundleIds', []],
    ['alerts.error5xxRatePct', 101],
    ['abuse.lowTrust.freeDaily', 6],
    ['abuse.lowTrust.cgnatAsns', [0]],
    ['abuse.lowTrust.powBits', 40],
    ['rl.readings.perMinute', 0],
  ])('rejects %s = %j', (key, value) => {
    expect(serverWith({ [key]: value }).success).toBe(false);
  });

  it('requires ordered budget floors (03 §10.2)', () => {
    expect(firstIssue(serverWith({ 'ai.budget.softFloorUsd': 200 }))).toContain('budget floors');
    expect(firstIssue(serverWith({ 'ai.budget.dailyHardUsd': 99 }))).toContain('budget floors');
  });

  it('rejects duplicate blocked countries', () => {
    expect(firstIssue(serverWith({ 'ai.blockedCountries': ['CN', 'CN'] }))).toContain(
      'duplicate CN',
    );
  });
});

describe('AI provider routing (RC97)', () => {
  it('ships the Anthropic defaults, no outage fallback, no moderation, both providers disclosed', () => {
    expect(DEFAULT_SERVER_CONFIG).toMatchObject({
      'ai.provider.paid': 'anthropic',
      'ai.provider.free': 'anthropic',
      'ai.provider.freeFallback': 'anthropic',
      'ai.outageFallback.provider': null,
      'ai.outageFallback.model': null,
      'ai.moderation.provider': 'none',
      'ai.disclosedProviders': ['anthropic', 'openai'],
      'ai.model.paid': 'claude-opus-5',
      'ai.model.free': 'claude-sonnet-5',
      'ai.model.freeFallback': 'claude-sonnet-5',
    });
  });

  it('blocks the CS16 fixed list plus the provider snapshot union (RC29, 2026-09-30)', () => {
    const blocked = DEFAULT_SERVER_CONFIG['ai.blockedCountries'];
    expect(blocked.slice(0, 8)).toEqual(['CN', 'RU', 'SA', 'AE', 'QA', 'KW', 'BH', 'OM']);
    for (const code of ['IR', 'KP', 'SY', 'CU', 'BY', 'VE', 'HK', 'MO', 'AF', 'MM', 'YE', 'PR']) {
      expect(blocked).toContain(code);
    }
    for (const code of ['US', 'GB', 'DE', 'UA', 'JP', 'KR', 'BR', 'IN', 'TR']) {
      expect(blocked).not.toContain(code);
    }
  });

  it('accepts routing a tier and the outage fallback to OpenAI with moderation', () => {
    const result = serverWith({
      'ai.provider.free': 'openai',
      'ai.model.free': 'gpt-6-luna',
      'ai.outageFallback.provider': 'openai',
      'ai.outageFallback.model': 'gpt-6.1-sol',
      'ai.moderation.provider': 'openai',
    });
    expect(result.success).toBe(true);
  });

  it.each([
    ['ai.provider.paid', 'google'],
    ['ai.outageFallback.provider', 'mistral'],
    ['ai.moderation.provider', 'anthropic'],
    ['ai.disclosedProviders', []],
    ['ai.disclosedProviders', ['anthropic', 'openai', 'anthropic']],
    ['ai.outageFallback.model', 'Claude Opus'],
  ])('rejects %s = %j', (key, value) => {
    expect(serverWith({ [key]: value }).success).toBe(false);
  });

  it('rejects a duplicate disclosed provider', () => {
    expect(
      firstIssue(serverWith({ 'ai.disclosedProviders': ['anthropic', 'anthropic'] })),
    ).toContain('duplicate anthropic');
  });

  it.each([
    [{ 'ai.provider.paid': 'openai', 'ai.model.paid': 'gpt-6.1-sol' }, 'ai.provider.paid'],
    [
      { 'ai.provider.freeFallback': 'openai', 'ai.model.freeFallback': 'gpt-6-luna' },
      'ai.provider.freeFallback',
    ],
    [
      { 'ai.outageFallback.provider': 'openai', 'ai.outageFallback.model': 'gpt-6-luna' },
      'ai.outageFallback.provider',
    ],
    [{ 'ai.moderation.provider': 'openai' }, 'ai.moderation.provider'],
  ])('rejects routing to a provider outside ai.disclosedProviders: %j', (overrides, key) => {
    const result = serverWith({ ...overrides, 'ai.disclosedProviders': ['anthropic'] });
    expect(firstIssue(result)).toBe(`${key}: provider openai is not in ai.disclosedProviders`);
  });

  it('rejects a tier model of the wrong provider family', () => {
    expect(firstIssue(serverWith({ 'ai.provider.free': 'openai' }))).toBe(
      'ai.model.free: model claude-sonnet-5 is not a openai model',
    );
    expect(firstIssue(serverWith({ 'ai.model.paid': 'gpt-6.1-sol' }))).toBe(
      'ai.model.paid: model gpt-6.1-sol is not a anthropic model',
    );
  });

  it('requires the outage fallback provider and model together, of one family', () => {
    expect(firstIssue(serverWith({ 'ai.outageFallback.provider': 'openai' }))).toContain(
      'both set or both null',
    );
    expect(firstIssue(serverWith({ 'ai.outageFallback.model': 'gpt-6-luna' }))).toContain(
      'both set or both null',
    );
    expect(
      firstIssue(
        serverWith({
          'ai.outageFallback.provider': 'anthropic',
          'ai.outageFallback.model': 'gpt-6-luna',
        }),
      ),
    ).toBe('ai.outageFallback.model: model gpt-6-luna is not a anthropic model');
    expect(
      serverWith({
        'ai.outageFallback.provider': 'anthropic',
        'ai.outageFallback.model': 'claude-sonnet-5',
      }).success,
    ).toBe(true);
  });
});

describe('sandbox caps (RC63)', () => {
  it.each(['purchases.sandboxMaxCreditsPerInstallPerDay', 'purchases.sandboxGlobalCreditsPerDay'])(
    'a prod config without %s is rejected on push and on read',
    (key) => {
      const server: Record<string, unknown> = { ...DEFAULT_SERVER_CONFIG };
      Reflect.deleteProperty(server, key);
      const push = ServerConfigSchema.safeParse(server);
      expect(push.success).toBe(false);
      expect(firstIssue(push)).toContain(key);
      expect(ServerConfigReadSchema.safeParse(server).success).toBe(false);
      expect(
        RemoteConfigFileSchema.safeParse({ public: DEFAULT_PUBLIC_CONFIG, server }).success,
      ).toBe(false);
    },
  );

  it('ships the RC63 defaults (30 per install, 1,000 globally per UTC day)', () => {
    expect(DEFAULT_SERVER_CONFIG['purchases.sandboxMaxCreditsPerInstallPerDay']).toBe(30);
    expect(DEFAULT_SERVER_CONFIG['purchases.sandboxGlobalCreditsPerDay']).toBe(1000);
  });
});

describe('RuntimeConfig', () => {
  it('merges both documents with the public version as version', () => {
    const merged = mergeConfig(
      { ...DEFAULT_PUBLIC_CONFIG, version: 7 },
      { ...DEFAULT_SERVER_CONFIG, version: 3 },
    );
    expect(merged.version).toBe(7);
    expect(merged.serverVersion).toBe(3);
    expect(merged['rl.install.perMinute']).toBe(60);
    expect(DEFAULT_RUNTIME_CONFIG['app.minVersion.ios']).toBe('1.0.0');
  });

  it('projects the public document back out (no server key leaks)', () => {
    const pub = toPublicConfig(DEFAULT_RUNTIME_CONFIG);
    expect(pub).toEqual(DEFAULT_PUBLIC_CONFIG);
    expect(Object.keys(pub)).not.toContain('ai.model.paid');
    expect(Object.keys(pub)).not.toContain('serverVersion');
  });
});

describe('config/remote_config.schema.json (export for check_remote_config.py)', () => {
  it('is up to date with the zod schema (npm run config:schema)', () => {
    expect(committedSchema).toEqual(JSON.parse(renderRemoteConfigJsonSchema()));
  });

  it('is strict and carries the ranges', () => {
    const schema = remoteConfigJsonSchema() as {
      additionalProperties: boolean;
      properties: {
        public: { additionalProperties: boolean; properties: Record<string, unknown> };
      };
    };
    expect(schema.additionalProperties).toBe(false);
    expect(schema.properties.public.additionalProperties).toBe(false);
    expect(schema.properties.public.properties['readings.freeDaily']).toMatchObject({
      type: 'integer',
      minimum: 1,
      maximum: 5,
    });
  });
});
