import type { Deps } from '../deps';
import {
  computeBalance,
  currentFreeDaily,
  freeRemaining,
  type AllowanceInput,
  type BalanceDto,
} from '../domain/allowance';
import { DEFAULT_TIMEZONE, isValidTimeZone, localDate } from '../domain/dayBoundary';
import { SoftLimits, type ClientNetwork } from '../http/middleware/rateLimit';
import { DailyUsageRepo } from '../repos/DailyUsageRepo';
import { DeviceUsageRepo } from '../repos/DeviceUsageRepo';
import { InstallRepo, type InstallRow } from '../repos/InstallRepo';
import { LedgerRepo } from '../repos/LedgerRepo';
import { RewardRepo } from '../repos/RewardRepo';
import { BudgetService } from './BudgetService';

/** `last_seen_at` is written at most once per hour (03 §5.1). */
export const LAST_SEEN_INTERVAL_MS = 3_600_000;

export interface BalanceReadOptions {
  /** `X-Taro-App-Version`, stored with `last_seen_at`. */
  readonly appVersion?: string | undefined;
  /** Client network for the low-trust free cap per IP prefix (03 §2.4). */
  readonly network?: ClientNetwork | undefined;
}

/** The install's zone, or UTC when none (or an unusable one) is stored. */
export function installTimezone(install: Pick<InstallRow, 'timezone'>): string {
  const tz = install.timezone;
  return tz !== null && isValidTimeZone(tz) ? tz : DEFAULT_TIMEZONE;
}

/**
 * `BalanceService.read` (03 §5.1, §5.2): the `BalanceDto` of one install.
 * Read-only for balances; holds, refunds and commits arrive in Phase 7.
 *
 * One D1 batch (a single serialised transaction) lazily snapshots today's
 * `daily_usage` row (`free_limit` = the current allowance, raised but never
 * lowered, §5.2) and reads the row, the ledger SUMs, the last rewarded grant,
 * the device row and `state_version`, so `ledgerVersion` always matches the
 * balances it is sent with (RC67). The snapshot never changes what the DTO
 * reports (`free.limit` is already `MAX(snapshot, current)`), so it does not
 * bump `state_version`.
 */
export class BalanceService {
  private readonly installs: InstallRepo;
  private readonly usage: DailyUsageRepo;
  private readonly devices: DeviceUsageRepo;
  private readonly ledger: LedgerRepo;
  private readonly rewards: RewardRepo;

  constructor(
    private readonly deps: Deps,
    private readonly budget: BudgetService = new BudgetService(deps.db),
  ) {
    this.installs = new InstallRepo(deps.db);
    this.usage = new DailyUsageRepo(deps.db);
    this.devices = new DeviceUsageRepo(deps.db);
    this.ledger = new LedgerRepo(deps.db);
    this.rewards = new RewardRepo(deps.db);
  }

  /** The balance of `installId`, or null when the install does not exist or is `deleted`. */
  async read(installId: string, options: BalanceReadOptions = {}): Promise<BalanceDto | null> {
    const found = await this.installs.findById(installId);
    if (found === null || found.status === 'deleted') {
      return null;
    }
    const config = await this.deps.config.snapshot();
    const now = this.deps.clock.now();
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
      options.network !== undefined &&
      freeRemaining(input) > 0 &&
      !(await new SoftLimits(this.deps).peekLowTrustFree(options.network)).allowed;

    await this.touch(install, now, options.appVersion);
    return computeBalance({ ...input, lowTrustIpCapReached });
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
