import { describe, expect, it } from 'vitest';
import { DEFAULT_RUNTIME_CONFIG } from '../../../src/config/defaults';
import type { AiProviderId, RuntimeConfig } from '../../../src/config/schema';
import type { AiProviders } from '../../../src/ports/AiProvider';
import { buildReadingPrompt, type ReadingPromptInput } from '../../../src/prompts/build';
import {
  AI_TIERS,
  AiRouter,
  aiTierFor,
  maxTokensFor,
  type AiTier,
} from '../../../src/services/AiRouter';
import { contractPrompt } from '../../contracts/aiProvider.contract';
import { CapturingAlerter } from '../../fakes/CapturingAlerter';
import { CapturingLogger } from '../../fakes/CapturingLogger';
import { FakeAiProvider } from '../../fakes/FakeAiProvider';
import { FixedClock } from '../../fakes/FixedClock';
import { InMemoryMetrics } from '../../fakes/InMemoryMetrics';

function setup(keyed: readonly AiProviderId[] = ['anthropic', 'openai']) {
  const clock = new FixedClock();
  const fakes = {
    anthropic: new FakeAiProvider('anthropic', { clock }),
    openai: new FakeAiProvider('openai', { clock }),
  };
  const ai: AiProviders = Object.fromEntries(keyed.map((id) => [id, fakes[id]]));
  const alerter = new CapturingAlerter();
  const metrics = new InMemoryMetrics();
  const logger = new CapturingLogger();
  const router = new AiRouter({ ai, alerter, metrics, logger, clock });
  return { clock, fakes, alerter, metrics, logger, router, now: clock.now().getTime() };
}

/**
 * The routing mechanics are exercised with an Anthropic primary and an OpenAI
 * fallback, so cross-provider fallback stays covered while the shipped
 * defaults are OpenAI-only (RC97 amendment 2026-10-01).
 */
const ANTHROPIC_PRIMARY: Partial<RuntimeConfig> = {
  'ai.provider.paid': 'anthropic',
  'ai.provider.free': 'anthropic',
  'ai.provider.freeFallback': 'anthropic',
  'ai.model.paid': 'claude-opus-5',
  'ai.model.free': 'claude-sonnet-5',
  'ai.model.freeFallback': 'claude-sonnet-5',
  'ai.disclosedProviders': ['anthropic', 'openai'],
};

function config(overrides: Partial<RuntimeConfig> = {}): RuntimeConfig {
  return { ...DEFAULT_RUNTIME_CONFIG, ...ANTHROPIC_PRIMARY, ...overrides };
}

const TIER_CONFIG: Record<
  AiTier,
  (provider: AiProviderId, model: string) => Partial<RuntimeConfig>
> = {
  paid: (provider, model) => ({ 'ai.provider.paid': provider, 'ai.model.paid': model }),
  free: (provider, model) => ({ 'ai.provider.free': provider, 'ai.model.free': model }),
  freeFallback: (provider, model) => ({
    'ai.provider.freeFallback': provider,
    'ai.model.freeFallback': model,
  }),
};

const FALLBACK: Partial<RuntimeConfig> = {
  'ai.outageFallback.provider': 'openai',
  'ai.outageFallback.model': 'gpt-6-luna',
};

describe('aiTierFor (03 §9.3)', () => {
  it('bonus and paid → paid; free → free, or freeFallback in the soft budget tier', () => {
    expect(aiTierFor('paid', 'soft')).toBe('paid');
    expect(aiTierFor('bonus', 'normal')).toBe('paid');
    expect(aiTierFor('free', 'normal')).toBe('free');
    expect(aiTierFor('free', 'soft')).toBe('freeFallback');
    expect(aiTierFor('free', 'freeStop')).toBe('free');
  });
});

describe('maxTokensFor', () => {
  it('reads ai.maxTokensBySpread, falling back to its * entry', () => {
    const table = { ...DEFAULT_RUNTIME_CONFIG['ai.maxTokensBySpread'], single: 700, '*': 999 };
    const cfg = config({ 'ai.maxTokensBySpread': table });
    expect(maxTokensFor(cfg, 'single')).toBe(700);
    expect(maxTokensFor(cfg, 'unknown_spread')).toBe(999);
  });
});

