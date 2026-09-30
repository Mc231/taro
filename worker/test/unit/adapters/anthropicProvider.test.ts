import {
  APIConnectionError,
  APIConnectionTimeoutError,
  APIError,
  APIUserAbortError,
} from '@anthropic-ai/sdk';
import type { BetaMessage } from '@anthropic-ai/sdk/resources/beta/messages/messages';
import { describe, expect, it } from 'vitest';
import {
  AnthropicProvider,
  anthropicParams,
  anthropicSchema,
  mapAnthropicError,
  mapAnthropicMessage,
  REFUSAL_FALLBACK_BETA,
} from '../../../src/adapters/anthropic/AnthropicProvider';
import type { AiAttemptRequest } from '../../../src/adapters/ai/callPolicy';
import {
  aiProviderContract,
  contractPrompt,
  contractRequest,
  testRuntime,
} from '../../contracts/aiProvider.contract';
import { AiFetch, ANTHROPIC_FIXTURES, fixtureResponse } from '../../helpers/aiFixtures';
import { fakeReading } from '../../fakes/FakeAiProvider';

const TEST_KEY = 'sk-ant-test-not-a-real-key';

aiProviderContract({
  name: 'AnthropicProvider',
  make(steps, runtime) {
    const stub = AiFetch.fromSteps(steps, ANTHROPIC_FIXTURES);
    return {
      provider: new AnthropicProvider({ apiKey: TEST_KEY, runtime, fetch: stub.fetch }),
      model: 'claude-sonnet-5',
      servedModel: 'claude-sonnet-5',
      attempts: () => stub.requests.length,
      sentMaxTokens: () => stub.requests.map((r) => r.body['max_tokens'] as number),
    };
  },
});

function attempt(model: string, overrides: Partial<AiAttemptRequest> = {}): AiAttemptRequest {
  return {
    model,
    prompt: contractPrompt(),
    maxTokens: 800,
    effort: 'low',
    refusalFallbacks: true,
    timeoutMs: 1000,
    ...overrides,
  };
}

describe('AnthropicProvider request shape (Sprint 8.1 API notes)', () => {
  it('sends the cached system block, the user message, adaptive thinking, effort and the stripped schema', async () => {
    const runtime = testRuntime();
    const stub = AiFetch.fromSteps(['ok'], ANTHROPIC_FIXTURES);
    const provider = new AnthropicProvider({ apiKey: TEST_KEY, runtime, fetch: stub.fetch });
    const request = contractRequest(runtime, 'claude-sonnet-5');
    await provider.generate(request);
    const [sent] = stub.requests;
    expect(sent?.url).toContain('/v1/messages');
    expect(sent?.headers.get('x-api-key')).toBe(TEST_KEY);
    expect(sent?.headers.get('anthropic-beta')).toBeNull();
    expect(sent?.body).toMatchObject({
      model: 'claude-sonnet-5',
      max_tokens: 800,
      stream: true,
      system: [{ type: 'text', text: request.prompt.system, cache_control: { type: 'ephemeral' } }],
      messages: [{ role: 'user', content: request.prompt.user }],
      thinking: { type: 'adaptive' },
      output_config: { effort: 'low', format: { type: 'json_schema' } },
    });
    for (const banned of ['temperature', 'top_p', 'top_k', 'metadata', 'fallbacks']) {
      expect(sent?.body).not.toHaveProperty(banned);
    }
    const schema = JSON.stringify(sent?.body['output_config']);
    expect(schema).not.toMatch(/maxLength|maxItems|\$comment/);
    expect(schema).toContain('"minItems":1');
  });

  it('adds the refusal-fallback beta and fallbacks only for Opus with ai.refusalFallbacks', async () => {
    const runtime = testRuntime();
    const stub = AiFetch.fromSteps(['ok'], ANTHROPIC_FIXTURES);
    const provider = new AnthropicProvider({ apiKey: TEST_KEY, runtime, fetch: stub.fetch });
    await provider.generate(contractRequest(runtime, 'claude-opus-5'));
    expect(stub.requests[0]?.headers.get('anthropic-beta')).toContain(REFUSAL_FALLBACK_BETA);
    expect(stub.requests[0]?.body['fallbacks']).toBe('default');
    expect(
      anthropicParams(attempt('claude-opus-5', { refusalFallbacks: false })),
    ).not.toHaveProperty('fallbacks');
    expect(anthropicParams(attempt('claude-sonnet-5'))).not.toHaveProperty('betas');
  });

  it('omits effort and adaptive thinking for claude-haiku-*', () => {
    const params = anthropicParams(attempt('claude-haiku-4-5'));
    expect(params).not.toHaveProperty('thinking');
    expect(params).not.toHaveProperty('fallbacks');
    expect(params.output_config).not.toHaveProperty('effort');
  });

  it('strips only the keywords the vendor rejects (minItems 1 stays, minItems 2 goes)', () => {
    expect(
      anthropicSchema({
        type: 'object',
        $comment: 'x',
        properties: {
          maxLength: { type: 'string', maxLength: 3, minLength: 1 },
          a: {
            type: 'array',
            minItems: 2,
            maxItems: 3,
            items: {
              type: 'number',
              minimum: 0,
              maximum: 1,
              multipleOf: 1,
              exclusiveMinimum: 0,
              exclusiveMaximum: 2,
            },
          },
          b: { type: 'array', minItems: 1 },
        },
        required: ['a'],
      }),
    ).toEqual({
      type: 'object',
      properties: {
        maxLength: { type: 'string' },
        a: { type: 'array', items: { type: 'number' } },
        b: { type: 'array', minItems: 1 },
      },
      required: ['a'],
    });
  });

  it('builds a client per call with the per-call timeout (min of ai.timeoutMs and the deadline)', async () => {
    const runtime = testRuntime();
    const stub = AiFetch.fromSteps(['ok'], ANTHROPIC_FIXTURES);
    const provider = new AnthropicProvider({
      apiKey: TEST_KEY,
      runtime,
      fetch: stub.fetch,
      baseURL: 'https://anthropic.test.invalid',
    });
    const request = contractRequest(runtime, 'claude-sonnet-5', { timeoutMs: 40_000 });
    await provider.generate({ ...request, deadlineAt: request.startedAt + 30_000 });
    expect(stub.requests[0]?.url).toMatch(/^https:\/\/anthropic\.test\.invalid\/v1\/messages/);
    expect(stub.requests[0]?.headers.get('x-stainless-timeout')).toBe('30');
  });
});

