/**
 * `used_challenges` (03 §3.2, §4, §12): replay detection for the stateless
 * attestation challenge. D1, not KV, because KV's cross-colo read-after-write
 * lag would let a replay through.
 */
export class UsedChallengeRepo {
  constructor(private readonly db: D1Database) {}

  /** Records the nonce; false when it was already used (a replay). */
  async consume(nonce: string, expiresAt: string): Promise<boolean> {
    const result = await this.db
      .prepare(
        `INSERT INTO used_challenges (nonce, expires_at) VALUES (?1, ?2) ON CONFLICT DO NOTHING`,
      )
      .bind(nonce, expiresAt)
      .run();
    return result.meta.changes === 1;
  }

  /** Hourly purge of nonces past expiry (03 §12); bounded per call. */
  async purgeExpired(now: string, limit = 500): Promise<number> {
    const result = await this.db
      .prepare(
        `DELETE FROM used_challenges WHERE nonce IN
           (SELECT nonce FROM used_challenges WHERE expires_at <= ?1 LIMIT ?2)`,
      )
      .bind(now, limit)
      .run();
    return result.meta.changes;
  }
}
