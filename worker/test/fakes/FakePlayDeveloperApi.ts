import type {
  PlayDeveloperApi,
  PlayProductPurchase,
  PlayPurchaseRef,
  PlayVoidedPurchase,
  StoreLookupFailure,
} from '../../src/ports/StoreApis';

interface Entry {
  productId: string;
  purchase: PlayProductPurchase;
}

/**
 * Scriptable Google Play Developer API (03 §15.3, GLOSSARY §9.2): purchases
 * by token (states 0/1/2, consumed, test), acknowledgement recording or
 * failure, and a voided-purchases list.
 */
export class FakePlayDeveloperApi implements PlayDeveloperApi {
  readonly purchases = new Map<string, Entry>();
  readonly lookups: PlayPurchaseRef[] = [];
  readonly acks: PlayPurchaseRef[] = [];
  readonly voided: PlayVoidedPurchase[] = [];
  /** When set, every `getProductPurchase` / `listVoidedPurchases` fails with this reason. */
  failure: StoreLookupFailure['reason'] | null = null;
  /** When true, `acknowledge` fails (a `pendingAck`). */
  ackFails = false;

  /** Adds a purchased, unconsumed, unacknowledged `readings_3` purchase with overrides. */
  add(
    purchaseToken: string,
    overrides: Partial<PlayProductPurchase> & { readonly productId?: string } = {},
  ): PlayProductPurchase {
    const { productId = 'com.vshyrochuk.taro.readings_3', ...fields } = overrides;
    const purchase: PlayProductPurchase = {
      purchaseState: 0,
      consumptionState: 0,
      acknowledgementState: 0,
      orderId: `GPA.${purchaseToken}`,
      purchaseTimeMillis: Date.parse('2026-09-26T09:59:00Z'),
      purchaseType: null,
      obfuscatedExternalAccountId: null,
      quantity: 1,
      ...fields,
    };
    this.purchases.set(purchaseToken, { productId, purchase });
    return purchase;
  }

  getProductPurchase(
    ref: PlayPurchaseRef,
  ): Promise<{ readonly ok: true; readonly purchase: PlayProductPurchase } | StoreLookupFailure> {
    this.lookups.push(ref);
    if (this.failure !== null) {
      return Promise.resolve({ ok: false, reason: this.failure });
    }
    const entry = this.purchases.get(ref.purchaseToken);
    return Promise.resolve(
      entry?.productId === ref.productId
        ? { ok: true, purchase: { ...entry.purchase } }
        : { ok: false, reason: 'not_found' },
    );
  }

  acknowledge(ref: PlayPurchaseRef): Promise<boolean> {
    this.acks.push(ref);
    const entry = this.purchases.get(ref.purchaseToken);
    if (this.ackFails || entry === undefined) {
      return Promise.resolve(false);
    }
    entry.purchase = { ...entry.purchase, acknowledgementState: 1 };
    return Promise.resolve(true);
  }

  listVoidedPurchases(input: {
    readonly packageName: string;
    readonly startTimeMillis: number;
  }): Promise<
    | {
        readonly ok: true;
        readonly purchases: readonly PlayVoidedPurchase[];
        readonly nextPageToken: string | null;
      }
    | StoreLookupFailure
  > {
    if (this.failure !== null) {
      return Promise.resolve({ ok: false, reason: this.failure });
    }
    return Promise.resolve({
      ok: true,
      purchases: this.voided.filter((v) => (v.voidedTimeMillis ?? 0) >= input.startTimeMillis),
      nextPageToken: null,
    });
  }
}
