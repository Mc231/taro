import { MIN_REMAINING_FOR_REGENERATION_MS } from '../adapters/ai/callPolicy';
import type { RuntimeConfig } from '../config/schema';
import type { Deps } from '../deps';
import type { BalanceDto } from '../domain/allowance';
import type { BudgetTier } from '../domain/budget';
import { isoSeconds, localDate, nextResetUtc } from '../domain/dayBoundary';
import type { RefundReason } from '../domain/ledgerRules';
import { holdExpired } from '../domain/ledgerRules';
import {
  readingText,
  regenerationNote,
  validateReadingOutput,
  type AnsweredReading,
  type Violation,
} from '../domain/outputValidator';
import { aiCallCost } from '../domain/pricing';
import {
  declinedLimitReached,
  declinedSafety,
  DECLINED_LIMIT_REASON,
  moderationInputCategory,
  moderationOutputFlagged,
  type CrisisResource,
  type SafetyLayer,
} from '../domain/safetyPolicy';
import {
  checkSpread,
  validateReading,
  type ReadingRequestInput,
  type SpreadRef,
  type ValidReading,
} from '../domain/spreadValidation';
import { isRefusalCategory, type Locale, type RefusalCategory } from '../domain/types';
import { ApiError } from '../http/errors';
import {
  IN_PROGRESS_RETRY_AFTER_SEC,
  readIdempotentBody,
  TAKEOVER_AFTER_SEC,
} from '../http/middleware/idempotency';
import type { ClientNetwork } from '../http/middleware/rateLimit';
import { inst8 } from '../logging/redact';
import { totalUsage, type AiCall } from '../ports/AiProvider';
import { buildReadingPrompt } from '../prompts/build';
import { isPromptVersion, type PromptVersion } from '../prompts/templates';
import { DailyUsageRepo } from '../repos/DailyUsageRepo';
import { prefilter } from '../safety/prefilter';
import { IdempotencyRepo } from '../repos/IdempotencyRepo';
import type { InstallRow } from '../repos/InstallRepo';
import {
  ReadingRepo,
  type ChargeSource,
  type HoldSource,
  type ReadingRow,
  type ReadingStatus,
} from '../repos/ReadingRepo';
import { aiTierFor, AiRouter, type RoutedAiResult, type RoutedModerationResult } from './AiRouter';
import {
  BalanceService,
  installTimezone,
  insufficientCreditsError,
  type HoldResult,
} from './BalanceService';
import { BudgetService, isolateDauCache } from './BudgetService';

/**
 * AI readings (03 §9.0, §9.1; RC28, RC29, RC47, RC49–RC52, RC74, RC97).
 *
 * - `hold`: the pre-draw hold `POST /v1/readings/holds`.
 * - `create`: the pipeline of `POST /v1/readings` (gates → row state
 *   machine → L1 → budget gate → question moderation in parallel with the
 *   provider call → L2/L3 with one regeneration → commit, or refund +
 *   `failed`).
 * - `status` / `ack`: `GET /v1/readings/{clientReadingId}` and its delivery
 *   acknowledgement (RC51).
 *
 * The question and the AI output are never stored or logged (BE13); the
 * encrypted idempotency body is the only copy, kept until acknowledged.
 */

/** Idempotency scope of `POST /v1/readings` (03 §2.3): the replay body of a reading. */
export const READINGS_ROUTE = 'POST /v1/readings';
/** Past the deadline, a `generating` row is stale after this grace (03 §9.1, RC52). */
export const STALE_GENERATING_GRACE_MS = 60_000;
/** A completed body is kept at most this long unacknowledged (RC51). */
export const UNDELIVERED_AFTER_MS = 7 * 86_400_000;
/** `safety.category` of a model refusal without a known category (GLOSSARY §5.2). */
export const GENERIC_REFUSAL = { category: 'other', messageKey: 'refusalGeneric' } as const;

/** The consent header value (RC28). */
export const AI_CONSENT_HEADER = 'X-Taro-AI-Consent';

/** Per-request inputs from the route (headers, `cf`, the authenticated install). */
export interface ReadingRequestContext {
  readonly install: InstallRow;
  /** `X-Taro-AI-Consent`, raw. */
  readonly consent: string | undefined;
  /** `request.cf.country`, used transiently and never stored (03 §9.5). */
  readonly country: string | null;
  readonly network: ClientNetwork;
  readonly appVersion: string | undefined;
  /** The install's `BalanceDto` now (`GET /v1/balance` semantics). */
  readonly balance: () => Promise<BalanceDto>;
}

