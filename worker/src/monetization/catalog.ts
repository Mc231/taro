/**
 * `PRODUCT_CATALOG` (04 MO2, 03 §6.1, RC3; GLOSSARY §3). Credits per product
 * live here and nowhere else: remote config only enables and orders packs
 * (`store.packs[]`), and `GET /v1/config` injects `credits` from this table.
 * A size change means a new product ID; a retired product stays here with
 * `retired: true` (not offered, still verifiable). `check_iap_ids.py` and
 * `check_glossary.py` parse the object literal below.
 */
export type ProductKind = 'consumable' | 'non_consumable';

export interface CatalogEntry {
  readonly kind: ProductKind;
  /** Readings granted; only consumables have credits. */
  readonly credits?: number;
  readonly retired?: boolean;
}

export const PRODUCT_CATALOG = {
  'com.vshyrochuk.taro.readings_3': { kind: 'consumable', credits: 3 },
  'com.vshyrochuk.taro.readings_10': { kind: 'consumable', credits: 10 },
  'com.vshyrochuk.taro.readings_30': { kind: 'consumable', credits: 30 },
  'com.vshyrochuk.taro.remove_ads': { kind: 'non_consumable' },
} as const satisfies Readonly<Record<string, CatalogEntry>>;

export type ProductId = keyof typeof PRODUCT_CATALOG;

/** Consumable product IDs a `store.packs[]` entry may name (not retired). */
export const PACK_PRODUCT_IDS = [
  'com.vshyrochuk.taro.readings_3',
  'com.vshyrochuk.taro.readings_10',
  'com.vshyrochuk.taro.readings_30',
] as const satisfies readonly ProductId[];

export type PackProductId = (typeof PACK_PRODUCT_IDS)[number];

/** Credits granted for a consumable pack. */
export function packCredits(productId: PackProductId): number {
  return PRODUCT_CATALOG[productId].credits;
}

/** A verifiable consumable (active or retired) and the credits it grants per unit. */
export interface ConsumableProduct {
  readonly productId: string;
  readonly credits: number;
  readonly retired: boolean;
}

/**
 * The catalog consumable for a store product ID (03 §6.2 step 3), active or
 * retired (a retired product is not offered but its old transactions still
 * verify); null for Remove Ads or an unknown ID (`422 PRODUCT_UNKNOWN`).
 */
export function consumableProduct(
  productId: string,
  catalog: Readonly<Record<string, CatalogEntry>> = PRODUCT_CATALOG,
): ConsumableProduct | null {
  const entry = Object.hasOwn(catalog, productId) ? catalog[productId] : undefined;
  return entry?.kind === 'consumable' && entry.credits !== undefined
    ? { productId, credits: entry.credits, retired: entry.retired === true }
    : null;
}

/** `test/fixtures/product_ids.json`: IDs and kinds only, for the Dart `TaroProducts` test (04 §15). */
export interface ProductIdsFixture {
  readonly products: readonly {
    readonly id: string;
    readonly kind: ProductKind;
    readonly retired: boolean;
  }[];
}

export function productIdsFixture(
  catalog: Readonly<Record<string, CatalogEntry>> = PRODUCT_CATALOG,
): ProductIdsFixture {
  return {
    products: Object.entries(catalog)
      .map(([id, entry]: [string, CatalogEntry]) => ({
        id,
        kind: entry.kind,
        retired: entry.retired === true,
      }))
      .sort((a, b) => a.id.localeCompare(b.id)),
  };
}
