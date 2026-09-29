import type { Crypto } from '../ports/Crypto';
import type { LedgerBucket } from '../repos/LedgerRepo';
import { numberOrNull, ROW_ID, sqlInt, sqlString, stringOrNull, supportIdOf } from './d1';

/**
 * Manual ledger adjustments (03 §6.5, §6.6; 04 §12; RC61, RC84): the pure
 * planner behind `scripts/ledger-adjust.ts`. Actions:
 *
 * - `adjust`: one `admin_adjust` entry `±n` on `paid` or `bonus`,
 *   `ref_id = ticketId` (idempotent per ticket and bucket). A negative
 *   adjustment never takes a bucket below 0 (guarded in SQL too).
 * - `settle`: settles a refund debt (`paid < 0`, 03 §6.5) with `+|paid|`,
 *   `ref_id = '{ticketId}#settle'`; guarded on the balance it was planned for.
 * - `block` / `unblock`: `installs.status` `active ↔ blocked` (purchases
 *   disabled with `purchasesBlockedReason = blocked`).
 *
 * Every write bumps `state_version` (RC67). The install is identified by the
 * user's Support ID, optionally narrowed by a full install ID or a store
 * transaction / order ID; a Support ID alone is resolved by scanning install
 * IDs page by page (`installPageSql`, `matchSupportId`).
 */
export type LedgerAction =
  | {
      readonly kind: 'adjust';
      readonly bucket: LedgerBucket;
      readonly delta: number;
      readonly note: string | null;
    }
  | { readonly kind: 'settle' }
  | { readonly kind: 'block' }
  | { readonly kind: 'unblock' };