export interface HoldBody {
  readonly clientReadingId: string;
  readonly spread: SpreadRef;
  readonly locale: Locale;
}

export interface CreateBody extends ReadingRequestInput {
  readonly clientReadingId: string;
}

export interface HoldResponse {
  readonly clientReadingId: string;
  readonly chargeSource: HoldSource;
  readonly expiresAt: string;
  readonly balance: BalanceDto;
}

/** The canonical wire reading (RC30). */
export interface ReadingWire {
  readonly title: string;
  readonly overview: string;
  readonly cards: {
    readonly positionId: string;
    readonly cardId: string;
    readonly reversed: boolean;
    readonly interpretation: string;
  }[];
  readonly synthesis: string;
  readonly reflectionPrompts: string[];
}

/** A `CrisisResource` as sent (RC81). */
export type CrisisResourceWire = Omit<CrisisResource, 'languages'> & { languages: string[] };

export interface SafetyWire {
  readonly category: RefusalCategory | typeof GENERIC_REFUSAL.category;
  readonly messageKey: string;
  readonly crisisResources: CrisisResourceWire[];
  readonly canRephrase: boolean;
}

export interface ReadingResponse {
  readonly readingId: string;
  readonly status: 'completed' | 'declined';
  readonly chargeSource: ChargeSource;
  readonly promptVersion?: string;
  readonly reading?: ReadingWire;
  readonly safety?: SafetyWire;
  readonly balance: BalanceDto;
}

export interface ReadingState {
  readonly status: ReadingStatus;
  readonly attempt: number;
  readonly chargeSource?: ChargeSource;
  readonly promptVersion?: string;
  readonly reading?: ReadingWire;
  readonly safety?: SafetyWire;
  readonly balance: BalanceDto;
}

/** Why a reading failed (`readings.error_code`, metric `reading_failed.code`). */
type FailCode =
  | 'ai_unavailable'
  | 'timeout'
  | 'rate_limited'
  | 'upstream'
  | 'truncated'
  | 'invalid_output'
  | 'l3_violation'
  | 'deadline'
  | 'prompt';

/** Accumulated model calls of one reading attempt (both generations). */
interface CallLog {
  calls: AiCall[];
  model: string | null;
}

interface Attempt {
  readonly reading: ReadingRow;
  readonly source: HoldSource;
  readonly request: ValidReading;
  readonly ctx: ReadingRequestContext;
  readonly config: RuntimeConfig;
  readonly startedAt: number;
  readonly promptVersion: PromptVersion;
}

export class ReadingService {
  private readonly readings: ReadingRepo;
  private readonly usage: DailyUsageRepo;
  readonly budget: BudgetService;
  readonly balance: BalanceService;
  readonly router: AiRouter;

  constructor(private readonly deps: Deps) {
    this.readings = new ReadingRepo(deps.db);
    this.usage = new DailyUsageRepo(deps.db);
    this.budget = new BudgetService(deps.db, isolateDauCache, { metrics: deps.metrics });
    this.balance = new BalanceService(deps, this.budget);
    this.router = new AiRouter(deps);
  }

  // --- POST /v1/readings/holds (03 §9.0, RC50) -------------------------------

  async hold(ctx: ReadingRequestContext, body: HoldBody): Promise<HoldResponse> {
    const config = await this.deps.config.snapshot();
    const now = this.deps.clock.now();
    this.consentGate(ctx, config);
    this.availabilityGates(ctx, config);
    const spread = checkSpread(body.spread, config['spreads.enabled']);
    if (!spread.ok) {
      throw spreadInvalid(spread.reason);
    }
    const budgetTier = await this.budget.assertHoldAllowed(config, now);
    await this.perMinuteGate(ctx);

    let row = await this.readings.findByClientId(ctx.install.id, body.clientReadingId);
    if (row?.status === 'generating') {
      throw inProgress();
    }
    if (row?.status === 'completed' || row?.status === 'declined') {
      throw new ApiError('HOLD_CONFLICT');
    }
    if (row === null || !liveHold(row, now)) {
      await this.dayLimitGates(ctx, config, now);
    }
    row ??= await this.insertRow(ctx, body.clientReadingId, now, {
      spreadId: body.spread.id,
      cardCount: spread.positionIds.length,
      hasQuestion: false,
      locale: body.locale,
    });
    await this.releaseOtherHolds(ctx.install.id, row.id);

    const result = await this.balance.hold({
      installId: ctx.install.id,
      readingId: row.id,
      status: 'held',
      network: ctx.network,
      appVersion: ctx.appVersion,
    });
    if (result.kind === 'insufficient') {
      throw this.budget.freeStopError(result.reason) ?? insufficientCreditsError(result);
    }
    if (result.kind === 'consumed') {
      throw new ApiError('HOLD_CONFLICT');
    }
    const tier = aiTierFor(result.chargeSource, budgetTier);
    if (!(await this.router.checkAvailable(tier, config))) {
      await this.balance.refund({ readingId: row.id, reason: 'failed', attempt: result.attempt });
      throw new ApiError('AI_UNAVAILABLE');
    }
    return {
      clientReadingId: body.clientReadingId,
      chargeSource: result.chargeSource,
      expiresAt: result.expiresAt,
      balance: await this.balanceOf(ctx),
    };
  }

