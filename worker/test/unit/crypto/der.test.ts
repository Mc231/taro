import { describe, expect, it } from 'vitest';
import { ecdsaDerToRaw, ecdsaRawToDer, readTlv } from '../../../src/crypto/der';

describe('DER helpers', () => {
  it('reads short and long form lengths', () => {
    expect(readTlv(Uint8Array.of(0x04, 0x02, 0xaa, 0xbb))).toEqual({ tag: 4, start: 2, end: 4 });
    const long = new Uint8Array(3 + 200);
    long.set([0x04, 0x81, 200]);
    expect(readTlv(long)).toEqual({ tag: 4, start: 3, end: 203 });
    const twoBytes = new Uint8Array(4 + 256);
    twoBytes.set([0x04, 0x82, 0x01, 0x00]);
    expect(readTlv(twoBytes)).toEqual({ tag: 4, start: 4, end: 260 });
  });

  it('rejects truncated or unsupported encodings', () => {
    expect(() => readTlv(Uint8Array.of(0x04))).toThrow(/truncated header/);
    expect(() => readTlv(Uint8Array.of(0x04, 0x80))).toThrow(/unsupported length/);
    expect(() => readTlv(Uint8Array.of(0x04, 0x84, 1, 1, 1, 1))).toThrow(/unsupported length/);
    expect(() => readTlv(Uint8Array.of(0x04, 0x82, 0x01))).toThrow(/truncated length/);
    expect(() => readTlv(Uint8Array.of(0x04, 0x05, 0x00))).toThrow(/truncated content/);
  });

  it('round-trips ECDSA signatures between raw and DER, including high-bit and short integers', () => {
    const raw = new Uint8Array(64);
    raw.fill(0x80, 0, 32); // r needs a 0x00 pad in DER
    raw[32] = 0;
    raw[33] = 0;
    raw.fill(0x11, 34, 64); // s has leading zeros that DER strips
    const der = ecdsaRawToDer(raw);
    expect(der[0]).toBe(0x30);
    expect(der[3]).toBe(33);
    expect(ecdsaDerToRaw(der)).toEqual(raw);
  });

  it('rejects malformed signatures', () => {
    expect(() => ecdsaDerToRaw(Uint8Array.of(0x31, 0x00))).toThrow(/sequence/);
    expect(() => ecdsaDerToRaw(Uint8Array.of(0x30, 0x04, 0x04, 0x00, 0x02, 0x00))).toThrow(
      /integers/,
    );
    const tooLong = Uint8Array.of(0x30, 0x06, 0x02, 0x02, 0x7f, 0x01, 0x02, 0x00);
    expect(() => ecdsaDerToRaw(tooLong, 1)).toThrow(/too long/);
  });
});
