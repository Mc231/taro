import Anthropic, {
  APIConnectionTimeoutError,
  APIError,
  APIUserAbortError,
} from '@anthropic-ai/sdk';
import type {
  BetaMessage,
  MessageCreateParamsBase,
} from '@anthropic-ai/sdk/resources/beta/messages/messages';
import type { AiGenerateRequest, AiProvider, AiResult } from '../../ports/AiProvider';
import {
  runWithPolicy,
  type AiAttemptOutcome,
  type AiAttemptRequest,
  type AiRuntime,
} from '../ai/callPolicy';
import { parseModelText, stripSchemaKeywords } from '../ai/output';

/**
 * Anthropic Messages API adapter (03 §9.3, RC32, RC97; wire shapes checked in
 * Sprint 8.1, `docs/ARCHITECTURE.md` §AI pipeline and cost).
 *
 * `@anthropic-ai/sdk` with `maxRetries: 0` (the retry policy is ours,
 * `runWithPolicy`) and a per-call timeout; `beta.messages.stream(...).finalMessage()`.
 * The static prefix is one system block with `cache_control: ephemeral`
 * (the `cacheBoundary` of `ReadingPromptInput`). Never sent: `temperature`,
 * `top_p`, `top_k`, an assistant prefill, `metadata.user_id`.
 */
export const REFUSAL_FALLBACK_BETA = 'server-side-fallback-2026-07-01';

/** JSON-schema keywords `output_config.format` rejects (400); L3 enforces them. */
export function anthropicSchema(schema: unknown): Record<string, unknown> {
  return stripSchemaKeywords(schema, (key, value) => {
    switch (key) {
      case 'minLength':
      case 'maxLength':
      case 'maxItems':
      case 'minimum':
      case 'maximum':
      case 'exclusiveMinimum':
      case 'exclusiveMaximum':
      case 'multipleOf':
      case '$comment':
        return true;
      case 'minItems':
        return typeof value === 'number' && value > 1;
      default:
        return false;
    }
  }) as Record<string, unknown>;
}

/** Haiku 4.5 takes neither adaptive thinking nor `effort` (400 on `effort`). */
function hasAdaptiveThinking(model: string): boolean {
  return !model.startsWith('claude-haiku-');
}

/** Request body of one call (exported for the request-shape tests). */
export function anthropicParams(request: AiAttemptRequest): MessageCreateParamsBase {
  const format = {
    type: 'json_schema' as const,
    schema: anthropicSchema(request.prompt.outputSchema),
  };
  const thinking = hasAdaptiveThinking(request.model);
  const fallbacks = request.refusalFallbacks && request.model.startsWith('claude-opus-');
  return {
    model: request.model,
    max_tokens: request.maxTokens,
    system: [{ type: 'text', text: request.prompt.system, cache_control: { type: 'ephemeral' } }],
    messages: [{ role: 'user', content: request.prompt.user }],
    output_config: thinking ? { format, effort: request.effort } : { format },
    ...(thinking ? { thinking: { type: 'adaptive' as const } } : {}),
    ...(fallbacks ? { betas: [REFUSAL_FALLBACK_BETA], fallbacks: 'default' as const } : {}),
  };
}

/** Maps a final message (03 §9.3 stop reasons). Thinking and `fallback` blocks are skipped. */
export function mapAnthropicMessage(
  message: BetaMessage,
  request: AiAttemptRequest,
): AiAttemptOutcome {
  const usage = {
    inputTokens: message.usage.input_tokens,
    outputTokens: message.usage.output_tokens,
    cacheReadTokens: message.usage.cache_read_input_tokens ?? 0,
    cacheWriteTokens: message.usage.cache_creation_input_tokens ?? 0,
  };
  const model = message.model;
  switch (message.stop_reason) {
    case 'end_turn': {
      const text = message.content
        .map((block) => (block.type === 'text' ? block.text : ''))
        .join('');
      const parsed = parseModelText(text, request.prompt.expected);
      return parsed.ok
        ? { kind: 'ok', output: parsed.output, model, usage }
        : { kind: 'invalid_output', issues: parsed.issues, model, usage };
    }
    case 'max_tokens':
      return { kind: 'truncated', model, usage };
    case 'refusal':
      return { kind: 'refused', category: message.stop_details?.category ?? null, model, usage };
    default:
      return {
        kind: 'invalid_output',
        issues: [`stop_reason ${String(message.stop_reason)}`],
        model,
        usage,
      };
  }
}

/** SDK error → outcome (Sprint 8.1 API notes). */
export function mapAnthropicError(error: unknown, timedOut: boolean): AiAttemptOutcome {
  if (
    error instanceof APIConnectionTimeoutError ||
    (error instanceof APIUserAbortError && timedOut)
  ) {
    return { kind: 'timeout' };
  }
  if (error instanceof APIError) {
    const status: unknown = error.status;
    if (status === 429) {
      return { kind: 'rate_limited', retryable: true, detail: '429' };
    }
    // No status: connection error or an in-stream `error` event (overloaded_error).
    if (typeof status !== 'number') {
      return { kind: 'upstream', retryable: true, detail: 'network' };
    }
    return { kind: 'upstream', retryable: status >= 500, detail: String(status) };
  }
  return { kind: 'upstream', retryable: false, detail: 'unknown' };
}

export interface AnthropicProviderOptions {
  readonly apiKey: string;
  readonly runtime: AiRuntime;
  readonly fetch?: typeof fetch;
  readonly baseURL?: string;
}

export class AnthropicProvider implements AiProvider {
  readonly id = 'anthropic' as const;

  constructor(private readonly options: AnthropicProviderOptions) {}

  generate(request: AiGenerateRequest): Promise<AiResult> {
    return runWithPolicy('anthropic', request, this.options.runtime, (attempt) =>
      this.attempt(attempt),
    );
  }

  private async attempt(request: AiAttemptRequest): Promise<AiAttemptOutcome> {
    const client = new Anthropic({
      apiKey: this.options.apiKey,
      maxRetries: 0,
      timeout: request.timeoutMs,
      ...(this.options.fetch === undefined ? {} : { fetch: this.options.fetch }),
      ...(this.options.baseURL === undefined ? {} : { baseURL: this.options.baseURL }),
    });
    const controller = new AbortController();
    const timer = setTimeout(() => {
      controller.abort();
    }, request.timeoutMs);
    try {
      const message = await client.beta.messages
        .stream(anthropicParams(request), { signal: controller.signal, timeout: request.timeoutMs })
        .finalMessage();
      return mapAnthropicMessage(message, request);
    } catch (error) {
      return mapAnthropicError(error, controller.signal.aborted);
    } finally {
      clearTimeout(timer);
    }
  }
}