  // --- POST /v1/readings (03 §9.1) ---------------------------------------------

  async create(ctx: ReadingRequestContext, body: CreateBody): Promise<ReadingResponse> {
    const startedAt = this.deps.clock.now().getTime();
    const config = await this.deps.config.snapshot();
    this.consentGate(ctx, config);
    this.availabilityGates(ctx, config);
    const checked = validateReading(body, {
      enabledSpreads: config['spreads.enabled'],
      questionMaxChars: config['ai.questionMaxChars'],
    });
    if (!checked.ok) {
      throw checked.error === 'spread'
        ? spreadInvalid(checked.reason)
        : new ApiError('VALIDATION_FAILED', {
            details: {
              issues: [
                {
                  path: 'question',
                  code: 'too_big',
                  message: `more than ${String(config['ai.questionMaxChars'])} characters`,
                },
              ],
            },
          });
    }
    const existing = await this.readings.findByClientId(ctx.install.id, body.clientReadingId);
    try {
      await this.budget.assertHoldAllowed(config, new Date(startedAt));
    } catch (err) {
      // Hard stop: a live pre-draw hold is given back, never charged (03 §10.2).
      if (existing !== null && liveHold(existing, new Date(startedAt))) {
        await this.refund(existing, 'budget');
      }
      throw err;
    }
    await this.perMinuteGate(ctx);

    const replay = await this.replayIfSettled(ctx, existing);
    if (replay !== null) {
      return replay;
    }
    const reading = await this.holdForReading(ctx, config, body, checked.reading, existing);
    await this.readings.describe(reading.id, {
      spreadId: checked.reading.spreadId,
      cardCount: checked.reading.cards.length,
      hasQuestion: checked.reading.question !== '',
      locale: checked.reading.locale,
    });
    const promptVersion = isPromptVersion(config['ai.promptVersion'])
      ? config['ai.promptVersion']
      : 'v1';
    return this.generate({
      reading,
      source: reading.holdSource ?? 'paid',
      request: checked.reading,
      ctx,
      config,
      startedAt,
      promptVersion,
    });
  }

  // --- GET /v1/readings/{clientReadingId}, ack (RC51) --------------------------

  /**
   * `{status, attempt, reading?, safety?, balance}`. A completed reading
   * whose replay body is gone and that was never acknowledged is refunded
   * once and answers `410 READING_EXPIRED_REFUNDED`; the next call sees
   * `expired_refunded` and refunds nothing.
   */
  async status(ctx: ReadingRequestContext, clientReadingId: string): Promise<ReadingState> {
    const row = await this.readings.findByClientId(ctx.install.id, clientReadingId);
    if (row === null) {
      throw new ApiError('NOT_FOUND');
    }
    const stored = await this.storedResponse(ctx.install.id, clientReadingId);
    const base = { status: row.status, attempt: row.attempt };
    if (row.status === 'completed') {
      if (stored.response?.reading !== undefined) {
        return {
          ...base,
          chargeSource: row.chargeSource,
          ...optional('promptVersion', row.promptVersion),
          reading: stored.response.reading,
          balance: await this.balanceOf(ctx),
        };
      }
      if (stored.running) {
        return { status: 'generating', attempt: row.attempt, balance: await this.balanceOf(ctx) };
      }
      if (row.ackedAt === null) {
        throw await this.expireUndelivered(ctx, row);
      }
      return { ...base, chargeSource: row.chargeSource, balance: await this.balanceOf(ctx) };
    }
    if (row.status === 'declined') {
      return {
        ...base,
        chargeSource: 'none',
        safety: stored.response?.safety ?? this.declinedFromRow(row, ctx.country),
        balance: await this.balanceOf(ctx),
      };
    }
    return { ...base, balance: await this.balanceOf(ctx) };
  }

