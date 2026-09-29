import { afterEach, describe, expect, it, vi } from 'vitest';
import { main as metrics, USAGE, type MetricsFetch } from '../../../scripts/metrics';
import {
  ALERT_THRESHOLDS,
  alertRules,
  formatRows,
  parseSqlResponse,
  QUERY_NAMES,
  querySql,
  SQL_API,
} from '../../../src/admin/metrics';
import { D1StubCli } from '../../helpers/d1Cli';

/** `scripts/metrics.ts` (Sprint 7.5; 03 §14.1, 04 §12.3, §14) with a stubbed SQL API. */
const ENV = { CLOUDFLARE_ACCOUNT_ID: 'acc123', CLOUDFLARE_API_TOKEN: 'cf-secret-token' };

interface Sent {
  readonly url: string;
  readonly auth: string | null;
  readonly sql: string;
}

function api(
  answer: (sql: string) => unknown,
  status = 200,
): { fetch: MetricsFetch; sent: Sent[] } {
  const sent: Sent[] = [];
  return {
    sent,
    fetch: (url, init) => {
      const sql = init.body as string;
      sent.push({ url, auth: new Headers(init.headers).get('Authorization'), sql });
      return Promise.resolve(Response.json(answer(sql), { status }));
    },
  };
}

async function run(argv: string[], fetchFn: MetricsFetch, env: Record<string, string> = ENV) {
  const cli = new D1StubCli(env);
  const code = await metrics(argv, cli, fetchFn);
  expect(cli.text).not.toContain('cf-secret-token');
  return { code, cli };
}

describe('scripts/metrics.ts main([...])', () => {
  it('runs a named report against the SQL API with the account token', async () => {
    const { fetch, sent } = api(() => ({
      data: [
        { platform: 'ios', outcome: 'granted', n: '12', p95_ms: 812.456 },
        { platform: 'ios', outcome: 'internal', n: 1, p95_ms: 'x' },
      ],
    }));
    const { code, cli } = await run(['--query', 'verify', '--minutes', '60'], fetch);
    expect(code).toBe(0);
    expect(sent).toEqual([
      {
        url: 'https://api.cloudflare.com/client/v4/accounts/acc123/analytics_engine/sql',
        auth: 'Bearer cf-secret-token',
        sql: querySql('verify', 60),
      },
    ]);
    expect(cli.stdout).toEqual([
      'verify (last 60 min)',
      'platform=ios  outcome=granted  n=12  p95_ms=812.46',
      'platform=ios  outcome=internal  n=1  p95_ms=x',
    ]);
  });

  it('--print-sql prints without credentials or network', async () => {
    const { fetch, sent } = api(() => ({ data: [] }));
    const r = await run(['--query', 'ssv-lag', '--print-sql'], fetch, {});
    expect(r.code).toBe(0);
    expect(r.cli.stdout[0]).toContain('quantileExactWeighted(0.95)(double2, _sample_interval)');
    expect(r.cli.stdout[0]).toContain("INTERVAL '1440' MINUTE");
    const alerts = await run(['--query', 'alerts', '--print-sql'], fetch, {});
    expect(alerts.cli.stdout.map((l) => l.split('\n')[0])).toEqual([
      '-- verify_error_rate',
      '-- ssv_rejected_spike',
      '-- sandbox_volume',
      '-- blocked_purchase',
    ]);
    expect(sent).toEqual([]);
  });

  it('alerts: exit 3 when a rule fires, 0 when all are quiet', async () => {
    const loud = api((sql) => {
      if (sql.includes("blob1 = 'purchase_verify'")) {
        return { data: [{ total: '100', errors: '5' }] };
      }
      if (sql.includes('rejected')) {
        return { data: [{ rejected: 12, granted: 20 }] };
      }
      if (sql.includes('sandbox_grant')) {
        return { data: [{ credits: 60 }] };
      }
      return { data: [{ n: 2 }] };
    });
    const fired = await run(['--query', 'alerts', '--sandbox-cap', '100'], loud.fetch);
    expect(fired.code).toBe(3);
    expect(fired.cli.stdout).toEqual([
      'ALERT  verify_error_rate: verify error rate 5.0 % (5/100) over 10 min',
      'ALERT  ssv_rejected_spike: ssv_rejected spike: 12 of 32 callbacks (37.5 %) in 15 min',
      'ALERT  sandbox_volume: sandbox/test grants: 60 of 100 credits in 24 h',
      'ALERT  blocked_purchase: 2 purchase(s) granted to blocked or indebted installs in the last hour; consider a store refund',
    ]);

    const quiet = api(() => ({ data: [] }));
    const ok = await run(['--query', 'alerts'], quiet.fetch);
    expect(ok.code).toBe(0);
    expect(ok.cli.stdout.every((l) => l.startsWith('ok     '))).toBe(true);
  });

  it('fails on API errors, missing data and missing credentials; exits 2 on usage', async () => {
    const down = api(() => ({ errors: [] }), 403);
    const r1 = await run(['--query', 'events'], down.fetch);
    expect([r1.code, r1.cli.stderr[0]]).toEqual([
      1,
      'failed: Analytics Engine SQL API returned 403',
    ]);
    const odd = api(() => ({ rows: 0 }));
    expect((await run(['--query', 'events'], odd.fetch)).cli.stderr[0]).toBe(
      'failed: Analytics Engine response has no data array',
    );
    const r3 = await run(['--query', 'rewards'], odd.fetch, {});
    expect([r3.code, r3.cli.stderr[0]]).toEqual([
      1,
      'CLOUDFLARE_ACCOUNT_ID and CLOUDFLARE_API_TOKEN must be set',
    ]);
    for (const argv of [
      [],
      ['--query', 'nope'],
      ['--query', 'events', '--minutes', '0'],
      ['--query', 'events', '--minutes', 'x'],
      ['--x'],
    ]) {
      const r = await run(argv, odd.fetch);
      expect(r.code, argv.join(' ')).toBe(2);
      expect(r.cli.stderr.at(-1)?.endsWith(USAGE)).toBe(true);
    }
  });
});

