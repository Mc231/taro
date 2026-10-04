import { fromBase64, fromHex, toHex } from '../crypto/encoding';
import { resolveAllowedAppIds } from '../domain/appIds';
import {
  openChallenge,
  registrationClientDataHash,
  registrationRequestHash,
  verifyProofOfWork,
} from '../domain/challenge';
import { appleAccountToken, playAccountId } from '../domain/purchaseBinding';
import type { Platform, Trust } from '../domain/types';
import type { RuntimeConfig } from '../config/schema';
import type { Deps } from '../deps';
import { ApiError } from '../http/errors';
import { SoftLimits, type ClientNetwork } from '../http/middleware/rateLimit';
import { InstallRepo, type AttestEnv, type InstallRow } from '../repos/InstallRepo';
import { UsedChallengeRepo } from '../repos/UsedChallengeRepo';
import { localDate } from '../domain/dayBoundary';
import { DailyUsageRepo } from '../repos/DailyUsageRepo';
import { DeviceUsageRepo } from '../repos/DeviceUsageRepo';
import { IdempotencyRepo, type IdempotencyKeyRef } from '../repos/IdempotencyRepo';
import { ReadingRepo } from '../repos/ReadingRepo';
import { ReportRepo } from '../repos/ReportRepo';
import { RewardRepo } from '../repos/RewardRepo';
import { installTimezone } from './BalanceService';

/**
 * Install registration and token refresh (03 §3.1–§3.4, §3.7; BE3, BE4,
 * BE19; RC9, RC53, RC54, RC55, RC65, RC87).
 *
 * `register`:
 *  1. the stateless challenge is checked and its nonce consumed (a replay → 403);
 *  2. attestation → trust: App Attest or Play Integrity pass → `high`
 *     (Play Integrity needs `MEETS_DEVICE_INTEGRITY`, and a recognised app in
 *     prod); `MEETS_BASIC_INTEGRITY` only, a Google/Apple outage, or
 *     `type: none` with valid proof-of-work → `low`; a hard failure (wrong
 *     app, bad signature, replay, missing or wrong proof-of-work) → `403
 *     ATTESTATION_FAILED` and nothing is written. The dev/staging debug token
 *     (RC86) counts as a pass;
 *  3. a **new** install stores `install_secret_hash = SHA-256(installSecret)`,
 *     `device_key_hash = HMAC(DEVICE_KEY_SECRET, deviceKey)` (Android) and
 *     `device_reused` from DeviceCheck `bit0` (iOS, then `bit0` is set),
 *     after the per-IP-prefix registration caps (§2.4) → `201`;
 *  4. an **existing** install must prove ownership: the matching
 *     `installSecret` (constant-time) or, on iOS, `previousKeyAssertion`
 *     signed by the stored App Attest key over the new registration hash.
 *     A proof replaces the attestation, bumps `token_generation` (old tokens
 *     are revoked), reactivates a `deleted` row and keeps the balance; 5 per
 *     install per UTC day → `200`.
 *
 * Returned bindings: `appleAccountToken = UUIDv5(APPLE_ACCOUNT_NS, id)` (iOS)
 * and `playAccountId = base64url(HMAC(PLAY_ACCOUNT_KEY, id))[0..43]` (Android).
 * The install secret never reaches a log line, a metric or an error.
 */
export type AttestationType = 'app_attest' | 'play_integrity' | 'none';

export type AttestationInput =
  | {
      readonly type: 'app_attest';
      readonly challenge: string;
      readonly keyId: string;
      readonly attestationObject: string;
      readonly previousKeyAssertion?: string | undefined;
    }
  | {
      readonly type: 'play_integrity';
      readonly challenge: string;
      readonly integrityToken: string;
    }
  | {
      readonly type: 'none';
      readonly challenge: string;
      readonly reason: 'unsupported' | 'error' | 'timeout';
      readonly pow?: string | undefined;
      readonly previousKeyAssertion?: string | undefined;
    };

