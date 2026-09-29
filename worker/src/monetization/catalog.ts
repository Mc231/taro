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
