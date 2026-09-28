/**
 * Worker bindings and vars (03 §1, §11; GLOSSARY §6.1).
 *
 * Declared by hand rather than taken from the generated `Cloudflare.Env`,
 * because `wrangler types` merges all environments and marks every binding
 * optional. Keep in sync with `wrangler.toml` (and re-run `npm run types`).
 */
export type Environment = 'dev' | 'staging' | 'prod';

export interface Env {
  readonly ENVIRONMENT: Environment;

  // Test-only vars: [env.dev] / [env.staging] only (BE20, RC86).
  readonly ALLOW_DEBUG_ATTESTATION?: string;
  readonly AI_PROVIDER?: string;
  readonly DEBUG_ATTESTATION_TOKEN?: string;

  readonly DB: D1Database;
  readonly ADMIN_TOKEN: string;
  readonly CONFIG_KV: KVNamespace;
  readonly RL_KV: KVNamespace;
  readonly CACHE_KV: KVNamespace;
  readonly METRICS: AnalyticsEngineDataset;
  readonly RL_BURST: RateLimit;
  readonly RL_READINGS: RateLimit;
}