function message(overrides: Partial<BetaMessage>): BetaMessage {
  return {
    id: 'msg_0',
    type: 'message',
    role: 'assistant',
    model: 'claude-opus-5',
    content: [],
    stop_reason: 'end_turn',
    stop_sequence: null,
    stop_details: null,
    usage: { input_tokens: 10, output_tokens: 5 },
    ...overrides,
  } as unknown as BetaMessage;
}

describe('AnthropicProvider result mapping', () => {
  const request = attempt('claude-opus-5');
  const reading = JSON.stringify(fakeReading(request.prompt.expected));

  it('skips thinking and fallback blocks and prices at the serving model', async () => {
    const runtime = testRuntime();
    const stub = AiFetch.fromSteps(['ok'], ANTHROPIC_FIXTURES);
    const provider = new AnthropicProvider({ apiKey: TEST_KEY, runtime, fetch: stub.fetch });
    const result = await provider.generate(contractRequest(runtime, 'claude-sonnet-5'));
    expect(result.kind).toBe('ok');
    const mapped = mapAnthropicMessage(
      message({
        model: 'claude-opus-4-8',
        content: [
          { type: 'fallback' } as never,
          { type: 'text', text: reading, citations: null } as never,
        ],
      }),
      request,
    );
    expect(mapped).toMatchObject({
      kind: 'ok',
      model: 'claude-opus-4-8',
      usage: { inputTokens: 10, outputTokens: 5, cacheReadTokens: 0, cacheWriteTokens: 0 },
    });
  });

  it('refusal without stop_details → category null; other stop reasons → invalid_output', () => {
    expect(mapAnthropicMessage(message({ stop_reason: 'refusal' }), request)).toMatchObject({
      kind: 'refused',
      category: null,
    });
    expect(mapAnthropicMessage(message({ stop_reason: 'pause_turn' }), request)).toMatchObject({
      kind: 'invalid_output',
      issues: ['stop_reason pause_turn'],
    });
  });

  it('valid JSON that fails the zod parse → invalid_output', () => {
    const mapped = mapAnthropicMessage(
      message({ content: [{ type: 'text', text: '{"classification":"none"}' } as never] }),
      request,
    );
    expect(mapped.kind).toBe('invalid_output');
  });

  it('maps SDK errors: timeout, abort, 429, 5xx, connection, 4xx, unknown', () => {
    expect(mapAnthropicError(new APIConnectionTimeoutError(), false)).toEqual({ kind: 'timeout' });
    expect(mapAnthropicError(new APIUserAbortError(), true)).toEqual({ kind: 'timeout' });
    expect(mapAnthropicError(new APIUserAbortError(), false)).toMatchObject({
      kind: 'upstream',
      retryable: true,
    });
    const status = (code: number) => new APIError(code, undefined, 'x', new Headers());
    expect(mapAnthropicError(status(429), false)).toMatchObject({
      kind: 'rate_limited',
      retryable: true,
    });
    expect(mapAnthropicError(status(529), false)).toMatchObject({
      kind: 'upstream',
      retryable: true,
    });
    expect(mapAnthropicError(new APIConnectionError({ message: 'down' }), false)).toMatchObject({
      kind: 'upstream',
      retryable: true,
      detail: 'network',
    });
    expect(mapAnthropicError(status(400), false)).toMatchObject({
      kind: 'upstream',
      retryable: false,
    });
    expect(mapAnthropicError(new Error('boom'), false)).toMatchObject({
      kind: 'upstream',
      retryable: false,
    });
  });

  it('a 400 is not retried; an in-stream overloaded error is', async () => {
    const runtime = testRuntime();
    const badRequest = new AiFetch([
      () =>
        fixtureResponse({
          status: 400,
          body: { type: 'error', error: { type: 'invalid_request_error', message: 'bad' } },
        }),
    ]);
    const provider = new AnthropicProvider({ apiKey: TEST_KEY, runtime, fetch: badRequest.fetch });
    expect((await provider.generate(contractRequest(runtime, 'claude-sonnet-5'))).kind).toBe(
      'upstream',
    );
    expect(badRequest.requests).toHaveLength(1);

    const streamError = new AiFetch([
      () =>
        fixtureResponse({
          status: 200,
          sse: [
            {
              event: 'error',
              data: { type: 'error', error: { type: 'overloaded_error', message: 'Overloaded' } },
            },
          ],
        }),
      () => fixtureResponse(ANTHROPIC_FIXTURES.ok),
    ]);
    const retrying = new AnthropicProvider({ apiKey: TEST_KEY, runtime, fetch: streamError.fetch });
    const result = await retrying.generate(contractRequest(runtime, 'claude-sonnet-5'));
    expect(result.kind).toBe('ok');
    expect(streamError.requests).toHaveLength(2);
  });
});