  /** Delivery acknowledged (RC51): `acked_at` set, the replay body deleted. Idempotent. */
  async ack(installId: string, clientReadingId: string): Promise<void> {
    const row = await this.readings.findByClientId(installId, clientReadingId);
    if (row === null) {
      throw new ApiError('NOT_FOUND');
    }
    if (row.status !== 'completed' && row.status !== 'declined') {
      return;
    }
    await this.readings.markAcked(installId, clientReadingId, this.deps.clock.now().toISOString());
    await new IdempotencyRepo(this.deps.db).deleteBody(this.replayRef(installId, clientReadingId));
  }

  // --- gates -----------------------------------------------------------------

  /** `X-Taro-AI-Consent` ≥ `ai.consentVersion`, else `412` (RC28). */
  private consentGate(ctx: ReadingRequestContext, config: RuntimeConfig): void {
    const required = config['ai.consentVersion'];
    const raw = ctx.consent?.trim() ?? '';
    const granted = /^\d{1,6}$/.test(raw) ? Number(raw) : 0;
    if (granted < required) {
      throw new ApiError('AI_CONSENT_REQUIRED', { details: { requiredVersion: required } });
    }
  }

  /** Kill switch (RC8) → region (RC29). */
  private availabilityGates(ctx: ReadingRequestContext, config: RuntimeConfig): void {
    if (!config['readings.enabled']) {
      throw new ApiError('READINGS_DISABLED');
    }
    const country = ctx.country?.toUpperCase();
    if (country !== undefined && config['ai.blockedCountries'].includes(country)) {
      throw new ApiError('AI_UNAVAILABLE_REGION');
    }
  }

  /** `RL_READINGS`: holds + readings per install per minute (03 §2.4). */
  private async perMinuteGate(ctx: ReadingRequestContext): Promise<void> {
    const { success } = await this.deps.rateLimiters.readings.limit({
      key: `inst:${ctx.install.id}`,
    });
    if (!success) {
      this.deps.metrics.write({ event: 'rate_limited', code: 'burst' });
      throw new ApiError('RATE_LIMITED', { details: { reason: 'burst' }, retryAfterSec: 60 });
    }
  }

  /**
   * Before a new hold (03 §2.4, RC74): `readings.maxPerInstallPerDay` →
   * `429 dailyLimit`; `safety.maxDeclinedPerDay` declined readings →
   * `429 declinedLimit`. Retryable at local midnight; never a paywall.
   */
  private async dayLimitGates(
    ctx: ReadingRequestContext,
    config: RuntimeConfig,
    now: Date,
  ): Promise<void> {
    const timezone = installTimezone(ctx.install);
    const usage = await this.usage.find({
      installId: ctx.install.id,
      localDate: localDate(now, timezone),
    });
    let reason: string | null = null;
    if ((usage?.readingsTotal ?? 0) >= config['readings.maxPerInstallPerDay']) {
      reason = 'dailyLimit';
    } else if (
      declinedLimitReached(usage?.declinedCount ?? 0, config['safety.maxDeclinedPerDay'])
    ) {
      reason = DECLINED_LIMIT_REASON;
    }
    if (reason !== null) {
      this.deps.metrics.write({ event: 'rate_limited', code: reason });
      const retryAfterSec = Math.max(
        1,
        Math.ceil((nextResetUtc(now, timezone).getTime() - now.getTime()) / 1000),
      );
      throw new ApiError('RATE_LIMITED', { details: { reason }, retryAfterSec });
    }
  }

  // --- the row state machine (03 §9.1 step 2) ----------------------------------

  /** A settled row answers from its stored outcome; null = go on and generate. */
  private async replayIfSettled(
    ctx: ReadingRequestContext,
    row: ReadingRow | null,
  ): Promise<ReadingResponse | null> {
    switch (row?.status) {
      case 'generating':
        throw inProgress();
      case 'completed':
        // The idempotency layer replays a stored body; reaching here means it is gone.
        if (row.ackedAt === null) {
          throw await this.expireUndelivered(ctx, row);
        }
        return {
          readingId: row.id,
          status: 'completed',
          chargeSource: row.chargeSource,
          ...optional('promptVersion', row.promptVersion),
          balance: await this.balanceOf(ctx),
        };
      case 'declined':
        return {
          readingId: row.id,
          status: 'declined',
          chargeSource: 'none',
          safety: this.declinedFromRow(row, ctx.country),
          balance: await this.balanceOf(ctx),
        };
      default:
        return null;
    }
  }

