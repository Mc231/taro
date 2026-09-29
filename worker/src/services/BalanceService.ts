import type { RuntimeConfig } from '../config/schema';
import type { Deps } from '../deps';
import {
  computeBalance,
  currentFreeDaily,
  freeRemaining,
  holdFailureReason,
  reusedDeviceFirstDay,
  type AllowanceInput,
  type BalanceDto,
} from '../domain/allowance';
import {
  freePaused,
  holdPlan,
  type HoldBucket,
  type InsufficientReason,
} from '../domain/consumptionOrder';
import {
  DEFAULT_TIMEZONE,
  isoSeconds,
  isValidTimeZone,
  localDate,
  nextResetUtc,
} from '../domain/dayBoundary';
import {
  holdExpired,
  isLedgerBucket,
  nextAttempt,
  refundRule,
  type RefundReason,
} from '../domain/ledgerRules';
import { ApiError } from '../http/errors';
import { SoftLimits, type ClientNetwork } from '../http/middleware/rateLimit';
import { inst8 } from '../logging/redact';
import { DailyUsageRepo } from '../repos/DailyUsageRepo';
import { DeviceUsageRepo } from '../repos/DeviceUsageRepo';
import { InstallRepo, type InstallRow } from '../repos/InstallRepo';
import { LedgerRepo, readingRef } from '../repos/LedgerRepo';
import {
  ReadingRepo,
  type ChargeSource,
  type HoldExpectation,
  type HoldSource,
  type ReadingRow,
  type ReadingStatus,
} from '../repos/ReadingRepo';
import { RewardRepo } from '../repos/RewardRepo';
import { BudgetService } from './BudgetService';

/** `last_seen_at` is written at most once per hour (03 §5.1). */
export const LAST_SEEN_INTERVAL_MS = 3_600_000;

/** Hold/commit loops re-read the row after a lost race at most this often. */
const MAX_CAS_ROUNDS = 3;

export interface BalanceReadOptions {
  /** `X-Taro-App-Version`, stored with `last_seen_at`. */
  readonly appVersion?: string | undefined;
  /** Client network for the low-trust free cap per IP prefix (03 §2.4). */
  readonly network?: ClientNetwork | undefined;
}

export interface HoldRequest {
  readonly installId: string;
  /** `readings.id` of a row of this install (created by the reading route). */
  readonly readingId: string;
  /** `readings.status` while held: `held` (pre-draw, §9.0) or `generating` (inline, §9.1). */
  readonly status?: 'held' | 'generating';
  /** Low-trust installs: the IP-prefix cap and the `(platform, appVersion)` alert bucket. */
  readonly network?: ClientNetwork | undefined;
  readonly appVersion?: string | undefined;
}

export type HoldResult =
  | {
      readonly kind: 'held';
      readonly chargeSource: HoldSource;
      readonly attempt: number;
      readonly expiresAt: string;
      /** A live hold was found and its TTL extended (idempotent renewal, §9.0). */
      readonly renewed: boolean;
    }
  | {
      /** `402 INSUFFICIENT_CREDITS`; the row is `no_credit` (03 §5.3 step 2). */
      readonly kind: 'insufficient';
      readonly reason: InsufficientReason;
      readonly freeResetsAt: string;
      readonly balance: BalanceDto;
    }
  /** The reading was already committed; nothing is held twice. */
  | { readonly kind: 'consumed'; readonly chargeSource: ChargeSource };

export interface RefundRequest {
  readonly readingId: string;
  readonly reason: RefundReason;
  /** Refund only this attempt (a caller that loaded the row earlier). */
  readonly attempt?: number;
}

export interface RefundResult {
  /** This call gave the hold back; false when it was not `held` (already settled). */
  readonly refunded: boolean;
  readonly source: HoldSource | null;
  readonly attempt: number | null;
}

export interface CommitRequest {
  readonly readingId: string;
  readonly network?: ClientNetwork | undefined;
  readonly appVersion?: string | undefined;
}