describe('AiRouter (RC97)', () => {
  const prompt = contractPrompt();

  it('the shipped defaults route every tier to OpenAI gpt-6.1-sol', async () => {
    const { router, fakes, now } = setup(['openai']);
    for (const tier of AI_TIERS) {
      await expect(router.checkAvailable(tier, DEFAULT_RUNTIME_CONFIG)).resolves.toBe(true);
      const result = await router.generate(tier, DEFAULT_RUNTIME_CONFIG, prompt, now);
      expect(result).toMatchObject({ kind: 'ok', model: 'openai/gpt-6.1-sol' });
    }
    expect(fakes.openai.generateRequests[0]).toMatchObject({ timeoutMs: 50000, effort: 'low' });
  });

  for (const tier of AI_TIERS) {
    for (const provider of ['anthropic', 'openai'] as const) {
      it(`${tier} tier routed to ${provider} calls that adapter with the tier's model and config`, async () => {
        const { router, fakes, now, alerter } = setup();
        const model = provider === 'anthropic' ? 'claude-sonnet-5' : 'gpt-6.1-sol';
        const cfg = config(TIER_CONFIG[tier](provider, model));
        await expect(router.checkAvailable(tier, cfg)).resolves.toBe(true);
        const result = await router.generate(tier, cfg, prompt, now);
        expect(result).toMatchObject({ kind: 'ok', model: `${provider}/${model}` });
        const other = provider === 'anthropic' ? fakes.openai : fakes.anthropic;
        expect(other.requests).toHaveLength(0);
        expect(fakes[provider].generateRequests[0]).toMatchObject({
          model,
          maxTokens: cfg['ai.maxTokensBySpread'].single,
          effort: cfg['ai.effort'],
          refusalFallbacks: cfg['ai.refusalFallbacks'],
          timeoutMs: cfg['ai.timeoutMs'],
          maxRetries: cfg['ai.maxRetries'],
          startedAt: now,
          deadlineAt: now + cfg['ai.deadlineMs'],
        });
        expect(alerter.alerts).toEqual([]);
      });
    }
  }

  it('a tier whose provider has no key and no keyed fallback is unavailable: alert, metric, no call', async () => {
    const { router, fakes, alerter, metrics, logger, now } = setup(['openai']);
    const cfg = config();
    expect(router.routing('paid', cfg)).toMatchObject({ available: false, primaryKeyed: false });
    await expect(router.checkAvailable('paid', cfg)).resolves.toBe(false);
    expect(alerter.alerts[0]).toMatchObject({
      kind: 'ai_provider_unavailable',
      dedupeKey: 'ai_provider_unavailable:paid',
      fields: { tier: 'paid', provider: 'anthropic' },
    });
    expect(await router.generate('paid', cfg, prompt, now)).toEqual({
      kind: 'unavailable',
      calls: [],
    });
    expect(fakes.anthropic.requests).toHaveLength(0);
    expect(fakes.openai.requests).toHaveLength(0);
    expect(metrics.points.filter((p) => p.event === 'ai_provider_unavailable')).toHaveLength(2);
    expect(logger.find('ai_provider_unavailable')[0]?.level).toBe('error');
  });

  it('an unkeyed provider covered by a keyed outage fallback is served by the fallback (and still alerts)', async () => {
    const { router, fakes, alerter, metrics, logger, now } = setup(['openai']);
    const cfg = config(FALLBACK);
    await expect(router.checkAvailable('free', cfg)).resolves.toBe(true);
    const result = await router.generate('free', cfg, prompt, now);
    expect(result).toMatchObject({ kind: 'ok', model: 'openai/gpt-6-luna' });
    expect(fakes.openai.requests).toHaveLength(1);
    expect(alerter.alerts[0]?.message).toContain('served by the outage fallback');
    expect(logger.find('ai_provider_unavailable')[0]?.level).toBe('warn');
    expect(metrics.points.find((p) => p.event === 'ai_outage_fallback')).toMatchObject({
      code: 'anthropic/claude-sonnet-5',
      model: 'openai/gpt-6-luna',
    });
  });

  for (const kind of ['timeout', 'rate_limited', 'upstream'] as const) {
    it(`falls back once after ${kind}, keeping the primary's billed calls`, async () => {
      const { router, fakes, metrics, now } = setup();
      const step = kind === 'timeout' ? { kind } : ({ kind, retryable: false } as const);
      fakes.anthropic.script(
        {
          kind: 'truncated',
          model: 'claude-opus-5',
          usage: { inputTokens: 1, outputTokens: 2, cacheReadTokens: 0, cacheWriteTokens: 0 },
        },
        step,
      );
      const cfg = config(FALLBACK);
      const result = await router.generate('paid', cfg, prompt, now);
      expect(result.kind).toBe('ok');
      expect(result.calls.map((c) => `${c.provider}/${c.model}`)).toEqual([
        'anthropic/claude-opus-5',
        'openai/gpt-6-luna',
      ]);
      expect(fakes.openai.generateRequests[0]?.model).toBe('gpt-6-luna');
      expect(metrics.count('ai_outage_fallback')).toBe(1);
    });
  }

  for (const step of [
    { kind: 'refused', category: 'general_harms' },
    { kind: 'truncated' },
    { kind: 'invalid_output', issues: ['$: not valid JSON'] },
  ] as const) {
    it(`never falls back after ${step.kind} (a safety decision is not shopped around)`, async () => {
      const { router, fakes, metrics, now } = setup();
      const usage = { inputTokens: 1, outputTokens: 1, cacheReadTokens: 0, cacheWriteTokens: 0 };
      fakes.anthropic.script(
        { ...step, model: 'claude-opus-5', usage },
        { ...step, model: 'claude-opus-5', usage },
      );
      const result = await router.generate('paid', config(FALLBACK), prompt, now);
      expect(result.kind).toBe(step.kind);
      expect(fakes.openai.requests).toHaveLength(0);
      expect(metrics.count('ai_outage_fallback')).toBe(0);
    });
  }

  it('respects the deadline: no fallback with under 15 s of ai.deadlineMs left', async () => {
    const { router, fakes, clock, now } = setup();
    fakes.anthropic.script(() => {
      clock.advance({ ms: 41_000 });
      return { kind: 'timeout' };
    });
    const result = await router.generate('paid', config(FALLBACK), prompt, now);
    expect(result).toEqual({ kind: 'timeout', calls: [] });
    expect(fakes.openai.requests).toHaveLength(0);
  });

  it('an outage without a configured (or keyed) fallback returns the primary result', async () => {
    const plain = setup();
    plain.fakes.anthropic.script({ kind: 'upstream', retryable: false });
    expect((await plain.router.generate('paid', config(), prompt, plain.now)).kind).toBe(
      'upstream',
    );

    const unkeyedFallback = setup(['anthropic']);
    unkeyedFallback.fakes.anthropic.script({ kind: 'upstream', retryable: false });
    const result = await unkeyedFallback.router.generate(
      'paid',
      config(FALLBACK),
      prompt,
      unkeyedFallback.now,
    );
    expect(result.kind).toBe('upstream');
    expect(unkeyedFallback.router.routing('paid', config(FALLBACK))).toMatchObject({
      fallback: { provider: 'openai', model: 'gpt-6-luna' },
      fallbackKeyed: false,
    });
  });

  it('uses the spread of the prompt for max tokens', async () => {
    const { router, fakes, now } = setup();
    const built = buildReadingPrompt({
      spreadId: 'three_ppf',
      locale: 'en',
      cards: [
        { positionId: 'past', cardId: 'major_16', reversed: false },
        { positionId: 'present', cardId: 'cups_03', reversed: true },
        { positionId: 'future', cardId: 'pentacles_14', reversed: false },
      ],
    });
    const three = (built as { ok: true; input: ReadingPromptInput }).input;
    await router.generate('free', config(), three, now);
    expect(fakes.anthropic.generateRequests[0]?.maxTokens).toBe(
      DEFAULT_RUNTIME_CONFIG['ai.maxTokensBySpread'].three_ppf,
    );
  });

  describe('moderate (03 §9.4)', () => {
    it('skipped when ai.moderation.provider is none: no call', async () => {
      const { router, fakes } = setup();
      fakes.openai.moderation({ kind: 'ok', flagged: false, categories: [] });
      await expect(
        router.moderate('text', config({ 'ai.moderation.provider': 'none' }), 2000),
      ).resolves.toEqual({ kind: 'skipped' });
      expect(fakes.openai.moderated).toEqual([]);
    });

    it('calls the configured provider; a provider without moderation (or no key) → error', async () => {
      const { router, fakes, logger } = setup();
      const cfg = config({ 'ai.moderation.provider': 'openai' });
      await expect(router.moderate('text', cfg, 2000)).resolves.toEqual({ kind: 'error' });
      expect(logger.find('ai_moderation_unavailable')).toHaveLength(1);
      fakes.openai.moderation({ kind: 'ok', flagged: true, categories: ['hate'] });
      await expect(router.moderate('text', cfg, 2000)).resolves.toEqual({
        kind: 'ok',
        flagged: true,
        categories: ['hate'],
      });
      const unkeyed = setup(['anthropic']);
      await expect(unkeyed.router.moderate('text', cfg, 2000)).resolves.toEqual({ kind: 'error' });
    });
  });
});
