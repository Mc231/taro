import { buildApp } from '../app';
import { unimplementedPort } from '../adapters/unimplemented';
import type { Deps } from '../deps';
import { INSTALL_TOKEN_SCHEME } from '../http/routeGuards';

/** Where `scripts/export-openapi.ts` writes the document (relative to `worker/`). */
export const OPENAPI_PATH = 'openapi/openapi.json';

/**
 * API major of the `/v1` surface. The document's `info.version` is the API
 * version, not the Worker release, so a version bump alone never makes the
 * committed file stale (`workerVersion` is served by `GET /v1/health`).
 */
export const API_VERSION = 'v1';

/**
 * Deps for building the route table only. Route registration never calls a
 * port, so every port rejects if one is ever reached.
 */
export function documentDeps(): Deps {
  // eslint-disable-next-line @typescript-eslint/no-unnecessary-type-parameters -- T is the port the proxy stands in for
  const port = <T extends object>(name: string): T =>
    unimplementedPort<T>(name, 'never (document only)');
  return {
    environment: 'prod',
    workerVersion: '0.0.0',
    ai: port('AiProvider'),
    appAttest: port('AppAttestVerifier'),
    playIntegrity: port('PlayIntegrityVerifier'),
    appStore: port('AppStoreServerApi'),
    playDeveloper: port('PlayDeveloperApi'),
    admobKeys: port('AdmobKeyProvider'),
    googleOidc: port('GoogleOidcVerifier'),
    deviceCheck: port('DeviceCheckApi'),
    tokenSigner: port('TokenSigner'),
    clock: port('Clock'),
    ids: port('IdGenerator'),
    crypto: port('Crypto'),
    config: port('ConfigStore'),
    metrics: port('Metrics'),
    logger: port('Logger'),
    alerter: port('Alerter'),
    db: port('D1Database'),
    rlKv: port('KVNamespace'),
    cacheKv: port('KVNamespace'),
    rateLimiters: { burst: port('RateLimiter'), readings: port('RateLimiter') },
    keys: port('SecretKeys'),
    appleTeamId: undefined,
    debugAttestationToken: undefined,
  };
}

/**
 * The OpenAPI 3.1 document of the `/v1` surface (03 BE1, §14.2; RC38),
 * generated from the zod route definitions that also validate requests.
 * `x-taro-auth` / `x-taro-flags` on each operation mirror GLOSSARY §4.
 */
export function openApiDocument(): Record<string, unknown> {
  const app = buildApp(documentDeps());
  app.openAPIRegistry.registerComponent('securitySchemes', INSTALL_TOKEN_SCHEME, {
    type: 'http',
    scheme: 'bearer',
    bearerFormat: 'JWT',
    description: 'EdDSA install token, 7-day TTL (03 §3.4).',
  });
  return app.getOpenAPI31Document({
    openapi: '3.1.0',
    info: {
      title: 'Taro API',
      version: API_VERSION,
      description:
        'Generated from worker/src/routes by scripts/export-openapi.ts; do not edit. Errors use the 03 §2.2 envelope with GLOSSARY §5 codes.',
    },
    servers: [
      { url: 'https://api.taro.vshyrochuk.com', description: 'prod' },
      { url: 'https://api-staging.taro.vshyrochuk.com', description: 'staging' },
    ],
  }) as unknown as Record<string, unknown>;
}

/** The committed file's exact text (2-space JSON plus a trailing newline). */
export function renderOpenApi(): string {
  return `${JSON.stringify(openApiDocument(), null, 2)}\n`;
}