export interface RegisterInput {
  readonly installId: string;
  readonly installSecret: string;
  readonly platform: Platform;
  readonly appVersion: string;
  readonly locale: string;
  readonly timezone: string;
  readonly deviceCheckToken?: string | undefined;
  readonly deviceKey?: string | undefined;
  readonly attestation: AttestationInput;
}

export interface RegisterContext {
  readonly network: ClientNetwork;
  /** A valid `X-Taro-Debug-Attestation` where the deploy env allows it (RC86). */
  readonly debugAttestation: boolean;
}

export interface PurchaseBinding {
  readonly appleAccountToken?: string;
  readonly playAccountId?: string;
}

export interface IssuedToken {
  readonly installToken: string;
  readonly expiresAt: Date;
  readonly trust: Trust;
}

export interface Registration extends IssuedToken {
  readonly created: boolean;
  readonly install: InstallRow;
  readonly purchaseBinding: PurchaseBinding;
}

/** Re-registrations per install per UTC day (03 §3.3). */
export const REREGISTRATIONS_PER_DAY = 5;

interface Verdict {
  readonly trust: Trust;
  readonly attestKeyId: string | null;
  readonly attestPublicKey: Uint8Array | null;
  readonly attestCounter: number | null;
  readonly attestEnv: AttestEnv | null;
  readonly integrityVerdict: string | null;
}

const NO_KEY = {
  attestKeyId: null,
  attestPublicKey: null,
  attestCounter: null,
  attestEnv: null,
  integrityVerdict: null,
} as const;

/** Seconds until the next UTC midnight (the soft daily caps reset then). */
export function secondsUntilUtcMidnight(now: Date): number {
  const next = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 1);
  return Math.max(1, Math.ceil((next - now.getTime()) / 1000));
}

export class InstallService {
  private readonly installs: InstallRepo;
  private readonly challenges: UsedChallengeRepo;
  private readonly limits: SoftLimits;

  constructor(private readonly deps: Deps) {
    this.installs = new InstallRepo(deps.db);
    this.challenges = new UsedChallengeRepo(deps.db);
    this.limits = new SoftLimits(deps);
  }

  async register(input: RegisterInput, context: RegisterContext): Promise<Registration> {
    const now = this.deps.clock.now();
    const config = await this.deps.config.snapshot();
    await this.useChallenge(input.platform, input.attestation.challenge, now);
    const verdict = context.debugAttestation
      ? this.debugVerdict(input)
      : await this.verify(input, config);
    this.logVerdict(input, verdict);

    const existing = await this.installs.findById(input.installId);
    if (existing !== null) {
      return this.reregister(existing, input, verdict, now);
    }
    const created = await this.create(input, verdict, context, now);
    if (created !== null) {
      return created;
    }
    // Lost an insert race for the same install ID: the winner's row needs a proof.
    const raced = await this.installs.findById(input.installId);
    if (raced === null) {
      throw new ApiError('REQUEST_IN_PROGRESS', { retryAfterSec: 3 });
    }
    return this.reregister(raced, input, verdict, now);
  }

  /** `POST /v1/installs/token` (03 §3.4): a fresh 7-day token for the current generation. */
  async refreshToken(install: InstallRow): Promise<IssuedToken> {
    const { token, expiresAt } = await this.deps.tokenSigner.sign(
      {
        sub: install.id,
        gen: install.tokenGeneration,
        trust: install.trust,
        plat: install.platform,
      },
      this.deps.clock.now(),
    );
    return { installToken: token, expiresAt, trust: install.trust };
  }

  /**
   * `PUT /v1/installs/me/timezone` (03 §3.5, RC8); see `changeInstallTimezone`.
   */
  changeTimezone(install: InstallRow, timezone: string): Promise<TimezoneChange> {
    return changeInstallTimezone(this.deps, install, timezone);
  }

