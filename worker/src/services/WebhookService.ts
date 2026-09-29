import type { RuntimeConfig } from '../config/schema';
import { fromBase64, fromUtf8 } from '../crypto/encoding';
import type { Deps } from '../deps';
import { STORE_APP_ID } from '../domain/appIds';
import type { AppleConsumptionInfo, AppleNotification, AppleTransaction } from '../ports/StoreApis';
import { LedgerRepo } from '../repos/LedgerRepo';
import { PurchaseRepo, type PurchaseRow } from '../repos/PurchaseRepo';
import {
  WebhookEventRepo,
  type WebhookSource,
  type WebhookStatus,
} from '../repos/WebhookEventRepo';
import { PurchaseService } from './PurchaseService';
import { RefundService } from './RefundService';

/** Outcome of one notification: the `webhook_events.status` plus a log detail. */
export interface WebhookOutcome {
  readonly status: WebhookStatus;
  readonly detail: string;
}

/** `POST /v1/webhooks/appstore` result: 400 only for a bad signature (03 §6.4). */
export type AppStoreWebhookResult = 'accepted' | 'bad_signature';

/** The Pub/Sub push envelope (`message.data` is base64 JSON of a `DeveloperNotification`). */
export interface PubsubPushMessage {
  readonly messageId: string;
  readonly data?: string | undefined;
}

/** RTDN `oneTimeProductNotification.notificationType` (03 §6.4). */
export const ONE_TIME_PRODUCT_PURCHASED = 1;
/** RTDN `voidedPurchaseNotification.productType` of a subscription (never ours). */
const PRODUCT_TYPE_SUBSCRIPTION = 1;
/** The Voided Purchases backstop looks back two days (03 §6.4). */
export const VOIDED_LOOKBACK_MS = 2 * 24 * 3600 * 1000;

function ignored(detail: string): WebhookOutcome {
  return { status: 'ignored', detail };
}

function processed(detail: string): WebhookOutcome {
  return { status: 'processed', detail };
}

function record(value: unknown): Record<string, unknown> | null {
  return value !== null && typeof value === 'object' && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : null;
}

function text(value: unknown): string | null {
  return typeof value === 'string' && value !== '' ? value : null;
}

/** `CONSUMPTION_REQUEST` figure: how much of the purchase's credits the paid bucket still holds. */
export function consumptionStatus(
  paid: number,
  credits: number,
): AppleConsumptionInfo['consumptionStatus'] {
  if (paid >= credits) {
    return 1;
  }
  return paid <= 0 ? 3 : 2;
}

/**
 * Store webhooks and the Voided Purchases backstop (03 §6.4–§6.5, §12; MO16,
 * RC66). Every notification is verified first (Apple JWS, Pub/Sub OIDC),
 * then deduped on its ID in `webhook_events` (`notificationUUID`,
 * `messageId`): a delivery already `processed` or `ignored` changes nothing;
 * a `failed` one (an exception, answered with 500 so the store retries) runs
 * again. Refunds go through `RefundService`, grants through
 * `PurchaseService`, and every handler is itself idempotent, so two racing
 * deliveries of the same event still move the ledger once.
 */
export class WebhookService {
  private readonly events: WebhookEventRepo;
  private readonly purchases: PurchaseRepo;
  private readonly ledger: LedgerRepo;
  private readonly refunds: RefundService;
  private readonly purchaseService: PurchaseService;

  constructor(private readonly deps: Deps) {
    this.events = new WebhookEventRepo(deps.db);
    this.purchases = new PurchaseRepo(deps.db);
    this.ledger = new LedgerRepo(deps.db);
    this.refunds = new RefundService(deps);
    this.purchaseService = new PurchaseService(deps);
  }

  /** App Store Server Notifications v2 (`signedPayload` + inner `signedTransactionInfo`). */
  async handleAppStore(signedPayload: string): Promise<AppStoreWebhookResult> {
    const verified = await this.deps.appStore.verifyNotification(signedPayload);
    if (!verified.ok) {
      this.signatureFailed('apple', 'payload');
      return 'bad_signature';
    }
    const notification = verified.notification;
    let txn: AppleTransaction | null = null;
    if (notification.signedTransactionInfo !== null) {
      const inner = await this.deps.appStore.verifySignedTransaction(
        notification.signedTransactionInfo,
      );
      if (!inner.ok) {
        this.signatureFailed('apple', 'transaction');
        return 'bad_signature';
      }
      txn = inner.transaction;
    }
    await this.once('apple', notification.notificationUUID, notification.notificationType, () =>
      this.dispatchApple(notification, txn),
    );
    return 'accepted';
  }

