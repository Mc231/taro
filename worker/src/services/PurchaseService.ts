import type { RuntimeConfig } from '../config/schema';
import { toHex } from '../crypto/encoding';
import type { Deps } from '../deps';
import type { BalanceDto } from '../domain/allowance';
import { STORE_APP_ID } from '../domain/appIds';
import type { Platform } from '../domain/types';
import { ApiError } from '../http/errors';
import type { ClientNetwork } from '../http/middleware/rateLimit';
import { inst8 } from '../logging/redact';
import { consumableProduct, type ConsumableProduct } from '../monetization/catalog';
import { createTransferToken, TRANSFER_TOKEN_TTL_SEC } from '../monetization/transferToken';
import type {
  AppleTransaction,
  PlayProductPurchase,
  PlayPurchaseRef,
  StoreLookupFailure,
} from '../ports/StoreApis';
import { InstallRepo, type InstallRow } from '../repos/InstallRepo';
import { LedgerRepo } from '../repos/LedgerRepo';
import { PendingAckRepo } from '../repos/PendingAckRepo';
import {
  PurchaseRepo,
  type NewPurchase,
  type PurchaseRow,
  type StoreEnvironment,
} from '../repos/PurchaseRepo';
import { BalanceService } from './BalanceService';

/** `POST /v1/purchases/verify` body (03 §6.2, §6.3; RC4): one route, `platform` discriminator. */
export type VerifyRequest =
  | {
      readonly platform: 'ios';
      /** Informational; the store's product ID wins. */
      readonly productId: string;
      readonly transactionId: string;
      /** StoreKit 2 JWS; proves the caller's store account for a transfer (RC85). */
      readonly signedTransaction?: string | undefined;
    }
  | {
      readonly platform: 'android';
      readonly productId: string;
      readonly purchaseToken: string;
      /** Informational; Google's `orderId` wins. */
      readonly orderId?: string | undefined;
    };

export interface VerifyGranted {
  readonly status: 'granted' | 'already_granted';
  readonly purchaseId: string;
  readonly productId: string;
  readonly creditsGranted: number;
  readonly isFirstPurchase: boolean;
  readonly balance: BalanceDto;
}

export type VerifyResult = VerifyGranted | { readonly status: 'pending' };

export interface VerifyOptions {
  readonly appVersion?: string | undefined;
  readonly network?: ClientNetwork | undefined;
}

/** `422 PURCHASE_INVALID` `details.reason` values (GLOSSARY §5.1). */
export type PurchaseInvalidReason =
  | 'not_found'
  | 'invalid_signature'
  | 'transaction_mismatch'
  | 'wrong_bundle'
  | 'not_consumable'
  | 'revoked'
  | 'environment'
  | 'cancelled'
  | 'invalid_state'
  | 'consumed'
  | 'sandbox_cap';

/** A verified store transaction, ready for the grant batch. */
interface Candidate {
  readonly platform: Platform;
  readonly product: ConsumableProduct;
  readonly credits: number;
  readonly storeTxnId: string;
  readonly originalTxnId: string | null;
  readonly purchaseToken: string | null;
  readonly environment: StoreEnvironment;
  readonly isTest: boolean;
  readonly accountTokenMatch: boolean;
  readonly purchasedAt: string;
}

type GrantOutcome =
  | { readonly kind: 'granted'; readonly purchase: NewPurchase; readonly isFirstPurchase: boolean }
  | { readonly kind: 'existing'; readonly row: PurchaseRow }
  | { readonly kind: 'sandbox_cap' };

/** Outcome of a webhook-driven grant: the `webhook_events.status` plus a log detail. */
export interface NotificationGrant {
  readonly status: 'processed' | 'ignored';
  readonly detail: string;
  /** The granted (or already granted) purchase. */
  readonly purchaseId?: string;
}