  /** `DELETE /v1/installs/me` (03 §3.6, RC37); see `eraseInstallData`. */
  erase(install: InstallRow, keep: IdempotencyKeyRef | undefined): Promise<void> {
    return eraseInstallData(this.deps, install, keep);
  }

  private async useChallenge(platform: Platform, challenge: string, now: Date): Promise<void> {
    const opened = await openChallenge(
      this.deps.crypto,
      this.deps.keys.challenge(),
      challenge,
      now,
    );
    if (!opened.ok) {
      this.reject(platform, `challenge_${opened.reason}`);
    }
    if (!(await this.challenges.consume(opened.nonce, opened.expiresAt.toISOString()))) {
      this.reject(platform, 'challenge_replay');
    }
  }

  private debugVerdict(input: RegisterInput): Verdict {
    this.deps.logger.log('warn', 'debug_attestation_used', { route: 'POST /v1/installs' });
    return {
      trust: 'high',
      ...NO_KEY,
      integrityVerdict: input.platform === 'android' ? 'debug' : null,
    };
  }

  private async verify(input: RegisterInput, config: RuntimeConfig): Promise<Verdict> {
    const { attestation, platform } = input;
    const allowedAppIds = resolveAllowedAppIds(
      config['attest.allowedAppIds'],
      this.deps.appleTeamId,
    );
    switch (attestation.type) {
      case 'none': {
        const pow = await verifyProofOfWork(this.deps.crypto, {
          challenge: attestation.challenge,
          installId: input.installId,
          pow: attestation.pow,
          bits: config['abuse.lowTrust.powBits'],
        });
        if (!pow) {
          this.reject(platform, 'pow');
        }
        return { trust: 'low', ...NO_KEY };
      }
      case 'app_attest': {
        const result = await this.deps.appAttest.verifyAttestation({
          keyId: attestation.keyId,
          attestationObject: fromBase64(attestation.attestationObject),
          clientDataHash: await registrationClientDataHash(
            this.deps.crypto,
            attestation.challenge,
            input.installId,
            input.deviceCheckToken,
          ),
          allowedAppIds,
        });
        if (result.ok) {
          return {
            trust: 'high',
            attestKeyId: attestation.keyId,
            attestPublicKey: result.publicKey,
            attestCounter: result.counter,
            attestEnv: result.env,
            integrityVerdict: null,
          };
        }
        return this.degradeOrReject(platform, result.reason, result.detail);
      }
      case 'play_integrity': {
        const result = await this.deps.playIntegrity.verify({
          token: attestation.integrityToken,
          expectedRequestHash: await registrationRequestHash(
            this.deps.crypto,
            attestation.challenge,
            input.installId,
            input.deviceKey ?? '',
          ),
          allowedPackageNames: allowedAppIds,
        });
        if (result.ok) {
          const genuine =
            result.deviceVerdict === 'device' &&
            (result.appRecognized || this.deps.environment !== 'prod');
          return {
            trust: genuine ? 'high' : 'low',
            ...NO_KEY,
            integrityVerdict: result.deviceVerdict,
          };
        }
        return this.degradeOrReject(platform, result.reason, result.detail);
      }
    }
  }

  private degradeOrReject(
    platform: Platform,
    reason: 'invalid' | 'unavailable',
    detail: string | undefined,
  ): Verdict {
    if (reason === 'invalid') {
      this.reject(platform, detail ?? 'invalid');
    }
    this.deps.metrics.write({ event: 'attest_failed', platform, code: 'unavailable' });
    return { trust: 'low', ...NO_KEY };
  }

