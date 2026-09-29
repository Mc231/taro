import { env } from 'cloudflare:workers';
import { WebCrypto } from '../../src/adapters/cf/WebCrypto';
import { unimplementedPort } from '../../src/adapters/unimplemented';
import { Ed25519TokenSigner } from '../../src/adapters/cf/Ed25519TokenSigner';
import { lazy, parseHmacKey, parseKeyring, parseUuidSecret } from '../../src/crypto/keyring';
import type { Deps } from '../../src/deps';
import type { Env } from '../../src/env';
import type { AiProvider } from '../../src/ports/AiProvider';
import type {
  AdmobKeyProvider,
  AppStoreServerApi,
  GoogleOidcVerifier,
  PlayDeveloperApi,
} from '../../src/ports/StoreApis';
import { CapturingAlerter } from './CapturingAlerter';
import { CapturingLogger } from './CapturingLogger';
import { FakeAppAttestVerifier } from './FakeAppAttestVerifier';
import { FakeConfigStore } from './FakeConfigStore';
import { FakeDeviceCheckApi } from './FakeDeviceCheckApi';
import { FakePlayIntegrityVerifier } from './FakePlayIntegrityVerifier';
import { FakeRateLimiter } from './FakeRateLimiter';
import { FixedClock } from './FixedClock';
import { InMemoryMetrics } from './InMemoryMetrics';
import { SeqIdGenerator } from './SeqIdGenerator';

/** Test-only key material (never a real secret): 32 bytes each, base64url. */
export const TEST_IDEMPOTENCY_KEYRING =
  'kt2:AgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgI,kt1:AQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQE';
export const TEST_IP_HASH_KEY = 'test-ip-hash-key-0123456789abcdef';
/** Test-only identity secrets (Phase 6.3); never real keys. */
export const TEST_CHALLENGE_KEY = 'test-challenge-key-0123456789abcdef';
export const TEST_PLAY_ACCOUNT_KEY = 'test-play-account-key-0123456789ab';
export const TEST_DEVICE_KEY_SECRET = 'test-device-key-secret-0123456789a';
export const TEST_APPLE_ACCOUNT_NS = '6f1c2b1e-9a4d-4c3b-8e2f-0a1b2c3d4e5f';
export const TEST_APPLE_TEAM_ID = 'TEAMID1234';
export const TEST_DEBUG_ATTESTATION_TOKEN = 'test-debug-attestation-token-0123456789';
/** Ed25519 JWKS (current `kt2`, previous `kt1`), generated for tests only. */
export const TEST_TOKEN_SIGNING_KEYS = JSON.stringify({
  keys: [
    {
      kty: 'OKP',
      crv: 'Ed25519',
      kid: 'kt2',
      x: 'ZA52og8vIb6YJ9XjGDidRr5YrVsCdB8kE7UmtzNiLys',
      d: '6Ck3ljNfESS6YgZvQpb7SArHYEZhMVDBgGkrf5Y1hbM',
    },
    {
      kty: 'OKP',
      crv: 'Ed25519',
      kid: 'kt1',
      x: '8K5V4nt3MiHwqSHOHNCvQlRGwfr4bUZAUooxDaZjX_Y',
      d: '-LVxMK2MzAcuMAxKXhomYQrdKy4esxroo45Jv60okwM',
    },
  ],
});

export const bindings = env as unknown as Env;

export interface TestHarness {
  readonly deps: Deps;
  readonly clock: FixedClock;
  readonly ids: SeqIdGenerator;
  readonly logger: CapturingLogger;
  readonly metrics: InMemoryMetrics;
  readonly alerter: CapturingAlerter;
  readonly config: FakeConfigStore;
  readonly appAttest: FakeAppAttestVerifier;
  readonly playIntegrity: FakePlayIntegrityVerifier;
  readonly burst: FakeRateLimiter;
  readonly readings: FakeRateLimiter;
  readonly deviceCheck: FakeDeviceCheckApi;
}

