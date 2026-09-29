import { toHex } from '../crypto/encoding';
import { verifyTransferToken, type TransferTokenClaims } from '../monetization/transferToken';
import type { Crypto } from '../ports/Crypto';
import {
  normalizeSupportId,
  numberOrNull,
  ROW_ID,
  sqlInt,
  sqlString,
  stringOrNull,
  supportIdOf,
  TICKET_ID,
} from './d1';

/**
 * Support credit transfer (03 §6.6, 04 §12.9; RC43, RC84): the pure batch
 * builder behind `scripts/credits-transfer.ts`. There is no admin HTTP route.
 *
 * 1. `checkTransferRequest` verifies the transfer code (`TRANSFER_TOKEN_KEY`
 *    HMAC, 7-day TTL) and that the user's Support ID is the hash prefix of
 *    the new install bound in the code.
 * 2. `snapshotSql` reads everything the plan needs in one SELECT.
 * 3. `planTransfer` decides: move `min(unspent paid of the old install,
 *    credits of the proven purchase)` with two paired `admin_adjust` ledger
 *    entries, or refuse, or report that the ticket was already applied.
 *
 * Ledger shape: `(reason 'admin_adjust', ref_type 'admin', bucket 'paid')`
 * with `ref_id = '{ticketId}#out'` (old install, `-n`) and
 * `'{ticketId}#in'` (new install, `+n`). The ledger's unique key
 * `(reason, ref_type, ref_id, bucket)` has no install column, so the two legs
 * of one ticket need distinct `ref_id`s; both start with the ticket ID and a
 * re-run of the same ticket is a no-op (idempotent per ticket).
 *
 * Single use: the `#out` note records the purchase (`purchase=<id> `), and
 * the `#out` insert only runs while no other ticket moved that purchase. So a
 * transfer code (which names one purchase) moves credits at most once, under
 * whichever ticket ran first. Every statement guards itself, so a partly
 * applied command can simply be run again: the `#in` leg copies its amount
 * from the `#out` row, never from a fresh computation.
 */
export interface TransferRequest {
  readonly ticketId: string;
  readonly transferToken: string;
  readonly supportId: string;
}

export type TransferCheck =
  | { readonly ok: true; readonly claims: TransferTokenClaims; readonly tokenDigest: string }
  | { readonly ok: false; readonly error: string };

export async function checkTransferRequest(
  crypto: Crypto,
  key: Uint8Array,
  request: TransferRequest,
  now: Date,
): Promise<TransferCheck> {
  if (!TICKET_ID.test(request.ticketId)) {
    return { ok: false, error: 'ticket ID must be 1-64 characters of A-Z a-z 0-9 . _ -' };
  }
  const supportId = normalizeSupportId(request.supportId);
  if (supportId === null) {
    return { ok: false, error: 'Support ID must be 8 hex characters (Settings → About)' };
  }
  const claims = await verifyTransferToken(crypto, key, request.transferToken.trim(), now);
  if (claims === null) {
    return {
      ok: false,
      error:
        'transfer code is invalid or expired (codes live 7 days); ask the user to tap "Move readings from another device" again',
    };
  }
  if (!ROW_ID.test(claims.purchaseId) || !ROW_ID.test(claims.newInstallId)) {
    return { ok: false, error: 'transfer code carries malformed IDs' };
  }
  if ((await supportIdOf(crypto, claims.newInstallId)) !== supportId) {
    return {
      ok: false,
      error: 'Support ID does not match the install that requested this transfer code',
    };
  }
  const tokenDigest = toHex(await crypto.sha256(request.transferToken.trim())).slice(0, 16);
  return { ok: true, claims, tokenDigest };
}

export function outRef(ticketId: string): string {
  return `${ticketId}#out`;
}

export function inRef(ticketId: string): string {
  return `${ticketId}#in`;
}

/** `instr` needle marking the purchase in a transfer note (trailing space ends the ID). */
export function purchaseMarker(purchaseId: string): string {
  return `purchase=${purchaseId} `;
}

const ADJUST = `reason = 'admin_adjust' AND ref_type = 'admin' AND bucket = 'paid'`;

