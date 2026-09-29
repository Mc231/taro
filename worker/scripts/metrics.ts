import { parseArgs, type CliDeps } from '../src/admin/cli';
import {
  alertRules,
  formatRows,
  isQueryName,
  parseSqlResponse,
  QUERY_NAMES,
  querySql,
  SQL_API,
  type Row,
} from '../src/admin/metrics';
import { DEFAULT_SERVER_CONFIG } from '../src/config/defaults';

/**
 * `npm run metrics -- --query <events|verify|purchases|rewards|ssv-lag|alerts> [--minutes <n>] [--sandbox-cap <credits>] [--print-sql]`
 *
 * Queries the Analytics Engine dataset `taro_api_events` through the SQL API
 * (03 §14.1, 04 §14). `CLOUDFLARE_ACCOUNT_ID` and `CLOUDFLARE_API_TOKEN`
 * (Account Analytics: Read) come from the environment and are never printed.
 * `alerts` evaluates the alert rules of `src/admin/metrics.ts` and exits 3
 * when one fires. Exit codes: 0 ok, 1 failed, 2 usage, 3 alert.
 */
export const USAGE = `usage: metrics --query <${[...QUERY_NAMES, 'alerts'].join('|')}> [--minutes <n>] [--sandbox-cap <credits>] [--print-sql]`;

export type MetricsFetch = (url: string, init: RequestInit) => Promise<Response>;

const DEFAULT_MINUTES = 24 * 60;
const MAX_MINUTES = 90 * 24 * 60;

function positiveInt(raw: string | undefined, fallback: number, max: number): number | null {
  if (raw === undefined) {
    return fallback;
  }
  const value = /^\d{1,7}$/.test(raw) ? Number(raw) : 0;
  return value >= 1 && value <= max ? value : null;
}

export async function main(
  argv: readonly string[],
  deps: CliDeps,
  fetchFn: MetricsFetch = (url, init) => fetch(url, init),
): Promise<number> {
  const args = parseArgs(argv, {
    flags: ['--print-sql'],
    options: ['--query', '--minutes', '--sandbox-cap'],
  });
  if (!args.ok) {
    deps.err(`${args.error}\n${USAGE}`);
    return 2;
  }
  const name = args.options.get('--query') ?? '';
  const minutes = positiveInt(args.options.get('--minutes'), DEFAULT_MINUTES, MAX_MINUTES);
  const cap = positiveInt(
    args.options.get('--sandbox-cap'),
    DEFAULT_SERVER_CONFIG['purchases.sandboxGlobalCreditsPerDay'],
    1_000_000,
  );
  if ((name !== 'alerts' && !isQueryName(name)) || minutes === null || cap === null) {
    deps.err(`--query is required; --minutes and --sandbox-cap are positive integers\n${USAGE}`);
    return 2;
  }
  const printSql = args.flags.has('--print-sql');
  const accountId = deps.env?.['CLOUDFLARE_ACCOUNT_ID'] ?? '';
  const token = deps.env?.['CLOUDFLARE_API_TOKEN'] ?? '';
  if (!printSql && (accountId === '' || token === '')) {
    deps.err('CLOUDFLARE_ACCOUNT_ID and CLOUDFLARE_API_TOKEN must be set');
    return 1;
  }

  const run = async (sql: string): Promise<Row[]> => {
    const res = await fetchFn(SQL_API(accountId), {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` },
      body: sql,
    });
    if (!res.ok) {
      throw new Error(`Analytics Engine SQL API returned ${String(res.status)}`);
    }
    return parseSqlResponse(await res.json());
  };

  try {
    if (name === 'alerts') {
      let fired = 0;
      for (const rule of alertRules({ sandboxGlobalCreditsPerDay: cap })) {
        if (printSql) {
          deps.out(`-- ${rule.kind}\n${rule.sql}`);
          continue;
        }
        const message = rule.evaluate(await run(rule.sql));
        if (message === null) {
          deps.out(`ok     ${rule.kind}`);
        } else {
          fired++;
          deps.out(`ALERT  ${rule.kind}: ${message}`);
        }
      }
      return fired > 0 ? 3 : 0;
    }
    const sql = querySql(name, minutes);
    if (printSql) {
      deps.out(sql);
      return 0;
    }
    deps.out(`${name} (last ${String(minutes)} min)`);
    for (const line of formatRows(await run(sql))) {
      deps.out(line);
    }
    return 0;
  } catch (err) {
    deps.err(`failed: ${(err as Error).message}`);
    return 1;
  }
}