  private async create(
    input: RegisterInput,
    verdict: Verdict,
    context: RegisterContext,
    now: Date,
  ): Promise<Registration | null> {
    const kind =
      input.attestation.type === 'none' && !context.debugAttestation ? 'none' : 'attested';
    const cap = await this.limits.consumeRegistration(context.network, kind);
    if (!cap.allowed) {
      throw new ApiError('RATE_LIMITED', {
        details: { reason: cap.reason === 'noneCap' ? 'lowTrustCap' : 'burst' },
        retryAfterSec: secondsUntilUtcMidnight(now),
      });
    }
    const deviceReused = await this.deviceReused(input);
    const binding = await this.binding(input.platform, input.installId);
    const inserted = await this.installs.insert({
      id: input.installId,
      platform: input.platform,
      trust: verdict.trust,
      installSecretHash: toHex(await this.deps.crypto.sha256(input.installSecret)),
      deviceKeyHash: await this.deviceKeyHash(input),
      deviceReused,
      appVersion: input.appVersion,
      locale: input.locale,
      timezone: input.timezone,
      attestKeyId: verdict.attestKeyId,
      attestPublicKey: verdict.attestPublicKey,
      attestCounter: verdict.attestCounter,
      attestEnv: verdict.attestEnv,
      integrityVerdict: verdict.integrityVerdict,
      appleAccountToken: binding.appleAccountToken ?? null,
      playAccountHash: binding.playAccountId ?? null,
      now: now.toISOString(),
    });
    if (!inserted) {
      return null;
    }
    await this.markDevice(input);
    this.deps.metrics.write({
      event: 'install_registered',
      platform: input.platform,
      locale: input.locale,
      code: verdict.trust,
    });
    return this.issue(true, input.installId, binding, now);
  }

  private async reregister(
    existing: InstallRow,
    input: RegisterInput,
    verdict: Verdict,
    now: Date,
  ): Promise<Registration> {
    if (existing.platform !== input.platform || !(await this.provesOwnership(existing, input))) {
      this.reject(input.platform, 'ownership');
    }
    const today = now.toISOString().slice(0, 10);
    const [day, count] = (existing.reregisterCountDay ?? '').split(':');
    const usedToday = day === today ? Number(count) || 0 : 0;
    if (usedToday >= REREGISTRATIONS_PER_DAY) {
      throw new ApiError('RATE_LIMITED', {
        details: { reason: 'burst' },
        retryAfterSec: secondsUntilUtcMidnight(now),
      });
    }
    const binding = await this.binding(input.platform, input.installId);
    const generation = await this.installs.reregister({
      id: existing.id,
      expectedGeneration: existing.tokenGeneration,
      trust: verdict.trust,
      appVersion: input.appVersion,
      locale: input.locale,
      timezone: input.timezone,
      deviceKeyHash: await this.deviceKeyHash(input),
      attestKeyId: verdict.attestKeyId,
      attestPublicKey: verdict.attestPublicKey,
      attestCounter: verdict.attestCounter,
      attestEnv: verdict.attestEnv,
      integrityVerdict: verdict.integrityVerdict,
      appleAccountToken: binding.appleAccountToken ?? null,
      playAccountHash: binding.playAccountId ?? null,
      reregisterCountDay: `${today}:${String(usedToday + 1)}`,
      now: now.toISOString(),
    });
    if (generation === null) {
      throw new ApiError('REQUEST_IN_PROGRESS', { retryAfterSec: 3 });
    }
    this.deps.logger.log('info', 'install_reregistered', {
      plat: input.platform,
      trust: verdict.trust,
      reactivated: existing.status === 'deleted',
    });
    return this.issue(false, existing.id, binding, now);
  }

  private async provesOwnership(existing: InstallRow, input: RegisterInput): Promise<boolean> {
    if (existing.installSecretHash !== null) {
      const presented = await this.deps.crypto.sha256(input.installSecret);
      let stored: Uint8Array;
      try {
        stored = fromHex(existing.installSecretHash);
      } catch {
        stored = new Uint8Array();
      }
      if (this.deps.crypto.timingSafeEqual(presented, stored)) {
        return true;
      }
    }
    const { attestation } = input;
    const assertion =
      attestation.type === 'play_integrity' ? undefined : attestation.previousKeyAssertion;
    if (
      existing.platform !== 'ios' ||
      assertion === undefined ||
      existing.attestPublicKey === null
    ) {
      return false;
    }
    const config = await this.deps.config.snapshot();
    const result = await this.deps.appAttest.verifyAssertion({
      assertion: fromBase64(assertion),
      clientDataHash: await registrationClientDataHash(
        this.deps.crypto,
        attestation.challenge,
        input.installId,
        input.deviceCheckToken,
      ),
      publicKey: existing.attestPublicKey,
      previousCounter: existing.attestCounter ?? 0,
      allowedAppIds: resolveAllowedAppIds(config['attest.allowedAppIds'], this.deps.appleTeamId),
    });
    return result.ok;
  }

