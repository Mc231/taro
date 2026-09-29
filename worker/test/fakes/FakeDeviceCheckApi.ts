import type { DeviceCheckApi } from '../../src/ports/StoreApis';

interface Bits {
  bit0: boolean;
  bit1: boolean;
}

/** In-memory DeviceCheck two bits per device token (03 §3.7, RC53) for route tests. */
export class FakeDeviceCheckApi implements DeviceCheckApi {
  readonly bits = new Map<string, Bits>();
  readonly queries: string[] = [];
  readonly updates: { token: string; bits: Bits }[] = [];
  /** When true every call fails (`{ ok: false }` / `false`), like an Apple outage. */
  failing = false;

  queryBits(deviceToken: string): Promise<({ ok: true } & Bits) | { ok: false }> {
    this.queries.push(deviceToken);
    if (this.failing) {
      return Promise.resolve({ ok: false });
    }
    const bits = this.bits.get(deviceToken) ?? { bit0: false, bit1: false };
    return Promise.resolve({ ok: true, ...bits });
  }

  updateBits(deviceToken: string, bits: Bits): Promise<boolean> {
    this.updates.push({ token: deviceToken, bits });
    if (this.failing) {
      return Promise.resolve(false);
    }
    this.bits.set(deviceToken, { ...bits });
    return Promise.resolve(true);
  }
}
