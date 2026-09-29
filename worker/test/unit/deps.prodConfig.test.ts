import { describe, expect, it } from 'vitest';
import { AnalyticsEngineMetrics } from '../../src/adapters/cf/AnalyticsEngineMetrics';
import { CryptoIdGenerator } from '../../src/adapters/cf/CryptoIdGenerator';
import { JsonLogger } from '../../src/adapters/cf/JsonLogger';
import { SystemClock } from '../../src/adapters/cf/SystemClock';
import { WebCrypto } from '../../src/adapters/cf/WebCrypto';
import { WebhookAlerter } from '../../src/adapters/cf/WebhookAlerter';
import { DEFAULT_RUNTIME_CONFIG } from '../../src/config/defaults';
import { ConfigService } from '../../src/services/ConfigService';
import { SecretConfigError } from '../../src/crypto/keyring';
import { makeProdDeps, TEST_ONLY_VARS } from '../../src/deps';
import type { Env } from '../../src/env';
import { WORKER_VERSION } from '../../src/version';
import pkg from '../../package.json';
import { AppleAppAttestVerifier } from '../../src/adapters/apple/AppAttestVerifier';
import { AppleDeviceCheckApi } from '../../src/adapters/apple/DeviceCheckApi';
import { Ed25519TokenSigner } from '../../src/adapters/cf/Ed25519TokenSigner';
import { GooglePlayIntegrityVerifier } from '../../src/adapters/google/PlayIntegrityVerifier';
import { parseUuidSecret } from '../../src/crypto/keyring';
import { debugAttestationToken } from '../../src/identityDeps';
import {
  bindings,
  TEST_APPLE_ACCOUNT_NS,
  TEST_CHALLENGE_KEY,
  TEST_DEVICE_KEY_SECRET,
  TEST_IDEMPOTENCY_KEYRING,
  TEST_IP_HASH_KEY,
  TEST_PLAY_ACCOUNT_KEY,
  TEST_TOKEN_SIGNING_KEYS as TOKEN_SIGNING_KEYS,
} from '../fakes/testDeps';

function withVars(vars: Record<string, string | undefined>): Env {
  const copy: Record<string, unknown> = { ...bindings };
  for (const [key, value] of Object.entries(vars)) {
    if (value === undefined) {
      Reflect.deleteProperty(copy, key);
    } else {
      copy[key] = value;
    }
  }
  return copy as unknown as Env;
}

const cleanProd = {
  ENVIRONMENT: 'prod',
  ALLOW_DEBUG_ATTESTATION: undefined,
  AI_PROVIDER: undefined,
  DEBUG_ATTESTATION_TOKEN: undefined,
};

