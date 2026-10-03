import type { AiProviderId, RuntimeConfig, SPREAD_IDS } from '../config/schema';
import type { BudgetTier } from '../domain/budget';
import { modelKey } from '../domain/pricing';
import type { Alerter } from '../ports/Alerter';
import {
  isAiOutage,
  type AiGenerateRequest,
  type AiModerationResult,
  type AiProvider,
  type AiProviders,
  type AiResult,
} from '../ports/AiProvider';
import type { Clock } from '../ports/Clock';
import type { Logger } from '../ports/Logger';
import type { Metrics } from '../ports/Metrics';
import type { ReadingPromptInput } from '../prompts/build';
import type { HoldSource } from '../repos/ReadingRepo';
import { MIN_REMAINING_FOR_REGENERATION_MS } from '../adapters/ai/callPolicy';

type SpreadId = (typeof SPREAD_IDS)[number];

/**
 * Tier → provider + model → adapter (03 §9.3, RC97).
 *
 * - The hold's charge source and the budget tier pick the tier: `paid` for
 *   bonus / paid, `freeFallback` for free readings in the soft tier, else `free`.
 * - `ai.provider.<tier>` + `ai.model.<tier>` pick the adapter and model. Only
 *   providers with a key have an adapter (`makeProdDeps`); a tier whose
 *   provider has none and no keyed `ai.outageFallback.*` is **unavailable**:
 *   the hold answers `503 AI_UNAVAILABLE`, nothing is charged, and the
 *   `ai_provider_unavailable` alert fires (deduplicated hourly by the Alerter).
 * - **Outage fallback:** after `timeout` / `rate_limited` / `upstream` (the
 *   adapter's own retry already spent) the fallback is tried once, if at least
 *   15 s of `ai.deadlineMs` remain. Never after `refused`, `truncated` or
 *   `invalid_output`: a safety decision is never shopped to a second provider.
 */
export type AiTier = 'paid' | 'free' | 'freeFallback';
export const AI_TIERS: readonly AiTier[] = ['paid', 'free', 'freeFallback'];

export function aiTierFor(source: HoldSource, budget: BudgetTier): AiTier {
  if (source !== 'free') {
    return 'paid';
  }
  return budget === 'soft' ? 'freeFallback' : 'free';
}

export interface AiRoute {
  readonly provider: AiProviderId;
  readonly model: string;
}

export interface AiRouting {
  readonly tier: AiTier;
  readonly primary: AiRoute;
  /** `ai.outageFallback.*` when both are set. */
  readonly fallback: AiRoute | null;
  readonly primaryKeyed: boolean;
  readonly fallbackKeyed: boolean;
  /** The tier can be served: its provider or its outage fallback has an adapter. */
  readonly available: boolean;
}

/** `AiResult`, or `unavailable` when no adapter can serve the tier (→ 503, no charge). */
export type RoutedAiResult =
  AiResult | { readonly kind: 'unavailable'; readonly calls: readonly [] };

export type RoutedModerationResult = AiModerationResult | { readonly kind: 'skipped' };

export interface AiRouterDeps {
  readonly ai: AiProviders;
  readonly alerter: Alerter;
  readonly metrics: Metrics;
  readonly logger: Logger;
  readonly clock: Clock;
}

const TIER_KEYS = {
  paid: ['ai.provider.paid', 'ai.model.paid'],
  free: ['ai.provider.free', 'ai.model.free'],
  freeFallback: ['ai.provider.freeFallback', 'ai.model.freeFallback'],
} as const satisfies Record<AiTier, readonly [keyof RuntimeConfig, keyof RuntimeConfig]>;

/** `ai.maxTokensBySpread[spread]`, or its `*` entry. */
export function maxTokensFor(config: RuntimeConfig, spreadId: string): number {
  const table = config['ai.maxTokensBySpread'];
  return (
    (table as Readonly<Partial<Record<SpreadId | '*', number>>>)[spreadId as SpreadId] ?? table['*']
  );
}

export class AiRouter {
  constructor(private readonly deps: AiRouterDeps) {}

  routing(tier: AiTier, config: RuntimeConfig): AiRouting {
    const [providerKey, modelKeyName] = TIER_KEYS[tier];
    const primary: AiRoute = { provider: config[providerKey], model: config[modelKeyName] };
    const fallbackProvider = config['ai.outageFallback.provider'];
    const fallbackModel = config['ai.outageFallback.model'];
    const fallback =
      fallbackProvider !== null && fallbackModel !== null
        ? { provider: fallbackProvider, model: fallbackModel }
        : null;
    const primaryKeyed = this.deps.ai[primary.provider] !== undefined;
    const fallbackKeyed = fallback !== null && this.deps.ai[fallback.provider] !== undefined;
    return {
      tier,
      primary,
      fallback,
      primaryKeyed,
      fallbackKeyed,
      available: primaryKeyed || fallbackKeyed,
    };
  }