export type CommitOutcome =
  /** `held → consumed`. */
  | 'committed'
  | 'already_committed'
  /** The stale-hold cron had refunded the hold; a new attempt was held and consumed. */
  | 'reheld'
  /** Refunded and no credit left: delivered uncharged, logged (03 §5.3 step 4). */
  | 'commit_after_refund'
  /** The row never had a hold. */
  | 'no_hold';

export interface CommitResult {
  readonly outcome: CommitOutcome;
  readonly chargeSource: ChargeSource;
  readonly attempt: number;
}

/** `402 INSUFFICIENT_CREDITS` with `details.freeResetsAt` and `details.reason` (03 §2.2). */
export function insufficientCreditsError(
  result: Extract<HoldResult, { kind: 'insufficient' }>,
): ApiError {
  return new ApiError('INSUFFICIENT_CREDITS', {
    details: { freeResetsAt: result.freeResetsAt, reason: result.reason },
  });
}

/** The install's zone, or UTC when none (or an unusable one) is stored. */
export function installTimezone(install: Pick<InstallRow, 'timezone'>): string {
  const tz = install.timezone;
  return tz !== null && isValidTimeZone(tz) ? tz : DEFAULT_TIMEZONE;
}

/** Everything a hold batch needs, computed once per attempt. */
interface HoldContext {
  readonly install: InstallRow;
  readonly expected: HoldExpectation;
  readonly attempt: number;
  readonly today: string;
  readonly expiresAt: string;
  readonly status: ReadingStatus;
  readonly current: number;
  readonly buckets: readonly HoldBucket[];
  readonly lowTrustFree: boolean;
  readonly now: Date;
}

/** Statements of a hold batch and the index of each bucket's gate. */
interface HoldBatch {
  readonly statements: D1PreparedStatement[];
  readonly gates: ReadonlyMap<HoldBucket, number>;
}

/**
 * Balance reads and the money paths of a reading (03 §5, BE5, BE6; RC49,
 * RC50, RC52, RC53, RC67): `read`, `hold`, `refund` and `commit`.
 *
 * There is no balance cache: `paid`/`bonus` are ledger SUMs. Each mutation is
 * **one** D1 batch whose first statement is a compare-and-set on
 * `readings.hold_state` carrying every balance condition, followed by
 * statements chained on `(SELECT changes()) = 1` (`repos/batchGuard.ts`,
 * docs/ARCHITECTURE.md §Ledger). Every applied batch bumps
 * `installs.state_version` (`ledgerVersion`).
 */
export class BalanceService {
  private readonly installs: InstallRepo;
  private readonly usage: DailyUsageRepo;
  private readonly devices: DeviceUsageRepo;
  private readonly ledger: LedgerRepo;
  private readonly rewards: RewardRepo;
  private readonly readings: ReadingRepo;

  constructor(
    private readonly deps: Deps,
    private readonly budget: BudgetService = new BudgetService(deps.db),
  ) {
    this.installs = new InstallRepo(deps.db);
    this.usage = new DailyUsageRepo(deps.db);
    this.devices = new DeviceUsageRepo(deps.db);
    this.ledger = new LedgerRepo(deps.db);
    this.rewards = new RewardRepo(deps.db);
    this.readings = new ReadingRepo(deps.db);
  }

  /**
   * The balance of `installId` (03 §5.1, §5.2), or null when the install does
   * not exist or is `deleted`. One D1 batch lazily snapshots today's
   * `daily_usage` row (raised, never lowered) and reads the row, the ledger
   * SUMs, the last rewarded grant, the device row and `state_version`, so
   * `ledgerVersion` always matches the balances it is sent with (RC67). The
   * snapshot does not change what the DTO reports, so it does not bump
   * `state_version`.
   */
  async read(installId: string, options: BalanceReadOptions = {}): Promise<BalanceDto | null> {
    const found = await this.installs.findById(installId);
    if (found === null || found.status === 'deleted') {
      return null;
    }
    const config = await this.deps.config.snapshot();
    const now = this.deps.clock.now();
    const input = await this.gather(found, config, now, options.network);
    await this.touch(found, now, options.appVersion);
    return computeBalance(input);
  }