/** One-row snapshot: the purchase, both installs, this ticket's legs, other tickets for the purchase. */
export function snapshotSql(claims: TransferTokenClaims, ticketId: string): string {
  const purchase = sqlString(claims.purchaseId);
  const next = sqlString(claims.newInstallId);
  const out = sqlString(outRef(ticketId));
  const inn = sqlString(inRef(ticketId));
  return `SELECT p.id AS purchase_id, p.install_id AS old_install_id, p.credits AS credits,
  p.status AS purchase_status, p.environment AS environment,
  (SELECT status FROM installs WHERE id = p.install_id) AS old_status,
  (SELECT COALESCE(SUM(delta), 0) FROM ledger WHERE install_id = p.install_id AND bucket = 'paid') AS old_paid,
  (SELECT status FROM installs WHERE id = ${next}) AS new_status,
  (SELECT delta FROM ledger WHERE ${ADJUST} AND ref_id = ${out}) AS out_delta,
  (SELECT install_id FROM ledger WHERE ${ADJUST} AND ref_id = ${out}) AS out_install_id,
  (SELECT note FROM ledger WHERE ${ADJUST} AND ref_id = ${out}) AS out_note,
  (SELECT delta FROM ledger WHERE ${ADJUST} AND ref_id = ${inn}) AS in_delta,
  (SELECT ref_id FROM ledger WHERE ${ADJUST} AND ref_id LIKE '%#out' AND ref_id <> ${out}
     AND instr(note, ${sqlString(purchaseMarker(claims.purchaseId))}) > 0 LIMIT 1) AS other_out_ref
FROM purchases p WHERE p.id = ${purchase}`;
}

export interface TransferSnapshot {
  readonly purchaseId: string;
  readonly oldInstallId: string;
  readonly credits: number;
  readonly purchaseStatus: string;
  readonly environment: string;
  readonly oldStatus: string | null;
  readonly oldPaid: number;
  readonly newStatus: string | null;
  readonly outDelta: number | null;
  readonly outInstallId: string | null;
  readonly outNote: string | null;
  readonly inDelta: number | null;
  readonly otherOutRef: string | null;
}

/** The snapshot row, or null when the purchase does not exist (no row). */
export function parseSnapshot(rows: readonly unknown[]): TransferSnapshot | null {
  const row = rows[0] as Record<string, unknown> | undefined;
  if (row === undefined) {
    return null;
  }
  const purchaseId = stringOrNull(row['purchase_id']);
  const oldInstallId = stringOrNull(row['old_install_id']);
  const credits = numberOrNull(row['credits']);
  if (purchaseId === null || oldInstallId === null || credits === null) {
    throw new Error('snapshot row is missing purchase columns');
  }
  return {
    purchaseId,
    oldInstallId,
    credits,
    purchaseStatus: stringOrNull(row['purchase_status']) ?? '',
    environment: stringOrNull(row['environment']) ?? '',
    oldStatus: stringOrNull(row['old_status']),
    oldPaid: numberOrNull(row['old_paid']) ?? 0,
    newStatus: stringOrNull(row['new_status']),
    outDelta: numberOrNull(row['out_delta']),
    outInstallId: stringOrNull(row['out_install_id']),
    outNote: stringOrNull(row['out_note']),
    inDelta: numberOrNull(row['in_delta']),
    otherOutRef: stringOrNull(row['other_out_ref']),
  };
}

export interface TransferParties {
  readonly ticketId: string;
  readonly purchaseId: string;
  readonly fromInstallId: string;
  readonly toInstallId: string;
  readonly amount: number;
}

export type TransferPlan =
  | { readonly kind: 'refused'; readonly reason: string }
  | ({ readonly kind: 'already_applied' } & TransferParties)
  | ({
      readonly kind: 'apply' | 'resume';
      readonly statements: readonly string[];
      readonly sandbox: boolean;
    } & TransferParties);

export interface PlanInput {
  readonly ticketId: string;
  readonly claims: TransferTokenClaims;
  readonly tokenDigest: string;
  /** ISO timestamp for `created_at`. */
  readonly now: string;
}

/** `transfer purchase=<id> token=<digest> from=<old8> to=<new8> ` (admin note, no user content). */
export function transferNote(input: PlanInput, fromInstallId: string): string {
  return `transfer ${purchaseMarker(input.claims.purchaseId)}token=${input.tokenDigest} from=${fromInstallId.slice(0, 8)} to=${input.claims.newInstallId.slice(0, 8)} `;
}

const COLUMNS = '(install_id, bucket, delta, reason, ref_type, ref_id, note, created_at)';