/** A verify-path rejection becomes an `ignored` webhook outcome. */
function ignoredBy(err: ApiError): NotificationGrant {
  const reason = err.options.details?.['reason'];
  return { status: 'ignored', detail: typeof reason === 'string' ? reason : err.code };
}

export function purchaseInvalid(reason: PurchaseInvalidReason): ApiError {
  return new ApiError('PURCHASE_INVALID', { details: { reason } });
}

/** Start of the UTC day of `now` (sandbox caps count per UTC day, RC63). */
export function utcDayStart(now: Date): string {
  return `${now.toISOString().slice(0, 10)}T00:00:00.000Z`;
}

function isoFromMillis(ms: number | null, fallback: Date): string {
  return new Date(ms ?? fallback.getTime()).toISOString();
}

function appleEnvironment(environment: string): StoreEnvironment | null {
  if (environment === 'Production') {
    return 'production';
  }
  return environment === 'Sandbox' ? 'sandbox' : null;
}

/**
 * Purchase verification and grant (03 §6.1–§6.3, BE8; RC4, RC9, RC10, RC63,
 * RC66, RC85). `verifyApple` and `verifyGoogle` check the transaction with
 * the store, then grant it in one D1 batch (`PurchaseRepo.grantBatch`):
 * exactly once per store transaction, first valid claim wins, a replay by
 * the same install is `already_granted`.
 *
 * - A blocked or indebted install is granted like any other (never 403,
 *   RC66); such grants emit `blocked_purchase`.
 * - Test purchases (Apple sandbox, Play license testers) are tagged
 *   `is_test` and capped per install and globally per UTC day inside the
 *   grant gate (`sandbox_cap`); half the global cap raises `sandbox_volume`.
 * - iOS binding (RC85): a transaction whose `appAccountToken` belongs to a
 *   different **active** install is never granted to the caller; it is
 *   granted to that install (the §6.4 `ONE_TIME_CHARGE` safety net) and the
 *   caller gets `409 PURCHASE_ALREADY_CLAIMED`.
 * - `409` carries `transferEligible` and a `transferToken` only when the
 *   caller proved the store account: on iOS a valid client `signedTransaction`
 *   of that transaction (an order ID or transaction ID alone is not proof,
 *   03 §6.6), on Android the purchase token itself.
 * - Google purchases are acknowledged server-side after the grant (RC10); a
 *   failed acknowledgement is recorded as `pendingAck` for the retry cron.
 */
export class PurchaseService {
  private readonly installs: InstallRepo;
  private readonly purchases: PurchaseRepo;
  private readonly ledger: LedgerRepo;
  private readonly pendingAcks: PendingAckRepo;

  constructor(
    private readonly deps: Deps,
    private readonly balances: BalanceService = new BalanceService(deps),
  ) {
    this.installs = new InstallRepo(deps.db);
    this.purchases = new PurchaseRepo(deps.db);
    this.ledger = new LedgerRepo(deps.db);
    this.pendingAcks = new PendingAckRepo(deps.cacheKv);
  }

  /**
   * Routes by platform and writes one `purchase_verify` metric per call
   * (`code` = `granted | already_granted | pending` or the lower-cased error
   * code; `internal` counts toward the verify error rate, 04 §12.3, §14).
   */
  async verify(
    install: InstallRow,
    request: VerifyRequest,
    options: VerifyOptions = {},
  ): Promise<VerifyResult> {
    const started = this.deps.clock.now().getTime();
    const record = (code: string): void => {
      this.deps.metrics.write({
        event: 'purchase_verify',
        platform: request.platform,
        code,
        latencyMs: Math.max(0, this.deps.clock.now().getTime() - started),
      });
    };
    try {
      const result =
        request.platform === 'ios'
          ? await this.verifyApple(install, request, options)
          : await this.verifyGoogle(install, request, options);
      record(result.status);
      return result;
    } catch (err) {
      record(err instanceof ApiError ? err.code.toLowerCase() : 'internal');
      throw err;
    }
  }