  /**
   * Takes the hold of one reading attempt (03 §5.3 steps 1–2, §9.0): free →
   * bonus → paid in **one** batch. A live hold is renewed; an expired one is
   * refunded first and replaced by a new attempt. With nothing left the row
   * becomes `no_credit` and the result carries the 402 reason and a fresh
   * balance. Concurrent calls for the same reading take one hold.
   */
  async hold(request: HoldRequest): Promise<HoldResult> {
    for (let round = 0; round < MAX_CAS_ROUNDS; round++) {
      const reading = await this.loadReading(request.readingId, request.installId);
      const now = this.deps.clock.now();
      const config = await this.deps.config.snapshot();
      if (reading.holdState === 'consumed') {
        return { kind: 'consumed', chargeSource: reading.chargeSource };
      }
      if (reading.holdState === 'held') {
        if (!holdExpired(reading.holdExpiresAt, now)) {
          const expiresAt = holdExpiry(now, config);
          if (await this.readings.extendHold(reading.id, reading.attempt, expiresAt)) {
            return {
              kind: 'held',
              chargeSource: reading.holdSource ?? 'paid',
              attempt: reading.attempt,
              expiresAt,
              renewed: true,
            };
          }
        } else {
          await this.refund({ readingId: reading.id, reason: 'expired', attempt: reading.attempt });
        }
        continue;
      }
      const install = await this.loadInstall(request.installId);
      const context = await this.holdContext(install, reading, config, now, request);
      const batch = this.holdBatch(context);
      batch.statements.push(
        this.readings.noCreditStmt(context.expected),
        this.readings.findByIdStmt(reading.id),
      );
      const results = await this.deps.db.batch(batch.statements);
      const applied = appliedBucket(batch, results);
      const after = ReadingRepo.parse(results.at(-1)?.results[0]);
      if (applied !== null) {
        await this.afterHold(context, applied, request);
      }
      if (after.holdState === 'held' && after.attempt === context.attempt) {
        return {
          kind: 'held',
          chargeSource: after.holdSource ?? applied ?? 'paid',
          attempt: after.attempt,
          expiresAt: after.holdExpiresAt ?? context.expiresAt,
          renewed: false,
        };
      }
      if (after.holdState === 'none' || after.holdState === 'refunded') {
        if (after.attempt === reading.attempt) {
          return this.insufficient(install, config, now, request.network);
        }
      }
    }
    throw new Error('hold: lost the compare-and-set too often');
  }

  /**
   * Gives a hold back (03 §5.3 step 3): CAS `held → refunded`, then free →
   * `free_used - 1` on the hold's own date in both usage tables; bonus/paid
   * → a `+1` `reading_refund` / `reading_undelivered` entry for
   * `{readingId}#{attempt}`. A second refund of the same attempt is a no-op.
   */
  async refund(request: RefundRequest): Promise<RefundResult> {
    const reading = await this.readings.findById(request.readingId);
    if (
      reading?.holdState !== 'held' ||
      reading.holdSource === null ||
      (request.attempt !== undefined && request.attempt !== reading.attempt)
    ) {
      return { refunded: false, source: null, attempt: reading?.attempt ?? null };
    }
    const source = reading.holdSource;
    const install = await this.loadInstall(reading.installId);
    const config = await this.deps.config.snapshot();
    const now = this.deps.clock.now();
    const rule = refundRule(request.reason);
    const holdDay = {
      installId: install.id,
      localDate: reading.holdLocalDate ?? reading.localDate,
    };
    const statements = [
      this.readings.refundGateStmt(reading.id, reading.attempt, source, rule.status),
      this.installs.bumpStateVersionAfterStmt(install.id),
    ];
    if (isLedgerBucket(source)) {
      statements.push(
        this.ledger.appendAfterStmt({
          installId: install.id,
          bucket: source,
          delta: 1,
          reason: rule.ledgerReason,
          refType: 'reading',
          refId: readingRef(reading.id, reading.attempt),
          createdAt: now.toISOString(),
        }),
        this.usage.refundAfterStmt(holdDay, false),
      );
    } else {
      statements.push(this.usage.refundAfterStmt(holdDay, true));
      if (install.deviceKeyHash !== null) {
        statements.push(
          this.devices.refundFreeAfterStmt({
            deviceKeyHash: install.deviceKeyHash,
            localDate: holdDay.localDate,
          }),
        );
      }
    }
    if (rule.countsAsDecline) {
      const today = localDate(now, installTimezone(install));
      statements.push(
        this.usage.declinedAfterStmt(
          { installId: install.id, localDate: today },
          currentFreeDaily(install.trust, config),
        ),
      );
    }
    const results = await this.deps.db.batch(statements);
    const refunded = results[0]?.meta.changes === 1;
    if (refunded) {
      this.refundMetric(request.reason, source, install);
    }
    return { refunded, source: refunded ? source : null, attempt: reading.attempt };
  }