  /**
   * Pub/Sub push authentication (03 §6.4): `Authorization: Bearer <OIDC JWT>`
   * with `aud == GOOGLE_PUBSUB_AUDIENCE` and `email == GOOGLE_PUBSUB_SA`.
   * Without those secrets every push is refused.
   */
  async authorizePlayPush(authorization: string | undefined): Promise<boolean> {
    const { audience, email } = this.deps.pubsubPush;
    if (audience === undefined || email === undefined) {
      this.deps.logger.log('error', 'pubsub_push_unconfigured', {});
      return false;
    }
    const match = /^Bearer\s+(\S+)$/i.exec(authorization ?? '');
    const valid =
      match?.[1] !== undefined &&
      (await this.deps.googleOidc.verify(match[1], { audience, email }));
    if (!valid) {
      this.signatureFailed('google', 'oidc');
    }
    return valid;
  }

  /** Google Play RTDN delivered by Pub/Sub push (already authorised). */
  async handlePlay(message: PubsubPushMessage): Promise<void> {
    const notification = this.decodeRtdn(message.data);
    const type = notification === null ? 'undecodable' : rtdnType(notification);
    await this.once('google', message.messageId, type, () =>
      notification === null
        ? Promise.resolve(ignored('undecodable'))
        : this.dispatchPlay(notification),
    );
  }

  /**
   * Daily Voided Purchases backstop (03 §6.4, §12): pages through
   * `purchases.voidedpurchases.list` (`type=0`) for the last two days and
   * revokes every voided purchase not revoked yet. Returns the number revoked.
   * A store failure rejects (the cron logs it; tomorrow's run overlaps).
   */
  async voidedBackstop(now: Date, maxPages: number): Promise<number> {
    let revoked = 0;
    let pageToken: string | undefined;
    for (let page = 0; page < maxPages; page++) {
      const result = await this.deps.playDeveloper.listVoidedPurchases({
        packageName: STORE_APP_ID,
        startTimeMillis: now.getTime() - VOIDED_LOOKBACK_MS,
        endTimeMillis: now.getTime(),
        ...(pageToken === undefined ? {} : { pageToken }),
      });
      if (!result.ok) {
        throw new Error(`voided purchases: ${result.reason}`);
      }
      for (const voided of result.purchases) {
        const purchase = await this.findPlayPurchase(voided.purchaseToken, voided.orderId);
        if (purchase !== null && (await this.refunds.revoke(purchase, 'voided_backstop')).revoked) {
          revoked++;
        }
      }
      if (result.nextPageToken === null) {
        break;
      }
      pageToken = result.nextPageToken;
    }
    return revoked;
  }

  private async dispatchApple(
    notification: AppleNotification,
    txn: AppleTransaction | null,
  ): Promise<WebhookOutcome> {
    const config = await this.deps.config.snapshot();
    if (
      notification.bundleId !== null &&
      !config['purchases.allowedBundleIds'].includes(notification.bundleId)
    ) {
      return ignored('wrong_bundle');
    }
    switch (notification.notificationType) {
      case 'TEST':
        this.deps.logger.log('info', 'appstore_test_notification', {});
        return processed('test');
      case 'REFUND':
        return this.withApplePurchase(txn, async (purchase) => {
          const result = await this.refunds.revoke(purchase, 'apple');
          return processed(result.revoked ? 'revoked' : 'already_revoked');
        });
      case 'REFUND_REVERSED':
        return this.withApplePurchase(txn, async (purchase) =>
          processed((await this.refunds.regrant(purchase)) ? 'regranted' : 'not_revoked'),
        );
      case 'ONE_TIME_CHARGE':
        return txn === null
          ? ignored('no_transaction')
          : this.purchaseService.grantAppleNotification(txn);
      case 'CONSUMPTION_REQUEST':
        return this.consumptionRequest(notification, txn, config);
      default:
        return ignored('unhandled_type');
    }
  }

  /** `CONSUMPTION_REQUEST`: answered only when `purchases.apple.sendConsumptionInfo` (BE Q4). */
  private async consumptionRequest(
    notification: AppleNotification,
    txn: AppleTransaction | null,
    config: RuntimeConfig,
  ): Promise<WebhookOutcome> {
    if (!config['purchases.apple.sendConsumptionInfo']) {
      return ignored('consumption_info_disabled');
    }
    return this.withApplePurchase(txn, async (purchase, transaction) => {
      if (transaction.appAccountToken === null) {
        return ignored('unbound');
      }
      const { paid } = await this.ledger.balances(purchase.installId);
      const sent = await this.deps.appStore.sendConsumptionInfo(
        transaction.transactionId,
        notification.environment === 'Sandbox' ? 'sandbox' : 'production',
        {
          consumptionStatus: consumptionStatus(paid, purchase.credits),
          deliveryStatus: 0,
          appAccountToken: transaction.appAccountToken,
        },
      );
      if (!sent) {
        throw new Error('consumption info not sent');
      }
      return processed('consumption_info_sent');
    });
  }

