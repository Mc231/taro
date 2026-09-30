import { describe, expect, it } from 'vitest';
import type { AiAttemptRequest } from '../../../src/adapters/ai/callPolicy';
import {
  mapOpenAiResponse,
  OPENAI_MODERATION_MODEL,
  OPENAI_SCHEMA_NAME,
  openAiBody,
  openAiSchema,
  OpenAiProvider,
} from '../../../src/adapters/openai/OpenAiProvider';
import {
  aiProviderContract,
  contractPrompt,
  contractRequest,
  testRuntime,
} from '../../contracts/aiProvider.contract';
import { AiFetch, fixtureResponse, hang, OPENAI_FIXTURES } from '../../helpers/aiFixtures';
import { fakeReading } from '../../fakes/FakeAiProvider';

const TEST_KEY = 'sk-openai-test-not-a-real-key';

aiProviderContract({
  name: 'OpenAiProvider',
  make(steps, runtime) {
    const stub = AiFetch.fromSteps(steps, OPENAI_FIXTURES);
    return {
      provider: new OpenAiProvider({ apiKey: TEST_KEY, runtime, fetch: stub.fetch }),
      model: 'gpt-6-luna',
      servedModel: 'gpt-6-luna',
      attempts: () => stub.requests.length,
      sentMaxTokens: () => stub.requests.map((r) => r.body['max_output_tokens'] as number),
    };
  },
});

function attempt(model: string): AiAttemptRequest {
  return {
    model,
    prompt: contractPrompt(),
    maxTokens: 800,
    effort: 'low',
    refusalFallbacks: true,
    timeoutMs: 1000,
  };
}

const request = attempt('gpt-6-luna');
const readingText = JSON.stringify(fakeReading(request.prompt.expected));

function body(overrides: Record<string, unknown>): Record<string, unknown> {
  return {
    status: 'completed',
    model: 'gpt-6-luna',
    output: [{ type: 'message', content: [{ type: 'output_text', text: readingText }] }],
    usage: { input_tokens: 100, output_tokens: 50 },
    ...overrides,
  };
}

describe('OpenAiProvider request shape (Sprint 8.1 API notes)', () => {
  it('posts developer + user input, a strict schema, reasoning effort, max_output_tokens, store false', async () => {
    const runtime = testRuntime();
    const stub = AiFetch.fromSteps(['ok'], OPENAI_FIXTURES);
    const provider = new OpenAiProvider({ apiKey: TEST_KEY, runtime, fetch: stub.fetch });
    const req = contractRequest(runtime, 'gpt-6.1-sol');
    await provider.generate(req);
    const [sent] = stub.requests;
    expect(sent?.url).toBe('https://api.openai.com/v1/responses');
    expect(sent?.headers.get('authorization')).toBe(`Bearer ${TEST_KEY}`);
    expect(sent?.body).toMatchObject({
      model: 'gpt-6.1-sol',
      input: [
        { role: 'developer', content: [{ type: 'input_text', text: req.prompt.system }] },
        { role: 'user', content: [{ type: 'input_text', text: req.prompt.user }] },
      ],
      text: { format: { type: 'json_schema', name: OPENAI_SCHEMA_NAME, strict: true } },
      reasoning: { effort: 'low' },
      max_output_tokens: 800,
      store: false,
    });
    for (const banned of [
      'user',
      'safety_identifier',
      'temperature',
      'prompt_cache_key',
      'fallbacks',
    ]) {
      expect(sent?.body).not.toHaveProperty(banned);
    }
  });

  it('omits reasoning for a model without it and keeps minItems/maxItems in the schema', () => {
    expect(openAiBody(attempt('gpt-4.1-mini'))).not.toHaveProperty('reasoning');
    expect(openAiBody(attempt('o4-mini'))).toHaveProperty('reasoning');
    expect(
      openAiSchema({
        $comment: 'x',
        type: 'object',
        properties: {
          a: {
            type: 'array',
            minItems: 1,
            maxItems: 3,
            items: { type: 'string', maxLength: 5, minLength: 1 },
          },
        },
      }),
    ).toEqual({
      type: 'object',
      properties: { a: { type: 'array', minItems: 1, maxItems: 3, items: { type: 'string' } } },
    });
  });
});

