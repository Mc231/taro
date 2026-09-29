import { AdmobSsvVerifier } from '../adapters/admob/SsvVerifier';
import type { RuntimeConfig } from '../config/schema';
import type { Deps } from '../deps';
import { currentFreeDaily, reusedDeviceFirstDay } from '../domain/allowance';
import { isoSeconds, localDate, nextResetUtc } from '../domain/dayBoundary';
import {
  adUnitAllowed,
  cancelledGrantDeadline,
  CANCEL_GRACE_SEC,
  intentDenial,
  ssvIntentRejection,
  visibleStatus,
  type IntentDenial,
  type SsvRejectReason,
} from '../domain/rewardRules';
import type { Trust } from '../domain/types';
import { ApiError } from '../http/errors';
import { SoftLimits, type ClientNetwork } from '../http/middleware/rateLimit';
import { inst8 } from '../logging/redact';
import { DailyUsageRepo } from '../repos/DailyUsageRepo';
import { DeviceUsageRepo } from '../repos/DeviceUsageRepo';
import { InstallRepo, type InstallRow } from '../repos/InstallRepo';
import { LedgerRepo } from '../repos/LedgerRepo';
import { RewardRepo, type RewardRow, type RewardStatus } from '../repos/RewardRepo';
import { WebhookEventRepo } from '../repos/WebhookEventRepo';
import { installTimezone } from './BalanceService';

/** `POST /v1/rewards/intents` response (03 §7.1): `customData == userId == intentId` (RC56). */
export interface RewardIntentDto {
  readonly intentId: string;
  readonly customData: string;
  readonly userId: string;
  readonly amount: number;
  readonly expiresAt: string;
}

export interface IntentRequest {
  readonly install: InstallRow;
  readonly adUnitId: string;
  /** Trust of this request after call attestation (`c.var.requestTrust`). */
  readonly trust: Trust;
  readonly network: ClientNetwork;
}

export interface IntentStatus {
  readonly status: RewardStatus;
  readonly amount: number;
}

export type SsvOutcome =
  /** Bad or unverifiable signature: `403` (03 §7.2 step 1). */
  | { readonly kind: 'forbidden' }
  | { readonly kind: 'granted'; readonly installId: string }
  /** The same `transaction_id` again: `200`, nothing granted twice. */
  | { readonly kind: 'duplicate' }
  /** Signed but not honoured: `200` with no grant, logged `ssv_rejected{reason}`. */
  | { readonly kind: 'rejected'; readonly reason: SsvRejectReason };

/** `webhook_events.id` of an SSV callback (03 §4). */
export function ssvEventId(transactionId: string): string {
  return `ssv:${transactionId}`;
}

/**
 * Rewarded ads through AdMob SSV (03 §7, 04 §9; BE14, RC33, RC35, RC56, RC57).
 *
 * - `createIntent`: enabled, ad unit allowed, cap (install and device),
 *   cooldown from the last grant, `device_reused`, low-trust IP cap; issues
 *   the intent in one batch that re-checks cap and cooldown in SQL, bumps
 *   `state_version` and cancels the install's other open intent.
 * - `cancel`: `issued → cancelled`; the row keeps a 2-minute SSV grace.
 * - `handleSsv`: signature, dedupe on `transaction_id`, intent checks, then
 *   the grant batch with the **snapshot** amount and no cap re-check (RC57).
 */
export class RewardService {
  private readonly rewards: RewardRepo;
  private readonly installs: InstallRepo;
  private readonly usage: DailyUsageRepo;
  private readonly devices: DeviceUsageRepo;
  private readonly ledger: LedgerRepo;
  private readonly events: WebhookEventRepo;

  constructor(private readonly deps: Deps) {
    this.rewards = new RewardRepo(deps.db);
    this.installs = new InstallRepo(deps.db);
    this.usage = new DailyUsageRepo(deps.db);
    this.devices = new DeviceUsageRepo(deps.db);
    this.ledger = new LedgerRepo(deps.db);
    this.events = new WebhookEventRepo(deps.db);
  }

