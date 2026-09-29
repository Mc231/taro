import { toHex } from '../crypto/encoding';
import type { Environment } from '../env';
import type { Crypto } from '../ports/Crypto';

/**
 * Shared helpers of the owner-run D1 scripts (`credits-transfer`,
 * `ledger-adjust`; 03 §6.6, RC61, RC84). The scripts talk to D1 only through
 * `wrangler d1 execute DB --env <env> --remote|--local --json --command <sql>`,
 * so every value is rendered as an SQL literal here. Only validated IDs,
 * integers and restricted notes reach these functions, and strings are
 * quoted anyway.
 */
export type D1Target = 'remote' | 'local';

/** Separator between the statements of one `--command` (no literal ever contains it). */
export const STATEMENT_SEPARATOR = ';\n';

/** Install, purchase and other row IDs (UUID-shaped). */
export const ROW_ID = /^[0-9A-Za-z][0-9A-Za-z-]{7,63}$/;
/** Support ticket IDs: `T-1234`, `2026-09-29.lost-credits`. */
export const TICKET_ID = /^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$/;
/** Support ID shown in About: first 8 hex chars of `SHA-256(installId)` (01 §7.10, RC43). */
export const SUPPORT_ID = /^[0-9a-f]{8}$/;

export function sqlString(value: string): string {
  return `'${value.replaceAll("'", "''")}'`;
}

export function sqlInt(value: number): string {
  if (!Number.isSafeInteger(value)) {
    throw new Error(`not an integer: ${String(value)}`);
  }
  return String(value);
}

/** `wrangler d1 execute DB …` arguments for one command of one or more statements. */
export function d1ExecuteArgs(
  env: Environment,
  target: D1Target,
  statements: readonly string[],
): string[] {
  return [
    'wrangler',
    'd1',
    'execute',
    'DB',
    '--env',
    env,
    `--${target}`,
    '--json',
    '--command',
    statements.join(STATEMENT_SEPARATOR),
  ];
}

export class D1OutputError extends Error {}

/**
 * The result rows of every statement in `wrangler d1 execute --json` output
 * (`[{ results: [...], success: true, meta: {...} }, …]`).
 */
export function parseD1Output(stdout: string): unknown[][] {
  let parsed: unknown;
  try {
    parsed = JSON.parse(stdout);
  } catch {
    throw new D1OutputError('wrangler did not print JSON');
  }
  if (!Array.isArray(parsed)) {
    throw new D1OutputError('wrangler JSON is not an array of results');
  }
  return parsed.map((entry: unknown) => {
    const result = entry as { success?: unknown; results?: unknown } | null;
    if (result?.success !== true || !Array.isArray(result.results)) {
      throw new D1OutputError('a statement did not succeed');
    }
    return result.results as unknown[];
  });
}

/** First 8 hex characters of `SHA-256(installId)` (01 §7.10, RC43). */
export async function supportIdOf(crypto: Crypto, installId: string): Promise<string> {
  return toHex(await crypto.sha256(installId)).slice(0, 8);
}

/** Normalises a user-typed Support ID (case, spaces); null if it is not 8 hex characters. */
export function normalizeSupportId(raw: string): string | null {
  const value = raw.trim().toLowerCase();
  return SUPPORT_ID.test(value) ? value : null;
}

/** Replaces every full ID in `text` with `<prefix…>` for printing (logs carry `inst8` only). */
export function redactIds(text: string, ids: readonly string[]): string {
  let out = text;
  for (const id of ids) {
    out = out.replaceAll(id, `<${id.slice(0, 8)}…>`);
  }
  return out;
}

/** A numeric SQL column that may come back as a number or a numeric string. */
export function numberOrNull(value: unknown): number | null {
  if (typeof value === 'number') {
    return value;
  }
  if (typeof value === 'string' && value.trim() !== '' && Number.isFinite(Number(value))) {
    return Number(value);
  }
  return null;
}

export function stringOrNull(value: unknown): string | null {
  return typeof value === 'string' ? value : null;
}
