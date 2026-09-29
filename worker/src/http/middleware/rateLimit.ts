import type { Context, MiddlewareHandler } from 'hono';
import { toBase64Url } from '../../crypto/encoding';
import { ipPrefix } from '../../domain/ipPrefix';
import type { Platform } from '../../domain/types';
import type { Deps } from '../../deps';
import type { AppEnv } from '../context';
import { ApiError } from '../errors';

/**
 * Rate limiting and approximate abuse counters (03 §2.4, RC53, RC65, RC74).
 *
 * - Burst limits use the Workers Rate Limiting bindings: `RL_BURST` keyed
 *   `inst:{id}` or `ip:{prefix hash}`, `RL_READINGS` keyed `inst:{id}`. The
 *   limit/period live in `wrangler.toml` (a binding cannot be tuned at run
 *   time), so `rl.install.perMinute` / `rl.readings.perMinute` document the
 *   binding values.
 * - Soft caps are KV counters in `RL_KV` (eventually consistent, per-colo
 *   approximate, TTL 48 h). Money never depends on them.
 */

export type BurstScope = 'install' | 'readings' | 'ipPrefix';

/** Seconds a client should wait after a burst 429 (the bindings use a 60 s period). */
export const BURST_RETRY_AFTER_SEC = 60;

/** Registrations of any attestation type per IP prefix per UTC day (03 §2.4). */
export const REGISTRATIONS_PER_PREFIX_PER_DAY = 50;

/** KV counter TTL; IP-derived keys live at most 48 h (03 §13). */
export const SOFT_COUNTER_TTL_SEC = 48 * 3600;

/** Fraction of `abuse.lowTrust.alertPerBucketPerDay` that sends the early alert. */
export const BUCKET_EARLY_ALERT_RATIO = 0.8;

export interface ClientNetwork {
  readonly ip: string | undefined;
  readonly asn: number | undefined;
}

/** Client IP (`CF-Connecting-IP`, set by Cloudflare) and ASN (`request.cf.asn`). */
export function clientNetwork(c: Context<AppEnv>): ClientNetwork {
  const cf = (c.req.raw as { cf?: { asn?: unknown } }).cf;
  const asn = typeof cf?.asn === 'number' ? cf.asn : undefined;
  return { ip: c.req.header('CF-Connecting-IP'), asn };
}

/** `HMAC(IP_HASH_KEY, prefix)` as 22 base64url chars; unknown addresses share one bucket. */
export async function ipPrefixHash(deps: Deps, ip: string | undefined): Promise<string> {
  const prefix = ipPrefix(ip) ?? 'unknown';
  const mac = await deps.crypto.hmacSha256(deps.keys.ipHash(), prefix);
  return toBase64Url(mac).slice(0, 22);
}

/** `yyyymmdd` of the UTC day. */
export function utcDay(now: Date): string {
  return now.toISOString().slice(0, 10).replace(/-/g, '');
}

/**
 * Burst limiter middleware → `429 RATE_LIMITED` `reason=burst` with
 * `Retry-After`. Install scopes need `c.var.installId` (set by auth) and are
 * skipped without it.
 */
export function rateLimit(deps: Deps, scope: BurstScope): MiddlewareHandler<AppEnv> {
  return async (c, next) => {
    const key = await limiterKey(deps, c, scope);
    if (key !== undefined) {
      const limiter = scope === 'readings' ? deps.rateLimiters.readings : deps.rateLimiters.burst;
      const { success } = await limiter.limit({ key });
      if (!success) {
        deps.metrics.write({
          event: 'rate_limited',
          code: 'burst',
          ...optionalPlatform(c.get('client').platform),
        });
        throw new ApiError('RATE_LIMITED', {
          details: { reason: 'burst' },
          retryAfterSec: BURST_RETRY_AFTER_SEC,
        });
      }
    }
    await next();
  };
}

async function limiterKey(
  deps: Deps,
  c: Context<AppEnv>,
  scope: BurstScope,
): Promise<string | undefined> {
  if (scope === 'ipPrefix') {
    return `ip:${await ipPrefixHash(deps, clientNetwork(c).ip)}`;
  }
  const installId = c.get('installId');
  return installId === undefined ? undefined : `inst:${installId}`;
}

function optionalPlatform(platform: Platform | undefined): { platform?: string } {
  return platform === undefined ? {} : { platform };
}

export interface SoftCapResult {
  readonly allowed: boolean;
  /** Count after this call (unchanged when not allowed). */
  readonly count: number;
  readonly limit: number;
}

export type RegistrationKind = 'none' | 'attested';

export interface RegistrationCapResult {
  readonly allowed: boolean;
  readonly reason?: 'noneCap' | 'prefixCap';
}

