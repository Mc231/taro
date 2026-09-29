import { describe, expect, it } from 'vitest';
import { main as smoke } from '../../../scripts/smoke';
import { buildApp } from '../../../src/app';
import type { CliDeps, CommandResult } from '../../../src/admin/cli';
import { API_HOSTS, runSmoke, type SmokeFetch } from '../../../src/admin/smoke';
import type { Environment } from '../../../src/env';
import { SeededCrypto } from '../../fakes/SeededCrypto';
import { createHarness, TEST_DEBUG_ATTESTATION_TOKEN } from '../../fakes/testDeps';

class StubCli implements CliDeps {
  readonly stdout: string[] = [];
  readonly stderr: string[] = [];

  constructor(readonly env: Readonly<Record<string, string | undefined>> = {}) {}

  readFile(): Promise<string> {
    return Promise.reject(new Error('smoke reads no files'));
  }

  writeFile(): Promise<void> {
    return Promise.reject(new Error('smoke writes no files'));
  }

  out(line: string): void {
    this.stdout.push(line);
  }

  err(line: string): void {
    this.stderr.push(line);
  }

  run(): Promise<CommandResult> {
    return Promise.reject(new Error('smoke runs no commands'));
  }
}

let seed = 100;

/** The real app on workerd with fakes, as the smoke target (`app.request` takes full URLs). */
function target(environment: Environment, debugAttestation: boolean): SmokeFetch {
  const h = createHarness({ debugAttestation, overrides: { environment } });
  const app = buildApp(h.deps);
  return async (url, init) => app.request(url, init);
}

async function run(argv: string[], fetchFn: SmokeFetch, env: Record<string, string> = {}) {
  const cli = new StubCli(env);
  const code = await smoke(argv, cli, fetchFn, new SeededCrypto(seed++));
  return { code, cli };
}

describe('scripts/smoke.ts main([...]) (03 §14.2)', () => {
  it('staging: health, config, debug-attested registration and balance', async () => {
    const { code, cli } = await run(['--env', 'staging'], target('staging', true), {
      DEBUG_ATTESTATION_TOKEN: TEST_DEBUG_ATTESTATION_TOKEN,
    });
    expect({ code, stderr: cli.stderr }).toEqual({ code: 0, stderr: [] });
    expect(cli.stdout).toEqual([
      `smoke staging ${API_HOSTS.staging}`,
      'ok   health: workerVersion 0.0.0-test (staging)',
      'ok   config: version 1, ETag "v1"',
      'ok   register: trust high',
      'ok   balance: canRead true, ledgerVersion 0',
    ]);
    expect(cli.stdout.join('\n')).not.toContain(TEST_DEBUG_ATTESTATION_TOKEN);
  });

  it('skips registration without a token, and always in prod (RC86)', async () => {
    const staging = await run(
      ['--env', 'staging', '--base-url', 'https://x.test/'],
      target('staging', true),
    );
    expect(staging.code).toBe(0);
    expect(staging.cli.stdout.at(-1)).toBe('ok   register: skipped: no DEBUG_ATTESTATION_TOKEN');

    const prod = await run(['--env', 'prod'], target('prod', false), {
      DEBUG_ATTESTATION_TOKEN: TEST_DEBUG_ATTESTATION_TOKEN,
    });
    expect(prod.code).toBe(0);
    expect(prod.cli.stdout.at(-1)).toBe(
      'ok   register: skipped: prod has no debug attestation (RC86)',
    );
  });

  it('fails the registration step where the Worker does not honour the token', async () => {
    const { code, cli } = await run(['--env', 'staging'], target('staging', false), {
      DEBUG_ATTESTATION_TOKEN: TEST_DEBUG_ATTESTATION_TOKEN,
    });
    expect(code).toBe(1);
    expect(cli.stderr).toEqual(['FAIL register: register: HTTP 403 ATTESTATION_FAILED']);
  });

  it('fails on the wrong environment, HTTP errors and network errors', async () => {
    const wrongEnv = await run(['--env', 'prod'], target('staging', false));
    expect(wrongEnv.code).toBe(1);
    expect(wrongEnv.cli.stderr).toEqual([
      'FAIL health: health: expected status ok in prod, got {"status":"ok","environment":"staging"}',
    ]);

    const down = await run(['--env', 'dev'], () =>
      Promise.resolve(new Response('upstream', { status: 502 })),
    );
    expect(down.cli.stderr).toEqual(['FAIL health: health: HTTP 502']);

    const unreachable = await run(['--env', 'dev'], () => Promise.reject(new TypeError('dns')));
    expect(unreachable.code).toBe(1);
    expect(unreachable.cli.stderr).toEqual(['FAIL health: health: request failed']);
  });

  it('fails a config without ETag and a failing balance read', async () => {
    const app = target('dev', true);
    const noEtag: SmokeFetch = async (url, init) => {
      const res = await app(url, init);
      if (url.endsWith('/v1/config')) {
        return new Response(await res.text(), { status: 200 });
      }
      return res;
    };
    const config = await run(['--env', 'dev'], noEtag);
    expect(config.cli.stderr).toEqual(['FAIL config: config: missing version or ETag']);

    const noBalance: SmokeFetch = async (url, init) =>
      url.endsWith('/v1/balance')
        ? new Response(JSON.stringify({ error: { code: 'INTERNAL' } }), { status: 500 })
        : app(url, init);
    const balance = await run(['--env', 'dev'], noBalance, {
      DEBUG_ATTESTATION_TOKEN: TEST_DEBUG_ATTESTATION_TOKEN,
    });
    expect(balance.code).toBe(1);
    expect(balance.cli.stderr).toEqual(['FAIL balance: balance: HTTP 500 INTERNAL']);

    const garbage = await runSmoke({
      environment: 'dev',
      baseUrl: 'http://x.test',
      crypto: new SeededCrypto(7),
      fetch: () => Promise.resolve(new Response('[1]', { status: 200 })),
    });
    expect(garbage.steps).toEqual([
      { name: 'health', ok: false, detail: 'health: expected status ok in dev, got {}' },
    ]);
  });

  it('rejects bad usage with exit code 2', async () => {
    const never: SmokeFetch = () => Promise.reject(new Error('not called'));
    for (const argv of [
      [],
      ['--env', 'qa'],
      ['--env', 'dev', '--base-url', 'ftp://x'],
      ['--nope'],
    ]) {
      const { code, cli } = await run(argv, never);
      expect({ argv, code }).toEqual({ argv, code: 2 });
      expect(cli.stderr.at(-1)).toContain('usage: smoke');
    }
  });
});