  /**
   * The hold this reading generates under, `generating`: a live hold is
   * continued; otherwise one is taken inline (a new attempt after an expired,
   * refunded or missing one). No credit → `402` for a new row, else
   * `409 HOLD_CONFLICT`; the free-stop tier → `503 AI_BUDGET_EXHAUSTED`.
   */
  private async holdForReading(
    ctx: ReadingRequestContext,
    config: RuntimeConfig,
    body: CreateBody,
    request: ValidReading,
    existing: ReadingRow | null,
  ): Promise<ReadingRow> {
    const now = this.deps.clock.now();
    const staleAt = isoSeconds(
      new Date(now.getTime() + config['ai.deadlineMs'] + STALE_GENERATING_GRACE_MS),
    );
    if (existing !== null && liveHold(existing, now)) {
      if (!(await this.readings.markGenerating(existing.id, existing.attempt, staleAt))) {
        throw inProgress();
      }
      return this.reload(existing.id);
    }
    await this.dayLimitGates(ctx, config, now);
    const row =
      existing ??
      (await this.insertRow(ctx, body.clientReadingId, now, {
        spreadId: request.spreadId,
        cardCount: request.cards.length,
        hasQuestion: request.question !== '',
        locale: request.locale,
      }));
    await this.releaseOtherHolds(ctx.install.id, row.id);
    const result: HoldResult = await this.balance.hold({
      installId: ctx.install.id,
      readingId: row.id,
      status: 'generating',
      network: ctx.network,
      appVersion: ctx.appVersion,
    });
    if (result.kind === 'insufficient') {
      throw (
        this.budget.freeStopError(result.reason) ??
        (existing === null ? insufficientCreditsError(result) : new ApiError('HOLD_CONFLICT'))
      );
    }
    if (result.kind === 'consumed') {
      throw new ApiError('HOLD_CONFLICT');
    }
    await this.readings.markGenerating(row.id, result.attempt, staleAt);
    return this.reload(row.id);
  }

  // --- generation (03 §9.1 steps 3–6) ------------------------------------------

  private async generate(attempt: Attempt): Promise<ReadingResponse> {
    const { reading, request, ctx, config } = attempt;
    const log: CallLog = { calls: [], model: null };

    const l1 = prefilter(request.question, request.locale);
    if (l1.kind === 'block') {
      this.deps.logger.log('info', 'reading_l1_block', {
        inst8: inst8(ctx.install.id),
        rule: l1.rule,
      });
      return this.decline(attempt, l1.category, 'L1', log);
    }

    let budgetTier: BudgetTier;
    try {
      budgetTier = await this.budget.assertModelCallAllowed(config, this.deps.clock.now());
    } catch (err) {
      await this.refund(reading, 'budget');
      await this.recordEnd(attempt, 'failed', log, { errorCode: 'budget' });
      throw err;
    }
    const tier = aiTierFor(attempt.source, budgetTier);
    // The question's moderation runs alongside the first model call (03 §9.4):
    // it is checked before that call's answer is used, so a flagged question
    // is still declined and its answer discarded, uncharged.
    let questionCheck: Promise<RoutedModerationResult> | null =
      request.question === '' ? null : this.moderateQuestion(request.question, config);

    let note: string | undefined;
    for (let round = 0; ; round++) {
      const built = buildReadingPrompt(
        {
          spreadId: request.spreadId,
          cards: request.cards,
          locale: request.locale,
          question: request.question,
          prefilterHints: l1.hints,
          ...(note === undefined ? {} : { regenerationNote: note }),
        },
        attempt.promptVersion,
      );
      if (!built.ok) {
        return this.fail(attempt, 'prompt', log);
      }
      const [moderated, result]: [RoutedModerationResult | null, RoutedAiResult] =
        await Promise.all([
          questionCheck,
          this.router.generate(tier, config, built.input, attempt.startedAt),
        ]);
      questionCheck = null;
      log.calls.push(...result.calls);
      if ('model' in result) {
        log.model = result.model;
      }
      const flagged =
        moderated === null || moderated.kind === 'skipped'
          ? null
          : moderationInputCategory(moderated);
      if (flagged !== null) {
        return this.decline(attempt, flagged, 'L2', log);
      }
      const outcome = await this.judge(attempt, result, built.input.expected);
      if (outcome.kind === 'answered') {
        return this.commit(attempt, outcome.reading, log);
      }
      if (outcome.kind === 'declined') {
        return this.decline(attempt, outcome.category, outcome.layer, log);
      }
      if (outcome.kind === 'failed') {
        return this.fail(attempt, outcome.code, log);
      }
      if (round > 0) {
        return this.fail(attempt, outcome.code, log);
      }
      if (!this.canRegenerate(attempt)) {
        return this.fail(attempt, 'deadline', log);
      }
      this.deps.logger.log('warn', 'reading_regenerate', {
        inst8: inst8(ctx.install.id),
        violations: outcome.violations.map((v) => v.kind).join(','),
      });
      note = regenerationNote(outcome.violations);
    }
  }

