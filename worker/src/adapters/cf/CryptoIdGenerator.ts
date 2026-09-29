import { toBase64Url, toHex } from '../../crypto/encoding';
import type { Clock } from '../../ports/Clock';
import type { Crypto } from '../../ports/Crypto';
import type { IdGenerator } from '../../ports/IdGenerator';

function formatUuid(bytes: Uint8Array): string {
  const hex = toHex(bytes);
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

/** UUID v4 / v7 and opaque IDs from the `Crypto` port's randomness. */
export class CryptoIdGenerator implements IdGenerator {
  constructor(
    private readonly crypto: Crypto,
    private readonly clock: Clock,
  ) {}

  uuid(): string {
    const bytes = this.crypto.randomBytes(16);
    bytes[6] = ((bytes[6] ?? 0) & 0x0f) | 0x40;
    bytes[8] = ((bytes[8] ?? 0) & 0x3f) | 0x80;
    return formatUuid(bytes);
  }

  uuidV7(): string {
    const bytes = this.crypto.randomBytes(16);
    let ms = this.clock.now().getTime();
    for (let i = 5; i >= 0; i--) {
      bytes[i] = ms % 256;
      ms = Math.floor(ms / 256);
    }
    bytes[6] = ((bytes[6] ?? 0) & 0x0f) | 0x70;
    bytes[8] = ((bytes[8] ?? 0) & 0x3f) | 0x80;
    return formatUuid(bytes);
  }

  opaque(bytes = 16): string {
    return toBase64Url(this.crypto.randomBytes(bytes));
  }
}
