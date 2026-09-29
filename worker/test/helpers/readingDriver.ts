import type { BudgetTier } from '../../src/domain/budget';
import type { RefundReason } from '../../src/domain/ledgerRules';
import { DailyUsageRepo, type DailyUsageRow } from '../../src/repos/DailyUsageRepo';
import { DeviceUsageRepo, type DeviceUsageRow } from '../../src/repos/DeviceUsageRepo';
import { InstallRepo } from '../../src/repos/InstallRepo';
import { LedgerRepo, type Balances, type LedgerEntry } from '../../src/repos/LedgerRepo';
import { ReadingRepo, type ReadingRow } from '../../src/repos/ReadingRepo';
import {
  BalanceService,
  type CommitResult,
  type HoldRequest,
  type HoldResult,
  type RefundResult,
} from '../../src/services/BalanceService';
import { BudgetService, DauCache, type BudgetStatus } from '../../src/services/BudgetService';
import { PurchaseRepo } from '../../src/repos/PurchaseRepo';
import { RefundService } from '../../src/services/RefundService';
import { uniqueId, type TestHarness } from '../fakes/testDeps';
import { db } from './db';

/** A `BudgetService` pinned to one tier (the real one reads `ai_spend_daily`, shared per file). */
export class FixedBudget extends BudgetService {
  constructor(public tier: BudgetTier = 'normal') {
    super(db, new DauCache());
  }

  override status(): Promise<BudgetStatus> {
    return Promise.resolve({ tier: this.tier, spendUsd: 0 });
  }
}

/**
 * Simulated readings until Phase 8 adds `POST /v1/readings/holds`: the
 * driver creates (or loads) the `readings` row by `clientReadingId` the way
 * the route will, then calls `BalanceService.hold/refund/commit`.
 */
export class ReadingDriver {
  readonly balance: BalanceService;
  readonly budget = new FixedBudget();
  private readonly readings = new ReadingRepo(db);
  private readonly ledger = new LedgerRepo(db);
  private readonly installs = new InstallRepo(db);

  constructor(readonly h: TestHarness) {
    this.balance = new BalanceService(h.deps, this.budget);
  }

  /** Insert-or-load the reading row of `(installId, clientReadingId)`. */
  async open(installId: string, clientReadingId: string = uniqueId('crid')): Promise<ReadingRow> {
    await this.readings.insert({
      id: uniqueId('read'),
      installId,
      clientReadingId,
      spreadId: 'single',
      cardCount: 1,
      hasQuestion: false,
      locale: 'en',
      localDate: '2026-09-26',
      status: 'held',
      chargeSource: 'none',
      createdAt: this.h.clock.now().toISOString(),
    });
    const row = await this.readings.findByClientId(installId, clientReadingId);
    if (row === null) {
      throw new Error('driver: reading row missing');
    }
    return row;
  }

  /** Open + hold, like the pre-draw hold route. */
  async hold(
    installId: string,
    clientReadingId: string = uniqueId('crid'),
    extra: Partial<HoldRequest> = {},
  ): Promise<HoldResult & { readonly readingId: string }> {
    const row = await this.open(installId, clientReadingId);
    const result = await this.balance.hold({ installId, readingId: row.id, ...extra });
    return { ...result, readingId: row.id };
  }

  refund(readingId: string, reason: RefundReason = 'failed'): Promise<RefundResult> {
    return this.balance.refund({ readingId, reason });
  }

  commit(readingId: string): Promise<CommitResult> {
    return this.balance.commit({ readingId });
  }

  /** A grant (purchase or rewarded) as one batch with the `state_version` bump. */
  async grant(installId: string, bucket: 'paid' | 'bonus', credits: number): Promise<void> {
    await db.batch([
      this.ledger.appendStmt({
        installId,
        bucket,
        delta: credits,
        reason: bucket === 'paid' ? 'purchase' : 'ad_reward',
        refType: bucket === 'paid' ? 'purchase' : 'ad_reward',
        refId: uniqueId('grnt'),
        createdAt: this.h.clock.now().toISOString(),
      }),
      this.installs.bumpStateVersionStmt(installId),
    ]);
  }

  /**
   * A refund clawback through the real `RefundService.revoke` (03 §6.5) of a
   * purchase row of `credits` (recorded without its grant, so paid may go
   * negative).
   */
  async revoke(installId: string, credits: number): Promise<void> {
    const purchases = new PurchaseRepo(db);
    const id = uniqueId('purc');
    const now = this.h.clock.now().toISOString();
    await purchases.insert({
      id,
      installId,
      platform: 'ios',
      productId: 'com.vshyrochuk.taro.readings_3',
      storeTxnId: uniqueId('rvke'),
      credits,
      environment: 'production',
      isTest: false,
      accountTokenMatch: true,
      purchasedAt: now,
      grantedAt: now,
    });
    const row = await purchases.findById(id);
    if (row === null) {
      throw new Error('driver: purchase row missing');
    }
    await new RefundService(this.h.deps).revoke(row, 'admin');
  }

  reading(id: string): Promise<ReadingRow | null> {
    return this.readings.findById(id);
  }

  balances(installId: string): Promise<Balances> {
    return this.ledger.balances(installId);
  }

  entries(installId: string): Promise<LedgerEntry[]> {
    return this.ledger.entries(installId);
  }

  usage(installId: string, localDate: string): Promise<DailyUsageRow | null> {
    return new DailyUsageRepo(db).find({ installId, localDate });
  }

  device(deviceKeyHash: string, localDate: string): Promise<DeviceUsageRow | null> {
    return new DeviceUsageRepo(db).find({ deviceKeyHash, localDate });
  }

  async stateVersion(installId: string): Promise<number> {
    return (await this.installs.findById(installId))?.stateVersion ?? -1;
  }
}