  /**
   * Commits a delivered reading (03 §5.3 step 4): CAS `held → consumed`,
   * `completed`. If the stale-hold cron refunded it first, a new attempt is
   * held (free → bonus → paid) and consumed in the same batch; with no
   * credit left the reading is still delivered, uncharged, and logged as
   * `commit_after_refund`.
   */
  async commit(request: CommitRequest): Promise<CommitResult> {
    for (let round = 0; round < MAX_CAS_ROUNDS; round++) {
      const reading = await this.loadReading(request.readingId);
      const now = this.deps.clock.now();
      const completedAt = now.toISOString();
      switch (reading.holdState) {
        case 'consumed':
          return result('already_committed', reading.chargeSource, reading.attempt);
        case 'none':
          return result('no_hold', 'none', reading.attempt);
        case 'held': {
          const results = await this.deps.db.batch([
            this.readings.consumeGateStmt(reading.id, reading.attempt, completedAt),
            this.installs.bumpStateVersionAfterStmt(reading.installId),
          ]);
          if (results[0]?.meta.changes === 1) {
            return result('committed', reading.chargeSource, reading.attempt);
          }
          break;
        }
        case 'refunded': {
          const outcome = await this.commitAfterRefund(reading, request, now);
          if (outcome !== null) {
            return outcome;
          }
          break;
        }
      }
    }
    throw new Error('commit: lost the compare-and-set too often');
  }

  private async commitAfterRefund(
    reading: ReadingRow,
    request: CommitRequest,
    now: Date,
  ): Promise<CommitResult | null> {
    const install = await this.loadInstall(reading.installId);
    const config = await this.deps.config.snapshot();
    const context = await this.holdContext(install, reading, config, now, {
      installId: install.id,
      readingId: reading.id,
      network: request.network,
      appVersion: request.appVersion,
    });
    const batch = this.holdBatch(context);
    const completedAt = now.toISOString();
    batch.statements.push(
      this.readings.consumeGateStmt(reading.id, context.attempt, completedAt),
      this.readings.completeUnchargedStmt(reading.id, reading.attempt, completedAt),
      this.readings.findByIdStmt(reading.id),
    );
    const results = await this.deps.db.batch(batch.statements);
    const applied = appliedBucket(batch, results);
    const after = ReadingRepo.parse(results.at(-1)?.results[0]);
    if (applied !== null) {
      await this.afterHold(context, applied, request);
    }
    if (results.at(-3)?.meta.changes === 1) {
      return result('reheld', after.chargeSource, context.attempt);
    }
    if (results.at(-2)?.meta.changes === 1) {
      this.deps.logger.log('warn', 'commit_after_refund', {
        inst8: inst8(install.id),
        attempt: reading.attempt,
      });
      return result('commit_after_refund', 'none', reading.attempt);
    }
    return null;
  }