  /** iOS DeviceCheck `bit0` (03 §3.7): failures degrade to "not reused" and are counted. */
  private async deviceReused(input: RegisterInput): Promise<boolean> {
    if (input.platform !== 'ios' || input.deviceCheckToken === undefined) {
      return false;
    }
    const bits = await this.deps.deviceCheck.queryBits(input.deviceCheckToken);
    if (!bits.ok) {
      this.deps.metrics.write({ event: 'devicecheck_error', platform: 'ios', code: 'query' });
      return false;
    }
    return bits.bit0;
  }

  /** Sets `bit0` after the first registration on the device (03 §3.7). */
  private async markDevice(input: RegisterInput): Promise<void> {
    if (input.platform !== 'ios' || input.deviceCheckToken === undefined) {
      return;
    }
    const bits = await this.deps.deviceCheck.queryBits(input.deviceCheckToken);
    if (bits.ok && bits.bit0) {
      return;
    }
    const updated = await this.deps.deviceCheck.updateBits(input.deviceCheckToken, {
      bit0: true,
      bit1: bits.ok ? bits.bit1 : false,
    });
    if (!updated) {
      this.deps.metrics.write({ event: 'devicecheck_error', platform: 'ios', code: 'update' });
    }
  }

  private async deviceKeyHash(input: RegisterInput): Promise<string | null> {
    if (input.platform !== 'android' || input.deviceKey === undefined) {
      return null;
    }
    return toHex(await this.deps.crypto.hmacSha256(this.deps.keys.deviceKey(), input.deviceKey));
  }

  private async binding(platform: Platform, installId: string): Promise<PurchaseBinding> {
    return platform === 'ios'
      ? {
          appleAccountToken: await appleAccountToken(
            this.deps.crypto,
            this.deps.keys.appleAccountNs(),
            installId,
          ),
        }
      : {
          playAccountId: await playAccountId(
            this.deps.crypto,
            this.deps.keys.playAccount(),
            installId,
          ),
        };
  }

  private async issue(
    created: boolean,
    installId: string,
    purchaseBinding: PurchaseBinding,
    now: Date,
  ): Promise<Registration> {
    const install = await this.installs.findById(installId);
    if (install === null) {
      throw new Error('install vanished after registration');
    }
    const { token, expiresAt } = await this.deps.tokenSigner.sign(
      {
        sub: install.id,
        gen: install.tokenGeneration,
        trust: install.trust,
        plat: install.platform,
      },
      now,
    );
    return {
      created,
      install,
      installToken: token,
      expiresAt,
      trust: install.trust,
      purchaseBinding,
    };
  }

  /**
   * One non-sensitive line per accepted registration attempt: the
   * attestation type the client sent, its `none` reason and the resulting
   * trust, so a low-trust registration shows why (never a key or token).
   */
  private logVerdict(input: RegisterInput, verdict: Verdict): void {
    const { attestation } = input;
    this.deps.logger.log(verdict.trust === 'low' ? 'warn' : 'info', 'install_attest_verdict', {
      plat: input.platform,
      att: attestation.type,
      noneReason: attestation.type === 'none' ? attestation.reason : undefined,
      trust: verdict.trust,
      attEnv: verdict.attestEnv ?? undefined,
      appVersion: input.appVersion,
    });
  }