export interface HarnessOptions {
  readonly idempotencyKeyring?: string;
  readonly ipHashKey?: string;
  /** `X-Taro-Debug-Attestation` accepted (as if `ALLOW_DEBUG_ATTESTATION = "true"`). */
  readonly debugAttestation?: boolean;
  readonly overrides?: Partial<Deps>;
}

/**
 * Fakes for every port plus the real miniflare D1/KV bindings from `[env.dev]`.
 * Storage is shared within a test file, so tests use unique install IDs/keys.
 */
export function createHarness(options: HarnessOptions = {}): TestHarness {
  const clock = new FixedClock();
  const ids = new SeqIdGenerator();
  const logger = new CapturingLogger();
  const metrics = new InMemoryMetrics();
  const alerter = new CapturingAlerter();
  const config = new FakeConfigStore();
  const appAttest = new FakeAppAttestVerifier();
  const playIntegrity = new FakePlayIntegrityVerifier();
  const burst = new FakeRateLimiter();
  const readings = new FakeRateLimiter();
  const deviceCheck = new FakeDeviceCheckApi();
  const keyring = options.idempotencyKeyring ?? TEST_IDEMPOTENCY_KEYRING;
  const ipKey = options.ipHashKey ?? TEST_IP_HASH_KEY;
  const deps: Deps = {
    environment: 'dev',
    workerVersion: '0.0.0-test',
    ai: unimplementedPort<AiProvider>('AiProvider', 'Phase 8'),
    appAttest,
    playIntegrity,
    appStore: unimplementedPort<AppStoreServerApi>('AppStoreServerApi', 'Phase 7'),
    playDeveloper: unimplementedPort<PlayDeveloperApi>('PlayDeveloperApi', 'Phase 7'),
    admobKeys: unimplementedPort<AdmobKeyProvider>('AdmobKeyProvider', 'Phase 7'),
    googleOidc: unimplementedPort<GoogleOidcVerifier>('GoogleOidcVerifier', 'Phase 7'),
    deviceCheck,
    tokenSigner: new Ed25519TokenSigner(() => TEST_TOKEN_SIGNING_KEYS),
    clock,
    ids,
    crypto: new WebCrypto(),
    config,
    metrics,
    logger,
    alerter,
    db: bindings.DB,
    rlKv: bindings.RL_KV,
    cacheKv: bindings.CACHE_KV,
    rateLimiters: { burst, readings },
    keys: {
      idempotency: lazy(() => parseKeyring(keyring, 'IDEMPOTENCY_ENC_KEY')),
      ipHash: lazy(() => parseHmacKey(ipKey, 'IP_HASH_KEY')),
      challenge: lazy(() => parseHmacKey(TEST_CHALLENGE_KEY, 'CHALLENGE_KEY')),
      playAccount: lazy(() => parseHmacKey(TEST_PLAY_ACCOUNT_KEY, 'PLAY_ACCOUNT_KEY')),
      deviceKey: lazy(() => parseHmacKey(TEST_DEVICE_KEY_SECRET, 'DEVICE_KEY_SECRET')),
      appleAccountNs: lazy(() => parseUuidSecret(TEST_APPLE_ACCOUNT_NS, 'APPLE_ACCOUNT_NS')),
    },
    appleTeamId: TEST_APPLE_TEAM_ID,
    debugAttestationToken:
      options.debugAttestation === true ? TEST_DEBUG_ATTESTATION_TOKEN : undefined,
    ...options.overrides,
  };
  return {
    deps,
    clock,
    ids,
    logger,
    metrics,
    alerter,
    config,
    appAttest,
    playIntegrity,
    burst,
    readings,
    deviceCheck,
  };
}

let uniqueCounter = 0;

/** A fresh UUID-shaped ID per call, unique within the test file's shared storage. */
export function uniqueId(tag = 'a'): string {
  uniqueCounter++;
  const hex = Array.from(tag, (ch) => ch.charCodeAt(0).toString(16))
    .join('')
    .slice(0, 8)
    .padEnd(8, '0');
  return `${hex}-1111-4111-8111-${uniqueCounter.toString(16).padStart(12, '0')}`;
}