describe('OpenAiProvider result mapping', () => {
  it('subtracts cache reads and writes from input tokens; absent details count as 0', () => {
    expect(
      mapOpenAiResponse(
        body({
          usage: {
            input_tokens: 3700,
            output_tokens: 600,
            input_tokens_details: { cached_tokens: 2000, cache_write_tokens: 900 },
          },
        }),
        request,
      ),
    ).toMatchObject({
      kind: 'ok',
      usage: { inputTokens: 800, outputTokens: 600, cacheReadTokens: 2000, cacheWriteTokens: 900 },
    });
    expect(mapOpenAiResponse(body({ usage: null }), request)).toMatchObject({
      usage: { inputTokens: 0, outputTokens: 0, cacheReadTokens: 0, cacheWriteTokens: 0 },
    });
  });

  it('maps incomplete reasons, failed and other statuses, and malformed bodies', () => {
    const incomplete = (reason: string | null) =>
      mapOpenAiResponse(body({ status: 'incomplete', incomplete_details: { reason } }), request);
    expect(incomplete('content_filter')).toMatchObject({ kind: 'refused', category: null });
    expect(incomplete('max_output_tokens').kind).toBe('truncated');
    expect(incomplete(null)).toMatchObject({
      kind: 'upstream',
      retryable: false,
      detail: 'incomplete:null',
    });
    expect(mapOpenAiResponse(body({ status: 'failed' }), request)).toMatchObject({
      kind: 'upstream',
      retryable: true,
    });
    expect(mapOpenAiResponse(body({ status: 'cancelled' }), request)).toMatchObject({
      kind: 'upstream',
      retryable: false,
    });
    expect(mapOpenAiResponse({ nope: true }, request)).toMatchObject({
      kind: 'upstream',
      detail: 'malformed_response',
    });
    expect(
      mapOpenAiResponse(body({ output: [{ type: 'message' }, { type: 'reasoning' }] }), request),
    ).toMatchObject({ kind: 'invalid_output' });
    expect(
      mapOpenAiResponse(
        body({ output: [{ type: 'message', content: [{ type: 'output_text' }] }] }),
        request,
      ),
    ).toMatchObject({ kind: 'invalid_output' });
  });

  it('insufficient_quota 429 is not retried; 4xx is not retried; a network error is', async () => {
    const runtime = testRuntime();
    const quota = new AiFetch([
      () => fixtureResponse({ status: 429, body: { error: { code: 'insufficient_quota' } } }),
    ]);
    const p1 = new OpenAiProvider({ apiKey: TEST_KEY, runtime, fetch: quota.fetch });
    expect((await p1.generate(contractRequest(runtime, 'gpt-6-luna'))).kind).toBe('upstream');
    expect(quota.requests).toHaveLength(1);

    const garbage429 = new AiFetch([
      () => new Response('not json', { status: 429 }),
      () => new Response('{}', { status: 401 }),
    ]);
    const p2 = new OpenAiProvider({ apiKey: TEST_KEY, runtime, fetch: garbage429.fetch });
    expect((await p2.generate(contractRequest(runtime, 'gpt-6-luna'))).kind).toBe('upstream');
    expect(garbage429.requests).toHaveLength(2);

    const network = new AiFetch([
      () => Promise.reject(new TypeError('network error')),
      () => fixtureResponse(OPENAI_FIXTURES.ok),
    ]);
    const p3 = new OpenAiProvider({ apiKey: TEST_KEY, runtime, fetch: network.fetch });
    expect((await p3.generate(contractRequest(runtime, 'gpt-6-luna'))).kind).toBe('ok');
    expect(network.requests).toHaveLength(2);
  });
});

describe('OpenAiProvider.moderate (03 §9.4, RC97)', () => {
  it('posts omni-moderation-latest and returns the flagged categories', async () => {
    const runtime = testRuntime();
    const stub = new AiFetch([
      () =>
        fixtureResponse({
          status: 200,
          body: {
            id: 'modr-0',
            model: 'omni-moderation-latest',
            results: [
              {
                flagged: true,
                categories: {
                  'self-harm': true,
                  'self-harm/intent': true,
                  violence: false,
                  hate: null,
                },
              },
            ],
          },
        }),
    ]);
    const provider = new OpenAiProvider({
      apiKey: TEST_KEY,
      runtime,
      fetch: stub.fetch,
      baseURL: 'https://openai.test.invalid/v1',
    });
    await expect(provider.moderate('question text', 2000)).resolves.toEqual({
      kind: 'ok',
      flagged: true,
      categories: ['self-harm', 'self-harm/intent'],
    });
    expect(stub.requests[0]?.url).toBe('https://openai.test.invalid/v1/moderations');
    expect(stub.requests[0]?.body).toEqual({
      model: OPENAI_MODERATION_MODEL,
      input: 'question text',
    });
  });

  it('any failure (HTTP error, bad body, timeout) → error, logged without the text', async () => {
    const runtime = testRuntime();
    const stub = new AiFetch([
      () => fixtureResponse({ status: 500, body: {} }),
      () => fixtureResponse({ status: 200, body: { results: [] } }),
      hang,
    ]);
    const provider = new OpenAiProvider({ apiKey: TEST_KEY, runtime, fetch: stub.fetch });
    await expect(provider.moderate('q', 1000)).resolves.toEqual({ kind: 'error' });
    await expect(provider.moderate('q', 1000)).resolves.toEqual({ kind: 'error' });
    await expect(provider.moderate('q', 20)).resolves.toEqual({ kind: 'error' });
    expect(runtime.logger.find('ai_moderation_failed')).toHaveLength(3);
    expect(runtime.logger.lines().join('\n')).not.toContain('"q"');
  });
});