  /** iOS branch (03 §6.2). */
  async verifyApple(
    install: InstallRow,
    request: Extract<VerifyRequest, { platform: 'ios' }>,
    options: VerifyOptions = {},
  ): Promise<VerifyGranted> {
    const config = await this.deps.config.snapshot();
    const lookup = await this.deps.appStore.getTransaction(request.transactionId);
    if (!lookup.ok) {
      throw this.lookupFailed(lookup, 'ios');
    }
    const txn = lookup.transaction;
    if (txn.transactionId !== request.transactionId) {
      throw purchaseInvalid('transaction_mismatch');
    }
    const checked = this.appleCandidate(txn, config);
    if (checked instanceof ApiError) {
      throw checked;
    }
    const proven = await this.provesAppleAccount(request.signedTransaction, txn);
    const bound =
      txn.appAccountToken === null
        ? null
        : await this.installs.findByAppleAccountToken(txn.appAccountToken);
    const candidate: Candidate = { ...checked, accountTokenMatch: bound?.id === install.id };
    if (bound !== null && bound.id !== install.id && bound.status === 'active') {
      // RC85: bound to another active install. Never granted to the caller.
      const owner = await this.grant(bound, { ...candidate, accountTokenMatch: true }, config);
      const row =
        owner.kind === 'granted'
          ? await this.purchases.findById(owner.purchase.id)
          : owner.kind === 'existing'
            ? owner.row
            : null;
      this.deps.logger.log('warn', 'purchase_bound_elsewhere', {
        inst: inst8(install.id),
        owner: inst8(bound.id),
        platform: 'ios',
      });
      throw await this.alreadyClaimed(install, row, proven);
    }
    return this.settle(install, candidate, config, proven, options);
  }

  /** Android branch (03 §6.3). */
  async verifyGoogle(
    install: InstallRow,
    request: Extract<VerifyRequest, { platform: 'android' }>,
    options: VerifyOptions = {},
  ): Promise<VerifyResult> {
    const product = consumableProduct(request.productId);
    if (product === null) {
      throw new ApiError('PRODUCT_UNKNOWN');
    }
    const config = await this.deps.config.snapshot();
    const ref: PlayPurchaseRef = {
      packageName: STORE_APP_ID,
      productId: product.productId,
      purchaseToken: request.purchaseToken,
    };
    const lookup = await this.deps.playDeveloper.getProductPurchase(ref);
    if (!lookup.ok) {
      throw this.lookupFailed(lookup, 'android');
    }
    const purchase = lookup.purchase;
    if (purchase.purchaseState === 2) {
      this.deps.logger.log('info', 'purchase_pending', { inst: inst8(install.id) });
      return { status: 'pending' };
    }
    if (purchase.purchaseState === 1) {
      throw purchaseInvalid('cancelled');
    }
    if (purchase.purchaseState !== 0) {
      throw purchaseInvalid('invalid_state');
    }
    const known = await this.purchases.findByPurchaseToken(request.purchaseToken);
    if (known === null && purchase.consumptionState === 1) {
      throw purchaseInvalid('consumed');
    }
    const bindingMatches =
      purchase.obfuscatedExternalAccountId !== null &&
      purchase.obfuscatedExternalAccountId === install.playAccountHash;
    if (purchase.obfuscatedExternalAccountId !== null && !bindingMatches) {
      // RC9: logged and counted, never blocking on Android.
      this.deps.logger.log('warn', 'binding_mismatch', { inst: inst8(install.id) });
      this.deps.metrics.write({ event: 'binding_mismatch', platform: 'android' });
    }
    const candidate = await this.googleCandidate(product, ref, purchase, bindingMatches);
    const result = await this.settle(install, candidate, config, true, options);
    await this.acknowledge(purchase, ref, result.purchaseId);
    return result;
  }

