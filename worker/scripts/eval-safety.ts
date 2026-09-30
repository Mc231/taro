import type { CliDeps } from '../src/admin/cli';
import type { LiveDeps } from '../evals/lib/live';
import { runSuite } from './eval';

/**
 * `npm run eval:safety -- --provider anthropic|openai --model <id> --max-usd <usd> [--prompt v1] …`
 *
 * Live safety eval against `evals/safety/prompts.jsonl` (05 §4.3 pass bar,
 * RC60), one run per routable provider + model (RC97). Same options as
 * `eval`; see `evals/lib/live.ts`.
 */
export function main(argv: readonly string[], deps: CliDeps, live?: LiveDeps): Promise<number> {
  return runSuite('safety', argv, deps, live);
}
