/** ID port (03 §1, QA9). Randomness only flows through `Crypto`. */
export interface IdGenerator {
  /** Random UUID v4 (request IDs). */
  uuid(): string;
  /** Time-ordered UUID v7 (server row IDs: readings, purchases, reports). */
  uuidV7(): string;
  /** Opaque random ID, base64url of `bytes` random bytes (default 16; reward `intentId`). */
  opaque(bytes?: number): string;
}
