import { importPKCS8, SignJWT } from 'jose';
import type { Clock } from '../../ports/Clock';
import type { IdGenerator } from '../../ports/IdGenerator';
import type { DeviceCheckApi } from '../../ports/StoreApis';

/**
 * Apple DeviceCheck two-bit API (03 §3.7, RC53) with an ES256 JWT signed by
 * the `APPLE_DEVICECHECK_*` key (`kid` = key ID, `iss` = `APPLE_TEAM_ID`).
 * `bit0 = 1` means "this device has registered a Taro install before".
 *
 * Never throws: a missing key, a network error or a non-200 answer is
 * `{ ok: false }` / `false`, which the caller degrades to "not reused" and
 * counts as `devicecheck_error`.
 */
export interface DeviceCheckCredentials {
  readonly keyId: string;
  readonly teamId: string;
  /** PKCS#8 PEM of the `.p8` key. */
  readonly privateKeyPem: string;
}

export interface AppleDeviceCheckOptions {
  readonly fetch: typeof fetch;
  readonly clock: Clock;
  readonly ids: IdGenerator;
  /** Resolved on first use; throws when the secrets are not set. */
  readonly credentials: () => DeviceCheckCredentials;
  /** Development endpoint (dev builds); production otherwise. */
  readonly development: boolean;
}

export const DEVICECHECK_PRODUCTION_URL = 'https://api.devicecheck.apple.com/v1';
export const DEVICECHECK_DEVELOPMENT_URL = 'https://api.development.devicecheck.apple.com/v1';
/** Apple's 200 body for a device whose bits were never set. */
const BITS_NEVER_SET = 'Failed to find bit state';

interface Bits {
  readonly bit0: boolean;
  readonly bit1: boolean;
}

export class AppleDeviceCheckApi implements DeviceCheckApi {
  constructor(private readonly options: AppleDeviceCheckOptions) {}

  async queryBits(
    deviceToken: string,
  ): Promise<({ readonly ok: true } & Bits) | { readonly ok: false }> {
    try {
      const res = await this.post('query_two_bits', deviceToken, {});
      if (res.status !== 200) {
        return { ok: false };
      }
      const text = await res.text();
      if (text.trim() === BITS_NEVER_SET) {
        return { ok: true, bit0: false, bit1: false };
      }
      const body = JSON.parse(text) as { bit0?: unknown; bit1?: unknown };
      return { ok: true, bit0: body.bit0 === true, bit1: body.bit1 === true };
    } catch {
      return { ok: false };
    }
  }

  async updateBits(deviceToken: string, bits: Bits): Promise<boolean> {
    try {
      const res = await this.post('update_two_bits', deviceToken, {
        bit0: bits.bit0,
        bit1: bits.bit1,
      });
      return res.status === 200;
    } catch {
      return false;
    }
  }

  private async post(
    operation: 'query_two_bits' | 'update_two_bits',
    deviceToken: string,
    extra: Record<string, boolean>,
  ): Promise<Response> {
    const now = this.options.clock.now();
    const base = this.options.development
      ? DEVICECHECK_DEVELOPMENT_URL
      : DEVICECHECK_PRODUCTION_URL;
    return this.options.fetch(`${base}/${operation}`, {
      method: 'POST',
      headers: {
        authorization: `Bearer ${await this.jwt(now)}`,
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        device_token: deviceToken,
        transaction_id: this.options.ids.uuid(),
        timestamp: now.getTime(),
        ...extra,
      }),
    });
  }

  private async jwt(now: Date): Promise<string> {
    const { keyId, teamId, privateKeyPem } = this.options.credentials();
    const key = await importPKCS8(privateKeyPem, 'ES256');
    return new SignJWT({})
      .setProtectedHeader({ alg: 'ES256', kid: keyId })
      .setIssuer(teamId)
      .setIssuedAt(Math.floor(now.getTime() / 1000))
      .sign(key);
  }
}
