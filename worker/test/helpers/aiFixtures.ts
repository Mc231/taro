import anthropicCacheRead from '../fixtures/ai/anthropic/cache_read.json';
import anthropicInvalidJson from '../fixtures/ai/anthropic/invalid_json.json';
import anthropicOk from '../fixtures/ai/anthropic/ok.json';
import anthropicOverloaded from '../fixtures/ai/anthropic/overloaded.json';
import anthropicRateLimited from '../fixtures/ai/anthropic/rate_limited.json';
import anthropicRefusal from '../fixtures/ai/anthropic/refusal.json';
import anthropicServerError from '../fixtures/ai/anthropic/server_error.json';
import anthropicTruncation from '../fixtures/ai/anthropic/truncation.json';
import openAiCacheRead from '../fixtures/ai/openai/cache_read.json';
import openAiInvalidJson from '../fixtures/ai/openai/invalid_json.json';
import openAiOk from '../fixtures/ai/openai/ok.json';
import openAiOverloaded from '../fixtures/ai/openai/overloaded.json';
import openAiRateLimited from '../fixtures/ai/openai/rate_limited.json';
import openAiRefusal from '../fixtures/ai/openai/refusal.json';
import openAiServerError from '../fixtures/ai/openai/server_error.json';
import openAiTruncation from '../fixtures/ai/openai/truncation.json';
import type { AiScenarioStep } from '../contracts/aiProvider.contract';

/**
 * Recorded, sanitised AI fixtures (`test/fixtures/ai/<provider>/<step>.json`)
 * served by a scripted `fetch` (no network, 03 §15.2). A fixture is either
 * `{status, body}` (JSON) or `{status: 200, sse: [{event, data}]}` (Anthropic
 * stream). `timeout` hangs until the request's signal aborts.
 */
export interface AiFixture {
  readonly status: number;
  readonly body?: unknown;
  readonly sse?: readonly { readonly event: string; readonly data: unknown }[];
}

type RecordedFixtures = Record<Exclude<AiScenarioStep, 'timeout'>, AiFixture>;

export const ANTHROPIC_FIXTURES: RecordedFixtures = {
  ok: anthropicOk,
  cache_read: anthropicCacheRead,
  refusal: anthropicRefusal,
  truncation: anthropicTruncation,
  invalid_json: anthropicInvalidJson,
  rate_limited: anthropicRateLimited,
  overloaded: anthropicOverloaded,
  server_error: anthropicServerError,
};

export const OPENAI_FIXTURES: RecordedFixtures = {
  ok: openAiOk,
  cache_read: openAiCacheRead,
  refusal: openAiRefusal,
  truncation: openAiTruncation,
  invalid_json: openAiInvalidJson,
  rate_limited: openAiRateLimited,
  overloaded: openAiOverloaded,
  server_error: openAiServerError,
};

export function fixtureResponse(fixture: AiFixture): Response {
  if (fixture.sse !== undefined) {
    const text = fixture.sse
      .map((e) => `event: ${e.event}\ndata: ${JSON.stringify(e.data)}\n\n`)
      .join('');
    return new Response(text, {
      status: fixture.status,
      headers: { 'content-type': 'text/event-stream' },
    });
  }
  return new Response(JSON.stringify(fixture.body), {
    status: fixture.status,
    headers: { 'content-type': 'application/json' },
  });
}

export interface AiRecordedRequest {
  readonly url: string;
  readonly headers: Headers;
  readonly body: Record<string, unknown>;
}

export type AiResponder = (
  request: AiRecordedRequest,
  signal: AbortSignal | undefined,
) => Response | Promise<Response>;

/** A step responder that never answers until the request is aborted. */
export const hang: AiResponder = (_request, signal) =>
  new Promise<Response>((_resolve, reject) => {
    signal?.addEventListener('abort', () => {
      reject(new DOMException('The operation was aborted.', 'AbortError'));
    });
  });

/** Scripted `fetch`: one responder per call, in order; extra calls fail loudly. */
export class AiFetch {
  readonly requests: AiRecordedRequest[] = [];
  private readonly responders: AiResponder[];

  constructor(responders: readonly AiResponder[]) {
    this.responders = [...responders];
  }

  static fromSteps(steps: readonly AiScenarioStep[], fixtures: RecordedFixtures): AiFetch {
    return new AiFetch(
      steps.map((step) => (step === 'timeout' ? hang : () => fixtureResponse(fixtures[step]))),
    );
  }

  readonly fetch: typeof fetch = async (input, init) => {
    const request = new Request(input, init);
    const text = await request.text();
    const recorded: AiRecordedRequest = {
      url: request.url,
      headers: request.headers,
      body: text === '' ? {} : (JSON.parse(text) as Record<string, unknown>),
    };
    this.requests.push(recorded);
    const responder = this.responders.shift();
    if (responder === undefined) {
      throw new Error('AiFetch: unexpected extra request');
    }
    return responder(recorded, init?.signal ?? undefined);
  };
}
