import type { Platform } from '../domain/types';

/** `purchases` (03 §4, §6; RC7 `is_test`, RC63). Kept 7 years, never erased (RC37). */
export type PurchaseStatus = 'granted' | 'revoked' | 'reversal_regranted';
export type StoreEnvironment = 'production' | 'sandbox';

export interface NewPurchase {
  readonly id: string;
  readonly installId: string;
  readonly platform: Platform;
  readonly productId: string;
  readonly storeTxnId: string;
  readonly originalTxnId?: string | null;
  readonly purchaseToken?: string | null;
  readonly credits: number;
  readonly environment: StoreEnvironment;
  /** Apple sandbox or Play license tester (RC7, RC63). */
  readonly isTest: boolean;
  readonly accountTokenMatch: boolean;
  readonly purchasedAt: string;
  readonly grantedAt: string;
}

export interface PurchaseRow extends Omit<NewPurchase, 'originalTxnId' | 'purchaseToken'> {
  readonly originalTxnId: string | null;
  readonly purchaseToken: string | null;
  readonly status: PurchaseStatus;
  readonly revokedAt: string | null;
}

interface RawPurchase {
  id: string;
  install_id: string;
  platform: Platform;
  product_id: string;
  store_txn_id: string;
  original_txn_id: string | null;
  purchase_token: string | null;
  credits: number;
  status: PurchaseStatus;
  environment: StoreEnvironment;
  is_test: number;
  account_token_match: number;
  purchased_at: string;
  granted_at: string;
  revoked_at: string | null;
}

export class PurchaseRepo {
  constructor(private readonly db: D1Database) {}

  /** Records a granted purchase; false when `(platform, store_txn_id)` or the token exists. */
  async insert(input: NewPurchase): Promise<boolean> {
    const result = await this.insertStmt(input).run();
    return result.meta.changes === 1;
  }

  /** `insert` for a batch with the ledger grant (`ON CONFLICT DO NOTHING`). */
  insertStmt(input: NewPurchase): D1PreparedStatement {
    return this.db
      .prepare(
        `INSERT INTO purchases
           (id, install_id, platform, product_id, store_txn_id, original_txn_id, purchase_token,
            credits, status, environment, is_test, account_token_match, purchased_at, granted_at)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, 'granted', ?9, ?10, ?11, ?12, ?13)
         ON CONFLICT DO NOTHING`,
      )
      .bind(
        input.id,
        input.installId,
        input.platform,
        input.productId,
        input.storeTxnId,
        input.originalTxnId ?? null,
        input.purchaseToken ?? null,
        input.credits,
        input.environment,
        input.isTest ? 1 : 0,
        input.accountTokenMatch ? 1 : 0,
        input.purchasedAt,
        input.grantedAt,
      );
  }

  async findById(id: string): Promise<PurchaseRow | null> {
    return this.first('id = ?1', [id]);
  }

  async findByStoreTxn(platform: Platform, storeTxnId: string): Promise<PurchaseRow | null> {
    return this.first('platform = ?1 AND store_txn_id = ?2', [platform, storeTxnId]);
  }

  async findByPurchaseToken(token: string): Promise<PurchaseRow | null> {
    return this.first('purchase_token = ?1', [token]);
  }

  /** `granted | reversal_regranted → revoked` (CAS); false if already revoked. */
  async markRevoked(id: string, revokedAt: string): Promise<boolean> {
    const result = await this.markRevokedStmt(id, revokedAt).run();
    return result.meta.changes === 1;
  }

  markRevokedStmt(id: string, revokedAt: string): D1PreparedStatement {
    return this.db
      .prepare(
        `UPDATE purchases SET status = 'revoked', revoked_at = ?2
          WHERE id = ?1 AND status <> 'revoked'`,
      )
      .bind(id, revokedAt);
  }

  /** `revoked → reversal_regranted` (CAS, 03 §6.5). */
  async markRegranted(id: string): Promise<boolean> {
    const result = await this.db
      .prepare(
        `UPDATE purchases SET status = 'reversal_regranted', revoked_at = NULL
          WHERE id = ?1 AND status = 'revoked'`,
      )
      .bind(id)
      .run();
    return result.meta.changes === 1;
  }

  /**
   * Credits granted by test purchases since `sinceIso` (RC63 sandbox caps):
   * for one install, or globally when `installId` is null.
   */
  async testCreditsSince(installId: string | null, sinceIso: string): Promise<number> {
    const row = await this.db
      .prepare(
        `SELECT COALESCE(SUM(credits), 0) AS total FROM purchases
          WHERE is_test = 1 AND granted_at >= ?1 AND (?2 IS NULL OR install_id = ?2)`,
      )
      .bind(sinceIso, installId)
      .first<{ total: number }>();
    return row?.total ?? 0;
  }

  private async first(where: string, values: readonly string[]): Promise<PurchaseRow | null> {
    const raw = await this.db
      .prepare(`SELECT * FROM purchases WHERE ${where}`)
      .bind(...values)
      .first<RawPurchase>();
    return raw === null ? null : toPurchase(raw);
  }
}

function toPurchase(raw: RawPurchase): PurchaseRow {
  return {
    id: raw.id,
    installId: raw.install_id,
    platform: raw.platform,
    productId: raw.product_id,
    storeTxnId: raw.store_txn_id,
    originalTxnId: raw.original_txn_id,
    purchaseToken: raw.purchase_token,
    credits: raw.credits,
    status: raw.status,
    environment: raw.environment,
    isTest: raw.is_test === 1,
    accountTokenMatch: raw.account_token_match === 1,
    purchasedAt: raw.purchased_at,
    grantedAt: raw.granted_at,
    revokedAt: raw.revoked_at,
  };
}