  /** `POST /v1/rewards/intents` (03 §7.1). Throws the 403 / 409 / 400 `ApiError`s. */
  async createIntent(request: IntentRequest): Promise<RewardIntentDto> {
    const { install } = request;
    const config = await this.deps.config.snapshot();
    const now = this.deps.clock.now();
    throwIfDenied(await this.denial(install, config, now));
    if (!adUnitAllowed(request.adUnitId, config['rewarded.allowedAdUnitIds'])) {
      throw new ApiError('VALIDATION_FAILED', {
        details: {
          issues: [{ path: 'adUnitId', code: 'not_allowed', message: 'unknown ad unit' }],
        },
      });
    }
    const today = localDate(now, installTimezone(install));

    const limits = new SoftLimits(this.deps);
    const lowTrust = request.trust === 'low';
    if (lowTrust && !(await limits.peekLowTrustFree(request.network)).allowed) {
      throw lowTrustCapError(now);
    }

    const intentId = this.deps.ids.opaque(16);
    const expiresAt = new Date(now.getTime() + config['rewarded.intentTtlSec'] * 1000);
    const cooldownFrom = new Date(now.getTime() - config['rewarded.cooldownSec'] * 1000);
    const results = await this.deps.db.batch([
      this.rewards.issueGateStmt(
        {
          id: intentId,
          installId: install.id,
          localDate: today,
          amount: config['rewarded.amount'],
          adUnit: request.adUnitId,
          issuedAt: now.toISOString(),
          expiresAt: expiresAt.toISOString(),
        },
        {
          dailyCap: config['rewarded.dailyCap'],
          cooldownFrom: cooldownFrom.toISOString(),
          deviceKeyHash: install.deviceKeyHash,
        },
      ),
      this.installs.bumpStateVersionAfterStmt(install.id),
      this.rewards.cancelOthersAfterStmt({
        installId: install.id,
        keepId: intentId,
        graceUntil: new Date(now.getTime() + CANCEL_GRACE_SEC * 1000).toISOString(),
      }),
    ]);
    if (results[0]?.meta.changes !== 1) {
      // Lost a race against a grant or another intent: report the fresh reason.
      throwIfDenied(await this.denial(install, config, now));
      throw capError('cap', isoSeconds(nextResetUtc(now, installTimezone(install))));
    }
    if (lowTrust) {
      await limits.consumeLowTrustFree(request.network);
    }
    this.deps.metrics.write({ event: 'reward_issued', platform: install.platform });
    return {
      intentId,
      customData: intentId,
      userId: intentId,
      amount: config['rewarded.amount'],
      expiresAt: isoSeconds(expiresAt),
    };
  }

  /** `POST /v1/rewards/intents/{intentId}/cancel` (03 §7.3): idempotent; `404` for another install's intent. */
  async cancel(installId: string, intentId: string): Promise<void> {
    const now = this.deps.clock.now();
    const row = await this.ownIntent(installId, intentId);
    if (row.status !== 'issued') {
      return;
    }
    await this.deps.db.batch([
      this.rewards.cancelStmt(intentId, installId, cancelledGrantDeadline(row.expiresAt, now)),
      this.installs.bumpStateVersionAfterStmt(installId),
    ]);
  }

  /** `GET /v1/rewards/intents/{intentId}` (03 §7.3): the intent as the client sees it, or `404`. */
  async status(installId: string, intentId: string): Promise<IntentStatus> {
    const row = await this.ownIntent(installId, intentId);
    return { status: visibleStatus(row, this.deps.clock.now()), amount: row.amount };
  }

  /** `GET /v1/ads/admob/ssv` (03 §7.2). Rejects only when the verifier keys cannot be fetched. */
  async handleSsv(query: string): Promise<SsvOutcome> {
    const verified = await new AdmobSsvVerifier(this.deps.admobKeys).verify(query);
    if (!verified.ok) {
      this.deps.metrics.write({ event: 'webhook_sig_failed', code: 'admob' });
      this.deps.logger.log('warn', 'ssv_rejected', {
        reason: 'signature',
        detail: verified.reason,
      });
      return { kind: 'forbidden' };
    }
    const params = verified.params;
    const txn = params['transaction_id'] ?? '';
    const customData = params['custom_data'] ?? '';
    if (txn === '' || customData === '') {
      return this.reject('malformed', null);
    }
    if ((await this.events.find(ssvEventId(txn))) !== null) {
      return this.duplicate();
    }
    const intent = await this.rewards.findById(customData);
    if (intent === null) {
      return this.reject('unknown_intent', txn);
    }
    const now = this.deps.clock.now();
    const config = await this.deps.config.snapshot();
    const adUnit = params['ad_unit'] ?? '';
    const mismatch: SsvRejectReason | null =
      params['user_id'] !== customData
        ? 'user_mismatch'
        : adUnitAllowed(adUnit, config['rewarded.allowedAdUnitIds'])
          ? null
          : 'ad_unit';
    if (mismatch !== null) {
      await this.rewards.reject(intent.id, mismatch);
      return this.reject(mismatch, txn);
    }
    const rejection = ssvIntentRejection(intent, now);
    if (rejection !== null) {
      return intent.admobTxnId === txn ? this.duplicate() : this.reject(rejection, txn);
    }
    return this.grant(intent, { txn, adUnit, now, config, timestamp: params['timestamp'] });
  }

