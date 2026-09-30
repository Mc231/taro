import { describe, expect, it } from 'vitest';
import type { AiAttemptOutcome, AiAttemptRequest } from '../../../../src/adapters/ai/callPolicy';
import {
  aiProviderContract,
  CONTRACT_USAGE,
  contractRequest,
  testRuntime,
  type AiScenarioStep,
} from '../../../contracts/aiProvider.contract';
import { FAKE_USAGE, FakeAiProvider, fakeReading } from '../../../fakes/FakeAiProvider';

const SERVED = 'fake-served-1';

function outcome(step: AiScenarioStep): (request: AiAttemptRequest) => AiAttemptOutcome {
  return (request) => {
    switch (step) {
      case 'ok':
      case 'cache_read':
        return {
          kind: 'ok',
          output: fakeReading(request.prompt.expected),
          model: SERVED,
          usage: CONTRACT_USAGE[step],
        };
      case 'refusal':
        return { kind: 'refused', category: null, model: SERVED, usage: CONTRACT_USAGE.refusal };
      case 'truncation':
        return { kind: 'truncated', model: SERVED, usage: CONTRACT_USAGE.truncation };
      case 'invalid_json':
        return {
          kind: 'invalid_output',
          issues: ['$: not valid JSON'],
          model: SERVED,
          usage: CONTRACT_USAGE.invalid_json,
        };
      case 'rate_limited':
        return { kind: 'rate_limited', retryable: true };
      case 'overloaded':
      case 'server_error':
        return { kind: 'upstream', retryable: true };
      case 'timeout':
        return { kind: 'timeout' };
    }
  };
}

aiProviderContract({
  name: 'FakeAiProvider',
  make(steps, runtime) {
    const provider = new FakeAiProvider('openai', runtime).script(...steps.map(outcome));
    return {
      provider,
      model: 'fake-model',
      servedModel: SERVED,
      attempts: () => provider.requests.length,
      sentMaxTokens: () => provider.requests.map((r) => r.maxTokens),
    };
  },
});

describe('FakeAiProvider', () => {
  it('answers a valid reading at the requested model when nothing is scripted', async () => {
    const runtime = testRuntime();
    const provider = new FakeAiProvider('anthropic', runtime);
    const request = contractRequest(runtime, 'claude-sonnet-5');
    const result = await provider.generate(request);
    expect(result).toEqual({
      kind: 'ok',
      output: fakeReading(request.prompt.expected),
      model: 'anthropic/claude-sonnet-5',
      calls: [{ provider: 'anthropic', model: 'claude-sonnet-5', usage: FAKE_USAGE }],
    });
    expect(provider.generateRequests).toEqual([request]);
    expect(provider.pending).toBe(0);
  });

  it('accepts plain outcomes and has no moderate until one is configured', async () => {
    const provider = new FakeAiProvider().script({ kind: 'timeout' });
    expect(provider.moderate).toBeUndefined();
    expect(provider.pending).toBe(1);
    const now = Date.now();
    const result = await provider.generate({
      ...contractRequest(testRuntime(), 'm'),
      startedAt: now,
      deadlineAt: now + 55_000,
    });
    expect(result.kind).toBe('timeout');
    provider.moderation({ kind: 'ok', flagged: true, categories: ['self-harm'] });
    await expect(provider.moderate?.('text', 1000)).resolves.toEqual({
      kind: 'ok',
      flagged: true,
      categories: ['self-harm'],
    });
    expect(provider.moderated).toEqual(['text']);
  });
});
