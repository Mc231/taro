import { packCredits, type PackProductId } from '../monetization/catalog';
import type { PublicConfig } from './schema';

export interface StorePackDto {
  readonly productId: PackProductId;
  readonly enabled: boolean;
  readonly sortOrder: number;
  /** Read-only, from `PRODUCT_CATALOG` (03 §6.1, RC3); never stored in KV. */
  readonly credits: number;
}

/** `PublicConfigDto` (03 §8, GLOSSARY §8.1): `config:public` with pack credits injected. */
export type PublicConfigDto = Omit<PublicConfig, 'store.packs'> & {
  readonly 'store.packs': readonly StorePackDto[];
};

export function buildPublicConfigDto(config: PublicConfig): PublicConfigDto {
  return {
    ...config,
    'store.packs': config['store.packs'].map((pack) => ({
      ...pack,
      credits: packCredits(pack.productId),
    })),
  };
}

/** Strong ETag of a public config version (03 §8.1). */
export function configEtag(version: number): string {
  return `"v${String(version)}"`;
}

/**
 * `If-None-Match` matches when it lists the ETag (weak or strong, RFC 9110
 * weak comparison) or is `*`.
 */
export function ifNoneMatchHits(header: string | undefined, etag: string): boolean {
  if (header === undefined) {
    return false;
  }
  return header
    .split(',')
    .map((tag) => tag.trim().replace(/^W\//, ''))
    .some((tag) => tag === '*' || tag === etag);
}
