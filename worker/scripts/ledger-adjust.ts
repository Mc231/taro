import { SystemClock } from '../src/adapters/cf/SystemClock';
import { WebCrypto } from '../src/adapters/cf/WebCrypto';
import { parseArgs, type CliDeps } from '../src/admin/cli';
import { ENVIRONMENTS } from '../src/admin/configPush';
import {
  d1ExecuteArgs,
  normalizeSupportId,
  parseD1Output,
  redactIds,
  ROW_ID,
  TICKET_ID,
  type D1Target,
} from '../src/admin/d1';
import {
  adjustSnapshotSql,
  describeBalances,
  idsOf,
  installByTxnSql,
  installPageSql,
  matchSupportId,
  parseAdjustSnapshot,
  planAdjustment,
  validateAdjust,
  type AdjustSnapshot,
  type LedgerAction,
} from '../src/admin/ledgerAdjust';
import type { Environment } from '../src/env';
import type { Clock } from '../src/ports/Clock';
import type { Crypto } from '../src/ports/Crypto';

/**
 * `npm run ledger-adjust -- --env <env> --ticket <id> --support-id <8 hex> [--install <id> | --txn <store txn/order id>]
 *    (--bucket paid|bonus --delta <±n> [--note <text>] | --settle-debt | --block | --unblock) [--dry-run] [--local]`
 *
 * Manual `admin_adjust` entries, refund-debt settlement and install blocking
 * (03 §6.5, §6.6; RC61, RC84) over `src/admin/ledgerAdjust.ts`. The Support
 * ID must match the install; without `--install` / `--txn` it is resolved by
 * scanning install IDs. Output carries install prefixes only.
 * Exit codes: 0 applied or already applied, 1 refused or failed, 2 usage.
 */
export const USAGE =
  'usage: ledger-adjust --env <dev|staging|prod> --ticket <id> --support-id <8 hex> [--install <id> | --txn <id>] (--bucket paid|bonus --delta <n> [--note <text>] | --settle-debt | --block | --unblock) [--dry-run] [--local]';

export const SCAN_PAGE = 1000;
export const MAX_SCAN_PAGES = 2000;

class Refused extends Error {}

function isEnvironment(value: string | undefined): value is Environment {
  return ENVIRONMENTS.includes(value as Environment);
}

type ActionResult =
  | { readonly ok: true; readonly action: LedgerAction }
  | { readonly ok: false; readonly error: string };

function actionOf(flags: ReadonlySet<string>, options: ReadonlyMap<string, string>): ActionResult {
  const chosen = ['--settle-debt', '--block', '--unblock'].filter((f) => flags.has(f));
  const adjust = options.has('--bucket') || options.has('--delta') || options.has('--note');
  if (chosen.length + (adjust ? 1 : 0) !== 1) {
    return {
      ok: false,
      error: 'choose exactly one of --bucket/--delta, --settle-debt, --block, --unblock',
    };
  }
  if (chosen[0] === '--settle-debt') {
    return { ok: true, action: { kind: 'settle' } };
  }
  if (chosen[0] === '--block') {
    return { ok: true, action: { kind: 'block' } };
  }
  if (chosen[0] === '--unblock') {
    return { ok: true, action: { kind: 'unblock' } };
  }
  const bucket = options.get('--bucket');
  if (bucket !== 'paid' && bucket !== 'bonus') {
    return { ok: false, error: '--bucket must be paid or bonus' };
  }
  const raw = options.get('--delta') ?? '';
  const delta = /^[+-]?\d{1,6}$/.test(raw) ? Number(raw) : Number.NaN;
  const note = options.get('--note') ?? null;
  const issue = validateAdjust(delta, note);
  return issue === null
    ? { ok: true, action: { kind: 'adjust', bucket, delta, note } }
    : { ok: false, error: issue };
}

async function query(
  deps: CliDeps,
  env: Environment,
  target: D1Target,
  sql: string,
): Promise<unknown[]> {
  const result = await deps.run('npx', d1ExecuteArgs(env, target, [sql]));
  if (result.code !== 0) {
    throw new Error(
      `wrangler d1 execute failed (exit ${String(result.code)}): ${result.stderr.trim()}`,
    );
  }
  return parseD1Output(result.stdout)[0] ?? [];
}

