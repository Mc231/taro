import type { Env, Environment } from './env';
import { WORKER_VERSION } from './version';

/**
 * Every port the app needs (03 §1). Phase 2 skeleton: only static runtime
 * info. Ports (AiProvider, Clock, Logger, …) are added in Phase 6.
 */
export interface Deps {
  readonly environment: Environment;
  readonly workerVersion: string;
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

/** Builds production deps from the Worker env. Throws on misconfiguration. */
export function makeProdDeps(env: Env): Deps {
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
  return { environment, workerVersion: WORKER_VERSION };
}