  /**
   * Question moderation; an error or a throw never blocks the reading
   * (03 §9.4), so a rejected promise maps to `error`.
   */
  private async moderateQuestion(
    question: string,
    config: RuntimeConfig,
  ): Promise<RoutedModerationResult> {
    try {
      return await this.router.moderate(question, config, config['ai.timeoutMs']);
    } catch {
      this.deps.logger.log('warn', 'ai_moderation_failed', { stage: 'question' });
      return { kind: 'error' };
    }
  }

  /** Maps one routed result to answered / declined / retry (L3) / failed. */
  private async judge(
    attempt: Attempt,
    result: RoutedAiResult,
    expected: Parameters<typeof validateReadingOutput>[1]['expected'],
  ): Promise<
    | { readonly kind: 'answered'; readonly reading: AnsweredReading }
    | {
        readonly kind: 'declined';
        readonly category: RefusalCategory | null;
        readonly layer: SafetyLayer;
      }
    | {
        readonly kind: 'retry';
        readonly code: FailCode;
        readonly violations: readonly Violation[];
      }
    | { readonly kind: 'failed'; readonly code: FailCode }
  > {
    switch (result.kind) {
      case 'unavailable':
        return { kind: 'failed', code: 'ai_unavailable' };
      case 'refused':
        return {
          kind: 'declined',
          category: isRefusalCategory(result.category) ? result.category : null,
          layer: 'model_refusal',
        };
      case 'truncated':
        return { kind: 'failed', code: 'truncated' };
      case 'timeout':
      case 'rate_limited':
      case 'upstream':
        return { kind: 'failed', code: result.kind };
      case 'invalid_output':
        return {
          kind: 'retry',
          code: 'invalid_output',
          violations: result.issues.map((detail) => ({ kind: 'schema', detail })),
        };
      case 'ok':
        break;
    }
    const verdict = validateReadingOutput(result.output, {
      locale: attempt.request.locale,
      expected,
    });
    if (verdict.kind === 'declined') {
      return { kind: 'declined', category: verdict.category, layer: 'L2' };
    }
    if (verdict.kind === 'invalid') {
      return { kind: 'retry', code: 'l3_violation', violations: verdict.violations };
    }
    const moderated = await this.router.moderate(
      readingText(verdict.reading),
      attempt.config,
      attempt.config['ai.timeoutMs'],
    );
    if (moderated.kind !== 'skipped' && moderationOutputFlagged(moderated)) {
      return {
        kind: 'retry',
        code: 'l3_violation',
        violations: [{ kind: 'forbidden_claim', detail: 'the answer was flagged by moderation' }],
      };
    }
    return { kind: 'answered', reading: verdict.reading };
  }

  /** A regeneration needs at least 15 s of `ai.deadlineMs` left (RC52). */
  private canRegenerate(attempt: Attempt): boolean {
    const deadline = attempt.startedAt + attempt.config['ai.deadlineMs'];
    return deadline - this.deps.clock.now().getTime() >= MIN_REMAINING_FOR_REGENERATION_MS;
  }

  // --- outcomes ------------------------------------------------------------------

  private async commit(
    attempt: Attempt,
    output: AnsweredReading,
    log: CallLog,
  ): Promise<ReadingResponse> {
    const { reading, ctx } = attempt;
    const committed = await this.balance.commit({
      readingId: reading.id,
      network: ctx.network,
      appVersion: ctx.appVersion,
    });
    const cost = this.cost(log);
    await this.recordEnd(attempt, 'completed', log, {
      chargeSource: committed.chargeSource,
      completedAt: this.deps.clock.now().toISOString(),
    });
    this.deps.metrics.write({
      event: 'reading_completed',
      platform: ctx.install.platform,
      locale: attempt.request.locale,
      chargeSource: committed.chargeSource,
      promptVersion: attempt.promptVersion,
      costMicroUsd: cost,
      latencyMs: this.latency(attempt),
      ...(log.model === null ? {} : { model: log.model }),
      ...usageFields(log),
    });
    return {
      readingId: reading.id,
      status: 'completed',
      chargeSource: committed.chargeSource,
      promptVersion: attempt.promptVersion,
      reading: {
        title: output.title,
        overview: output.overview,
        cards: output.cards.map((card) => ({
          positionId: card.positionId,
          cardId: card.cardId,
          reversed: card.reversed,
          interpretation: card.interpretation,
        })),
        synthesis: output.synthesis,
        reflectionPrompts: [...output.reflectionPrompts],
      },
      balance: await this.balanceOf(ctx),
    };
  }

