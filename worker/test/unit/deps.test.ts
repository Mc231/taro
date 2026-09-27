import { env } from 'cloudflare:workers';
import { describe, expect, it } from 'vitest';
import { makeProdDeps } from '../../src/deps';
import type { Env } from '../../src/env';
import { WORKER_VERSION } from '../../src/version';
import pkg from '../../package.json';

const baseEnv = env as unknown as Env;

function withVars(vars: Record<string, string | undefined>): Env {
  const copy: Record<string, unknown> = { ...baseEnv };
  for (const [key, value] of Object.entries(vars)) {
    if (value === undefined) {
      Reflect.deleteProperty(copy, key);
    } else {
      copy[key] = value;
    }
  }
  return copy as unknown as Env;
}

describe('makeProdDeps', () => {
  it('reads ENVIRONMENT and the package version', () => {
    expect(makeProdDeps(baseEnv)).toEqual({
      environment: 'dev',
      workerVersion: pkg.version,
    });
    expect(WORKER_VERSION).toBe(pkg.version);
  });

  it('allows test-only vars outside prod', () => {
    const deps = makeProdDeps(withVars({ ENVIRONMENT: 'staging' }));
    expect(deps.environment).toBe('staging');
  });

  it('accepts a clean prod env', () => {
    const prodEnv = withVars({
      ENVIRONMENT: 'prod',
      ALLOW_DEBUG_ATTESTATION: undefined,
      AI_PROVIDER: undefined,
      DEBUG_ATTESTATION_TOKEN: undefined,
    });
    expect(makeProdDeps(prodEnv).environment).toBe('prod');
  });

  it.each(['ALLOW_DEBUG_ATTESTATION', 'AI_PROVIDER', 'DEBUG_ATTESTATION_TOKEN'])(
    'throws when %s is set in prod (BE20, RC86)',
    (name) => {
      const prodEnv = withVars({
        ENVIRONMENT: 'prod',
        ALLOW_DEBUG_ATTESTATION: undefined,
        AI_PROVIDER: undefined,
        DEBUG_ATTESTATION_TOKEN: undefined,
        [name]: 'x',
      });
      expect(() => makeProdDeps(prodEnv)).toThrow(name);
    },
  );

  it('throws on an unknown ENVIRONMENT', () => {
    expect(() => makeProdDeps(withVars({ ENVIRONMENT: 'qa' }))).toThrow('Invalid ENVIRONMENT: qa');
    expect(() => makeProdDeps(withVars({ ENVIRONMENT: undefined }))).toThrow(
      'Invalid ENVIRONMENT: undefined',
    );
  });
});
