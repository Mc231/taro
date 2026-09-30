import { parseArgs, type CliDeps } from '../src/admin/cli';
import { parseCases, providerView, renderCase } from '../src/admin/renderPrompt';
import { isPromptVersion, PROMPT_VERSIONS } from '../src/prompts/templates';

/**
 * `npm run prompt:render -- --cases <file.json|file.jsonl> --out <dir> [--prompt v1]`
 *
 * Offline prompt evaluation (Phase 8 Sprints 8.2, 8.6): renders every case
 * `{id, locale, spreadId, cards: [{cardId, reversed, positionId?}], question?,
 * prefilterHint?, regenerationNote?}` into `<out>/<id>.txt` holding
 * `=== SYSTEM ===` and `=== USER ===` exactly as a provider receives them.
 * Calls no AI provider and needs no key. Cards without `positionId` fill the
 * spread's positions in draw order. Exit codes: 0 ok, 1 a case failed, 2 usage.
 */
export const USAGE =
  'usage: render-prompt --cases <file.json|file.jsonl> --out <dir> [--prompt <version>]';

export async function main(argv: readonly string[], deps: CliDeps): Promise<number> {
  const args = parseArgs(argv, { flags: [], options: ['--cases', '--out', '--prompt'] });
  if (!args.ok) {
    deps.err(`${args.error}\n${USAGE}`);
    return 2;
  }
  const casesPath = args.options.get('--cases');
  const outDir = args.options.get('--out');
  if (casesPath === undefined || outDir === undefined) {
    deps.err(`--cases and --out are required\n${USAGE}`);
    return 2;
  }
  const version = args.options.get('--prompt') ?? 'v1';
  if (!isPromptVersion(version)) {
    deps.err(`--prompt must be one of ${PROMPT_VERSIONS.join(', ')}\n${USAGE}`);
    return 2;
  }
  let text: string;
  try {
    text = await deps.readFile(casesPath);
  } catch {
    deps.err(`cannot read ${casesPath}`);
    return 1;
  }
  const parsed = parseCases(text, casesPath.endsWith('.jsonl'));
  if (!parsed.ok) {
    deps.err(`${casesPath}: ${parsed.error}`);
    return 1;
  }
  const dir = outDir.replace(/\/+$/, '');
  let failed = 0;
  for (const evalCase of parsed.cases) {
    const rendered = renderCase(evalCase, version);
    if (!rendered.ok) {
      failed++;
      deps.err(`${evalCase.id}: ${rendered.error}`);
      continue;
    }
    await deps.writeFile(`${dir}/${evalCase.id}.txt`, providerView(rendered.input));
  }
  const done = parsed.cases.length - failed;
  deps.out(
    `rendered ${String(done)} of ${String(parsed.cases.length)} case(s) to ${dir} (prompt ${version})`,
  );
  return failed === 0 ? 0 : 1;
}
