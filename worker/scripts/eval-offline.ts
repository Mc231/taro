import { main as evalOffline } from '../evals/lib/cli';
import { SystemClock } from '../src/adapters/cf/SystemClock';
import type { CliDeps } from '../src/admin/cli';
import type { Clock } from '../src/ports/Clock';

export { USAGE } from '../evals/lib/cli';

/**
 * `npm run eval:offline -- --cases <jsonl> [--cases …] --outputs <dir|jsonl> --out <dir>`
 *
 * Grades pre-recorded model outputs with the rule-based graders of
 * `evals/lib/` (Sprint 8.6, 05 §4.3). No provider API is called and no key
 * is read. All logic lives in `evals/lib/cli.ts` (RC61).
 */
export function main(
  argv: readonly string[],
  deps: CliDeps,
  clock: Clock = new SystemClock(),
): Promise<number> {
  return evalOffline(argv, deps, () => clock.now());
}
