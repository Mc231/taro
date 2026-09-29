import type { Clock } from '../../ports/Clock';
import type {
  PlayIntegrityInput,
  PlayIntegrityResult,
  PlayIntegrityVerifier,
} from '../../ports/PlayIntegrityVerifier';

/**
 * Play Integrity, **Standard API only** (03 §3.3, §3.4; RC87). Decodes the
 * token with `POST playintegrity.googleapis.com/v1/{package}:decodeIntegrityToken`
 * (service-account OAuth, cached 50 min) and checks:
 *
 * - `requestDetails.requestHash` equals the expected binding (registration:
 *   `base64url(SHA256(challenge ‖ installId ‖ deviceKey))`; per call: the
 *   §3.4 request hash);
 * - `requestDetails.requestPackageName` (and `appIntegrity.packageName`) ∈
 *   the Android entries of `attest.allowedAppIds` (RC78);
 * - `requestDetails.timestampMillis` at most 120 s from now;
 * - `appIntegrity.appRecognitionVerdict`: `UNRECOGNIZED_VERSION` is a hard
 *   failure where `requireRecognizedApp` (prod); `UNEVALUATED` is reported as
 *   not recognised (low trust);
 * - `deviceIntegrity.deviceRecognitionVerdict`: `MEETS_DEVICE_INTEGRITY` (or
 *   stronger) → `device`, `MEETS_BASIC_INTEGRITY` only → `basic`, else `none`.
 *
 * `accountDetails.appLicensingVerdict` is reported, never required. Google
 * outages (network errors, 429, 5xx, no OAuth token) are `unavailable` and
 * degrade to low trust; everything else is `invalid`.
 */
export interface GooglePlayIntegrityOptions {
  readonly fetch: typeof fetch;
  readonly clock: Clock;
  readonly accessToken: () => Promise<string>;
  readonly requireRecognizedApp: boolean;
}

export const PLAY_INTEGRITY_BASE_URL = 'https://playintegrity.googleapis.com/v1';
export const MAX_TOKEN_AGE_MS = 120_000;

interface TokenPayload {
  readonly requestDetails?: {
    readonly requestPackageName?: string;
    readonly requestHash?: string;
    readonly timestampMillis?: string | number;
  };
  readonly appIntegrity?: {
    readonly appRecognitionVerdict?: string;
    readonly packageName?: string;
  };
  readonly deviceIntegrity?: { readonly deviceRecognitionVerdict?: readonly string[] };
  readonly accountDetails?: { readonly appLicensingVerdict?: string };
}

type Decoded =
  | { readonly kind: 'payload'; readonly payload: TokenPayload }
  | { readonly kind: 'rejected' }
  | { readonly kind: 'unavailable' };

/** Java package names: the Android entries of `attest.allowedAppIds` (iOS app IDs start with the team ID). */
export function androidPackageNames(appIds: readonly string[]): string[] {
  return appIds.filter((id) => /^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$/.test(id));
}

function isTransient(status: number): boolean {
  return status === 429 || status >= 500;
}

export class GooglePlayIntegrityVerifier implements PlayIntegrityVerifier {
  constructor(private readonly options: GooglePlayIntegrityOptions) {}

  async verify(input: PlayIntegrityInput): Promise<PlayIntegrityResult> {
    const packages = androidPackageNames(input.allowedPackageNames);
    const decoded = await this.decode(input.token, packages);
    if (decoded.kind === 'unavailable') {
      return { ok: false, reason: 'unavailable', detail: 'decode_unavailable' };
    }
    if (decoded.kind === 'rejected') {
      return { ok: false, reason: 'invalid', detail: 'decode_rejected' };
    }
    const { requestDetails, appIntegrity, deviceIntegrity, accountDetails } = decoded.payload;
    if (requestDetails?.requestHash !== input.expectedRequestHash) {
      return { ok: false, reason: 'invalid', detail: 'request_hash' };
    }
    const packageName = requestDetails.requestPackageName ?? '';
    if (
      !packages.includes(packageName) ||
      (appIntegrity?.packageName !== undefined && !packages.includes(appIntegrity.packageName))
    ) {
      return { ok: false, reason: 'invalid', detail: 'package' };
    }
    const timestamp = Number(requestDetails.timestampMillis);
    const ageMs = this.options.clock.now().getTime() - timestamp;
    if (!Number.isFinite(timestamp) || Math.abs(ageMs) > MAX_TOKEN_AGE_MS) {
      return { ok: false, reason: 'invalid', detail: 'stale' };
    }
    const recognition = appIntegrity?.appRecognitionVerdict;
    if (this.options.requireRecognizedApp && recognition === 'UNRECOGNIZED_VERSION') {
      return { ok: false, reason: 'invalid', detail: 'app_unrecognized' };
    }
    const verdicts = deviceIntegrity?.deviceRecognitionVerdict ?? [];
    const deviceVerdict =
      verdicts.includes('MEETS_DEVICE_INTEGRITY') || verdicts.includes('MEETS_STRONG_INTEGRITY')
        ? 'device'
        : verdicts.includes('MEETS_BASIC_INTEGRITY')
          ? 'basic'
          : 'none';
    const licensing = accountDetails?.appLicensingVerdict;
    return {
      ok: true,
      deviceVerdict,
      appRecognized: recognition === 'PLAY_RECOGNIZED',
      packageName,
      ...(licensing === undefined ? {} : { licensed: licensing === 'LICENSED' }),
    };
  }

  /**
   * A token can only be decoded under the package that requested it, so each
   * allowed package is tried in turn (staging accepts the prod and `.stg`
   * apps, RC78). A transient error stops the loop as `unavailable`.
   */
  private async decode(token: string, packages: readonly string[]): Promise<Decoded> {
    let accessToken: string;
    try {
      accessToken = await this.options.accessToken();
    } catch {
      return { kind: 'unavailable' };
    }
    for (const packageName of packages) {
      let res: Response;
      try {
        res = await this.options.fetch(
          `${PLAY_INTEGRITY_BASE_URL}/${packageName}:decodeIntegrityToken`,
          {
            method: 'POST',
            headers: {
              authorization: `Bearer ${accessToken}`,
              'content-type': 'application/json',
            },
            body: JSON.stringify({ integrity_token: token }),
          },
        );
      } catch {
        return { kind: 'unavailable' };
      }
      if (isTransient(res.status)) {
        return { kind: 'unavailable' };
      }
      if (res.ok) {
        const body: { tokenPayloadExternal?: TokenPayload } = await res
          .json<{ tokenPayloadExternal?: TokenPayload }>()
          .catch(() => ({}));
        return body.tokenPayloadExternal === undefined
          ? { kind: 'rejected' }
          : { kind: 'payload', payload: body.tokenPayloadExternal };
      }
    }
    return { kind: 'rejected' };
  }
}