  /**
   * The hold gate (03 §9.0): false when the tier cannot be served, after
   * sending the alert. A keyed fallback covering an unkeyed provider still alerts.
   */
  async checkAvailable(tier: AiTier, config: RuntimeConfig): Promise<boolean> {
    const routing = this.routing(tier, config);
    if (!routing.primaryKeyed) {
      await this.alertUnavailable(routing);
    }
    return routing.available;
  }

  async generate(
    tier: AiTier,
    config: RuntimeConfig,
    prompt: ReadingPromptInput,
    startedAt: number,
  ): Promise<RoutedAiResult> {
    const routing = this.routing(tier, config);
    if (!routing.primaryKeyed) {
      await this.alertUnavailable(routing);
    }
    const base: Omit<AiGenerateRequest, 'model'> = {
      prompt,
      maxTokens: maxTokensFor(config, prompt.spreadId),
      effort: config['ai.effort'],
      serviceTier: config['ai.serviceTier'],
      refusalFallbacks: config['ai.refusalFallbacks'],
      timeoutMs: config['ai.timeoutMs'],
      maxRetries: config['ai.maxRetries'],
      startedAt,
      deadlineAt: startedAt + config['ai.deadlineMs'],
    };
    const primaryAdapter = this.deps.ai[routing.primary.provider];
    const fallback = routing.fallback;
    const fallbackAdapter = fallback === null ? undefined : this.deps.ai[fallback.provider];
    if (primaryAdapter === undefined) {
      if (fallback === null || fallbackAdapter === undefined) {
        return { kind: 'unavailable', calls: [] };
      }
      return this.callFallback(routing.primary, fallback, fallbackAdapter, base, []);
    }
    const result = await primaryAdapter.generate({ ...base, model: routing.primary.model });
    if (
      fallback === null ||
      fallbackAdapter === undefined ||
      !isAiOutage(result) ||
      base.deadlineAt - this.deps.clock.now().getTime() < MIN_REMAINING_FOR_REGENERATION_MS
    ) {
      return result;
    }
    return this.callFallback(routing.primary, fallback, fallbackAdapter, base, result.calls);
  }

  /** The optional moderation pass (03 §9.4): `skipped` when `ai.moderation.provider` is `none`. */
  async moderate(
    text: string,
    config: RuntimeConfig,
    timeoutMs: number,
  ): Promise<RoutedModerationResult> {
    const provider = config['ai.moderation.provider'];
    if (provider === 'none') {
      return { kind: 'skipped' };
    }
    const moderate = this.deps.ai[provider]?.moderate;
    if (moderate === undefined) {
      this.deps.logger.log('warn', 'ai_moderation_unavailable', { provider });
      return { kind: 'error' };
    }
    return moderate(text, timeoutMs);
  }

  private async callFallback(
    from: AiRoute,
    to: AiRoute,
    adapter: AiProvider,
    base: Omit<AiGenerateRequest, 'model'>,
    earlier: AiResult['calls'],
  ): Promise<AiResult> {
    const fromKey = modelKey(from.provider, from.model);
    const toKey = modelKey(to.provider, to.model);
    this.deps.metrics.write({ event: 'ai_outage_fallback', code: fromKey, model: toKey });
    this.deps.logger.log('warn', 'ai_outage_fallback', { from: fromKey, to: toKey });
    const result = await adapter.generate({ ...base, model: to.model });
    return { ...result, calls: [...earlier, ...result.calls] };
  }

  private async alertUnavailable(routing: AiRouting): Promise<void> {
    const model = modelKey(routing.primary.provider, routing.primary.model);
    this.deps.metrics.write({ event: 'ai_provider_unavailable', code: routing.tier, model });
    this.deps.logger.log(routing.available ? 'warn' : 'error', 'ai_provider_unavailable', {
      tier: routing.tier,
      provider: routing.primary.provider,
      servedByFallback: routing.available,
    });
    await this.deps.alerter.send({
      kind: 'ai_provider_unavailable',
      message: routing.available
        ? `AI tier ${routing.tier}: no key for ${routing.primary.provider}; served by the outage fallback`
        : `AI tier ${routing.tier} disabled: no key for ${routing.primary.provider} and no keyed outage fallback`,
      fields: { tier: routing.tier, provider: routing.primary.provider },
      dedupeKey: `ai_provider_unavailable:${routing.tier}`,
    });
  }
}
