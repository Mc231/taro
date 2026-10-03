import { z } from 'zod';
import type {
  AiGenerateRequest,
  AiModerationResult,
  AiProvider,
  AiResult,
} from '../../ports/AiProvider';
import {
  runWithPolicy,
  type AiAttemptOutcome,
  type AiAttemptRequest,
  type AiRuntime,
} from '../ai/callPolicy';
import { parseModelText, stripSchemaKeywords } from '../ai/output';

/**
 * OpenAI Responses API adapter over plain `fetch` (03 §9.3, RC97; Sprint 8.1
 * decision: no SDK, non-streaming, `store: false`). The static prefix goes
 * first as the developer message, so OpenAI's automatic prefix caching
 * (>= 1024 tokens) can reuse it; no explicit breakpoint exists or is needed.
 * `ai.serviceTier: "fast"` sends `service_tier: "fast"` (Fast mode, formerly
 * Priority processing: about 40 % lower latency at 2x the price, measured
 * 2026-10-03); the response's `service_tier` says what was served, since
 * OpenAI may downgrade to `default` (billed at standard rates) under load.
 * Never sent: `user`, `safety_identifier`, `temperature`, `prompt_cache_key`.
 * `ai.refusalFallbacks` is ignored.
 */
export const OPENAI_BASE_URL = 'https://api.openai.com/v1';
export const OPENAI_SCHEMA_NAME = 'tarot_reading';
export const OPENAI_MODERATION_MODEL = 'omni-moderation-latest';

/** `service_tier` values billed at the Fast price (`priority` is the pre-rename name). */
const FAST_SERVICE_TIERS: readonly string[] = ['fast', 'priority'];

/** Models with a `reasoning.effort` parameter (GPT-5+ and the o-series). */
const REASONING_MODEL = /^(gpt-(?:[5-9]|\d{2,})|o\d)/;

/** Keywords outside OpenAI's documented strict-mode list; L3 enforces them. */
export function openAiSchema(schema: unknown): Record<string, unknown> {
  return stripSchemaKeywords(
    schema,
    (key) => key === 'minLength' || key === 'maxLength' || key === '$comment',
  ) as Record<string, unknown>;
}

/** Request body of one call (exported for the request-shape tests). */
export function openAiBody(request: AiAttemptRequest): Record<string, unknown> {
  return {
    model: request.model,
    input: [
      { role: 'developer', content: [{ type: 'input_text', text: request.prompt.system }] },
      { role: 'user', content: [{ type: 'input_text', text: request.prompt.user }] },
    ],
    text: {
      format: {
        type: 'json_schema',
        name: OPENAI_SCHEMA_NAME,
        schema: openAiSchema(request.prompt.outputSchema),
        strict: true,
      },
    },
    ...(REASONING_MODEL.test(request.model) ? { reasoning: { effort: request.effort } } : {}),
    max_output_tokens: request.maxTokens,
    ...(request.serviceTier === 'fast' ? { service_tier: 'fast' } : {}),
    store: false,
  };
}

const count = z.int().min(0);

const responseSchema = z.object({
  status: z.string(),
  model: z.string(),
  service_tier: z.string().nullish(),
  output: z
    .array(
      z.object({
        type: z.string(),
        content: z.array(z.object({ type: z.string(), text: z.string().optional() })).optional(),
      }),
    )
    .default([]),
  incomplete_details: z.object({ reason: z.string().nullish() }).nullish(),
  usage: z
    .object({
      input_tokens: count,
      output_tokens: count,
      input_tokens_details: z
        .object({ cached_tokens: count.nullish(), cache_write_tokens: count.nullish() })
        .nullish(),
    })
    .nullish(),
});

type OpenAiResponse = z.infer<typeof responseSchema>;

/** Normalised usage: OpenAI's `input_tokens` includes cache reads and writes (API notes). */
function usageOf(response: OpenAiResponse) {
  const usage = response.usage;
  const cacheRead = usage?.input_tokens_details?.cached_tokens ?? 0;
  const cacheWrite = usage?.input_tokens_details?.cache_write_tokens ?? 0;
  return {
    inputTokens: Math.max(0, (usage?.input_tokens ?? 0) - cacheRead - cacheWrite),
    outputTokens: usage?.output_tokens ?? 0,
    cacheReadTokens: cacheRead,
    cacheWriteTokens: cacheWrite,
  };
}