function outStatement(input: PlanInput, from: string, amount: number): string {
  const old = sqlString(from);
  return `INSERT INTO ledger ${COLUMNS}
SELECT ${old}, 'paid', ${sqlInt(-amount)}, 'admin_adjust', 'admin', ${sqlString(outRef(input.ticketId))}, ${sqlString(transferNote(input, from))}, ${sqlString(input.now)}
WHERE (SELECT COALESCE(SUM(delta), 0) FROM ledger WHERE install_id = ${old} AND bucket = 'paid') >= ${sqlInt(amount)}
  AND NOT EXISTS (SELECT 1 FROM ledger WHERE ${ADJUST} AND ref_id LIKE '%#out'
    AND instr(note, ${sqlString(purchaseMarker(input.claims.purchaseId))}) > 0)
ON CONFLICT (reason, ref_type, ref_id, bucket) DO NOTHING`;
}

function inStatement(input: PlanInput, from: string): string {
  return `INSERT INTO ledger ${COLUMNS}
SELECT ${sqlString(input.claims.newInstallId)}, 'paid', -delta, 'admin_adjust', 'admin', ${sqlString(inRef(input.ticketId))}, note, ${sqlString(input.now)}
FROM ledger WHERE ${ADJUST} AND ref_id = ${sqlString(outRef(input.ticketId))} AND install_id = ${sqlString(from)}
ON CONFLICT (reason, ref_type, ref_id, bucket) DO NOTHING`;
}

/** RC67: every batch touching an install's ledger bumps `state_version`. */
function bumpStatement(ids: readonly string[]): string {
  return `UPDATE installs SET state_version = state_version + 1 WHERE id IN (${ids.map(sqlString).join(', ')})`;
}

export function planTransfer(input: PlanInput, snapshot: TransferSnapshot | null): TransferPlan {
  const refuse = (reason: string): TransferPlan => ({ kind: 'refused', reason });
  if (snapshot === null) {
    return refuse('purchase from the transfer code was not found in this environment');
  }
  const from = snapshot.oldInstallId;
  const to = input.claims.newInstallId;
  const parties = (amount: number): TransferParties => ({
    ticketId: input.ticketId,
    purchaseId: snapshot.purchaseId,
    fromInstallId: from,
    toInstallId: to,
    amount,
  });
  const sandbox = snapshot.environment === 'sandbox';

  if (snapshot.outDelta !== null) {
    const samePurchase =
      snapshot.outInstallId === from &&
      (snapshot.outNote ?? '').includes(purchaseMarker(snapshot.purchaseId)) &&
      (snapshot.outNote ?? '').includes(`to=${to.slice(0, 8)} `);
    if (!samePurchase) {
      return refuse(`ticket ${input.ticketId} was already used for a different transfer`);
    }
    const amount = -snapshot.outDelta;
    if (snapshot.inDelta !== null) {
      return { kind: 'already_applied', ...parties(amount) };
    }
    return {
      kind: 'resume',
      statements: [inStatement(input, from), bumpStatement([from, to])],
      sandbox,
      ...parties(amount),
    };
  }
  if (snapshot.otherOutRef !== null) {
    return refuse(
      `purchase was already transferred under ticket ${snapshot.otherOutRef.replace(/#out$/, '')}; a transfer code works once`,
    );
  }
  if (snapshot.purchaseStatus === 'revoked') {
    return refuse('purchase was refunded (revoked); there is nothing to transfer');
  }
  if (from === to) {
    return refuse('the transfer code names the install that already owns the purchase');
  }
  if (snapshot.newStatus === null || snapshot.newStatus === 'deleted') {
    return refuse('the new install is unknown or erased; ask the user to open the app once');
  }
  const amount = Math.min(Math.max(0, snapshot.oldPaid), snapshot.credits);
  if (amount <= 0) {
    return refuse('the old install has no unspent paid credits left; nothing to move');
  }
  return {
    kind: 'apply',
    statements: [
      outStatement(input, from, amount),
      inStatement(input, from),
      bumpStatement([from, to]),
    ],
    sandbox,
    ...parties(amount),
  };
}

/** One summary line (install prefixes only, never full IDs or the code). */
export function describeTransfer(parties: TransferParties): string {
  return `ticket ${parties.ticketId}: ${String(parties.amount)} paid credit(s) ${parties.fromInstallId.slice(0, 8)} → ${parties.toInstallId.slice(0, 8)} (purchase ${parties.purchaseId.slice(0, 8)})`;
}