  /**
   * App Store `ONE_TIME_CHARGE` safety net (03 §6.4): a verified transaction
   * whose `appAccountToken` maps to an install is granted to that install
   * through the same checks and grant batch as `verifyApple`. Anything the
   * verify route would reject is `ignored` (the webhook still answers 200).
   */
  async grantAppleNotification(txn: AppleTransaction): Promise<NotificationGrant> {
    const config = await this.deps.config.snapshot();
    const checked = this.appleCandidate(txn, config);
    if (checked instanceof ApiError) {
      return ignoredBy(checked);
    }
    const owner =
      txn.appAccountToken === null
        ? null
        : await this.installs.findByAppleAccountToken(txn.appAccountToken);
    if (owner === null) {
      return { status: 'ignored', detail: 'unbound' };
    }
    return this.grantNotification(owner, { ...checked, accountTokenMatch: true }, config);
  }

  /**
   * Play `ONE_TIME_PRODUCT_PURCHASED` (03 §6.4): verified with
   * `purchases.products.get` as in §6.3; when `obfuscatedExternalAccountId`
   * maps to an install and the purchase is not yet granted, it is granted to
   * that install and acknowledged. A store outage rejects (Pub/Sub retries).
   */
  async grantPlayNotification(
    purchaseToken: string,
    productId: string,
  ): Promise<NotificationGrant> {
    const product = consumableProduct(productId);
    if (product === null) {
      return { status: 'ignored', detail: 'product_unknown' };
    }
    const ref: PlayPurchaseRef = { packageName: STORE_APP_ID, productId, purchaseToken };
    const lookup = await this.deps.playDeveloper.getProductPurchase(ref);
    if (!lookup.ok) {
      if (lookup.reason === 'unavailable') {
        throw new Error('play developer api unavailable');
      }
      return { status: 'ignored', detail: lookup.reason };
    }
    const purchase = lookup.purchase;
    if (purchase.purchaseState !== 0) {
      return { status: 'ignored', detail: `state_${String(purchase.purchaseState)}` };
    }
    const known = await this.purchases.findByPurchaseToken(purchaseToken);
    if (known !== null) {
      await this.acknowledge(purchase, ref, known.id);
      return { status: 'processed', detail: 'already_granted' };
    }
    if (purchase.consumptionState === 1) {
      return { status: 'ignored', detail: 'consumed' };
    }
    const owner =
      purchase.obfuscatedExternalAccountId === null
        ? null
        : await this.installs.findByPlayAccountHash(purchase.obfuscatedExternalAccountId);
    if (owner === null) {
      return { status: 'ignored', detail: 'unbound' };
    }
    const config = await this.deps.config.snapshot();
    const candidate = await this.googleCandidate(product, ref, purchase, true);
    const outcome = await this.grantNotification(owner, candidate, config);
    if (outcome.purchaseId !== undefined) {
      await this.acknowledge(purchase, ref, outcome.purchaseId);
    }
    return outcome;
  }

  /**
   * Hourly retry of failed Google acknowledgements (03 §12, RC10): each
   * `ack:pending:{purchaseId}` marker is re-checked with the store and
   * acknowledged; the marker is cleared once acknowledged, consumed, revoked
   * or unknown. Returns the number of markers cleared.
   */
  async retryPendingAcks(limit: number): Promise<number> {
    let cleared = 0;
    for (const marker of await this.pendingAcks.list(limit)) {
      const row = await this.purchases.findById(marker.purchaseId);
      const purchaseToken = row?.purchaseToken ?? null;
      if (row === null || purchaseToken === null || row.status === 'revoked') {
        await this.pendingAcks.clear(marker.purchaseId);
        cleared++;
        continue;
      }
      const ref: PlayPurchaseRef = {
        packageName: STORE_APP_ID,
        productId: row.productId,
        purchaseToken,
      };
      const lookup = await this.deps.playDeveloper.getProductPurchase(ref);
      if (!lookup.ok && lookup.reason === 'unavailable') {
        continue;
      }
      const done =
        !lookup.ok ||
        lookup.purchase.acknowledgementState === 1 ||
        lookup.purchase.consumptionState === 1 ||
        (await this.deps.playDeveloper.acknowledge(ref));
      if (done) {
        await this.pendingAcks.clear(marker.purchaseId);
        cleared++;
      } else {
        this.deps.logger.log('warn', 'pending_ack_retry_failed', { purchaseId: row.id });
      }
    }
    return cleared;
  }

