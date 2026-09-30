/**
 * Worker bindings, vars and secrets (03 §1, §11; GLOSSARY §6.1, §13).
 *
 * Declared by hand rather than taken from the generated `Cloudflare.Env`,
 * because `wrangler types` merges all environments and marks every binding
 * optional. Keep in sync with `wrangler.toml` (and re-run `npm run types`).
 * Every field name must be a GLOSSARY §6.1 / §13 name (`check_glossary.py`).
 *
 * Secrets are optional at the type level: they are parsed lazily by the code
 * that needs them (a missing secret fails that request with 500, and
 * `GET /v1/health` keeps working), and some exist only in staging/prod.
 */
export type Environment = 'dev' | 'staging' | 'prod';

export interface Env {
  // [vars]
  readonly ENVIRONMENT: Environment;
  readonly APPLE_TEAM_ID?: string;

  // Test-only vars: [env.dev] / [env.staging] only (BE20, RC86).
  readonly ALLOW_DEBUG_ATTESTATION?: string;
  readonly AI_PROVIDER?: string;
  readonly DEBUG_ATTESTATION_TOKEN?: string;

  // Bindings (GLOSSARY §6.1).
  readonly DB: D1Database;
  readonly CONFIG_KV: KVNamespace;
  readonly RL_KV: KVNamespace;
  readonly CACHE_KV: KVNamespace;
  readonly METRICS: AnalyticsEngineDataset;
  readonly RL_BURST: RateLimit;
  readonly RL_READINGS: RateLimit;

  // Secrets (03 §11, GLOSSARY §13); `wrangler secret put --env <env>`.
  readonly ANTHROPIC_API_KEY?: string;
  readonly OPENAI_API_KEY?: string;
  readonly TOKEN_SIGNING_KEYS?: string;
  readonly CHALLENGE_KEY?: string;
  readonly IDEMPOTENCY_ENC_KEY?: string;
  readonly IP_HASH_KEY?: string;
  readonly PLAY_ACCOUNT_KEY?: string;
  readonly DEVICE_KEY_SECRET?: string;
  readonly TRANSFER_TOKEN_KEY?: string;
  readonly REPORT_ENC_KEY?: string;
  readonly APPLE_ACCOUNT_NS?: string;
  readonly APPLE_DEVICECHECK_KEY_ID?: string;
  readonly APPLE_DEVICECHECK_PRIVATE_KEY?: string;
  readonly APPLE_ASC_ISSUER_ID?: string;
  readonly APPLE_ASC_KEY_ID?: string;
  readonly APPLE_ASC_PRIVATE_KEY?: string;
  readonly GOOGLE_SERVICE_ACCOUNT_JSON?: string;
  readonly GOOGLE_PUBSUB_AUDIENCE?: string;
  readonly GOOGLE_PUBSUB_SA?: string;
  readonly ALERT_WEBHOOK_URL?: string;
  readonly ANALYTICS_ACCOUNT_ID?: string;
  readonly ANALYTICS_API_TOKEN?: string;
}
