import { describe, expect, it } from 'vitest';
import { aiDeps } from '../../src/aiDeps';
import { WebCrypto } from '../../src/adapters/cf/WebCrypto';
import { AnthropicProvider } from '../../src/adapters/anthropic/AnthropicProvider';
import { OpenAiProvider } from '../../src/adapters/openai/OpenAiProvider';
import type { Env } from '../../src/env';
import { CapturingLogger } from '../fakes/CapturingLogger';
import { FakeAiProvider } from '../fakes/FakeAiProvider';
import { FixedClock } from '../fakes/FixedClock';

function env(vars: Partial<Env>): Env {
  return vars as Env;
}

const clock = new FixedClock();
const crypto = new WebCrypto();
const logger = new CapturingLogger();

describe('aiDeps (03 §9.3, §11, RC97)', () => {
  it('builds an adapter only for each present key', () => {
    expect(aiDeps(env({}), 'prod', clock, crypto, logger).ai).toEqual({});
    const both = aiDeps(
      env({ ANTHROPIC_API_KEY: 'a', OPENAI_API_KEY: 'o' }),
      'staging',
      clock,
      crypto,
      logger,
    ).ai;
    expect(both.anthropic).toBeInstanceOf(AnthropicProvider);
    expect(both.openai).toBeInstanceOf(OpenAiProvider);
    const openAiOnly = aiDeps(
      env({ ANTHROPIC_API_KEY: '', OPENAI_API_KEY: 'o' }),
      'prod',
      clock,
      crypto,
      logger,
    ).ai;
    expect(Object.keys(openAiOnly)).toEqual(['openai']);
  });

  it('AI_PROVIDER=fake serves every provider with FakeAiProvider outside prod only', () => {
    const fake = aiDeps(
      env({ AI_PROVIDER: 'fake', ANTHROPIC_API_KEY: 'a' }),
      'staging',
      clock,
      crypto,
      logger,
    ).ai;
    expect(fake.anthropic).toBeInstanceOf(FakeAiProvider);
    expect(fake.openai?.id).toBe('openai');
    const prod = aiDeps(
      env({ AI_PROVIDER: 'fake', ANTHROPIC_API_KEY: 'a' }),
      'prod',
      clock,
      crypto,
      logger,
    ).ai;
    expect(prod.anthropic).toBeInstanceOf(AnthropicProvider);
    expect(prod.openai).toBeUndefined();
  });
});
