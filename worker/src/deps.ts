import { GstaticAdmobKeyProvider } from './adapters/admob/AdmobKeyProvider';
import {
  AnalyticsEngineMetrics,
  type MetricsSqlAccess,
} from './adapters/cf/AnalyticsEngineMetrics';
import { CryptoIdGenerator } from './adapters/cf/CryptoIdGenerator';
import { consoleSink, JsonLogger } from './adapters/cf/JsonLogger';
import { SystemClock } from './adapters/cf/SystemClock';
import { WebCrypto } from './adapters/cf/WebCrypto';
import { WebhookAlerter } from './adapters/cf/WebhookAlerter';
import { lazy, parseHmacKey, parseKeyring, parseUuidSecret, type Keyring } from './crypto/keyring';
import type { Env, Environment } from './env';
import type { AiProviders } from './ports/AiProvider';
import type { Alerter } from './ports/Alerter';
import type { AppAttestVerifier } from './ports/AppAttestVerifier';
import type { Clock } from './ports/Clock';
import type { ConfigStore } from './ports/ConfigStore';
import type { Crypto } from './ports/Crypto';
import type { IdGenerator } from './ports/IdGenerator';
import type { Logger } from './ports/Logger';
import type { Metrics } from './ports/Metrics';
import type { PlayIntegrityVerifier } from './ports/PlayIntegrityVerifier';
import type { RateLimiter } from './ports/RateLimiter';
import type {
  AdmobKeyProvider,
  AppStoreServerApi,
  DeviceCheckApi,
  GoogleOidcVerifier,
  PlayDeveloperApi,
} from './ports/StoreApis';
import type { TokenSigner } from './ports/TokenSigner';
import { ConfigService, isolateConfigCache } from './services/ConfigService';
import { aiDeps } from './aiDeps';
import { identityDeps } from './identityDeps';
import { storeDeps } from './storeDeps';
import { WORKER_VERSION } from './version';

/** Parsed secrets, resolved on first use (a missing one fails only the requests that need it). */
export interface SecretKeys {
  /** `IDEMPOTENCY_ENC_KEY` keyring (AES-256-GCM, current + previous, 03 §2.3, §11). */
  readonly idempotency: () => Keyring;
  /** `IP_HASH_KEY` (HMAC for IP-prefix limiter keys, 03 §2.4). */
  readonly ipHash: () => Uint8Array;
  /** `CHALLENGE_KEY` (HMAC of the stateless attestation challenge, 03 §3.2). */
  readonly challenge: () => Uint8Array;
  /** `PLAY_ACCOUNT_KEY` (HMAC for `playAccountId` / `play_account_hash`, 03 §3.3, RC9). */
  readonly playAccount: () => Uint8Array;
  /** `DEVICE_KEY_SECRET` (HMAC for `device_key_hash`, 03 §3.7). */
  readonly deviceKey: () => Uint8Array;
  /** `APPLE_ACCOUNT_NS` (UUID namespace of `appleAccountToken`, 03 §3.3, RC9). */
  readonly appleAccountNs: () => string;
  /** `TRANSFER_TOKEN_KEY` (HMAC of the support `transferToken`, 03 §6.6, RC84). */
  readonly transferToken: () => Uint8Array;
  /** `REPORT_ENC_KEY` keyring (AES-256-GCM of `reading_reports.payload_enc`, 03 §9.7, RC22). */
  readonly report: () => Keyring;
}

/**
 * Every port the app needs (03 §1, GLOSSARY §9.2). `buildApp(deps)` takes this
 * object; tests pass fakes, production passes `makeProdDeps(env)` (RC38).
 */
export interface Deps {
  readonly environment: Environment;
  readonly workerVersion: string;

  // External services.
  /** One adapter per provider with a key (RC97); `AiRouter` picks per tier. */
  readonly ai: AiProviders;
  readonly appAttest: AppAttestVerifier;
  readonly playIntegrity: PlayIntegrityVerifier;
  readonly appStore: AppStoreServerApi;
  readonly playDeveloper: PlayDeveloperApi;
  readonly admobKeys: AdmobKeyProvider;
  readonly googleOidc: GoogleOidcVerifier;
  /**
   * Expected claims of the Pub/Sub push token (`GOOGLE_PUBSUB_AUDIENCE`,
   * `GOOGLE_PUBSUB_SA`, 03 §6.4); undefined when the secret is not set, and
   * `POST /v1/webhooks/googleplay` then refuses every push.
   */
  readonly pubsubPush: {
    readonly audience: string | undefined;
    readonly email: string | undefined;
  };
  readonly deviceCheck: DeviceCheckApi;
  readonly tokenSigner: TokenSigner;

  // Runtime.
  readonly clock: Clock;
  readonly ids: IdGenerator;
  readonly crypto: Crypto;
  readonly config: ConfigStore;
  readonly metrics: Metrics;
  readonly logger: Logger;
  readonly alerter: Alerter;

  // Storage and limiter bindings (used by repos and middleware only, never by routes).
  readonly db: D1Database;
  readonly rlKv: KVNamespace;
  readonly cacheKv: KVNamespace;
  readonly rateLimiters: { readonly burst: RateLimiter; readonly readings: RateLimiter };
  readonly keys: SecretKeys;

