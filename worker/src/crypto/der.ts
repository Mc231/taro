/**
 * The few DER pieces the attestation adapters need (no general ASN.1 parser):
 * reading one TLV, and converting ECDSA signatures between DER
 * (`SEQUENCE { INTEGER r, INTEGER s }`, what Apple and Google send) and the
 * raw `r ‖ s` form WebCrypto verifies. Throws on malformed input.
 */
export interface Tlv {
  readonly tag: number;
  /** Offset of the first content byte. */
  readonly start: number;
  /** Offset just past the last content byte. */
  readonly end: number;
}

export function readTlv(bytes: Uint8Array, offset = 0): Tlv {
  const tag = bytes[offset];
  let lengthByte = bytes[offset + 1];
  if (tag === undefined || lengthByte === undefined) {
    throw new Error('DER: truncated header');
  }
  let start = offset + 2;
  let length = lengthByte;
  if (lengthByte & 0x80) {
    const count = lengthByte & 0x7f;
    if (count === 0 || count > 3) {
      throw new Error('DER: unsupported length');
    }
    length = 0;
    for (let i = 0; i < count; i++) {
      lengthByte = bytes[start + i];
      if (lengthByte === undefined) {
        throw new Error('DER: truncated length');
      }
      length = length * 256 + lengthByte;
    }
    start += count;
  }
  const end = start + length;
  if (end > bytes.length) {
    throw new Error('DER: truncated content');
  }
  return { tag, start, end };
}

function fixedWidth(integer: Uint8Array, size: number): Uint8Array {
  let value = integer;
  while (value.length > size && value[0] === 0) {
    value = value.subarray(1);
  }
  if (value.length > size) {
    throw new Error('DER: integer too long');
  }
  const out = new Uint8Array(size);
  out.set(value, size - value.length);
  return out;
}

/** DER ECDSA signature → raw `r ‖ s`, each `size` bytes (32 for P-256). */
export function ecdsaDerToRaw(der: Uint8Array, size = 32): Uint8Array {
  const seq = readTlv(der);
  if (seq.tag !== 0x30 || seq.end !== der.length) {
    throw new Error('DER: not a signature sequence');
  }
  const r = readTlv(der, seq.start);
  const s = readTlv(der, r.end);
  if (r.tag !== 0x02 || s.tag !== 0x02 || s.end !== seq.end) {
    throw new Error('DER: bad signature integers');
  }
  const out = new Uint8Array(size * 2);
  out.set(fixedWidth(der.subarray(r.start, r.end), size), 0);
  out.set(fixedWidth(der.subarray(s.start, s.end), size), size);
  return out;
}

function derInteger(raw: Uint8Array): Uint8Array {
  let value = raw;
  while (value.length > 1 && value[0] === 0 && ((value[1] ?? 0) & 0x80) === 0) {
    value = value.subarray(1);
  }
  const pad = ((value[0] ?? 0) & 0x80) !== 0 ? 1 : 0;
  const out = new Uint8Array(2 + pad + value.length);
  out[0] = 0x02;
  out[1] = pad + value.length;
  out.set(value, 2 + pad);
  return out;
}

/** Raw `r ‖ s` → DER ECDSA signature (the form Apple sends; used by tests and fakes). */
export function ecdsaRawToDer(raw: Uint8Array): Uint8Array {
  const half = raw.length / 2;
  const r = derInteger(raw.subarray(0, half));
  const s = derInteger(raw.subarray(half));
  const out = new Uint8Array(2 + r.length + s.length);
  out[0] = 0x30;
  out[1] = r.length + s.length;
  out.set(r, 2);
  out.set(s, 2 + r.length);
  return out;
}