  /**
   * Checks shared by `verifyApple` and `ONE_TIME_CHARGE` (03 §6.2 step 3):
   * the candidate, or the `422` the verify route answers.
   */
  private appleCandidate(
    txn: AppleTransaction,
    config: RuntimeConfig,
  ): Omit<Candidate, 'accountTokenMatch'> | ApiError {
    if (!config['purchases.allowedBundleIds'].includes(txn.bundleId)) {
      return purchaseInvalid('wrong_bundle');
    }
    const product = consumableProduct(txn.productId);
    if (product === null) {
      return new ApiError('PRODUCT_UNKNOWN');
    }
    if (txn.type !== 'Consumable') {
      return purchaseInvalid('not_consumable');
    }
    if (txn.revocationDate !== null) {
      return purchaseInvalid('revoked');
    }
    const environment = appleEnvironment(txn.environment);
    if (environment === null) {
      return purchaseInvalid('environment');
    }
    return {
      platform: 'ios',
      product,
      credits: product.credits * txn.quantity,
      storeTxnId: txn.transactionId,
      originalTxnId: txn.originalTransactionId,
      purchaseToken: null,
      environment,
      isTest: environment === 'sandbox',
      purchasedAt: isoFromMillis(txn.purchaseDate, this.deps.clock.now()),
    };
  }

  /** The grant candidate of a purchased Play product (03 §6.3 step 3). */
  private async googleCandidate(
    product: ConsumableProduct,
    ref: PlayPurchaseRef,
    purchase: PlayProductPurchase,
    accountTokenMatch: boolean,
  ): Promise<Candidate> {
    const isTest = purchase.purchaseType === 0;
    return {
      platform: 'android',
      product,
      credits: product.credits * purchase.quantity,
      storeTxnId:
        purchase.orderId ?? `token:${toHex(await this.deps.crypto.sha256(ref.purchaseToken))}`,
      originalTxnId: null,
      purchaseToken: ref.purchaseToken,
      environment: isTest ? 'sandbox' : 'production',
      isTest,
      accountTokenMatch,
      purchasedAt: isoFromMillis(purchase.purchaseTimeMillis, this.deps.clock.now()),
    };
  }

  /** A webhook grant to the bound install: never a 409, only processed or ignored. */
  private async grantNotification(
    owner: InstallRow,
    candidate: Candidate,
    config: RuntimeConfig,
  ): Promise<NotificationGrant> {
    const outcome = await this.grant(owner, candidate, config);
    switch (outcome.kind) {
      case 'granted':
        this.deps.logger.log('info', 'purchase_granted_by_webhook', {
          inst: inst8(owner.id),
          platform: candidate.platform,
        });
        return { status: 'processed', detail: 'granted', purchaseId: outcome.purchase.id };
      case 'existing':
        return { status: 'processed', detail: 'already_granted', purchaseId: outcome.row.id };
      case 'sandbox_cap':
        return { status: 'ignored', detail: 'sandbox_cap' };
    }
  }