  // Identity (Phase 6.3).
  /** `APPLE_TEAM_ID`: resolves `{TEAM}` in `attest.allowedAppIds` (03 §3.3, RC78). */
  readonly appleTeamId: string | undefined;
  /**
   * `DEBUG_ATTESTATION_TOKEN`, set only when the deploy env sets
   * `ALLOW_DEBUG_ATTESTATION = "true"` (dev/staging, BE20, RC86); otherwise
   * undefined and `X-Taro-Debug-Attestation` is ignored.
   */
  readonly debugAttestationToken: string | undefined;
}

const ENVIRONMENTS: readonly Environment[] = ['dev', 'staging', 'prod'];

/** Vars that must never reach prod (BE20, RC86). */
export const TEST_ONLY_VARS = [
  'ALLOW_DEBUG_ATTESTATION',
  'AI_PROVIDER',
  'DEBUG_ATTESTATION_TOKEN',
] as const;

function isEnvironment(value: unknown): value is Environment {
  return ENVIRONMENTS.includes(value as Environment);
}

/** Checks the deploy environment and the prod test-var guard (BE20, RC86). */
export function assertEnvironment(env: Env): Environment {
  const environment: unknown = env.ENVIRONMENT;
  if (!isEnvironment(environment)) {
    throw new Error(`Invalid ENVIRONMENT: ${String(environment)}`);
  }
  if (environment === 'prod') {
    const leaked = TEST_ONLY_VARS.filter((name) => env[name] !== undefined);
    if (leaked.length > 0) {
      throw new Error(`Test-only vars set in prod: ${leaked.join(', ')}`);
    }
  }
  return environment;
}

/**
 * Analytics Engine SQL API access for `AlertService` (03 §14.1), when both
 * `ANALYTICS_ACCOUNT_ID` and `ANALYTICS_API_TOKEN` are set; otherwise the
 * metric alert rules are skipped.
 */
export function metricsSqlAccess(env: Env, logger: Logger): MetricsSqlAccess | undefined {
  const accountId = env.ANALYTICS_ACCOUNT_ID?.trim() ?? '';
  const token = env.ANALYTICS_API_TOKEN?.trim() ?? '';
  if (accountId === '' || token === '') {
    return undefined;
  }
  return { accountId, token, fetch: fetch.bind(globalThis), logger };
}

/** Builds production deps from the Worker env. Throws on misconfiguration. */
export function makeProdDeps(env: Env): Deps {
  const environment = assertEnvironment(env);
  const clock = new SystemClock();
  const crypto = new WebCrypto();
  const logger = new JsonLogger(clock, consoleSink);
  return {
    environment,
    workerVersion: WORKER_VERSION,
    // ai: aiDeps() below (keyed adapters, or FakeAiProvider when AI_PROVIDER=fake; RC97).
    // appAttest, playIntegrity, deviceCheck, tokenSigner: identityDeps() below (Phase 6.3).
    // Store APIs, Pub/Sub OIDC: storeDeps below.
    admobKeys: new GstaticAdmobKeyProvider({
      fetch: fetch.bind(globalThis),
      clock,
      cache: env.CACHE_KV,
    }),
    clock,
    ids: new CryptoIdGenerator(crypto, clock),
    crypto,
    config: new ConfigService(env.CONFIG_KV, clock, logger, isolateConfigCache),
    metrics: new AnalyticsEngineMetrics(env.METRICS, metricsSqlAccess(env, logger)),
    logger,
    alerter: new WebhookAlerter(fetch.bind(globalThis), env.ALERT_WEBHOOK_URL, logger, {
      cache: env.CACHE_KV,
      clock,
    }),
    db: env.DB,
    rlKv: env.RL_KV,
    cacheKv: env.CACHE_KV,
    rateLimiters: { burst: env.RL_BURST, readings: env.RL_READINGS },
    keys: {
      idempotency: lazy(() => parseKeyring(env.IDEMPOTENCY_ENC_KEY, 'IDEMPOTENCY_ENC_KEY')),
      ipHash: lazy(() => parseHmacKey(env.IP_HASH_KEY, 'IP_HASH_KEY')),
      challenge: lazy(() => parseHmacKey(env.CHALLENGE_KEY, 'CHALLENGE_KEY')),
      playAccount: lazy(() => parseHmacKey(env.PLAY_ACCOUNT_KEY, 'PLAY_ACCOUNT_KEY')),
      deviceKey: lazy(() => parseHmacKey(env.DEVICE_KEY_SECRET, 'DEVICE_KEY_SECRET')),
      appleAccountNs: lazy(() => parseUuidSecret(env.APPLE_ACCOUNT_NS, 'APPLE_ACCOUNT_NS')),
      transferToken: lazy(() => parseHmacKey(env.TRANSFER_TOKEN_KEY, 'TRANSFER_TOKEN_KEY')),
      report: lazy(() => parseKeyring(env.REPORT_ENC_KEY, 'REPORT_ENC_KEY')),
    },
    ...aiDeps(env, environment, clock, crypto, logger),
    ...identityDeps(env, environment, clock, crypto),
    // Store adapters (Phase 7.2/7.3): App Store Server API, Play Developer API, Pub/Sub OIDC.
    ...storeDeps(env, clock),
  };
}