  /** Declined (L1, L2, moderation, model refusal): refunded, never charged (MO6, RC74). */
  private async decline(
    attempt: Attempt,
    category: RefusalCategory | null,
    layer: SafetyLayer,
    log: CallLog,
  ): Promise<ReadingResponse> {
    const { reading, ctx } = attempt;
    await this.refund(reading, 'declined');
    await this.recordEnd(attempt, 'declined', log, {
      chargeSource: 'none',
      safetyCategory: category ?? GENERIC_REFUSAL.category,
      safetyLayer: layer,
      completedAt: this.deps.clock.now().toISOString(),
    });
    this.deps.metrics.write({
      event: 'reading_declined',
      code: category ?? GENERIC_REFUSAL.category,
      platform: ctx.install.platform,
      locale: attempt.request.locale,
      promptVersion: attempt.promptVersion,
      ...(log.model === null ? {} : { model: log.model }),
    });
    return {
      readingId: reading.id,
      status: 'declined',
      chargeSource: 'none',
      safety: safetyFor(category, ctx.country, attempt.request.locale),
      balance: await this.balanceOf(ctx),
    };
  }

  /** `failed` + refund → `503 AI_UNAVAILABLE` (a retry with the same id is a new attempt, RC49). */
  private async fail(attempt: Attempt, code: FailCode, log: CallLog): Promise<never> {
    await this.refund(attempt.reading, 'failed');
    await this.recordEnd(attempt, 'failed', log, { errorCode: code });
    this.deps.metrics.write({
      event: 'reading_failed',
      code,
      platform: attempt.ctx.install.platform,
      locale: attempt.request.locale,
      promptVersion: attempt.promptVersion,
      ...(log.model === null ? {} : { model: log.model }),
    });
    this.deps.logger.log('warn', 'reading_failed', {
      inst8: inst8(attempt.ctx.install.id),
      code,
      attempt: attempt.reading.attempt,
    });
    throw new ApiError('AI_UNAVAILABLE');
  }

  private async refund(reading: ReadingRow, reason: RefundReason): Promise<void> {
    await this.balance.refund({ readingId: reading.id, reason, attempt: reading.attempt });
  }

  /**
   * Row metadata (tokens, cost, latency, model) and the day's model spend
   * (03 §10.1: after every model call, whatever the outcome) in one batch.
   */
  private async recordEnd(
    attempt: Attempt,
    status: ReadingStatus,
    log: CallLog,
    extra: {
      readonly chargeSource?: ChargeSource;
      readonly safetyCategory?: string;
      readonly safetyLayer?: SafetyLayer;
      readonly errorCode?: string;
      readonly completedAt?: string;
    },
  ): Promise<void> {
    const usage = totalUsage(log.calls);
    const cost = this.cost(log);
    const called = log.calls.length > 0;
    const statements = [
      this.readings.recordResultStmt(attempt.reading.id, {
        status,
        ...extra,
        promptVersion: attempt.promptVersion,
        model: log.model,
        inputTokens: called ? usage.inputTokens : null,
        cacheReadTokens: called ? usage.cacheReadTokens : null,
        cacheWriteTokens: called ? usage.cacheWriteTokens : null,
        outputTokens: called ? usage.outputTokens : null,
        costMicroUsd: called ? cost : null,
        latencyMs: this.latency(attempt),
      }),
    ];
    if (called) {
      statements.push(this.budget.recordStmt(this.deps.clock.now(), cost));
    }
    await this.deps.db.batch(statements);
  }

  private cost(log: CallLog): number {
    return log.calls.reduce((sum, call) => sum + aiCallCost(call, this.deps.logger), 0);
  }

  private latency(attempt: Attempt): number {
    return this.deps.clock.now().getTime() - attempt.startedAt;
  }

  // --- helpers -------------------------------------------------------------------

