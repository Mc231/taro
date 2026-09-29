import { concatBytes, fromBase64, toBase64Url, utf8 } from '../crypto/encoding';
import type { Crypto } from '../ports/Crypto';

/**
 * Stateless attestation challenge (03 §3.2) and the registration bindings
 * that hash it (03 §2.4, §3.1, §3.3; RC65, RC87).
 *
 * `challenge = base64url(nonce16 ‖ exp8 ‖ HMAC-SHA256(CHALLENGE_KEY, nonce ‖ exp)[0..16])`,
 * where `exp8` is the expiry in Unix seconds as an unsigned 64-bit big-endian
 * integer. The challenge lives 5 minutes. Replays are caught by inserting the
 * nonce into `used_challenges` when it is used (`UsedChallengeRepo`).
 *
 * `‖` over strings is the concatenation of their UTF-8 bytes exactly as the
 * client sent them (the challenge in its base64url form).
 */
export const CHALLENGE_TTL_SEC = 300;
export const CHALLENGE_NONCE_BYTES = 16;
const EXP_BYTES = 8;
const MAC_BYTES = 16;
const CHALLENGE_BYTES = CHALLENGE_NONCE_BYTES + EXP_BYTES + MAC_BYTES;
/** base64url length of the 40 challenge bytes (no padding). */
export const CHALLENGE_LENGTH = 54;

/** Upper bound for a client proof-of-work string (03 §2.4). */
export const POW_MAX_LENGTH = 64;

export interface IssuedChallenge {
  readonly challenge: string;
  readonly expiresAt: Date;
}

export type ChallengeRejection = 'malformed' | 'bad_mac' | 'expired';

export type OpenedChallenge =
  | { readonly ok: true; readonly nonce: string; readonly expiresAt: Date }
  | { readonly ok: false; readonly reason: ChallengeRejection };

function expBytes(expSec: number): Uint8Array {
  const out = new Uint8Array(EXP_BYTES);
  new DataView(out.buffer).setBigUint64(0, BigInt(expSec));
  return out;
}

async function mac(crypto: Crypto, key: Uint8Array, nonce: Uint8Array, exp: Uint8Array) {
  return (await crypto.hmacSha256(key, concatBytes(nonce, exp))).subarray(0, MAC_BYTES);
}

/** Issues a challenge that expires `CHALLENGE_TTL_SEC` after `now` (whole seconds). */
export async function issueChallenge(
  crypto: Crypto,
  key: Uint8Array,
  now: Date,
): Promise<IssuedChallenge> {
  const expSec = Math.floor(now.getTime() / 1000) + CHALLENGE_TTL_SEC;
  const nonce = crypto.randomBytes(CHALLENGE_NONCE_BYTES);
  const exp = expBytes(expSec);
  const tag = await mac(crypto, key, nonce, exp);
  return {
    challenge: toBase64Url(concatBytes(nonce, exp, tag)),
    expiresAt: new Date(expSec * 1000),
  };
}

/** Checks format, MAC (constant time) and expiry. Does not consume the nonce. */
export async function openChallenge(
  crypto: Crypto,
  key: Uint8Array,
  challenge: string,
  now: Date,
): Promise<OpenedChallenge> {
  if (challenge.length !== CHALLENGE_LENGTH || !/^[A-Za-z0-9_-]+$/.test(challenge)) {
    return { ok: false, reason: 'malformed' };
  }
  const raw = fromBase64(challenge);
  const nonce = raw.subarray(0, CHALLENGE_NONCE_BYTES);
  const exp = raw.subarray(CHALLENGE_NONCE_BYTES, CHALLENGE_NONCE_BYTES + EXP_BYTES);
  const tag = raw.subarray(CHALLENGE_NONCE_BYTES + EXP_BYTES, CHALLENGE_BYTES);
  if (!crypto.timingSafeEqual(tag, await mac(crypto, key, nonce, exp))) {
    return { ok: false, reason: 'bad_mac' };
  }
  const expSec = Number(new DataView(exp.buffer, exp.byteOffset, EXP_BYTES).getBigUint64(0));
  const expiresAt = new Date(expSec * 1000);
  if (expiresAt.getTime() <= now.getTime()) {
    return { ok: false, reason: 'expired' };
  }
  return { ok: true, nonce: toBase64Url(nonce), expiresAt };
}

/** Number of leading zero bits of `bytes`. */
export function leadingZeroBits(bytes: Uint8Array): number {
  let bits = 0;
  for (const byte of bytes) {
    if (byte === 0) {
      bits += 8;
      continue;
    }
    return bits + Math.clz32(byte) - 24;
  }
  return bits;
}

/**
 * Proof-of-work for `type: none` registrations (03 §2.4, RC65):
 * `SHA-256(challenge ‖ installId ‖ pow)` has at least `bits` leading zero bits.
 */
export async function verifyProofOfWork(
  crypto: Crypto,
  input: { challenge: string; installId: string; pow: string | undefined; bits: number },
): Promise<boolean> {
  const { pow } = input;
  if (pow === undefined || pow === '' || pow.length > POW_MAX_LENGTH) {
    return false;
  }
  const digest = await crypto.sha256(`${input.challenge}${input.installId}${pow}`);
  return leadingZeroBits(digest) >= input.bits;
}

/** iOS registration `clientDataHash = SHA256(challenge ‖ installId ‖ deviceCheckToken?)` (03 §3.1). */
export function registrationClientDataHash(
  crypto: Crypto,
  challenge: string,
  installId: string,
  deviceCheckToken: string | undefined,
): Promise<Uint8Array> {
  return crypto.sha256(`${challenge}${installId}${deviceCheckToken ?? ''}`);
}

/**
 * Android registration Play Integrity `requestHash =
 * base64url(SHA256(challenge ‖ installId ‖ deviceKey))` (03 §3.1, RC87).
 */
export async function registrationRequestHash(
  crypto: Crypto,
  challenge: string,
  installId: string,
  deviceKey: string,
): Promise<string> {
  return toBase64Url(await crypto.sha256(`${challenge}${installId}${deviceKey}`));
}

/**
 * Per-call binding for `[attest]` routes (03 §3.4):
 * `SHA256(method ‖ path ‖ SHA256(body) ‖ Idempotency-Key)`, with the raw
 * 32-byte body digest and an empty key when the route sends none.
 */
export async function callClientDataHash(
  crypto: Crypto,
  input: { method: string; path: string; body: Uint8Array; idempotencyKey: string | undefined },
): Promise<Uint8Array> {
  const bodyHash = await crypto.sha256(input.body);
  return crypto.sha256(
    concatBytes(
      utf8(input.method.toUpperCase()),
      utf8(input.path),
      bodyHash,
      utf8(input.idempotencyKey ?? ''),
    ),
  );
}
