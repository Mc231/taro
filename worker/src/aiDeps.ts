import { FakeAiProvider } from '../test/fakes/FakeAiProvider';
import { timerSleep, type AiRuntime } from './adapters/ai/callPolicy';
import { AnthropicProvider } from './adapters/anthropic/AnthropicProvider';
import { OpenAiProvider } from './adapters/openai/OpenAiProvider';
import type { Env, Environment } from './env';
import type { AiProviders } from './ports/AiProvider';
import type { Clock } from './ports/Clock';
import type { Crypto } from './ports/Crypto';
import type { Logger } from './ports/Logger';

/**
 * AI adapters for `makeProdDeps` (03 §9.3, §11, RC97): one adapter per
 * provider whose key is present (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`); a
 * missing key leaves that provider out, and `AiRouter` then disables the
 * tiers routed to it. `AI_PROVIDER=fake` (dev / staging only, BE20; prod is
 * refused by `assertEnvironment`) serves every provider with `FakeAiProvider`.
 */
export function aiDeps(
  env: Env,
  environment: Environment,
  clock: Clock,
  crypto: Crypto,
  logger: Logger,
  fetchImpl: typeof fetch = fetch.bind(globalThis),
): { readonly ai: AiProviders } {
  const runtime: AiRuntime = { clock, crypto, sleep: timerSleep, logger };
  if (environment !== 'prod' && env.AI_PROVIDER === 'fake') {
    return {
      ai: {
        anthropic: new FakeAiProvider('anthropic', runtime),
        openai: new FakeAiProvider('openai', runtime),
      },
    };
  }
  const ai: { -readonly [K in keyof AiProviders]: AiProviders[K] } = {};
  if (env.ANTHROPIC_API_KEY !== undefined && env.ANTHROPIC_API_KEY !== '') {
    ai.anthropic = new AnthropicProvider({
      apiKey: env.ANTHROPIC_API_KEY,
      runtime,
      fetch: fetchImpl,
    });
  }
  if (env.OPENAI_API_KEY !== undefined && env.OPENAI_API_KEY !== '') {
    ai.openai = new OpenAiProvider({ apiKey: env.OPENAI_API_KEY, runtime, fetch: fetchImpl });
  }
  return { ai };
}
