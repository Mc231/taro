/**
 * The LLM port (03 §9.3, RC38). `AiResult` = ok | refused | truncated |
 * error{timeout | rate_limited | upstream | invalid_output} (GLOSSARY §9.2).
 * The Anthropic adapter and `FakeAiProvider` arrive in Phase 8.
 */
export interface AiUsage {
  readonly inputTokens: number;
  readonly outputTokens: number;
  readonly cacheReadTokens: number;
  readonly cacheWriteTokens: number;
}

export interface AiRequest {
  readonly model: string;
  readonly system: string;
  readonly user: string;
  readonly maxTokens: number;
  readonly outputSchema: unknown;
  readonly effort?: string;
  readonly deadlineMs: number;
}

export type AiErrorKind = 'timeout' | 'rate_limited' | 'upstream' | 'invalid_output';

export interface AiOk {
  readonly kind: 'ok';
  readonly output: unknown;
  readonly usage: AiUsage;
}

export interface AiRefusedOrTruncated {
  readonly kind: 'refused' | 'truncated';
  readonly usage: AiUsage;
}

export interface AiError {
  readonly kind: 'error';
  readonly error: AiErrorKind;
}

export type AiResult = AiOk | AiRefusedOrTruncated | AiError;

export interface AiProvider {
  generate(request: AiRequest): Promise<AiResult>;
}