/** Maps a Responses API body (03 §9.3 result mapping). */
export function mapOpenAiResponse(body: unknown, request: AiAttemptRequest): AiAttemptOutcome {
  const parsed = responseSchema.safeParse(body);
  if (!parsed.success) {
    return { kind: 'upstream', retryable: false, detail: 'malformed_response' };
  }
  const response = parsed.data;
  const usage = usageOf(response);
  const model = response.model;
  const served = {
    model,
    usage,
    ...(FAST_SERVICE_TIERS.includes(response.service_tier ?? '') ? { fast: true } : {}),
  };
  const content = response.output
    .filter((item) => item.type === 'message')
    .flatMap((item) => item.content ?? []);
  if (content.some((part) => part.type === 'refusal')) {
    return { kind: 'refused', category: null, ...served };
  }
  if (response.status === 'completed') {
    const text = content
      .filter((part) => part.type === 'output_text')
      .map((part) => part.text ?? '')
      .join('');
    const result = parseModelText(text, request.prompt.expected);
    return result.ok
      ? { kind: 'ok', output: result.output, ...served }
      : { kind: 'invalid_output', issues: result.issues, ...served };
  }
  if (response.status === 'incomplete') {
    const reason = response.incomplete_details?.reason;
    if (reason === 'max_output_tokens') {
      return { kind: 'truncated', ...served };
    }
    if (reason === 'content_filter') {
      return { kind: 'refused', category: null, ...served };
    }
    return { kind: 'upstream', retryable: false, detail: `incomplete:${String(reason)}` };
  }
  return { kind: 'upstream', retryable: response.status === 'failed', detail: response.status };
}

const errorBodySchema = z.object({ error: z.object({ code: z.string().nullish() }).nullish() });

/** HTTP error → outcome: `insufficient_quota` 429 is not retried (API notes). */
export async function mapOpenAiHttpError(response: Response): Promise<AiAttemptOutcome> {
  const status = response.status;
  if (status === 429) {
    const body = errorBodySchema.safeParse(await response.json().catch(() => null));
    const code = body.success ? body.data.error?.code : undefined;
    return code === 'insufficient_quota'
      ? { kind: 'upstream', retryable: false, detail: 'insufficient_quota' }
      : { kind: 'rate_limited', retryable: true, detail: '429' };
  }
  return { kind: 'upstream', retryable: status >= 500, detail: String(status) };
}

const moderationSchema = z.object({
  results: z
    .array(
      z.object({ flagged: z.boolean(), categories: z.record(z.string(), z.boolean().nullish()) }),
    )
    .min(1),
});

export interface OpenAiProviderOptions {
  readonly apiKey: string;
  readonly runtime: AiRuntime;
  readonly fetch?: typeof fetch;
  readonly baseURL?: string;
}

export class OpenAiProvider implements AiProvider {
  readonly id = 'openai' as const;
  private readonly fetchImpl: typeof fetch;
  private readonly baseURL: string;

  constructor(private readonly options: OpenAiProviderOptions) {
    this.fetchImpl = options.fetch ?? fetch.bind(globalThis);
    this.baseURL = options.baseURL ?? OPENAI_BASE_URL;
  }

  generate(request: AiGenerateRequest): Promise<AiResult> {
    return runWithPolicy('openai', request, this.options.runtime, (attempt) =>
      this.attempt(attempt),
    );
  }

  /** `POST /v1/moderations`; any failure is `error`, which never blocks a reading (03 §9.4). */
  readonly moderate = async (text: string, timeoutMs: number): Promise<AiModerationResult> => {
    const outcome = await this.post(
      '/moderations',
      { model: OPENAI_MODERATION_MODEL, input: text },
      timeoutMs,
    );
    const parsed = outcome.ok ? moderationSchema.safeParse(outcome.body) : undefined;
    if (parsed?.success !== true) {
      this.options.runtime.logger.log('warn', 'ai_moderation_failed', { provider: this.id });
      return { kind: 'error' };
    }
    const [result] = parsed.data.results as [(typeof parsed.data.results)[number]];
    return {
      kind: 'ok',
      flagged: result.flagged,
      categories: Object.entries(result.categories)
        .filter(([, on]) => on === true)
        .map(([name]) => name),
    };
  };

  private async attempt(request: AiAttemptRequest): Promise<AiAttemptOutcome> {
    const outcome = await this.post('/responses', openAiBody(request), request.timeoutMs);
    if (outcome.ok) {
      return mapOpenAiResponse(outcome.body, request);
    }
    return outcome.failure;
  }

  private async post(
    path: string,
    body: unknown,
    timeoutMs: number,
  ): Promise<
    | { readonly ok: true; readonly body: unknown }
    | { readonly ok: false; readonly failure: AiAttemptOutcome }
  > {
    const controller = new AbortController();
    const timer = setTimeout(() => {
      controller.abort();
    }, timeoutMs);
    try {
      const response = await this.fetchImpl(`${this.baseURL}${path}`, {
        method: 'POST',
        headers: {
          authorization: `Bearer ${this.options.apiKey}`,
          'content-type': 'application/json',
        },
        body: JSON.stringify(body),
        signal: controller.signal,
      });
      if (!response.ok) {
        return { ok: false, failure: await mapOpenAiHttpError(response) };
      }
      return { ok: true, body: await response.json() };
    } catch {
      return {
        ok: false,
        failure: controller.signal.aborted
          ? { kind: 'timeout' }
          : { kind: 'upstream', retryable: true, detail: 'network' },
      };
    } finally {
      clearTimeout(timer);
    }
  }
}
