import { WebCrypto } from '../../src/adapters/cf/WebCrypto';
import type { App } from '../../src/app';
import { toBase64Url } from '../../src/crypto/encoding';
import { verifyProofOfWork } from '../../src/domain/challenge';
import { uniqueId } from '../fakes/testDeps';
import { APP_HEADERS } from './app';

/** Registration helpers for route tests (03 §3.1–§3.4). */
const crypto = new WebCrypto();

export const ANDROID_HEADERS = { ...APP_HEADERS, 'X-Taro-Platform': 'android' } as const;

let secretCounter = 0;
let ipCounter = 0;

/**
 * A client IP in its own /24, so the per-prefix KV registration caps (§2.4),
 * shared by every test in a file, never interfere across tests.
 */
export function uniqueIp(): string {
  ipCounter++;
  return `10.${String(Math.floor(ipCounter / 256) % 256)}.${String(ipCounter % 256)}.7`;
}

/** A distinct base64url 32-byte install secret per call. */
export function newSecret(): string {
  secretCounter++;
  const bytes = new Uint8Array(32).fill(secretCounter % 256);
  bytes[0] = Math.floor(secretCounter / 256);
  return toBase64Url(bytes);
}

/** A `type: none` attestation with a solved proof-of-work for `bits` (RC65). */
export function noneAttestation(bits: number) {
  return async (challenge: string, installId: string) => ({
    type: 'none',
    challenge,
    reason: 'unsupported',
    pow: await solvePow(challenge, installId, bits),
  });
}

/** A distinct base64url 32-byte Android device key per call. */
export function newDeviceKey(): string {
  return newSecret().replace(/^./, 'd');
}

/** A fresh UUID v4 for `Idempotency-Key`. */
export function idemKey(): string {
  return uniqueId('1de0');
}

/** A UUID v4 install ID (unique within the test file). */
export function installIdV4(): string {
  return uniqueId('1a57');
}

/** Finds a proof-of-work string with `bits` leading zero bits (tests configure small `bits`). */
export async function solvePow(
  challenge: string,
  installId: string,
  bits: number,
): Promise<string> {
  for (let i = 0; ; i++) {
    const pow = i.toString(36);
    if (await verifyProofOfWork(crypto, { challenge, installId, pow, bits })) {
      return pow;
    }
  }
}

export interface ChallengeBody {
  challenge: string;
  expiresAt: string;
  powBits: number;
}

export async function fetchChallenge(
  app: App,
  headers: Record<string, string> = APP_HEADERS,
): Promise<ChallengeBody> {
  const res = await app.request('/v1/attest/challenge', { method: 'POST', headers });
  if (res.status !== 200) {
    throw new Error(`challenge: ${String(res.status)}`);
  }
  return res.json<ChallengeBody>();
}

export interface RegistrationBody {
  installToken: string;
  expiresAt: string;
  trust: 'high' | 'low';
  purchaseBinding: { appleAccountToken?: string; playAccountId?: string };
  balance: Record<string, unknown>;
  config: Record<string, unknown>;
}

export interface RegisterOptions {
  readonly installId?: string;
  readonly secret?: string;
  readonly idempotencyKey?: string;
  readonly headers?: Record<string, string>;
  /** Replaces or extends the body (after the challenge is filled in). */
  readonly body?: (challenge: string) => Record<string, unknown>;
  readonly attestation?: (
    challenge: string,
    installId: string,
  ) => Record<string, unknown> | Promise<Record<string, unknown>>;
  readonly deviceCheckToken?: string;
  readonly deviceKey?: string;
  readonly platform?: 'ios' | 'android';
}

export interface Registered {
  readonly res: Response;
  readonly installId: string;
  readonly secret: string;
  readonly challenge: string;
}

/** `POST /v1/attest/challenge` then `POST /v1/installs` with a fake-verifiable attestation. */
export async function register(app: App, options: RegisterOptions = {}): Promise<Registered> {
  const platform = options.platform ?? 'ios';
  const headers = options.headers ?? {
    ...(platform === 'ios' ? APP_HEADERS : ANDROID_HEADERS),
    'CF-Connecting-IP': uniqueIp(),
  };
  const installId = options.installId ?? installIdV4();
  const secret = options.secret ?? newSecret();
  const { challenge } = await fetchChallenge(app, headers);
  const attestation =
    (await options.attestation?.(challenge, installId)) ??
    (platform === 'ios'
      ? { type: 'app_attest', challenge, keyId: 'a2V5LWlk', attestationObject: 'b2JqZWN0' }
      : { type: 'play_integrity', challenge, integrityToken: 'integrity.token' });
  const body = options.body?.(challenge) ?? {
    installId,
    installSecret: secret,
    platform,
    appVersion: '1.2.0+14',
    locale: 'de',
    timezone: 'Europe/Berlin',
    ...(platform === 'ios'
      ? options.deviceCheckToken === undefined
        ? {}
        : { deviceCheckToken: options.deviceCheckToken }
      : { deviceKey: options.deviceKey ?? newDeviceKey() }),
    attestation,
  };
  const res = await app.request('/v1/installs', {
    method: 'POST',
    headers: {
      ...headers,
      'content-type': 'application/json',
      'Idempotency-Key': options.idempotencyKey ?? idemKey(),
    },
    body: JSON.stringify(body),
  });
  return { res, installId, secret, challenge };
}

/** Registers and returns the parsed 201/200 body; throws on any other status. */
export async function registerOk(
  app: App,
  options: RegisterOptions = {},
): Promise<Registered & { body: RegistrationBody }> {
  const registered = await register(app, options);
  if (registered.res.status !== 201 && registered.res.status !== 200) {
    throw new Error(`register: ${String(registered.res.status)} ${await registered.res.text()}`);
  }
  return { ...registered, body: await registered.res.json<RegistrationBody>() };
}
