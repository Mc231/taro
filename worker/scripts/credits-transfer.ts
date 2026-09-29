import { SystemClock } from '../src/adapters/cf/SystemClock';
import { WebCrypto } from '../src/adapters/cf/WebCrypto';
import { parseArgs, type CliDeps } from '../src/admin/cli';
import { ENVIRONMENTS } from '../src/admin/configPush';
import {
  checkTransferRequest,
  describeTransfer,
  parseSnapshot,
  planTransfer,
  snapshotSql,
  type PlanInput,
  type TransferSnapshot,
} from '../src/admin/creditsTransfer';
import { d1ExecuteArgs, parseD1Output, redactIds, type D1Target } from '../src/admin/d1';
import { parseHmacKey } from '../src/crypto/keyring';
import type { Environment } from '../src/env';
import type { Clock } from '../src/ports/Clock';
import type { Crypto } from '../src/ports/Crypto';

/**
 * `npm run credits-transfer -- --env <env> --ticket <id> --code <transfer code> --support-id <8 hex> [--dry-run] [--local]`
 *
 * Support credit transfer (03 §6.6, 04 §12.9, RC84; runbook
 * docs/runbooks/SUPPORT_CREDITS.md). `TRANSFER_TOKEN_KEY` comes from the
 * environment, never from argv. Reads one snapshot, plans with
 * `src/admin/creditsTransfer.ts`, applies the guarded statements with
 * `wrangler d1 execute DB --remote` and re-reads to confirm. Output names
 * the ticket, both install prefixes and the amount; never a full install ID
 * or the code. Exit codes: 0 moved or already moved, 1 refused or failed,
 * 2 usage.
 */
export const USAGE =
  'usage: credits-transfer --env <dev|staging|prod> --ticket <id> --code <transfer code> --support-id <8 hex> [--dry-run] [--local]';

function isEnvironment(value: string | undefined): value is Environment {
  return ENVIRONMENTS.includes(value as Environment);
}

async function readSnapshot(
  deps: CliDeps,
  env: Environment,
  target: D1Target,
  sql: string,
): Promise<TransferSnapshot | null> {
  const result = await deps.run('npx', d1ExecuteArgs(env, target, [sql]));
  if (result.code !== 0) {
    throw new Error(
      `wrangler d1 execute failed (exit ${String(result.code)}): ${result.stderr.trim()}`,
    );
  }
  return parseSnapshot(parseD1Output(result.stdout)[0] ?? []);
}

export async function main(
  argv: readonly string[],
  deps: CliDeps,
  crypto: Crypto = new WebCrypto(),
  clock: Clock = new SystemClock(),
): Promise<number> {
  const args = parseArgs(argv, {
    flags: ['--dry-run', '--local'],
    options: ['--env', '--ticket', '--code', '--support-id'],
  });
  if (!args.ok) {
    deps.err(`${args.error}\n${USAGE}`);
    return 2;
  }
  const env = args.options.get('--env');
  const ticketId = args.options.get('--ticket');
  const code = args.options.get('--code');
  const supportId = args.options.get('--support-id');
  if (
    !isEnvironment(env) ||
    ticketId === undefined ||
    code === undefined ||
    supportId === undefined
  ) {
    deps.err(`--env, --ticket, --code and --support-id are required\n${USAGE}`);
    return 2;
  }
  const target: D1Target = args.flags.has('--local') ? 'local' : 'remote';

  let key: Uint8Array;
  try {
    key = parseHmacKey(deps.env?.['TRANSFER_TOKEN_KEY'], 'TRANSFER_TOKEN_KEY');
  } catch (err) {
    deps.err(`${(err as Error).message} (export it from the secrets bundle for --env ${env})`);
    return 1;
  }
  const now = clock.now();
  const check = await checkTransferRequest(
    crypto,
    key,
    { ticketId, transferToken: code, supportId },
    now,
  );
  if (!check.ok) {
    deps.err(`refused: ${check.error}`);
    return 1;
  }
  const input: PlanInput = {
    ticketId,
    claims: check.claims,
    tokenDigest: check.tokenDigest,
    now: now.toISOString(),
  };
  const sql = snapshotSql(check.claims, ticketId);

  try {
    const plan = planTransfer(input, await readSnapshot(deps, env, target, sql));
    if (plan.kind === 'refused') {
      deps.err(`refused: ticket ${ticketId}: ${plan.reason}`);
      return 1;
    }
    if (plan.kind === 'already_applied') {
      deps.out(`already applied: ${describeTransfer(plan)}`);
      return 0;
    }
    if (plan.sandbox) {
      deps.out('note: the purchase is a sandbox/test purchase');
    }
    const ids = [plan.fromInstallId, plan.toInstallId, plan.purchaseId];
    if (args.flags.has('--dry-run')) {
      deps.out(`[dry-run] ${plan.kind}: ${describeTransfer(plan)}`);
      for (const statement of plan.statements) {
        deps.out(redactIds(statement, ids));
      }
      deps.out('nothing written (--dry-run).');
      return 0;
    }
    const applied = await deps.run('npx', d1ExecuteArgs(env, target, plan.statements));
    if (applied.code !== 0) {
      deps.err(
        `wrangler d1 execute failed (exit ${String(applied.code)}); re-run the same command:`,
      );
      deps.err(redactIds(applied.stderr.trim(), ids));
      return 1;
    }
    const after = await readSnapshot(deps, env, target, sql);
    if (after?.inDelta !== plan.amount || after.outDelta !== -plan.amount) {
      deps.err(
        `not applied: ticket ${ticketId}: the old install's paid balance changed; re-run to re-plan`,
      );
      return 1;
    }
    deps.out(`transferred (${env}, ${target}): ${describeTransfer(plan)}`);
    return 0;
  } catch (err) {
    deps.err(
      `failed: ${redactIds((err as Error).message, [check.claims.newInstallId, check.claims.purchaseId])}`,
    );
    return 1;
  }
}
