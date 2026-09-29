/** WebCrypto port (03 §1). Keeps randomness and key handling injectable. */
export type BytesLike = Uint8Array | string;

export interface AesGcmSealed {
  readonly iv: Uint8Array;
  /** Ciphertext followed by the 16-byte GCM tag. */
  readonly ciphertext: Uint8Array;
}

export interface Crypto {
  randomBytes(length: number): Uint8Array;
  sha256(data: BytesLike): Promise<Uint8Array>;
  /** SHA-1, only for name-based UUIDs (UUIDv5, RFC 9562 §5.5); never for security. */
  sha1(data: BytesLike): Promise<Uint8Array>;
  hmacSha256(key: BytesLike, data: BytesLike): Promise<Uint8Array>;
  /** AES-256-GCM with a fresh 96-bit IV; `aad` is authenticated, not encrypted. */
  aesGcmEncrypt(key: Uint8Array, plaintext: Uint8Array, aad: Uint8Array): Promise<AesGcmSealed>;
  /** Rejects when the tag, key or `aad` does not match. */
  aesGcmDecrypt(key: Uint8Array, sealed: AesGcmSealed, aad: Uint8Array): Promise<Uint8Array>;
  /** Constant-time comparison (length leak only). */
  timingSafeEqual(a: Uint8Array, b: Uint8Array): boolean;
}
