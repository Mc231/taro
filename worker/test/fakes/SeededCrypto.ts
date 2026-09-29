import { WebCrypto } from '../../src/adapters/cf/WebCrypto';

/**
 * `WebCrypto` with a deterministic `randomBytes` (a counter-seeded xorshift
 * stream), so exported contract fixtures (challenges, nonces) are byte-stable
 * across runs. Hashes, HMACs and AES stay real. Test-only: never random.
 */
export class SeededCrypto extends WebCrypto {
  private state: number;

  constructor(seed = 0x7a2c_91e5) {
    super();
    this.state = seed >>> 0 || 1;
  }

  override randomBytes(length: number): Uint8Array {
    const out = new Uint8Array(length);
    for (let i = 0; i < length; i++) {
      let x = this.state;
      x ^= x << 13;
      x ^= x >>> 17;
      x ^= x << 5;
      this.state = x >>> 0;
      out[i] = this.state & 0xff;
    }
    return out;
  }
}
