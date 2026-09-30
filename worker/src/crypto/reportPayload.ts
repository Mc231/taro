import type { Crypto } from '../ports/Crypto';
import { concatBytes, fromUtf8, utf8 } from './encoding';
import type { Keyring } from './keyring';

/**
 * `reading_reports.payload_enc` (03 §9.7, RC22): AES-256-GCM over
 * `{question?, reading, note?}` with the `REPORT_ENC_KEY` keyring, associated
 * data `install_id‖client_reading_id`. The owner's `reportsExport` script
 * opens it with the same keyring.
 *
 * Blob layout (as the idempotency bodies): `version(1) ‖ kidLen(1) ‖ kid ‖ iv(12) ‖ ciphertext+tag`.
 */
export interface ReportPayload {
  readonly question?: string;
  readonly reading: Readonly<Record<string, unknown>>;
  readonly note?: string;
}

export interface ReportRef {
  readonly installId: string;
  readonly clientReadingId: string;
}

const VERSION = 1;
const IV_BYTES = 12;

function aad(ref: ReportRef): Uint8Array {
  return utf8(`${ref.installId}‖${ref.clientReadingId}`);
}

export async function sealReport(
  crypto: Crypto,
  keyring: Keyring,
  ref: ReportRef,
  payload: ReportPayload,
): Promise<Uint8Array> {
  const { kid, key } = keyring.current;
  const sealed = await crypto.aesGcmEncrypt(key, utf8(JSON.stringify(payload)), aad(ref));
  const kidBytes = utf8(kid);
  return concatBytes(
    Uint8Array.of(VERSION, kidBytes.length),
    kidBytes,
    sealed.iv,
    sealed.ciphertext,
  );
}

/** Opens a sealed report; rejects on an unknown version or kid, a wrong key, or a wrong `ref`. */
export async function openReport(
  crypto: Crypto,
  keyring: Keyring,
  ref: ReportRef,
  blob: Uint8Array,
): Promise<ReportPayload> {
  const [version, kidLength] = blob;
  if (version !== VERSION || kidLength === undefined) {
    throw new Error('report payload: unknown version');
  }
  const entry = keyring.get(fromUtf8(blob.subarray(2, 2 + kidLength)));
  if (entry === undefined) {
    throw new Error('report payload: unknown kid');
  }
  const ivStart = 2 + kidLength;
  const plaintext = await crypto.aesGcmDecrypt(
    entry.key,
    {
      iv: blob.subarray(ivStart, ivStart + IV_BYTES),
      ciphertext: blob.subarray(ivStart + IV_BYTES),
    },
    aad(ref),
  );
  return JSON.parse(fromUtf8(plaintext)) as ReportPayload;
}
