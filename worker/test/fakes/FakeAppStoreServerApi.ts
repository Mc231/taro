import type {
  AppleConsumptionInfo,
  AppleNotification,
  AppleNotificationResult,
  AppleTransaction,
  AppleTransactionResult,
  AppStoreServerApi,
  StoreLookupFailure,
} from '../../src/ports/StoreApis';

/** Client `signedTransaction` accepted by the fake: `fake-jws:{transactionId}`. */
export const FAKE_JWS_PREFIX = 'fake-jws:';
/** ASSN v2 `signedPayload` accepted by the fake: `fake-ntf:{JSON of AppleNotification}`. */
export const FAKE_NOTIFICATION_PREFIX = 'fake-ntf:';

export interface ConsumptionCall {
  readonly transactionId: string;
  readonly environment: 'production' | 'sandbox';
  readonly info: AppleConsumptionInfo;
}

/**
 * Scriptable App Store Server API (03 §15.3, GLOSSARY §9.2): transactions by
 * ID, a forced failure, and client JWS values of the form
 * `fake-jws:{transactionId}`. The real adapter's JWS and HTTP behaviour is
 * covered by its own tests with a generated CA and a stubbed `fetch`.
 */
export class FakeAppStoreServerApi implements AppStoreServerApi {
  readonly transactions = new Map<string, AppleTransaction>();
  readonly lookups: string[] = [];
  /** When set, every `getTransaction` fails with this reason. */
  failure: StoreLookupFailure['reason'] | null = null;
  readonly consumptionCalls: ConsumptionCall[] = [];
  /** When true, `sendConsumptionInfo` fails. */
  consumptionFails = false;

  /** Adds a consumable transaction (defaults: `readings_3`, production, prod bundle). */
  add(overrides: Partial<AppleTransaction> & { readonly transactionId: string }): AppleTransaction {
    const transaction: AppleTransaction = {
      originalTransactionId: overrides.transactionId,
      bundleId: 'com.vshyrochuk.taro',
      productId: 'com.vshyrochuk.taro.readings_3',
      type: 'Consumable',
      environment: 'Production',
      appAccountToken: null,
      purchaseDate: Date.parse('2026-09-26T09:59:00Z'),
      revocationDate: null,
      quantity: 1,
      ...overrides,
    };
    this.transactions.set(transaction.transactionId, transaction);
    return transaction;
  }

  /** The client JWS the fake accepts for a known transaction. */
  static signed(transactionId: string): string {
    return `${FAKE_JWS_PREFIX}${transactionId}`;
  }

  /** A `signedPayload` the fake verifies (defaults: `TEST`, no data). */
  static notification(
    fields: Partial<AppleNotification> & { readonly notificationUUID: string },
  ): string {
    const notification: AppleNotification = {
      notificationType: 'TEST',
      subtype: null,
      bundleId: 'com.vshyrochuk.taro',
      environment: 'Production',
      signedTransactionInfo: null,
      consumptionRequestReason: null,
      ...fields,
    };
    return `${FAKE_NOTIFICATION_PREFIX}${JSON.stringify(notification)}`;
  }

  verifyNotification(signedPayload: string): Promise<AppleNotificationResult> {
    if (!signedPayload.startsWith(FAKE_NOTIFICATION_PREFIX)) {
      return Promise.resolve({ ok: false, reason: 'invalid' });
    }
    const notification = JSON.parse(
      signedPayload.slice(FAKE_NOTIFICATION_PREFIX.length),
    ) as AppleNotification;
    return Promise.resolve({ ok: true, notification });
  }

  sendConsumptionInfo(
    transactionId: string,
    environment: 'production' | 'sandbox',
    info: AppleConsumptionInfo,
  ): Promise<boolean> {
    this.consumptionCalls.push({ transactionId, environment, info });
    return Promise.resolve(!this.consumptionFails);
  }

  getTransaction(transactionId: string): Promise<AppleTransactionResult> {
    this.lookups.push(transactionId);
    if (this.failure !== null) {
      return Promise.resolve({ ok: false, reason: this.failure });
    }
    return Promise.resolve(this.result(transactionId, 'not_found'));
  }

  verifySignedTransaction(jws: string): Promise<AppleTransactionResult> {
    return Promise.resolve(
      jws.startsWith(FAKE_JWS_PREFIX)
        ? this.result(jws.slice(FAKE_JWS_PREFIX.length), 'invalid')
        : { ok: false, reason: 'invalid' },
    );
  }

  private result(
    transactionId: string,
    missing: StoreLookupFailure['reason'],
  ): AppleTransactionResult {
    const transaction = this.transactions.get(transactionId);
    return transaction === undefined ? { ok: false, reason: missing } : { ok: true, transaction };
  }
}