  /** Grants `candidate` to `install`, or answers from the stored grant; 409/422 otherwise. */
  private async settle(
    install: InstallRow,
    candidate: Candidate,
    config: RuntimeConfig,
    proven: boolean,
    options: VerifyOptions,
  ): Promise<VerifyGranted> {
    const outcome = await this.grant(install, candidate, config);
    switch (outcome.kind) {
      case 'granted':
        return {
          status: 'granted',
          purchaseId: outcome.purchase.id,
          productId: outcome.purchase.productId,
          creditsGranted: outcome.purchase.credits,
          isFirstPurchase: outcome.isFirstPurchase,
          balance: await this.balance(install.id, options),
        };
      case 'existing': {
        const row = outcome.row;
        if (row.installId !== install.id) {
          throw await this.alreadyClaimed(install, row, proven);
        }
        return {
          status: 'already_granted',
          purchaseId: row.id,
          productId: row.productId,
          creditsGranted: row.credits,
          isFirstPurchase: (await this.purchases.firstPurchaseId(install.id)) === row.id,
          balance: await this.balance(install.id, options),
        };
      }
      case 'sandbox_cap':
        this.deps.logger.log('warn', 'sandbox_cap', {
          inst: inst8(install.id),
          platform: candidate.platform,
          credits: candidate.credits,
        });
        throw purchaseInvalid('sandbox_cap');
    }
  }

  /** The grant batch (03 §6.2 step 4); on no insert, the existing row or the sandbox cap. */
  private async grant(
    install: InstallRow,
    candidate: Candidate,
    config: RuntimeConfig,
  ): Promise<GrantOutcome> {
    const now = this.deps.clock.now();
    const purchase: NewPurchase = {
      id: this.deps.ids.uuidV7(),
      installId: install.id,
      platform: candidate.platform,
      productId: candidate.product.productId,
      storeTxnId: candidate.storeTxnId,
      originalTxnId: candidate.originalTxnId,
      purchaseToken: candidate.purchaseToken,
      credits: candidate.credits,
      environment: candidate.environment,
      isTest: candidate.isTest,
      accountTokenMatch: candidate.accountTokenMatch,
      purchasedAt: candidate.purchasedAt,
      grantedAt: now.toISOString(),
    };
    const dayStart = utcDayStart(now);
    const results = await this.deps.db.batch(
      this.purchases.grantBatch(
        purchase,
        {
          dayStart,
          perInstall: config['purchases.sandboxMaxCreditsPerInstallPerDay'],
          global: config['purchases.sandboxGlobalCreditsPerDay'],
        },
        { ledger: this.ledger, installs: this.installs },
      ),
    );
    if (results[0]?.meta.changes === 1) {
      const first = results[3]?.results[0] as { id: string } | undefined;
      await this.afterGrant(install, purchase, config, dayStart);
      return { kind: 'granted', purchase, isFirstPurchase: first?.id === purchase.id };
    }
    const existing =
      (await this.purchases.findByStoreTxn(candidate.platform, candidate.storeTxnId)) ??
      (candidate.purchaseToken === null
        ? null
        : await this.purchases.findByPurchaseToken(candidate.purchaseToken));
    if (existing !== null) {
      return { kind: 'existing', row: existing };
    }
    if (!candidate.isTest) {
      throw new Error('purchase grant neither applied nor found');
    }
    return { kind: 'sandbox_cap' };
  }

  /** Metrics, logs and alerts of a new grant (03 §14.1, RC63, RC66). */
  private async afterGrant(
    install: InstallRow,
    purchase: NewPurchase,
    config: RuntimeConfig,
    dayStart: string,
  ): Promise<void> {
    const { metrics, logger } = this.deps;
    metrics.write({
      event: 'purchase_granted',
      platform: purchase.platform,
      credits: purchase.credits,
      code: purchase.environment,
    });
    logger.log('info', 'purchase_granted', {
      inst: inst8(install.id),
      platform: purchase.platform,
      productId: purchase.productId,
      credits: purchase.credits,
      environment: purchase.environment,
      isTest: purchase.isTest,
    });
    const paidBefore = (await this.ledger.balances(install.id)).paid - purchase.credits;
    if (install.status === 'blocked' || paidBefore < 0) {
      const reason = install.status === 'blocked' ? 'blocked' : 'refundDebt';
      metrics.write({ event: 'blocked_purchase', platform: purchase.platform, code: reason });
      logger.log('warn', 'blocked_purchase', { inst: inst8(install.id), reason });
      // 03 §6.5: such grants alert support, who may refund through the store.
      await this.deps.alerter.send({
        kind: 'blocked_purchase',
        message: `Purchase granted to a ${reason === 'blocked' ? 'blocked' : 'refund-debt'} install`,
        fields: { inst: inst8(install.id), reason, platform: purchase.platform },
      });
    }
    if (purchase.isTest) {
      metrics.write({
        event: 'sandbox_grant',
        platform: purchase.platform,
        credits: purchase.credits,
      });
      const cap = config['purchases.sandboxGlobalCreditsPerDay'];
      const today = await this.purchases.testCreditsSince(null, dayStart);
      if (today * 2 >= cap) {
        await this.deps.alerter.send({
          kind: 'sandbox_volume',
          message: `Sandbox/test grants today: ${String(today)} of ${String(cap)} credits`,
          fields: { credits: today, cap },
        });
      }
    }
  }