  private async grant(
    intent: RewardRow,
    input: {
      readonly txn: string;
      readonly adUnit: string;
      readonly now: Date;
      readonly config: RuntimeConfig;
      readonly timestamp: string | undefined;
    },
  ): Promise<SsvOutcome> {
    const install = await this.installs.findById(intent.installId);
    if (install === null) {
      return this.reject('unknown_intent', input.txn);
    }
    const nowIso = input.now.toISOString();
    const today = localDate(input.now, installTimezone(install));
    const statements = [
      this.rewards.grantGateStmt({
        id: intent.id,
        admobTxnId: input.txn,
        adUnit: input.adUnit,
        now: nowIso,
      }),
      this.ledger.appendAfterStmt({
        installId: install.id,
        bucket: 'bonus',
        delta: intent.amount,
        reason: 'ad_reward',
        refType: 'ad_reward',
        refId: intent.id,
        createdAt: nowIso,
      }),
      this.usage.rewardedGrantAfterStmt(
        { installId: install.id, localDate: today },
        currentFreeDaily(install.trust, input.config),
      ),
    ];
    if (install.deviceKeyHash !== null) {
      statements.push(
        this.devices.rewardedGrantAfterStmt({
          deviceKeyHash: install.deviceKeyHash,
          localDate: today,
        }),
      );
    }
    statements.push(this.installs.bumpStateVersionAfterStmt(install.id));

    let applied: boolean;
    try {
      applied = (await this.deps.db.batch(statements))[0]?.meta.changes === 1;
    } catch (err) {
      // `admob_txn_id` is UNIQUE: the transaction already granted another intent.
      if ((await this.rewards.findByTxn(input.txn)) !== null) {
        return this.reject('duplicate_txn', input.txn);
      }
      throw err;
    }
    if (!applied) {
      // Lost a race (a parallel delivery granted it, or it just expired).
      const after = await this.rewards.findById(intent.id);
      if (after?.admobTxnId === input.txn) {
        return this.duplicate();
      }
      const reason = after === null ? 'unknown_intent' : ssvIntentRejection(after, input.now);
      return this.reject(reason ?? 'expired', input.txn);
    }
    await this.events.record({
      id: ssvEventId(input.txn),
      source: 'admob',
      type: 'reward',
      status: 'processed',
      receivedAt: nowIso,
    });
    const sentAt = Number(input.timestamp);
    this.deps.metrics.write({
      event: 'reward_granted',
      platform: install.platform,
      credits: intent.amount,
      ...(Number.isFinite(sentAt) && sentAt > 0
        ? { latencyMs: Math.max(0, input.now.getTime() - sentAt) }
        : {}),
    });
    this.deps.logger.log('info', 'reward_granted', {
      inst8: inst8(install.id),
      amount: intent.amount,
    });
    return { kind: 'granted', installId: install.id };
  }

  private async reject(reason: SsvRejectReason, txn: string | null): Promise<SsvOutcome> {
    if (txn !== null) {
      await this.events.record({
        id: ssvEventId(txn),
        source: 'admob',
        type: 'reward',
        status: 'ignored',
        receivedAt: this.deps.clock.now().toISOString(),
      });
    }
    this.deps.metrics.write({ event: 'reward_rejected', code: reason });
    this.deps.logger.log('warn', 'ssv_rejected', { reason });
    return { kind: 'rejected', reason };
  }

  private duplicate(): SsvOutcome {
    this.deps.logger.log('info', 'ssv_duplicate', {});
    return { kind: 'duplicate' };
  }

  private async ownIntent(installId: string, intentId: string): Promise<RewardRow> {
    const row = await this.rewards.findById(intentId);
    if (row?.installId !== installId) {
      throw new ApiError('NOT_FOUND');
    }
    return row;
  }

  /** Cap, cooldown and `device_reused` of `install` now (03 §7.1), from one batch. */
  private async denial(
    install: InstallRow,
    config: RuntimeConfig,
    now: Date,
  ): Promise<IntentDenial | null> {
    const timezone = installTimezone(install);
    const today = localDate(now, timezone);
    const statements = [
      this.usage.findStmt({ installId: install.id, localDate: today }),
      this.rewards.lastGrantedAtStmt(install.id),
    ];
    if (install.deviceKeyHash !== null) {
      statements.push(
        this.devices.findStmt({ deviceKeyHash: install.deviceKeyHash, localDate: today }),
      );
    }
    const results = await this.deps.db.batch<Record<string, unknown>>(statements);
    const row = (index: number): Record<string, unknown> | undefined => results[index]?.results[0];
    const usage = row(0);
    const device = row(2);
    const last = row(1)?.['last'];
    return intentDenial({
      now,
      enabled: config['rewarded.enabled'],
      dailyCap: config['rewarded.dailyCap'],
      cooldownSec: config['rewarded.cooldownSec'],
      grantedToday: Math.max(
        usage === undefined ? 0 : DailyUsageRepo.parse(usage).rewardedGranted,
        device === undefined ? 0 : DeviceUsageRepo.parse(device).rewardedGranted,
      ),
      lastGrantedAt: typeof last === 'string' ? last : null,
      deviceReusedFirstDay: reusedDeviceFirstDay(install, timezone, today),
      resetsAt: nextResetUtc(now, timezone),
    });
  }
}

function capError(reason: 'cap' | 'cooldown', availableAt: string): ApiError {
  return new ApiError('REWARDED_DAILY_CAP', { details: { reason, availableAt } });
}

function throwIfDenied(denial: IntentDenial | null): void {
  if (denial === null) {
    return;
  }
  throw denial.kind === 'disabled'
    ? new ApiError('REWARDED_DISABLED')
    : capError(denial.reason, denial.availableAt);
}

/** Low-trust installs share the per-IP-prefix free cap (03 Q8, §2.4); it resets at UTC midnight. */
function lowTrustCapError(now: Date): ApiError {
  const midnight = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 1);
  return capError('cap', isoSeconds(new Date(midnight)));
}
