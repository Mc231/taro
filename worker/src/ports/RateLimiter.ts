/**
 * Structural view of a Workers Rate Limiting binding (`RL_BURST`, `RL_READINGS`,
 * 03 §2.4). The Cloudflare `RateLimit` binding satisfies it; tests inject fakes.
 */
export interface RateLimiter {
  limit(options: { key: string }): Promise<{ success: boolean }>;
}