  private async holdContext(
    install: InstallRow,
    reading: ReadingRow,
    config: RuntimeConfig,
    now: Date,
    request: HoldRequest,
  ): Promise<HoldContext> {
    const timezone = installTimezone(install);
    const today = localDate(now, timezone);
    const current = currentFreeDaily(install.trust, config);
    const paused = freePaused((await this.budget.status(config, now)).tier);
    const lowTrust = install.trust === 'low';
    const ipCapReached =
      lowTrust &&
      request.network !== undefined &&
      !(await new SoftLimits(this.deps).peekLowTrustFree(request.network)).allowed;
    const plan = holdPlan({
      freeDaily: current,
      freePaused: paused,
      deviceReusedFirstDay: reusedDeviceFirstDay(install, timezone, today),
      lowTrustIpCapReached: ipCapReached,
    });
    return {
      install,
      expected: {
        id: reading.id,
        installId: install.id,
        state: reading.holdState,
        attempt: reading.attempt,
      },
      attempt: nextAttempt(reading.holdState, reading.attempt),
      today,
      expiresAt: holdExpiry(now, config),
      status: request.status ?? 'held',
      current,
      buckets: plan.buckets,
      lowTrustFree: lowTrust,
      now,
    };
  }

  /** One gate plus its chained statements per bucket, in consumption order. */
  private holdBatch(context: HoldContext): HoldBatch {
    const { install, expected, today, now } = context;
    const day = { installId: install.id, localDate: today };
    const statements: D1PreparedStatement[] = [];
    const gates = new Map<HoldBucket, number>();
    for (const bucket of context.buckets) {
      gates.set(bucket, statements.length);
      const target = {
        attempt: context.attempt,
        source: bucket,
        localDate: today,
        expiresAt: context.expiresAt,
        status: context.status,
      };
      if (bucket === 'free') {
        statements.push(
          this.readings.holdGateStmt(expected, target, {
            bucket,
            current: context.current,
            deviceKeyHash: install.deviceKeyHash,
          }),
          this.usage.takeFreeAfterStmt(day, context.current),
        );
        if (install.deviceKeyHash !== null) {
          statements.push(
            this.devices.takeFreeAfterStmt({
              deviceKeyHash: install.deviceKeyHash,
              localDate: today,
            }),
          );
        }
      } else {
        statements.push(
          this.readings.holdGateStmt(expected, target, { bucket }),
          this.ledger.appendAfterStmt({
            installId: install.id,
            bucket,
            delta: -1,
            reason: 'reading_hold',
            refType: 'reading',
            refId: readingRef(expected.id, context.attempt),
            createdAt: now.toISOString(),
          }),
          this.usage.countReadingAfterStmt(day, context.current),
        );
      }
      statements.push(this.installs.bumpStateVersionAfterStmt(install.id));
    }
    return { statements, gates };
  }

  /** Low-trust free holds count against the KV soft caps (03 §2.4, RC65). */
  private async afterHold(
    context: HoldContext,
    applied: HoldBucket,
    request: {
      readonly network?: ClientNetwork | undefined;
      readonly appVersion?: string | undefined;
    },
  ): Promise<void> {
    if (applied !== 'free' || !context.lowTrustFree) {
      return;
    }
    const limits = new SoftLimits(this.deps);
    if (request.network !== undefined) {
      await limits.consumeLowTrustFree(request.network);
    }
    await limits.recordLowTrustBucket(
      context.install.platform,
      request.appVersion ?? context.install.appVersion ?? 'unknown',
    );
  }

  private async insufficient(
    install: InstallRow,
    config: RuntimeConfig,
    now: Date,
    network: ClientNetwork | undefined,
  ): Promise<HoldResult> {
    const input = await this.gather(install, config, now, network);
    return {
      kind: 'insufficient',
      reason: holdFailureReason(input, freePaused(input.budgetTier)),
      freeResetsAt: isoSeconds(nextResetUtc(now, input.timezone)),
      balance: computeBalance(input),
    };
  }