export const MAX_ADJUST = 1000;
/** Admin notes: short, plain, never user content. */
export const NOTE = /^[A-Za-z0-9 .,:_#/()+-]{1,200}$/;

/** Validates `--delta` and `--note`; returns an error message or null. */
export function validateAdjust(delta: number, note: string | null): string | null {
  if (!Number.isSafeInteger(delta) || delta === 0 || Math.abs(delta) > MAX_ADJUST) {
    return `--delta must be a non-zero integer between -${String(MAX_ADJUST)} and ${String(MAX_ADJUST)}`;
  }
  if (note !== null && !NOTE.test(note)) {
    return '--note must be 1-200 characters of letters, digits, spaces and . , : _ # / ( ) + -';
  }
  return null;
}

export function settleRef(ticketId: string): string {
  return `${ticketId}#settle`;
}

const ADJUST = `reason = 'admin_adjust' AND ref_type = 'admin'`;

/** Keyset page of install IDs for the Support ID scan. */
export function installPageSql(after: string, limit: number): string {
  return `SELECT id FROM installs WHERE id > ${sqlString(after)} ORDER BY id LIMIT ${sqlInt(limit)}`;
}

/** Install owning a store transaction (Apple `transactionId`, Google `orderId`). */
export function installByTxnSql(storeTxnId: string): string {
  return `SELECT install_id AS id FROM purchases WHERE store_txn_id = ${sqlString(storeTxnId)} LIMIT 2`;
}

/** IDs from an `id` column result, skipping anything malformed. */
export function idsOf(rows: readonly unknown[]): string[] {
  return rows
    .map((row) => stringOrNull((row as { id?: unknown } | null)?.id))
    .filter((id): id is string => id !== null && ROW_ID.test(id));
}

/** The IDs whose Support ID equals `supportId`. */
export async function matchSupportId(
  crypto: Crypto,
  ids: readonly string[],
  supportId: string,
): Promise<string[]> {
  const matches: string[] = [];
  for (const id of ids) {
    if ((await supportIdOf(crypto, id)) === supportId) {
      matches.push(id);
    }
  }
  return matches;
}

export function adjustSnapshotSql(installId: string, ticketId: string): string {
  const id = sqlString(installId);
  const ticket = sqlString(ticketId);
  return `SELECT i.id AS id, i.status AS status,
  (SELECT COALESCE(SUM(delta), 0) FROM ledger WHERE install_id = i.id AND bucket = 'paid') AS paid,
  (SELECT COALESCE(SUM(delta), 0) FROM ledger WHERE install_id = i.id AND bucket = 'bonus') AS bonus,
  (SELECT delta FROM ledger WHERE ${ADJUST} AND ref_id = ${ticket} AND bucket = 'paid') AS ticket_paid,
  (SELECT delta FROM ledger WHERE ${ADJUST} AND ref_id = ${ticket} AND bucket = 'bonus') AS ticket_bonus,
  (SELECT install_id FROM ledger WHERE ${ADJUST} AND ref_id IN (${ticket}, ${sqlString(settleRef(ticketId))}) LIMIT 1) AS ticket_install,
  (SELECT delta FROM ledger WHERE ${ADJUST} AND ref_id = ${sqlString(settleRef(ticketId))} AND bucket = 'paid') AS ticket_settle
FROM installs i WHERE i.id = ${id}`;
}

export interface AdjustSnapshot {
  readonly installId: string;
  readonly status: string;
  readonly paid: number;
  readonly bonus: number;
  readonly ticketPaid: number | null;
  readonly ticketBonus: number | null;
  readonly ticketSettle: number | null;
  readonly ticketInstallId: string | null;
}

export function parseAdjustSnapshot(rows: readonly unknown[]): AdjustSnapshot | null {
  const row = rows[0] as Record<string, unknown> | undefined;
  const installId = stringOrNull(row?.['id']);
  if (row === undefined || installId === null) {
    return null;
  }
  return {
    installId,
    status: stringOrNull(row['status']) ?? '',
    paid: numberOrNull(row['paid']) ?? 0,
    bonus: numberOrNull(row['bonus']) ?? 0,
    ticketPaid: numberOrNull(row['ticket_paid']),
    ticketBonus: numberOrNull(row['ticket_bonus']),
    ticketSettle: numberOrNull(row['ticket_settle']),
    ticketInstallId: stringOrNull(row['ticket_install']),
  };
}

export type AdjustPlan =
  | { readonly kind: 'refused'; readonly reason: string }
  | { readonly kind: 'already_applied'; readonly summary: string }
  | {
      readonly kind: 'apply';
      readonly summary: string;
      readonly statements: readonly string[];
      /** How to confirm on a re-read. */
      readonly expect: (after: AdjustSnapshot) => boolean;
    };

export interface AdjustInput {
  readonly ticketId: string;
  readonly installId: string;
  readonly action: LedgerAction;
  /** ISO timestamp for `created_at`. */
  readonly now: string;
}

const COLUMNS = '(install_id, bucket, delta, reason, ref_type, ref_id, note, created_at)';

function bump(installId: string): string {
  return `UPDATE installs SET state_version = state_version + 1 WHERE id = ${sqlString(installId)}`;
}

function sumOf(installId: string, bucket: LedgerBucket): string {
  return `(SELECT COALESCE(SUM(delta), 0) FROM ledger WHERE install_id = ${sqlString(installId)} AND bucket = '${bucket}')`;
}

function insert(
  input: AdjustInput,
  bucket: LedgerBucket,
  delta: number,
  refId: string,
  note: string | null,
  guard: string,
): string {
  return `INSERT INTO ledger ${COLUMNS}
SELECT ${sqlString(input.installId)}, '${bucket}', ${sqlInt(delta)}, 'admin_adjust', 'admin', ${sqlString(refId)}, ${note === null ? 'NULL' : sqlString(note)}, ${sqlString(input.now)}
WHERE ${guard}
ON CONFLICT (reason, ref_type, ref_id, bucket) DO NOTHING`;
}

export function planAdjustment(input: AdjustInput, snapshot: AdjustSnapshot | null): AdjustPlan {
  const refuse = (reason: string): AdjustPlan => ({ kind: 'refused', reason });
  if (snapshot === null || snapshot.status === 'deleted') {
    return refuse('install not found (or erased)');
  }
  const who = input.installId.slice(0, 8);
  const ticket = input.ticketId;
  if (snapshot.ticketInstallId !== null && snapshot.ticketInstallId !== input.installId) {
    return refuse(`ticket ${ticket} was already used for another install`);
  }
  const action = input.action;
  switch (action.kind) {
    case 'adjust': {
      const summary = `ticket ${ticket}: ${action.bucket} ${action.delta > 0 ? '+' : ''}${String(action.delta)} on ${who}`;
      const existing = action.bucket === 'paid' ? snapshot.ticketPaid : snapshot.ticketBonus;
      if (existing !== null) {
        return existing === action.delta
          ? { kind: 'already_applied', summary }
          : refuse(
              `ticket ${ticket} already adjusted ${action.bucket} by ${String(existing)}; use a new ticket ID`,
            );
      }
      const current = action.bucket === 'paid' ? snapshot.paid : snapshot.bonus;
      if (action.delta < 0 && current + action.delta < 0) {
        return refuse(
          `${action.bucket} balance is ${String(current)}; ${String(action.delta)} would go below 0`,
        );
      }
      const guard =
        action.delta < 0
          ? `${sumOf(input.installId, action.bucket)} >= ${sqlInt(-action.delta)}`
          : 'true';
      return {
        kind: 'apply',
        summary,
        statements: [
          insert(input, action.bucket, action.delta, ticket, action.note, guard),
          bump(input.installId),
        ],
        expect: (after) =>
          (action.bucket === 'paid' ? after.ticketPaid : after.ticketBonus) === action.delta,
      };
    }
    case 'settle': {
      if (snapshot.ticketSettle !== null) {
        return {
          kind: 'already_applied',
          summary: `ticket ${ticket}: refund debt of ${String(snapshot.ticketSettle)} settled on ${who}`,
        };
      }
      if (snapshot.paid >= 0) {
        return refuse(
          `paid balance is ${String(snapshot.paid)}; there is no refund debt to settle`,
        );
      }
      const delta = -snapshot.paid;
      return {
        kind: 'apply',
        summary: `ticket ${ticket}: refund debt of ${String(delta)} settled on ${who} (paid → 0)`,
        statements: [
          insert(
            input,
            'paid',
            delta,
            settleRef(ticket),
            'settle refund debt',
            `${sumOf(input.installId, 'paid')} = ${sqlInt(snapshot.paid)}`,
          ),
          bump(input.installId),
        ],
        expect: (after) => after.ticketSettle === delta,
      };
    }
    case 'block':
    case 'unblock': {
      const [from, to] = action.kind === 'block' ? ['active', 'blocked'] : ['blocked', 'active'];
      const summary = `ticket ${ticket}: ${who} ${to}`;
      if (snapshot.status === to) {
        return { kind: 'already_applied', summary };
      }
      return {
        kind: 'apply',
        summary,
        statements: [
          `UPDATE installs SET status = '${to}', state_version = state_version + 1 WHERE id = ${sqlString(input.installId)} AND status = '${from}'`,
        ],
        expect: (after) => after.status === to,
      };
    }
  }
}

/** Balance line after a change (prefix only). */
export function describeBalances(snapshot: AdjustSnapshot): string {
  return `${snapshot.installId.slice(0, 8)}: status ${snapshot.status}, paid ${String(snapshot.paid)}, bonus ${String(snapshot.bonus)}`;
}
