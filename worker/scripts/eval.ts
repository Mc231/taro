import { timerSleep } from '../src/adapters/ai/callPolicy';
import { JsonLogger } from '../src/adapters/cf/JsonLogger';
import { SystemClock } from '../src/adapters/cf/SystemClock';
import { WebCrypto } from '../src/adapters/cf/WebCrypto';
import type { CliDeps } from '../src/admin/cli';
import { main as liveEval, type LiveDeps, type Suite } from '../evals/lib/live';

/**
 * `npm run eval -- --provider anthropic|openai --model <id> --max-usd <usd> [--prompt v1] …`
 *
 * Live quality eval (Sprint 8.6, 03 §15.4): calls the real provider adapter
 * with the key from `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` (never printed)
 * and grades the answers with the rule graders. All logic lives in
 * `evals/lib/live.ts` (RC61).
 */
export function liveDeps(err: (line: string) => void): LiveDeps {
  const clock = new SystemClock();
  return {
    now: () => clock.now(),
    fetch: globalThis.fetch.bind(globalThis),
    runtime: {
      clock,
      crypto: new WebCrypto(),
      sleep: timerSleep,
      logger: new JsonLogger(clock, err, 'warn'),
    },
  };
}

export function runSuite(
  suite: Suite,
  argv: readonly string[],
  deps: CliDeps,
  live: LiveDeps = liveDeps((line) => {
    deps.err(line);
  }),
): Promise<number> {
  return liveEval(argv, deps, live, suite);
}

export function main(argv: readonly string[], deps: CliDeps, live?: LiveDeps): Promise<number> {
  return runSuite('quality', argv, deps, live);
}
