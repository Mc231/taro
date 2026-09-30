import { describe, expect, it } from 'vitest';
import { isAiOutage, totalUsage, ZERO_USAGE } from '../../../src/ports/AiProvider';

describe('AiProvider port helpers', () => {
  it('totalUsage sums every billed call (retries and fallback included)', () => {
    expect(totalUsage([])).toEqual(ZERO_USAGE);
    const usage = { inputTokens: 1, outputTokens: 2, cacheReadTokens: 3, cacheWriteTokens: 4 };
    expect(
      totalUsage([
        { provider: 'anthropic', model: 'claude-opus-5', usage },
        { provider: 'openai', model: 'gpt-6-luna', usage },
      ]),
    ).toEqual({ inputTokens: 2, outputTokens: 4, cacheReadTokens: 6, cacheWriteTokens: 8 });
  });

  it('isAiOutage is true only for timeout, rate_limited and upstream', () => {
    expect(isAiOutage({ kind: 'timeout', calls: [] })).toBe(true);
    expect(isAiOutage({ kind: 'upstream', calls: [] })).toBe(true);
    expect(isAiOutage({ kind: 'truncated', model: 'm', calls: [] })).toBe(false);
  });
});
