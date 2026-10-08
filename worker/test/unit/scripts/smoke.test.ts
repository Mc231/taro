import { describe, expect, it } from 'vitest';
import { main as smoke } from '../../../scripts/smoke';
import { buildApp } from '../../../src/app';
import type { CliDeps, CommandResult } from '../../../src/admin/cli';
import { API_HOSTS, runSmoke, type SmokeFetch } from '../../../src/admin/smoke';
import type { Environment } from '../../../src/env';
import { FixedClock } from '../../fakes/FixedClock';
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

const targets = new Map<string, SmokeFetch>();

/**
 * The real app on workerd with fakes, as the smoke target (`app.request` takes
 * full URLs). One harness per variant: the test D1 is shared across the file,
 * and a fresh `SeqIdGenerator` would reuse reading row ids.
 */
function target(environment: Environment, debugAttestation: boolean): SmokeFetch {
  const key = `${environment}:${String(debugAttestation)}`;
  let fetchFn = targets.get(key);
  if (fetchFn === undefined) {
    const app = buildApp(createHarness({ debugAttestation, overrides: { environment } }).deps);
    fetchFn = async (url, init) => app.request(url, init);
    targets.set(key, fetchFn);
  }
  return fetchFn;
}

async function run(argv: string[], fetchFn: SmokeFetch, env: Record<string, string> = {}) {
  const cli = new StubCli(env);
  const code = await smoke(argv, cli, fetchFn, new SeededCrypto(seed++), new FixedClock());
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
      'ok   hold: chargeSource free, expiresAt 2026-09-26T10:15:00Z',
      'ok   reading: status completed, 0 ms, classification none, chargeSource free, promptVersion v2, balance free 0/1, bonus 0, paid 0, text "The cards point to a steady, reflective moment."',
      'ok   ack: HTTP 204',
    ]);
    const printed = cli.stdout.join('\n');
    expect(printed).not.toContain(TEST_DEBUG_ATTESTATION_TOKEN);
    expect(printed).not.toMatch(/Bearer|installSecret|installToken/);
  });

  describe('reading steps (03 §9.0, §9.1)', () => {
    const debugEnv = { DEBUG_ATTESTATION_TOKEN: TEST_DEBUG_ATTESTATION_TOKEN };
    const json = (body: unknown, status: number) =>
      new Response(JSON.stringify(body), {
        status,
        headers: { 'content-type': 'application/json' },
      });
    /** The real app, with one path answered by `stub` instead. */
    function overriding(suffix: string, stub: (init?: RequestInit) => Response): SmokeFetch {
      const app = target('staging', true);
      return async (url, init) => (url.endsWith(suffix) ? stub(init) : app(url, init));
    }
    const balance = {
      free: { remaining: 1, limit: 1 },
      bonus: 0,
      paid: 2,
    };

    it('sends the RC42 key, consent version, debug attestation and the single spread', async () => {
      const seen: { holds?: RequestInit | undefined; reading?: RequestInit | undefined } = {};
      const app = target('staging', true);
      const spy: SmokeFetch = async (url, init) => {
        if (url.endsWith('/v1/readings/holds')) seen.holds = init;
        if (url.endsWith('/v1/readings')) seen.reading = init;
        return app(url, init);
      };
      const { code } = await run(['--env', 'staging'], spy, debugEnv);
      expect(code).toBe(0);
      const holdHeaders = seen.holds?.headers as Record<string, string>;
      const hold = JSON.parse(seen.holds?.body as string) as Record<string, unknown>;
      const reading = JSON.parse(seen.reading?.body as string) as Record<string, unknown>;
      expect(holdHeaders['Idempotency-Key']).toBe(hold['clientReadingId']);
      expect(holdHeaders['X-Taro-AI-Consent']).toBe('2');
      expect(holdHeaders['X-Taro-Debug-Attestation']).toBe(TEST_DEBUG_ATTESTATION_TOKEN);
      expect(hold).toMatchObject({ spread: { id: 'single', version: 1 }, locale: 'en' });
      expect(reading).toMatchObject({
        clientReadingId: hold['clientReadingId'],
        cards: [{ positionId: 'focus', cardId: 'major_00', reversed: false }],
        question: 'What should I focus on this week?',
        locale: 'en',
      });
    });

    it('fails on a 402 hold with the reason', async () => {
      const { code, cli } = await run(
        ['--env', 'staging'],
        overriding('/v1/readings/holds', () =>
          json({ error: { code: 'INSUFFICIENT_CREDITS', details: { reason: 'dailyLimit' } } }, 402),
        ),
        debugEnv,
      );
      expect(code).toBe(1);
      expect(cli.stderr).toEqual([
        'FAIL hold: hold: HTTP 402 INSUFFICIENT_CREDITS (reason dailyLimit)',
      ]);
    });

    it('fails on a 503 reading (AI_UNAVAILABLE, AI_BUDGET_EXHAUSTED)', async () => {
      const unavailable = await run(
        ['--env', 'staging'],
        overriding('/v1/readings', () => json({ error: { code: 'AI_UNAVAILABLE' } }, 503)),
        debugEnv,
      );
      expect(unavailable.code).toBe(1);
      expect(unavailable.cli.stderr).toEqual(['FAIL reading: reading: HTTP 503 AI_UNAVAILABLE']);

      const budget = await run(
        ['--env', 'staging'],
        overriding('/v1/readings', () =>
          json({ error: { code: 'AI_BUDGET_EXHAUSTED', details: { tier: 'free' } } }, 503),
        ),
        debugEnv,
      );
      expect(budget.cli.stderr).toEqual([
        'FAIL reading: reading: HTTP 503 AI_BUDGET_EXHAUSTED (tier free)',
      ]);
    });

    it('fails a declined reading and reports its classification', async () => {
      const { code, cli } = await run(
        ['--env', 'staging'],
        overriding('/v1/readings', () =>
          json(
            {
              readingId: 'r',
              status: 'declined',
              chargeSource: 'none',
              safety: {
                category: 'self_harm',
                messageKey: 'k',
                crisisResources: [],
                canRephrase: false,
              },
              balance,
            },
            200,
          ),
        ),
        debugEnv,
      );
      expect(code).toBe(1);
      expect(cli.stderr).toEqual([
        'FAIL reading: reading: status declined, 0 ms, classification self_harm (declined, not charged), balance free 1/1, bonus 0, paid 2',
      ]);
    });

    it('fails an unexpected status and a failing ack; truncates long text', async () => {
      const odd = await run(
        ['--env', 'staging'],
        overriding('/v1/readings', () => json({ status: 'held' }, 200)),
        debugEnv,
      );
      expect(odd.cli.stderr).toEqual(['FAIL reading: reading: unexpected status held, 0 ms']);

      const app = target('staging', true);
      const long = 'word '.repeat(40);
      const noAck: SmokeFetch = async (url, init) => {
        if (url.endsWith('/ack')) return json({ error: { code: 'NOT_FOUND' } }, 404);
        if (url.endsWith('/v1/readings')) {
          return json(
            {
              status: 'completed',
              chargeSource: 'paid',
              promptVersion: 'v2',
              reading: { overview: long },
              balance,
            },
            200,
          );
        }
        return app(url, init);
      };
      const acked = await run(['--env', 'staging'], noAck, debugEnv);
      expect(acked.code).toBe(1);
      expect(acked.cli.stdout.at(-1)).toBe(
        `ok   reading: status completed, 0 ms, classification none, chargeSource paid, promptVersion v2, balance free 1/1, bonus 0, paid 2, text "${long.slice(0, 80)}…"`,
      );
      expect(acked.cli.stderr).toEqual(['FAIL ack: ack: HTTP 404 NOT_FOUND']);
    });

    it('fails the hold when the config has no ai.consentVersion', async () => {
      const app = target('staging', true);
      const noConsent: SmokeFetch = async (url, init) => {
        const res = await app(url, init);
        if (!url.endsWith('/v1/config')) return res;
        const body: Record<string, unknown> = await res.json();
        delete body['ai.consentVersion'];
        return new Response(JSON.stringify(body), { status: 200, headers: res.headers });
      };
      const { code, cli } = await run(['--env', 'staging'], noConsent, debugEnv);
      expect(code).toBe(1);
      expect(cli.stderr).toEqual(['FAIL hold: hold: config has no numeric ai.consentVersion']);
    });
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
      expect(cli.stderr.at(-1)).toContain('smoke --env <dev|staging|prod>');
    }
  });
});