describe('scripts/metrics.ts default fetch', () => {
  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('uses the global fetch when none is injected (stubbed, no network)', async () => {
    const stub = vi.fn(() => Promise.resolve(Response.json({ data: [{ n: 1 }] })));
    vi.stubGlobal('fetch', stub);
    const cli = new D1StubCli(ENV);
    expect(await metrics(['--query', 'ssv-lag'], cli)).toBe(0);
    expect(stub).toHaveBeenCalledTimes(1);
    expect(cli.stdout).toEqual(['ssv-lag (last 1440 min)', 'n=1']);
  });
});

describe('src/admin/metrics', () => {
  it('every report reads the dataset within the window', () => {
    for (const name of QUERY_NAMES) {
      const sql = querySql(name, 30);
      expect(sql).toContain('FROM taro_api_events');
      expect(sql).toContain("timestamp > NOW() - INTERVAL '30' MINUTE");
    }
    expect(querySql('purchases', 5)).toContain(
      "blob1 IN ('purchase_granted', 'purchase_revoked', 'sandbox_grant', 'blocked_purchase')",
    );
    expect(querySql('rewards', 5)).toContain("'reward_rejected'");
    expect(SQL_API('a')).toBe(
      'https://api.cloudflare.com/client/v4/accounts/a/analytics_engine/sql',
    );
  });

  it('alert rules stay quiet below their thresholds', () => {
    const [verify, ssv, sandbox, blocked] = alertRules({ sandboxGlobalCreditsPerDay: 1000 });
    expect(verify?.evaluate([{ total: 100, errors: 2 }])).toBeNull();
    expect(verify?.evaluate([{ total: 50, errors: 2 }])).toBeNull();
    expect(verify?.evaluate([{ total: 0, errors: 0 }])).toBeNull();
    expect(verify?.evaluate([])).toBeNull();
    expect(ssv?.evaluate([{ rejected: 9, granted: 0 }])).toBeNull();
    expect(ssv?.evaluate([{ rejected: 10, granted: 100 }])).toBeNull();
    expect(ssv?.evaluate([{ rejected: 0, granted: 0 }])).toBeNull();
    expect(sandbox?.evaluate([{ credits: 499 }])).toBeNull();
    expect(sandbox?.evaluate([{ credits: 500 }])).not.toBeNull();
    expect(blocked?.evaluate([{ n: 0 }])).toBeNull();
    expect(ALERT_THRESHOLDS.verifyErrorRatePct).toBe(2);
    expect(verify?.sql).toContain("INTERVAL '10' MINUTE");
  });

  it('parses and formats rows', () => {
    expect(() => parseSqlResponse(null)).toThrow('no data array');
    expect(parseSqlResponse({ data: [{ a: 1 }] })).toEqual([{ a: 1 }]);
    expect(formatRows([])).toEqual(['(no rows)']);
  });
});