  private async withApplePurchase(
    txn: AppleTransaction | null,
    handle: (purchase: PurchaseRow, txn: AppleTransaction) => Promise<WebhookOutcome>,
  ): Promise<WebhookOutcome> {
    if (txn === null) {
      return ignored('no_transaction');
    }
    const purchase = await this.purchases.findByStoreTxn('ios', txn.transactionId);
    return purchase === null ? ignored('unknown_purchase') : handle(purchase, txn);
  }

  private async dispatchPlay(notification: Record<string, unknown>): Promise<WebhookOutcome> {
    if (notification['packageName'] !== STORE_APP_ID) {
      return ignored('wrong_package');
    }
    const voided = record(notification['voidedPurchaseNotification']);
    if (voided !== null) {
      if (voided['productType'] === PRODUCT_TYPE_SUBSCRIPTION) {
        return ignored('subscription');
      }
      const purchase = await this.findPlayPurchase(
        text(voided['purchaseToken']),
        text(voided['orderId']),
      );
      if (purchase === null) {
        return ignored('unknown_purchase');
      }
      const result = await this.refunds.revoke(purchase, 'google');
      return processed(result.revoked ? 'revoked' : 'already_revoked');
    }
    const oneTime = record(notification['oneTimeProductNotification']);
    if (oneTime !== null) {
      const token = text(oneTime['purchaseToken']);
      const sku = text(oneTime['sku']);
      if (oneTime['notificationType'] !== ONE_TIME_PRODUCT_PURCHASED) {
        return ignored('one_time_canceled');
      }
      return token === null || sku === null
        ? ignored('malformed')
        : this.purchaseService.grantPlayNotification(token, sku);
    }
    if (record(notification['testNotification']) !== null) {
      this.deps.logger.log('info', 'googleplay_test_notification', {});
      return processed('test');
    }
    return ignored('unhandled_type');
  }

  private async findPlayPurchase(
    purchaseToken: string | null,
    orderId: string | null,
  ): Promise<PurchaseRow | null> {
    const byToken =
      purchaseToken === null ? null : await this.purchases.findByPurchaseToken(purchaseToken);
    if (byToken !== null || orderId === null) {
      return byToken;
    }
    return this.purchases.findByStoreTxn('android', orderId);
  }

  private decodeRtdn(data: string | undefined): Record<string, unknown> | null {
    try {
      return record(JSON.parse(fromUtf8(fromBase64(data ?? ''))));
    } catch {
      return null;
    }
  }

  /** Dedupe + outcome bookkeeping around one handler (03 §4 `webhook_events`). */
  private async once(
    source: WebhookSource,
    id: string,
    type: string,
    handle: () => Promise<WebhookOutcome>,
  ): Promise<void> {
    const seen = await this.events.find(id);
    if (seen !== null && seen.status !== 'failed') {
      this.deps.logger.log('info', 'webhook_duplicate', { source, type, status: seen.status });
      return;
    }
    const receivedAt = this.deps.clock.now().toISOString();
    let outcome: WebhookOutcome;
    try {
      outcome = await handle();
    } catch (err) {
      await this.events.save({ id, source, type, status: 'failed', receivedAt });
      this.deps.logger.log('error', 'webhook_failed', {
        source,
        type,
        error: (err as Error).name,
      });
      throw err;
    }
    await this.events.save({ id, source, type, status: outcome.status, receivedAt });
    this.deps.logger.log('info', 'webhook_handled', {
      source,
      type,
      status: outcome.status,
      detail: outcome.detail,
    });
  }

  private signatureFailed(source: WebhookSource, part: string): void {
    this.deps.metrics.write({ event: 'webhook_sig_failed', code: `${source}:${part}` });
    this.deps.logger.log('warn', 'webhook_sig_failed', { source, part });
  }
}

/** The `webhook_events.type` of an RTDN (its notification kind). */
function rtdnType(notification: Record<string, unknown>): string {
  const oneTime = record(notification['oneTimeProductNotification']);
  if (oneTime !== null) {
    return oneTime['notificationType'] === ONE_TIME_PRODUCT_PURCHASED
      ? 'ONE_TIME_PRODUCT_PURCHASED'
      : 'ONE_TIME_PRODUCT_CANCELED';
  }
  for (const key of [
    'voidedPurchaseNotification',
    'testNotification',
    'subscriptionNotification',
  ]) {
    if (record(notification[key]) !== null) {
      return key;
    }
  }
  return 'unknown';
}
