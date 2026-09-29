import { DEFAULT_PUBLIC_CONFIG, DEFAULT_SERVER_CONFIG } from '../config/defaults';
import {
  CONFIG_KV_KEYS,
  mergeConfig,
  PublicConfigReadSchema,
  ServerConfigReadSchema,
  type ConfigDocumentKind,
  type PublicConfig,
  type RuntimeConfig,
  type ServerConfig,
} from '../config/schema';
import type { Clock } from '../ports/Clock';
import type { ConfigStore } from '../ports/ConfigStore';
import type { Logger } from '../ports/Logger';

/** Parsed config lives this long in isolate memory (03 §8.1). */
export const CONFIG_CACHE_TTL_MS = 60_000;

export interface ConfigDocuments {
  readonly public: PublicConfig;
  readonly server: ServerConfig;
}

/**
 * Isolate-level cache. `makeProdDeps` runs per request, so the cache must
 * outlive the service: production passes the module singleton
 * `isolateConfigCache`, tests pass a fresh object.
 */
export interface ConfigCache {
  entry?: { readonly value: RuntimeConfig; readonly expiresAtMs: number };
  inflight?: Promise<RuntimeConfig>;
  /** Last documents that validated, served when KV itself fails. */
  lastGood?: Partial<ConfigDocuments>;
}

export const isolateConfigCache: ConfigCache = {};

export type DocumentParse<T> =
  | { readonly ok: true; readonly value: T }
  | { readonly ok: false; readonly reason: 'json' | 'schema'; readonly detail: string };

/**
 * Validates a stored document on read: its keys are laid over the defaults
 * (a key added by a newer Worker is not yet in KV), unknown keys are dropped,
 * and `version` must come from the stored document itself.
 */
export function parseStoredDocument<T extends PublicConfig | ServerConfig>(
  kind: ConfigDocumentKind,
  text: string,
  defaults: T,
): DocumentParse<T> {
  let stored: unknown;
  try {
    stored = JSON.parse(text);
  } catch {
    return { ok: false, reason: 'json', detail: 'not JSON' };
  }
  if (typeof stored !== 'object' || stored === null || Array.isArray(stored)) {
    return { ok: false, reason: 'json', detail: 'not a JSON object' };
  }
  const merged = {
    ...defaults,
    ...stored,
    version: (stored as { version?: unknown }).version,
  };
  const schema = kind === 'public' ? PublicConfigReadSchema : ServerConfigReadSchema;
  const result = schema.safeParse(merged);
  if (!result.success) {
    const issue = result.error.issues[0];
    const path = issue?.path.map(String).join('.') ?? '';
    return {
      ok: false,
      reason: 'schema',
      detail: `${String(result.error.issues.length)} issue(s); first at '${path}': ${issue?.message ?? ''}`,
    };
  }
  return { ok: true, value: result.data as T };
}

/**
 * `ConfigStore` over `CONFIG_KV` (03 §8.1, RC8): `config:public` and
 * `config:server`, each validated on read. A missing or invalid document
 * falls back to the compiled defaults and logs `config_invalid`; a KV
 * failure serves the last valid document of this isolate (else the defaults).
 * The merged result is cached for 60 s, and concurrent misses share one load.
 */
export class ConfigService implements ConfigStore {
  constructor(
    private readonly kv: KVNamespace,
    private readonly clock: Clock,
    private readonly logger: Logger,
    private readonly cache: ConfigCache = {},
    private readonly defaults: ConfigDocuments = {
      public: DEFAULT_PUBLIC_CONFIG,
      server: DEFAULT_SERVER_CONFIG,
    },
    private readonly ttlMs: number = CONFIG_CACHE_TTL_MS,
  ) {}

  snapshot(): Promise<RuntimeConfig> {
    const entry = this.cache.entry;
    if (entry !== undefined && this.clock.now().getTime() < entry.expiresAtMs) {
      return Promise.resolve(entry.value);
    }
    this.cache.inflight ??= this.load().finally(() => {
      delete this.cache.inflight;
    });
    return this.cache.inflight;
  }

  private async load(): Promise<RuntimeConfig> {
    const [publicConfig, serverConfig] = await Promise.all([
      this.readDocument('public', this.defaults.public),
      this.readDocument('server', this.defaults.server),
    ]);
    const value = mergeConfig(publicConfig, serverConfig);
    this.cache.entry = { value, expiresAtMs: this.clock.now().getTime() + this.ttlMs };
    return value;
  }

  private async readDocument<K extends ConfigDocumentKind>(
    kind: K,
    defaults: ConfigDocuments[K],
  ): Promise<ConfigDocuments[K]> {
    let text: string | null;
    try {
      text = await this.kv.get(CONFIG_KV_KEYS[kind], 'text');
    } catch (err) {
      this.logger.log('error', 'config_invalid', {
        document: kind,
        reason: 'kv_error',
        error: err instanceof Error ? err.name : 'unknown',
      });
      return (this.cache.lastGood?.[kind] as ConfigDocuments[K] | undefined) ?? defaults;
    }
    if (text === null) {
      this.logger.log('warn', 'config_invalid', { document: kind, reason: 'missing' });
      return defaults;
    }
    const parsed = parseStoredDocument(kind, text, defaults);
    if (!parsed.ok) {
      this.logger.log('error', 'config_invalid', {
        document: kind,
        reason: parsed.reason,
        detail: parsed.detail,
      });
      return defaults;
    }
    this.cache.lastGood = { ...this.cache.lastGood, [kind]: parsed.value };
    return parsed.value;
  }
}
