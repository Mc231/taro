import { describe, expect, it } from 'vitest';
import { DEFAULT_PUBLIC_CONFIG } from '../../../src/config/defaults';
import { buildPublicConfigDto } from '../../../src/config/publicDto';
import {
  consumableProduct,
  PACK_PRODUCT_IDS,
  PRODUCT_CATALOG,
  productIdsFixture,
  type CatalogEntry,
} from '../../../src/monetization/catalog';

/** `PRODUCT_CATALOG` (04 MO2, §4, §15; 03 §6.1; RC3). */
describe('PRODUCT_CATALOG', () => {
  it('holds the four RC3 products; credits only on consumables', () => {
    expect(PRODUCT_CATALOG).toEqual({
      'com.vshyrochuk.taro.readings_3': { kind: 'consumable', credits: 3 },
      'com.vshyrochuk.taro.readings_10': { kind: 'consumable', credits: 10 },
      'com.vshyrochuk.taro.readings_30': { kind: 'consumable', credits: 30 },
      'com.vshyrochuk.taro.remove_ads': { kind: 'non_consumable' },
    });
  });

  it('resolves verifiable consumables; Remove Ads and unknown IDs are PRODUCT_UNKNOWN', () => {
    expect(consumableProduct('com.vshyrochuk.taro.readings_10')).toEqual({
      productId: 'com.vshyrochuk.taro.readings_10',
      credits: 10,
      retired: false,
    });
    expect(consumableProduct('com.vshyrochuk.taro.remove_ads')).toBeNull();
    expect(consumableProduct('com.vshyrochuk.taro.readings_5')).toBeNull();
    expect(consumableProduct('toString')).toBeNull();
  });

  it('still verifies a retired product (03 §6.1: not offered, old transactions verify)', () => {
    const catalog: Record<string, CatalogEntry> = {
      ...PRODUCT_CATALOG,
      'com.vshyrochuk.taro.readings_5': { kind: 'consumable', credits: 5, retired: true },
    };
    expect(consumableProduct('com.vshyrochuk.taro.readings_5', catalog)).toEqual({
      productId: 'com.vshyrochuk.taro.readings_5',
      credits: 5,
      retired: true,
    });
    expect(productIdsFixture(catalog).products).toContainEqual({
      id: 'com.vshyrochuk.taro.readings_5',
      kind: 'consumable',
      retired: true,
    });
  });

  it('agrees with the public config: every offered pack is an active consumable with catalog credits', () => {
    const dto = buildPublicConfigDto(DEFAULT_PUBLIC_CONFIG);
    for (const pack of dto['store.packs']) {
      const product = consumableProduct(pack.productId);
      expect(product, pack.productId).not.toBeNull();
      expect(product?.retired).toBe(false);
      expect(pack.credits).toBe(product?.credits);
    }
    const consumables = Object.entries(PRODUCT_CATALOG as Record<string, CatalogEntry>)
      .filter(([, entry]) => entry.kind === 'consumable' && entry.retired !== true)
      .map(([id]) => id)
      .sort();
    expect([...PACK_PRODUCT_IDS].sort()).toEqual(consumables);
  });

  it('exports test/fixtures/product_ids.json for the Dart TaroProducts test (04 §15)', async () => {
    await expect(`${JSON.stringify(productIdsFixture(), null, 2)}\n`).toMatchFileSnapshot(
      '../../fixtures/product_ids.json',
    );
  });
});