  /** Google acknowledgement after the grant (RC10); a failure is a `pendingAck`. */
  private async acknowledge(
    purchase: PlayProductPurchase,
    ref: PlayPurchaseRef,
    purchaseId: string,
  ): Promise<void> {
    if (purchase.acknowledgementState !== 0) {
      return;
    }
    if (await this.deps.playDeveloper.acknowledge(ref)) {
      return;
    }
    this.deps.logger.log('warn', 'pending_ack', { purchaseId });
    await this.pendingAcks.mark(purchaseId, this.deps.clock.now().toISOString());
  }

  /** A client JWS of the same transaction proves the store account (03 §6.6). */
  private async provesAppleAccount(
    signedTransaction: string | undefined,
    txn: AppleTransaction,
  ): Promise<boolean> {
    if (signedTransaction === undefined || signedTransaction === '') {
      return false;
    }
    const client = await this.deps.appStore.verifySignedTransaction(signedTransaction);
    return client.ok && client.transaction.transactionId === txn.transactionId;
  }

  /** `409 PURCHASE_ALREADY_CLAIMED`, with a `transferToken` when the caller proved the account. */
  private async alreadyClaimed(
    install: InstallRow,
    row: PurchaseRow | null,
    proven: boolean,
  ): Promise<ApiError> {
    this.deps.logger.log('info', 'purchase_already_claimed', {
      inst: inst8(install.id),
      owner: inst8(row?.installId),
      proven,
    });
    const token = row !== null && proven ? await this.transferToken(row.id, install.id) : null;
    return new ApiError('PURCHASE_ALREADY_CLAIMED', {
      details:
        token === null
          ? { transferEligible: false }
          : { transferEligible: true, transferToken: token },
    });
  }

  private async transferToken(purchaseId: string, newInstallId: string): Promise<string | null> {
    let key: Uint8Array;
    try {
      key = this.deps.keys.transferToken();
    } catch {
      this.deps.logger.log('error', 'transfer_token_unavailable', {});
      return null;
    }
    const expiresAt = Math.floor(this.deps.clock.now().getTime() / 1000) + TRANSFER_TOKEN_TTL_SEC;
    return createTransferToken(this.deps.crypto, key, { purchaseId, newInstallId, expiresAt });
  }

  private lookupFailed(failure: StoreLookupFailure, platform: Platform): ApiError {
    if (failure.reason === 'not_found') {
      return purchaseInvalid('not_found');
    }
    if (failure.reason === 'invalid') {
      return purchaseInvalid('invalid_signature');
    }
    this.deps.logger.log('warn', 'purchase_store_unavailable', {
      platform,
      detail: failure.detail ?? 'unknown',
    });
    return new ApiError('INTERNAL');
  }

  private async balance(installId: string, options: VerifyOptions): Promise<BalanceDto> {
    const balance = await this.balances.read(installId, options);
    if (balance === null) {
      throw new ApiError('UNAUTHENTICATED');
    }
    return balance;
  }
}
