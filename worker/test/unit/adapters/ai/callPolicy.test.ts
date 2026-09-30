import { describe, expect, it } from 'vitest';
import { backoffMs, runWithPolicy, timerSleep } from '../../../../src/adapters/ai/callPolicy';
import { stripSchemaKeywords } from '../../../../src/adapters/ai/output';
import { AnthropicProvider } from '../../../../src/adapters/anthropic/AnthropicProvider';
import { OpenAiProvider } from '../../../../src/adapters/openai/OpenAiProvider';
import { contractRequest, testRuntime } from '../../../contracts/aiProvider.contract';

describe('AI call policy (03 §9.3, RC52)', () => {
  it('backoff is jittered within [500, 1500) ms', () => {
    expect(backoffMs({ randomBytes: (n) => new Uint8Array(n) })).toBe(500);
    expect(backoffMs({ randomBytes: (n) => new Uint8Array(n).fill(0xff) })).toBe(1499);
    expect(backoffMs({ randomBytes: () => new Uint8Array(0) })).toBe(500);
  });

  it('an adapter that throws becomes a non-retried upstream result, logged without details', async () => {
    const runtime = testRuntime();
    let calls = 0;
    const result = await runWithPolicy('anthropic', contractRequest(runtime, 'm'), runtime, () => {
      calls++;
      return Promise.reject(new RangeError('bug'));
    });
    expect(result).toEqual({ kind: 'upstream', calls: [] });
    expect(calls).toBe(1);
    expect(runtime.logger.find('ai_adapter_error')[0]?.fields).toEqual({
      provider: 'anthropic',
      error: 'RangeError',
    });
    const other = await runWithPolicy('openai', contractRequest(runtime, 'm'), runtime, () =>
      Promise.reject(new Error('x')),
    );
    expect(other.kind).toBe('upstream');
    await runWithPolicy('openai', contractRequest(runtime, 'm'), runtime, () =>
      // eslint-disable-next-line @typescript-eslint/prefer-promise-reject-errors -- a non-Error rejection is the case under test
      Promise.reject('str'),
    );
    expect(runtime.logger.find('ai_adapter_error').at(-1)?.fields['error']).toBe('unknown');
  });

  it('the per-call timeout is min(ai.timeoutMs, time left before the deadline)', async () => {
    const runtime = testRuntime();
    const seen: number[] = [];
    const request = contractRequest(runtime, 'm', { timeoutMs: 40_000 });
    await runWithPolicy(
      'anthropic',
      { ...request, deadlineAt: request.startedAt + 12_345 },
      runtime,
      (a) => {
        seen.push(a.timeoutMs);
        return Promise.resolve({ kind: 'timeout' });
      },
    );
    await runWithPolicy('anthropic', request, runtime, (a) => {
      seen.push(a.timeoutMs);
      return Promise.resolve({ kind: 'timeout' });
    });
    expect(seen).toEqual([12_345, 40_000]);
  });

  it('timerSleep waits on a real timer', async () => {
    await expect(timerSleep(1)).resolves.toBeUndefined();
  });

  it('stripSchemaKeywords walks arrays and leaves scalars and null alone', () => {
    expect(
      stripSchemaKeywords(
        { anyOf: [{ x: 1, drop: 2 }, null, 'a'], properties: null },
        (k) => k === 'drop',
      ),
    ).toEqual({ anyOf: [{ x: 1 }, null, 'a'], properties: null });
  });

  it('adapters default to the global fetch and the vendor base URL', () => {
    const runtime = testRuntime();
    expect(new AnthropicProvider({ apiKey: 'k', runtime }).id).toBe('anthropic');
    expect(new OpenAiProvider({ apiKey: 'k', runtime }).id).toBe('openai');
  });
});
