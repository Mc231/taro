import { AppleJwsVerifier } from './adapters/apple/AppleJwsVerifier';
import { AppleAppStoreServerApi } from './adapters/apple/AppStoreServerApi';
import {
  GoogleAccessTokenProvider,
  parseServiceAccount,
} from './adapters/google/GoogleAccessTokenProvider';
import { GoogleJwksOidcVerifier } from './adapters/google/GoogleOidcVerifier';
import {
  ANDROID_PUBLISHER_SCOPE,
  GooglePlayDeveloperApi,
} from './adapters/google/PlayDeveloperApi';
import { lazy, SecretConfigError } from './crypto/keyring';
import { STORE_APP_ID } from './domain/appIds';
import type { Env } from './env';
import type { Clock } from './ports/Clock';
import type { AppStoreServerApi, GoogleOidcVerifier, PlayDeveloperApi } from './ports/StoreApis';

/** `CACHE_KV` key of the Play Developer API OAuth token (GLOSSARY §6.1). */
export const ANDROID_PUBLISHER_TOKEN_CACHE_KEY = 'google:oauth:androidpublisher';

export interface StoreDeps {
  readonly appStore: AppStoreServerApi;
  readonly playDeveloper: PlayDeveloperApi;
  readonly googleOidc: GoogleOidcVerifier;
  readonly pubsubPush: {
    readonly audience: string | undefined;
    readonly email: string | undefined;
  };
}

function nonEmpty(value: string | undefined): string | undefined {
  const trimmed = value?.trim();
  return trimmed === undefined || trimmed === '' ? undefined : trimmed;
}

/**
 * Production store adapters (Phase 7.2, 7.3), composed by `makeProdDeps`. Secrets
 * (`APPLE_ASC_*`, `GOOGLE_SERVICE_ACCOUNT_JSON`) are resolved on first use: a
 * missing one makes verification `unavailable` (retryable), never a grant.
 */
export function storeDeps(env: Env, clock: Clock): StoreDeps {
  const httpFetch = fetch.bind(globalThis);
  const googleToken = new GoogleAccessTokenProvider({
    fetch: httpFetch,
    clock,
    cache: env.CACHE_KV,
    serviceAccount: lazy(() => parseServiceAccount(env.GOOGLE_SERVICE_ACCOUNT_JSON)),
    scope: ANDROID_PUBLISHER_SCOPE,
    cacheKey: ANDROID_PUBLISHER_TOKEN_CACHE_KEY,
  });
  return {
    appStore: new AppleAppStoreServerApi({
      fetch: httpFetch,
      clock,
      jws: new AppleJwsVerifier({ clock }),
      credentials: lazy(() => {
        const issuerId = nonEmpty(env.APPLE_ASC_ISSUER_ID);
        const keyId = nonEmpty(env.APPLE_ASC_KEY_ID);
        const privateKeyPem = nonEmpty(env.APPLE_ASC_PRIVATE_KEY);
        if (issuerId === undefined || keyId === undefined || privateKeyPem === undefined) {
          throw new SecretConfigError('APPLE_ASC_* is not set');
        }
        return { issuerId, keyId, privateKeyPem, bundleId: STORE_APP_ID };
      }),
    }),
    playDeveloper: new GooglePlayDeveloperApi({
      fetch: httpFetch,
      accessToken: () => googleToken.token(),
    }),
    googleOidc: new GoogleJwksOidcVerifier({ fetch: httpFetch, clock, cache: env.CACHE_KV }),
    pubsubPush: {
      audience: nonEmpty(env.GOOGLE_PUBSUB_AUDIENCE),
      email: nonEmpty(env.GOOGLE_PUBSUB_SA),
    },
  };
}