/** KV soft counters in `RL_KV` (03 §2.4). */
export class SoftLimits {
  constructor(private readonly deps: Deps) {}

  /**
   * Low-trust free readings per IP prefix per UTC day: `lt:ip:{hash}:{yyyymmdd}`,
   * `abuse.lowTrust.freePerIpPerDay` (3), or `freePerCgnatPrefixPerDay` (20)
   * when `cf.asn ∈ abuse.lowTrust.cgnatAsns`. Counts only when allowed.
   */
  async consumeLowTrustFree(network: ClientNetwork): Promise<SoftCapResult> {
    const { key, limit } = await this.lowTrustFreeCounter(network);
    return this.consume(key, limit);
  }

  /**
   * The same counter without consuming (balance read, 03 §5.1): `allowed`
   * says whether one more low-trust free reading fits today.
   */
  async peekLowTrustFree(network: ClientNetwork): Promise<SoftCapResult> {
    const { key, limit } = await this.lowTrustFreeCounter(network);
    const count = await this.read(key);
    return { allowed: count < limit, count, limit };
  }

  private async lowTrustFreeCounter(
    network: ClientNetwork,
  ): Promise<{ readonly key: string; readonly limit: number }> {
    const config = await this.deps.config.snapshot();
    const cgnat =
      network.asn !== undefined && config['abuse.lowTrust.cgnatAsns'].includes(network.asn);
    const limit = cgnat
      ? config['abuse.lowTrust.freePerCgnatPrefixPerDay']
      : config['abuse.lowTrust.freePerIpPerDay'];
    const hash = await ipPrefixHash(this.deps, network.ip);
    return { key: `lt:ip:${hash}:${utcDay(this.deps.clock.now())}`, limit };
  }

  /**
   * Registration caps per IP prefix per UTC day: `type: none` ≤
   * `abuse.lowTrust.registrationsPerPrefixPerDay` (5), any type ≤ 50.
   * Both counters advance only when the registration is allowed.
   */
  async consumeRegistration(
    network: ClientNetwork,
    kind: RegistrationKind,
  ): Promise<RegistrationCapResult> {
    const config = await this.deps.config.snapshot();
    const hash = await ipPrefixHash(this.deps, network.ip);
    const day = utcDay(this.deps.clock.now());
    const allKey = `reg:all:${hash}:${day}`;
    const noneKey = `reg:none:${hash}:${day}`;
    const all = await this.read(allKey);
    if (all >= REGISTRATIONS_PER_PREFIX_PER_DAY) {
      return { allowed: false, reason: 'prefixCap' };
    }
    if (kind === 'none') {
      const none = await this.consume(
        noneKey,
        config['abuse.lowTrust.registrationsPerPrefixPerDay'],
      );
      if (!none.allowed) {
        return { allowed: false, reason: 'noneCap' };
      }
    }
    await this.write(allKey, all + 1);
    return { allowed: true };
  }

  /**
   * Low-trust volume per `(platform, appVersion)` per UTC day:
   * `lt:bucket:{plat}:{ver}:{yyyymmdd}`. **Alert only** (RC65): alerts when the
   * count reaches 80 % and 100 % of `abuse.lowTrust.alertPerBucketPerDay`;
   * never blocks.
   */
  async recordLowTrustBucket(platform: Platform, appVersion: string): Promise<number> {
    const config = await this.deps.config.snapshot();
    const limit = config['abuse.lowTrust.alertPerBucketPerDay'];
    const day = utcDay(this.deps.clock.now());
    const key = `lt:bucket:${platform}:${appVersion}:${day}`;
    const count = (await this.read(key)) + 1;
    await this.write(key, count);
    const early = Math.ceil(limit * BUCKET_EARLY_ALERT_RATIO);
    if (count === early || count === limit) {
      await this.deps.alerter.send({
        kind: 'low_trust_bucket',
        message: `low-trust volume ${String(count)}/${String(limit)} for ${platform} ${appVersion} on ${day}`,
        fields: { platform, appVersion, count, limit, day },
      });
    }
    return count;
  }

  private async consume(key: string, limit: number): Promise<SoftCapResult> {
    const current = await this.read(key);
    if (current >= limit) {
      return { allowed: false, count: current, limit };
    }
    await this.write(key, current + 1);
    return { allowed: true, count: current + 1, limit };
  }

  private async read(key: string): Promise<number> {
    const raw = await this.deps.rlKv.get(key);
    const value = raw === null ? 0 : Number(raw);
    return Number.isFinite(value) && value > 0 ? Math.floor(value) : 0;
  }

  private async write(key: string, value: number): Promise<void> {
    await this.deps.rlKv.put(key, String(value), { expirationTtl: SOFT_COUNTER_TTL_SEC });
  }
}