  private reject(platform: Platform, detail: string): never {
    this.deps.metrics.write({ event: 'attest_failed', platform, code: detail });
    this.deps.logger.log('warn', 'install_attest_rejected', { plat: platform, detail });
    throw new ApiError('ATTESTATION_FAILED');
  }
}

const HOUR_MS = 3_600_000;

export type TimezoneChange = 'unchanged' | 'changed';

/**
 * `PUT /v1/installs/me/timezone` (03 §3.5, RC8). The caller validated the
 * zone. Same zone → no-op. A change within `readings.tzCooldownHours` of the
 * last one → `409 TIMEZONE_CHANGE_TOO_SOON` with `details.allowedAfter`.
 * Otherwise a compare-and-set on `tz_changed_at` stores it and bumps
 * `state_version`; a lost race is decided again against the winner's row.
 */
async function changeInstallTimezone(
  deps: Deps,
  install: InstallRow,
  timezone: string,
): Promise<TimezoneChange> {
  const repo = new InstallRepo(deps.db);
  const config = await deps.config.snapshot();
  const now = deps.clock.now();
  const cooldownMs = config['readings.tzCooldownHours'] * HOUR_MS;
  const decide = (row: InstallRow): TimezoneChange | undefined => {
    if (row.timezone === timezone) {
      return 'unchanged';
    }
    if (row.tzChangedAt !== null) {
      const allowedAfter = Date.parse(row.tzChangedAt) + cooldownMs;
      if (now.getTime() < allowedAfter) {
        throw new ApiError('TIMEZONE_CHANGE_TOO_SOON', {
          details: { allowedAfter: new Date(allowedAfter).toISOString() },
        });
      }
    }
    return undefined;
  };

  const early = decide(install);
  if (early !== undefined) {
    return early;
  }
  const changed = await repo.changeTimezone({
    id: install.id,
    timezone,
    changedAt: now.toISOString(),
    expectedChangedAt: install.tzChangedAt,
  });
  if (changed) {
    return 'changed';
  }
  // Lost the compare-and-set: a concurrent change won, so decide against its
  // row (same zone → no-op, otherwise inside the cooldown it just started).
  const winner = await repo.findById(install.id);
  if (winner === null) {
    throw new ApiError('UNAUTHENTICATED');
  }
  return decide(winner) ?? 'unchanged';
}

/**
 * `DELETE /v1/installs/me` (03 §3.6, RC37), one D1 batch:
 *
 * - deleted: `reading_reports`, `readings` (except a reading whose hold is
 *   still `held`, so the stale-hold cron can refund it), `ad_rewards`, the
 *   install's other `idempotency_keys` rows (the running request keeps its
 *   own, so a retry replays the `204`), `daily_usage` rows other than today's
 *   local date, and the device's `device_daily_usage` rows before today;
 * - nulled: `installs.locale`;
 * - kept: the `installs` row (status unchanged), tokens, secret and device
 *   hashes, the ledger and purchases, so the balance and today's allowance
 *   are unchanged;
 * - `state_version + 1`.
 */
async function eraseInstallData(
  deps: Deps,
  install: InstallRow,
  keep: IdempotencyKeyRef | undefined,
): Promise<void> {
  const db = deps.db;
  const today = localDate(deps.clock.now(), installTimezone(install));
  const idempotency = new IdempotencyRepo(db);
  const installs = new InstallRepo(db);
  const statements = [
    new ReportRepo(db).eraseStmt(install.id),
    new ReadingRepo(db).eraseSettledStmt(install.id),
    new RewardRepo(db).eraseStmt(install.id),
    keep === undefined
      ? idempotency.eraseStmt(install.id)
      : idempotency.eraseExceptStmt(install.id, keep),
    new DailyUsageRepo(db).erasePastStmt(install.id, today),
    installs.eraseLocaleStmt(install.id),
    installs.bumpStateVersionStmt(install.id),
  ];
  if (install.deviceKeyHash !== null) {
    statements.push(new DeviceUsageRepo(db).erasePastStmt(install.deviceKeyHash, today));
  }
  await db.batch(statements);
}