describe('makeProdDeps', () => {
  it('reads ENVIRONMENT and the package version', () => {
    const deps = makeProdDeps(bindings);
    expect(deps.environment).toBe('dev');
    expect(deps.workerVersion).toBe(pkg.version);
    expect(WORKER_VERSION).toBe(pkg.version);
  });

  it('wires every 03 §1 port', () => {
    const deps = makeProdDeps(bindings);
    for (const port of [
      'ai',
      'appAttest',
      'playIntegrity',
      'appStore',
      'playDeveloper',
      'admobKeys',
      'googleOidc',
      'deviceCheck',
      'tokenSigner',
      'clock',
      'ids',
      'crypto',
      'config',
      'metrics',
      'logger',
      'alerter',
    ] as const) {
      expect(deps[port], port).toBeDefined();
    }
    expect(deps.clock).toBeInstanceOf(SystemClock);
    expect(deps.ids).toBeInstanceOf(CryptoIdGenerator);
    expect(deps.crypto).toBeInstanceOf(WebCrypto);
    expect(deps.metrics).toBeInstanceOf(AnalyticsEngineMetrics);
    expect(deps.logger).toBeInstanceOf(JsonLogger);
    expect(deps.alerter).toBeInstanceOf(WebhookAlerter);
    expect(deps.db).toBe(bindings.DB);
    expect(deps.rlKv).toBe(bindings.RL_KV);
    expect(deps.cacheKv).toBe(bindings.CACHE_KV);
    expect(deps.rateLimiters.burst).toBe(bindings.RL_BURST);
    expect(deps.rateLimiters.readings).toBe(bindings.RL_READINGS);
  });

  it('reads remote config through ConfigService over CONFIG_KV (defaults while it is empty)', async () => {
    const { config } = makeProdDeps(bindings);
    expect(config).toBeInstanceOf(ConfigService);
    await expect(config.snapshot()).resolves.toEqual(DEFAULT_RUNTIME_CONFIG);
  });

  it('rejects calls to adapters of later phases instead of pretending success', async () => {
    const deps = makeProdDeps(bindings);
    await expect(deps.ai.generate({} as never)).rejects.toThrow('Phase 8');
    await expect(deps.appStore.getTransactionInfo('1')).rejects.toThrow('Phase 7');
  });

  it('parses secrets lazily and fails only when one is used', () => {
    const missing = makeProdDeps(
      withVars({ IDEMPOTENCY_ENC_KEY: undefined, IP_HASH_KEY: undefined }),
    );
    expect(() => missing.keys.idempotency()).toThrow(SecretConfigError);
    expect(() => missing.keys.ipHash()).toThrow('IP_HASH_KEY');

    const present = makeProdDeps(
      withVars({ IDEMPOTENCY_ENC_KEY: TEST_IDEMPOTENCY_KEYRING, IP_HASH_KEY: TEST_IP_HASH_KEY }),
    );
    expect(present.keys.idempotency().current.kid).toBe('kt2');
    expect(present.keys.ipHash().length).toBe(TEST_IP_HASH_KEY.length);
  });

  it('wires the Phase 6.3 identity adapters (App Attest, Play Integrity, DeviceCheck, Ed25519)', async () => {
    const deps = makeProdDeps(withVars({ APPLE_TEAM_ID: ' TEAMID1234 ' }));
    expect(deps.appAttest).toBeInstanceOf(AppleAppAttestVerifier);
    expect(deps.playIntegrity).toBeInstanceOf(GooglePlayIntegrityVerifier);
    expect(deps.deviceCheck).toBeInstanceOf(AppleDeviceCheckApi);
    expect(deps.tokenSigner).toBeInstanceOf(Ed25519TokenSigner);
    expect(deps.appleTeamId).toBe('TEAMID1234');
    expect(makeProdDeps(withVars({ APPLE_TEAM_ID: ' ' })).appleTeamId).toBeUndefined();
    // Missing secrets fail soft (DeviceCheck, Play Integrity) or reject (token signing).
    const bare = makeProdDeps(
      withVars({
        APPLE_TEAM_ID: undefined,
        APPLE_DEVICECHECK_KEY_ID: undefined,
        GOOGLE_SERVICE_ACCOUNT_JSON: undefined,
        TOKEN_SIGNING_KEYS: undefined,
      }),
    );
    expect(await bare.deviceCheck.queryBits('t')).toEqual({ ok: false });
    expect(
      await bare.playIntegrity.verify({
        token: 't',
        expectedRequestHash: 'h',
        allowedPackageNames: ['com.vshyrochuk.taro'],
      }),
    ).toMatchObject({ ok: false, reason: 'unavailable' });
    await expect(bare.tokenSigner.verify('t', new Date(0))).rejects.toBeInstanceOf(
      SecretConfigError,
    );
    const signing = makeProdDeps(withVars({ TOKEN_SIGNING_KEYS }));
    await expect(signing.tokenSigner.verify('t', new Date(0))).resolves.toEqual({ ok: false });
  });

  it('parses the identity secrets lazily', () => {
    const missing = makeProdDeps(
      withVars({
        CHALLENGE_KEY: undefined,
        PLAY_ACCOUNT_KEY: undefined,
        DEVICE_KEY_SECRET: undefined,
        APPLE_ACCOUNT_NS: undefined,
      }),
    );
    expect(() => missing.keys.challenge()).toThrow('CHALLENGE_KEY');
    expect(() => missing.keys.playAccount()).toThrow('PLAY_ACCOUNT_KEY');
    expect(() => missing.keys.deviceKey()).toThrow('DEVICE_KEY_SECRET');
    expect(() => missing.keys.appleAccountNs()).toThrow('APPLE_ACCOUNT_NS');
    const present = makeProdDeps(
      withVars({
        CHALLENGE_KEY: TEST_CHALLENGE_KEY,
        PLAY_ACCOUNT_KEY: TEST_PLAY_ACCOUNT_KEY,
        DEVICE_KEY_SECRET: TEST_DEVICE_KEY_SECRET,
        APPLE_ACCOUNT_NS: TEST_APPLE_ACCOUNT_NS.toUpperCase(),
      }),
    );
    expect(present.keys.challenge().length).toBe(TEST_CHALLENGE_KEY.length);
    expect(present.keys.playAccount().length).toBe(TEST_PLAY_ACCOUNT_KEY.length);
    expect(present.keys.deviceKey().length).toBe(TEST_DEVICE_KEY_SECRET.length);
    expect(present.keys.appleAccountNs()).toBe(TEST_APPLE_ACCOUNT_NS);
    expect(() => parseUuidSecret('nope', 'APPLE_ACCOUNT_NS')).toThrow(SecretConfigError);
  });

  it('honours DEBUG_ATTESTATION_TOKEN only with ALLOW_DEBUG_ATTESTATION = "true" (RC86)', () => {
    const token = 'debug-token-0123456789abcdef';
    expect(
      makeProdDeps(withVars({ ALLOW_DEBUG_ATTESTATION: 'true', DEBUG_ATTESTATION_TOKEN: token }))
        .debugAttestationToken,
    ).toBe(token);
    expect(
      makeProdDeps(withVars({ ALLOW_DEBUG_ATTESTATION: undefined, DEBUG_ATTESTATION_TOKEN: token }))
        .debugAttestationToken,
    ).toBeUndefined();
    expect(
      makeProdDeps(withVars({ ALLOW_DEBUG_ATTESTATION: '1', DEBUG_ATTESTATION_TOKEN: token }))
        .debugAttestationToken,
    ).toBeUndefined();
    // Too short to be a real token: ignored.
    expect(
      makeProdDeps(withVars({ ALLOW_DEBUG_ATTESTATION: 'true', DEBUG_ATTESTATION_TOKEN: 'short' }))
        .debugAttestationToken,
    ).toBeUndefined();
    expect(
      debugAttestationToken(
        withVars({ ALLOW_DEBUG_ATTESTATION: 'true', DEBUG_ATTESTATION_TOKEN: undefined }),
      ),
    ).toBeUndefined();
    // A clean prod env never enables it.
    expect(makeProdDeps(withVars(cleanProd)).debugAttestationToken).toBeUndefined();
  });

  it('allows test-only vars outside prod', () => {
    const deps = makeProdDeps(withVars({ ENVIRONMENT: 'staging' }));
    expect(deps.environment).toBe('staging');
  });

  it('accepts a clean prod env', () => {
    expect(makeProdDeps(withVars(cleanProd)).environment).toBe('prod');
  });

  it.each(TEST_ONLY_VARS)('throws when %s is set in prod (BE20, RC86)', (name) => {
    expect(() => makeProdDeps(withVars({ ...cleanProd, [name]: 'x' }))).toThrow(name);
  });

  it('names every leaked var at once', () => {
    expect(() =>
      makeProdDeps(
        withVars({ ...cleanProd, AI_PROVIDER: 'fake', DEBUG_ATTESTATION_TOKEN: 'secret' }),
      ),
    ).toThrow('Test-only vars set in prod: AI_PROVIDER, DEBUG_ATTESTATION_TOKEN');
  });

  it('throws on an unknown ENVIRONMENT', () => {
    expect(() => makeProdDeps(withVars({ ENVIRONMENT: 'qa' }))).toThrow('Invalid ENVIRONMENT: qa');
    expect(() => makeProdDeps(withVars({ ENVIRONMENT: undefined }))).toThrow(
      'Invalid ENVIRONMENT: undefined',
    );
  });
});