  private refundMetric(reason: RefundReason, source: HoldSource, install: InstallRow): void {
    if (reason === 'expired' || reason === 'abandoned') {
      this.deps.metrics.write({
        event: 'hold_abandoned',
        chargeSource: source,
        platform: install.platform,
      });
    } else if (reason === 'undelivered') {
      this.deps.metrics.write({
        event: 'reading_undelivered_refund',
        chargeSource: source,
        platform: install.platform,
      });
    }
  }

  /** The `AllowanceInput` of `install` now, from one D1 batch (see `read`). */
  private async gather(
    found: InstallRow,
    config: RuntimeConfig,
    now: Date,
    network: ClientNetwork | undefined,
  ): Promise<AllowanceInput> {
    const installId = found.id;
    const timezone = installTimezone(found);
    const day = { installId, localDate: localDate(now, timezone) };
    const freeDaily = currentFreeDaily(found.trust, config);

    const statements = [
      this.usage.ensureStmt(day, freeDaily),
      this.usage.findStmt(day),
      this.ledger.balancesStmt(installId),
      this.rewards.lastGrantedAtStmt(installId),
      this.installs.findByIdStmt(installId),
    ];
    if (found.deviceKeyHash !== null) {
      statements.push(
        this.devices.findStmt({ deviceKeyHash: found.deviceKeyHash, localDate: day.localDate }),
      );
    }
    const results = await this.deps.db.batch<Record<string, unknown>>(statements);
    const row = (index: number): Record<string, unknown> | undefined => results[index]?.results[0];
    const install = InstallRepo.parse(row(4));
    const deviceRow = row(5);
    const last = row(3)?.['last'];

    const input: AllowanceInput = {
      now,
      timezone,
      install,
      usage: DailyUsageRepo.parse(row(1)),
      device: deviceRow === undefined ? null : DeviceUsageRepo.parse(deviceRow),
      balances: LedgerRepo.parseBalances(results[2]?.results ?? []),
      lastGrantedAt: typeof last === 'string' ? last : null,
      budgetTier: (await this.budget.status(config, now)).tier,
      lowTrustIpCapReached: false,
      config,
    };
    const lowTrustIpCapReached =
      install.trust === 'low' &&
      network !== undefined &&
      freeRemaining(input) > 0 &&
      !(await new SoftLimits(this.deps).peekLowTrustFree(network)).allowed;
    return { ...input, lowTrustIpCapReached };
  }

  private async loadInstall(installId: string): Promise<InstallRow> {
    const install = await this.installs.findById(installId);
    if (install === null) {
      throw new Error('balance: unknown install');
    }
    return install;
  }

  private async loadReading(readingId: string, installId?: string): Promise<ReadingRow> {
    const reading = await this.readings.findById(readingId);
    if (reading === null || (installId !== undefined && reading.installId !== installId)) {
      throw new Error('balance: unknown reading');
    }
    return reading;
  }

  /** `last_seen_at` at most hourly, sooner when the app version changed (03 §5.1). */
  private async touch(
    install: InstallRow,
    now: Date,
    appVersion: string | undefined,
  ): Promise<void> {
    const stale = now.getTime() - Date.parse(install.lastSeenAt) >= LAST_SEEN_INTERVAL_MS;
    const upgraded = appVersion !== undefined && appVersion !== install.appVersion;
    if (stale || upgraded) {
      await this.installs.touch(install.id, now.toISOString(), appVersion ?? null);
    }
  }
}

/** `readings.holdTtlSec` from now (03 §9.0), whole seconds. */
function holdExpiry(now: Date, config: RuntimeConfig): string {
  return isoSeconds(new Date(now.getTime() + config['readings.holdTtlSec'] * 1000));
}

/** The bucket whose gate changed a row, if any. */
function appliedBucket(batch: HoldBatch, results: readonly D1Result[]): HoldBucket | null {
  for (const [bucket, index] of batch.gates) {
    if (results[index]?.meta.changes === 1) {
      return bucket;
    }
  }
  return null;
}

function result(outcome: CommitOutcome, chargeSource: ChargeSource, attempt: number): CommitResult {
  return { outcome, chargeSource, attempt };
}