async function resolveInstall(
  deps: CliDeps,
  crypto: Crypto,
  env: Environment,
  target: D1Target,
  supportId: string,
  options: ReadonlyMap<string, string>,
): Promise<string> {
  const install = options.get('--install');
  const txn = options.get('--txn');
  let candidates: string[];
  if (install !== undefined) {
    if (!ROW_ID.test(install)) {
      throw new Refused('--install is not an install ID');
    }
    candidates = [install];
  } else if (txn !== undefined) {
    candidates = idsOf(await query(deps, env, target, installByTxnSql(txn)));
    if (candidates.length === 0) {
      throw new Refused('no purchase with that store transaction / order ID');
    }
  } else {
    candidates = [];
    let after = '';
    for (let page = 0; page < MAX_SCAN_PAGES; page++) {
      const ids = idsOf(await query(deps, env, target, installPageSql(after, SCAN_PAGE)));
      candidates.push(...(await matchSupportId(crypto, ids, supportId)));
      if (ids.length < SCAN_PAGE) {
        break;
      }
      after = ids[ids.length - 1] ?? '';
    }
    if (candidates.length > 1) {
      throw new Refused(
        `Support ID matches ${String(candidates.length)} installs; narrow it with --txn or --install`,
      );
    }
  }
  const matching = await matchSupportId(crypto, candidates, supportId);
  if (matching.length !== 1 || matching[0] === undefined) {
    throw new Refused(
      matching.length === 0
        ? 'Support ID does not match the install'
        : 'the transaction ID matches more than one install; use --install',
    );
  }
  return matching[0];
}

export async function main(
  argv: readonly string[],
  deps: CliDeps,
  crypto: Crypto = new WebCrypto(),
  clock: Clock = new SystemClock(),
): Promise<number> {
  const args = parseArgs(argv, {
    flags: ['--dry-run', '--local', '--settle-debt', '--block', '--unblock'],
    options: [
      '--env',
      '--ticket',
      '--support-id',
      '--install',
      '--txn',
      '--bucket',
      '--delta',
      '--note',
    ],
  });
  if (!args.ok) {
    deps.err(`${args.error}\n${USAGE}`);
    return 2;
  }
  const env = args.options.get('--env');
  const ticketId = args.options.get('--ticket') ?? '';
  const supportId = normalizeSupportId(args.options.get('--support-id') ?? '');
  if (!isEnvironment(env) || !TICKET_ID.test(ticketId) || supportId === null) {
    deps.err(`--env, --ticket (A-Z a-z 0-9 . _ -) and --support-id (8 hex) are required\n${USAGE}`);
    return 2;
  }
  if (args.options.has('--install') && args.options.has('--txn')) {
    deps.err(`use --install or --txn, not both\n${USAGE}`);
    return 2;
  }
  const action = actionOf(args.flags, args.options);
  if (!action.ok) {
    deps.err(`${action.error}\n${USAGE}`);
    return 2;
  }
  const target: D1Target = args.flags.has('--local') ? 'local' : 'remote';

  let installId = '';
  try {
    installId = await resolveInstall(deps, crypto, env, target, supportId, args.options);
    const snapshotSql = adjustSnapshotSql(installId, ticketId);
    const read = async (): Promise<AdjustSnapshot | null> =>
      parseAdjustSnapshot(await query(deps, env, target, snapshotSql));
    const plan = planAdjustment(
      { ticketId, installId, action: action.action, now: clock.now().toISOString() },
      await read(),
    );
    if (plan.kind === 'refused') {
      deps.err(`refused: ${plan.reason}`);
      return 1;
    }
    if (plan.kind === 'already_applied') {
      deps.out(`already applied: ${plan.summary}`);
      return 0;
    }
    if (args.flags.has('--dry-run')) {
      deps.out(`[dry-run] ${plan.summary}`);
      for (const statement of plan.statements) {
        deps.out(redactIds(statement, [installId]));
      }
      deps.out('nothing written (--dry-run).');
      return 0;
    }
    const applied = await deps.run('npx', d1ExecuteArgs(env, target, plan.statements));
    if (applied.code !== 0) {
      deps.err(
        `wrangler d1 execute failed (exit ${String(applied.code)}); re-run the same command:`,
      );
      deps.err(redactIds(applied.stderr.trim(), [installId]));
      return 1;
    }
    const after = await read();
    if (after === null || !plan.expect(after)) {
      deps.err(`not applied: ${plan.summary} (the balance changed meanwhile); re-run to re-plan`);
      return 1;
    }
    deps.out(`applied (${env}, ${target}): ${plan.summary}`);
    deps.out(describeBalances(after));
    return 0;
  } catch (err) {
    const message = redactIds((err as Error).message, installId === '' ? [] : [installId]);
    deps.err(err instanceof Refused ? `refused: ${message}` : `failed: ${message}`);
    return 1;
  }
}
