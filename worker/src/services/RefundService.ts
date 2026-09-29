import type { Deps } from '../deps';
import { inst8 } from '../logging/redact';
import { InstallRepo } from '../repos/InstallRepo';
import { LedgerRepo } from '../repos/LedgerRepo';
import { PurchaseRepo, type PurchaseRow } from '../repos/PurchaseRepo';

/** Who reported the refund (log and metric `code`). */
export type RevokeSource = 'apple' | 'google' | 'voided_backstop' | 'admin';

export interface RevokeResult {
  /** False when the purchase was already revoked (a duplicate or late report). */
  readonly revoked: boolean;
  /** True when this revoke moved the install to `blocked` (RC66). */
  readonly blocked: boolean;
}

/**
 * Refund / revocation policy (03 §6.5, MO16; RC66, RC67).
 *
 * `revoke(purchase)` runs one D1 batch gated on the `purchases` CAS
 * (`granted | reversal_regranted → revoked`, `batchGuard`): the ledger
 * `refund_revoke` of the purchase's credits (`paid`, which **may go
 * negative**: `paidBlocked`, `purchasesAllowed = false` with `refundDebt`),
 * `refund_count + 1`, `state_version + 1`, and `status = 'blocked'` once
 * `refund_count` reaches `abuse.refundBlockThreshold`. A blocked install
 * keeps its free, bonus and positive paid credits; only new purchases are
 * disabled (`purchasesBlockedReason = blocked`), and a verified purchase that
 * still arrives is granted (§6.2 step 4).
 *
 * `regrant(purchase)` (`REFUND_REVERSED`) is the inverse CAS
 * (`revoked → reversal_regranted`) with a `purchase_reversal_regrant` entry.
 * It does not lower `refund_count` or unblock: support decides that.
 *
 * Both are idempotent: a second call finds the CAS already applied and
 * changes nothing, whichever webhook, cron or script got there first.
 */
export class RefundService {
  private readonly purchases: PurchaseRepo;
  private readonly ledger: LedgerRepo;
  private readonly installs: InstallRepo;

  constructor(private readonly deps: Deps) {
    this.purchases = new PurchaseRepo(deps.db);
    this.ledger = new LedgerRepo(deps.db);
    this.installs = new InstallRepo(deps.db);
  }

  async revoke(purchase: PurchaseRow, source: RevokeSource): Promise<RevokeResult> {
    const config = await this.deps.config.snapshot();
    const now = this.deps.clock.now().toISOString();
    const before = await this.installs.findById(purchase.installId);
    const results = await this.deps.db.batch([
      this.purchases.markRevokedStmt(purchase.id, now),
      this.ledger.purchaseMovementAfterStmt({
        installId: purchase.installId,
        delta: -purchase.credits,
        reason: 'refund_revoke',
        purchaseId: purchase.id,
        createdAt: now,
      }),
      this.installs.recordRefundAfterStmt(purchase.installId, config['abuse.refundBlockThreshold']),
    ]);
    if (results[0]?.meta.changes !== 1) {
      this.deps.logger.log('info', 'purchase_revoke_duplicate', {
        purchaseId: purchase.id,
        source,
      });
      return { revoked: false, blocked: false };
    }
    const after = await this.installs.findById(purchase.installId);
    const blocked = before?.status === 'active' && after?.status === 'blocked';
    this.deps.metrics.write({
      event: 'purchase_revoked',
      platform: purchase.platform,
      credits: purchase.credits,
      code: source,
    });
    this.deps.logger.log('info', 'purchase_revoked', {
      inst: inst8(purchase.installId),
      purchaseId: purchase.id,
      platform: purchase.platform,
      credits: purchase.credits,
      source,
      refundCount: after?.refundCount,
    });
    if (blocked) {
      this.deps.logger.log('warn', 'install_blocked', {
        inst: inst8(purchase.installId),
        reason: 'refund_threshold',
        refundCount: after.refundCount,
      });
    }
    return { revoked: true, blocked };
  }

  /** `REFUND_REVERSED` (03 §6.4): true when this call re-granted the credits. */
  async regrant(purchase: PurchaseRow): Promise<boolean> {
    const now = this.deps.clock.now().toISOString();
    const results = await this.deps.db.batch([
      this.purchases.markRegrantedStmt(purchase.id),
      this.ledger.purchaseMovementAfterStmt({
        installId: purchase.installId,
        delta: purchase.credits,
        reason: 'purchase_reversal_regrant',
        purchaseId: purchase.id,
        createdAt: now,
      }),
      this.installs.bumpStateVersionAfterStmt(purchase.installId),
    ]);
    const regranted = results[0]?.meta.changes === 1;
    this.deps.logger.log('info', regranted ? 'purchase_regranted' : 'purchase_regrant_skipped', {
      inst: inst8(purchase.installId),
      purchaseId: purchase.id,
      credits: purchase.credits,
    });
    return regranted;
  }
}