  private async insertRow(
    ctx: ReadingRequestContext,
    clientReadingId: string,
    now: Date,
    request: {
      readonly spreadId: string;
      readonly cardCount: number;
      readonly hasQuestion: boolean;
      readonly locale: string;
    },
  ): Promise<ReadingRow> {
    await this.readings.insert({
      id: this.deps.ids.uuidV7(),
      installId: ctx.install.id,
      clientReadingId,
      ...request,
      localDate: localDate(now, installTimezone(ctx.install)),
      status: 'held',
      chargeSource: 'none',
      createdAt: now.toISOString(),
    });
    // The insert or a concurrent one (the hold and the reading share the ID) created it.
    const row = await this.readings.findByClientId(ctx.install.id, clientReadingId);
    return row ?? Promise.reject(new Error('reading: row missing after insert'));
  }

  /** At most one open pre-draw hold per install (03 §9.0): older never-submitted ones are released. */
  private async releaseOtherHolds(installId: string, readingId: string): Promise<void> {
    for (const other of await this.readings.openHolds(installId, readingId)) {
      await this.balance.refund({
        readingId: other.id,
        reason: 'released',
        attempt: other.attempt,
      });
    }
  }

  private async reload(id: string): Promise<ReadingRow> {
    return ReadingRepo.parse(await this.readings.findByIdStmt(id).first());
  }

  /** Refunds an undelivered completed reading once and returns the `410` to throw (RC51). */
  private async expireUndelivered(ctx: ReadingRequestContext, row: ReadingRow): Promise<ApiError> {
    await this.balance.refundUndelivered(row.id);
    return new ApiError('READING_EXPIRED_REFUNDED', {
      details: { balance: await this.balanceOf(ctx) },
    });
  }

  private declinedFromRow(row: ReadingRow, country: string | null): SafetyWire {
    const category = isRefusalCategory(row.safetyCategory) ? row.safetyCategory : null;
    const locale = row.locale as Locale;
    return safetyFor(category, country, locale);
  }

  private replayRef(installId: string, clientReadingId: string) {
    return { installId, route: READINGS_ROUTE, key: clientReadingId };
  }

  /** The stored `POST /v1/readings` response, and whether that request is still running. */
  private async storedResponse(
    installId: string,
    clientReadingId: string,
  ): Promise<{ readonly response: Partial<ReadingResponse> | null; readonly running: boolean }> {
    const ref = this.replayRef(installId, clientReadingId);
    const stored = await readIdempotentBody(this.deps, ref);
    if (stored !== null && stored.status === 200) {
      return { response: JSON.parse(stored.body) as Partial<ReadingResponse>, running: false };
    }
    const row = await new IdempotencyRepo(this.deps.db).find(ref);
    const running =
      row?.state === 'in_progress' &&
      this.deps.clock.now().getTime() - Date.parse(row.createdAt) < TAKEOVER_AFTER_SEC * 1000;
    return { response: null, running };
  }

  private balanceOf(ctx: ReadingRequestContext): Promise<BalanceDto> {
    return ctx.balance();
  }
}

/** A live hold: `held` and not expired. */
function liveHold(row: ReadingRow, now: Date): boolean {
  return row.holdState === 'held' && row.status === 'held' && !holdExpired(row.holdExpiresAt, now);
}

function spreadInvalid(reason: string): ApiError {
  return new ApiError('SPREAD_INVALID', { details: { reason } });
}

function inProgress(): ApiError {
  return new ApiError('REQUEST_IN_PROGRESS', { retryAfterSec: IN_PROGRESS_RETRY_AFTER_SEC });
}

/** The declined `safety` object; a refusal without a known category is `other` / `refusalGeneric`. */
export function safetyFor(
  category: RefusalCategory | null,
  country: string | null,
  locale: Locale,
): SafetyWire {
  if (category === null) {
    return { ...GENERIC_REFUSAL, crisisResources: [], canRephrase: false };
  }
  const safety = declinedSafety(category, { country, locale });
  return {
    ...safety,
    crisisResources: safety.crisisResources.map((r) => ({ ...r, languages: [...r.languages] })),
  };
}

function optional<K extends string>(key: K, value: string | null): Partial<Record<K, string>> {
  return value === null ? {} : ({ [key]: value } as Record<K, string>);
}

function usageFields(log: CallLog): { inputTokens?: number; outputTokens?: number } {
  if (log.calls.length === 0) {
    return {};
  }
  const usage = totalUsage(log.calls);
  return { inputTokens: usage.inputTokens, outputTokens: usage.outputTokens };
}
