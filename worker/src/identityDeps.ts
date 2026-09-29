import { AppleAppAttestVerifier } from './adapters/apple/AppAttestVerifier';
import { AppleDeviceCheckApi } from './adapters/apple/DeviceCheckApi';
import { CryptoIdGenerator } from './adapters/cf/CryptoIdGenerator';
import { Ed25519TokenSigner } from './adapters/cf/Ed25519TokenSigner';
import {
  GoogleAccessTokenProvider,
  parseServiceAccount,
  PLAY_INTEGRITY_SCOPE,
} from './adapters/google/GoogleAccessTokenProvider';
import { GooglePlayIntegrityVerifier } from './adapters/google/PlayIntegrityVerifier';
import { lazy, SecretConfigError } from './crypto/keyring';
import type { Env, Environment } from './env';
import type { AppAttestVerifier } from './ports/AppAttestVerifier';
import type { Clock } from './ports/Clock';
import type { Crypto } from './ports/Crypto';
import type { PlayIntegrityVerifier } from './ports/PlayIntegrityVerifier';
import type { DeviceCheckApi } from './ports/StoreApis';
import type { TokenSigner } from './ports/TokenSigner';

/** `CACHE_KV` key of the Play Integrity OAuth token (GLOSSARY §6.1). */
export const PLAY_INTEGRITY_TOKEN_CACHE_KEY = 'google:oauth:playintegrity';

export interface IdentityDeps {
  readonly appAttest: AppAttestVerifier;
  readonly playIntegrity: PlayIntegrityVerifier;
  readonly deviceCheck: DeviceCheckApi;
  readonly tokenSigner: TokenSigner;
  readonly appleTeamId: string | undefined;
  readonly debugAttestationToken: string | undefined;
}

/**
 * The debug attestation token (02 §5 `DebugAttestationService`) is honoured
 * only when the deploy env var `ALLOW_DEBUG_ATTESTATION` is exactly `"true"`
 * (set in `[env.dev]` / `[env.staging]` only, BE20, RC86). A request header
 * alone never enables it, and prod refuses to start with either var set
 * (`assertEnvironment`).
 */
export function debugAttestationToken(env: Env): string | undefined {
  const token = env.DEBUG_ATTESTATION_TOKEN?.trim();
  return env.ALLOW_DEBUG_ATTESTATION === 'true' && token !== undefined && token.length >= 16
    ? token
    : undefined;
}

function nonEmpty(value: string | undefined): string | undefined {
  const trimmed = value?.trim();
  return trimmed === undefined || trimmed === '' ? undefined : trimmed;
}

/** Production identity and attestation adapters (Phase 6.3), composed by `makeProdDeps`. */
export function identityDeps(
  env: Env,
  environment: Environment,
  clock: Clock,
  crypto: Crypto,
): IdentityDeps {
  const httpFetch = fetch.bind(globalThis);
  const appleTeamId = nonEmpty(env.APPLE_TEAM_ID);
  const googleToken = new GoogleAccessTokenProvider({
    fetch: httpFetch,
    clock,
    cache: env.CACHE_KV,
    serviceAccount: lazy(() => parseServiceAccount(env.GOOGLE_SERVICE_ACCOUNT_JSON)),
    scope: PLAY_INTEGRITY_SCOPE,
    cacheKey: PLAY_INTEGRITY_TOKEN_CACHE_KEY,
  });
  return {
    appAttest: new AppleAppAttestVerifier({
      crypto,
      clock,
      allowDevelopment: environment !== 'prod',
    }),
    playIntegrity: new GooglePlayIntegrityVerifier({
      fetch: httpFetch,
      clock,
      accessToken: () => googleToken.token(),
      requireRecognizedApp: environment === 'prod',
    }),
    deviceCheck: new AppleDeviceCheckApi({
      fetch: httpFetch,
      clock,
      ids: new CryptoIdGenerator(crypto, clock),
      development: environment === 'dev',
      credentials: lazy(() => {
        const keyId = nonEmpty(env.APPLE_DEVICECHECK_KEY_ID);
        const privateKeyPem = nonEmpty(env.APPLE_DEVICECHECK_PRIVATE_KEY);
        if (keyId === undefined || privateKeyPem === undefined || appleTeamId === undefined) {
          throw new SecretConfigError('APPLE_DEVICECHECK_* or APPLE_TEAM_ID is not set');
        }
        return { keyId, privateKeyPem, teamId: appleTeamId };
      }),
    }),
    tokenSigner: new Ed25519TokenSigner(() => env.TOKEN_SIGNING_KEYS),
    appleTeamId,
    debugAttestationToken: debugAttestationToken(env),
  };
}
