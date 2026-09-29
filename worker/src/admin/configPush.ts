import type { Environment } from '../env';
import {
  CONFIG_KV_KEYS,
  PublicConfigSchema,
  RemoteConfigFileSchema,
  ServerConfigSchema,
  type ConfigDocumentKind,
  type RemoteConfigFile,
} from '../config/schema';

/**
 * Owner-run config push (03 §8.1, RC8, RC61): validation and payload building
 * for `scripts/config-push.ts`, which only parses arguments and runs
 * `wrangler`. The input file has the shape of
 * `config/remote_config.default.json` (`public` + `server`, each complete and
 * in range); `store.packs[].credits` is rejected (the Worker injects it, RC3).
 */
export const ENVIRONMENTS: readonly Environment[] = ['dev', 'staging', 'prod'];

export type Validation =
  | { readonly ok: true; readonly file: RemoteConfigFile }
  | { readonly ok: false; readonly issues: readonly string[] };

export interface KvPayload {
  readonly kind: ConfigDocumentKind;
  readonly key: string;
  readonly version: number;
  /** Compact JSON as stored in `CONFIG_KV`. */
  readonly value: string;
}

export function validateConfigText(text: string): Validation {
  let parsed: unknown;
  try {
    parsed = JSON.parse(text);
  } catch (err) {
    return { ok: false, issues: [`not valid JSON: ${(err as Error).message}`] };
  }
  const result = RemoteConfigFileSchema.safeParse(parsed);
  if (!result.success) {
    return {
      ok: false,
      issues: result.error.issues.map((issue) => {
        const path = issue.path.map(String).join(' > ');
        return `${path === '' ? '(root)' : path}: ${issue.message}`;
      }),
    };
  }
  return { ok: true, file: result.data };
}

/** The two `CONFIG_KV` documents, re-validated one by one, in push order (server first). */
export function buildKvPayloads(file: RemoteConfigFile): KvPayload[] {
  const server = ServerConfigSchema.parse(file.server);
  const pub = PublicConfigSchema.parse(file.public);
  return [
    {
      kind: 'server',
      key: CONFIG_KV_KEYS.server,
      version: server.version,
      value: JSON.stringify(server),
    },
    {
      kind: 'public',
      key: CONFIG_KV_KEYS.public,
      version: pub.version,
      value: JSON.stringify(pub),
    },
  ];
}

export type KvTarget = 'remote' | 'local';

function kvFlags(env: Environment, target: KvTarget): string[] {
  return ['--binding', 'CONFIG_KV', '--env', env, `--${target}`];
}

/** `wrangler kv key put <key> <value> --binding CONFIG_KV --env <env> --remote|--local`. */
export function kvPutArgs(payload: KvPayload, env: Environment, target: KvTarget): string[] {
  return ['kv', 'key', 'put', payload.key, payload.value, ...kvFlags(env, target)];
}

/** `wrangler kv key get <key> --text …` (reads the stored version before a push). */
export function kvGetArgs(key: string, env: Environment, target: KvTarget): string[] {
  return ['kv', 'key', 'get', key, '--text', ...kvFlags(env, target)];
}

/**
 * The stored document's `version`, or null when there is none or it is not a
 * config document (then any version may be pushed).
 */
export function storedVersion(stdout: string): number | null {
  try {
    const value: unknown = JSON.parse(stdout);
    const version = (value as { version?: unknown } | null)?.version;
    return typeof version === 'number' ? version : null;
  } catch {
    return null;
  }
}

/**
 * A push must raise `version`: clients revalidate with `If-None-Match:
 * "v{version}"` (03 §8.1), so an unchanged version would hide the new values.
 */
export function versionIssue(payload: KvPayload, stored: number | null): string | null {
  if (stored === null || payload.version > stored) {
    return null;
  }
  return `${payload.key}: version ${String(payload.version)} must be greater than the stored ${String(stored)}`;
}
