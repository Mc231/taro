import { OPENAPI_PATH, renderOpenApi } from '../src/admin/openapi';
import { parseArgs, type CliDeps } from '../src/admin/cli';

/**
 * `npm run openapi [-- --check]`
 *
 * Writes `openapi/openapi.json` from the zod route definitions (03 BE1,
 * §14.2), or with `--check` fails when the committed file is stale. The
 * `test/contract/openapi.test.ts` test runs the same comparison in CI.
 * Exit codes: 0 ok, 1 stale, 2 usage.
 */
export const USAGE = 'usage: export-openapi [--check]';

export async function main(argv: readonly string[], deps: CliDeps): Promise<number> {
  const args = parseArgs(argv, { flags: ['--check'], options: [] });
  if (!args.ok) {
    deps.err(`${args.error}\n${USAGE}`);
    return 2;
  }
  const expected = renderOpenApi();
  if (args.flags.has('--check')) {
    let current = '';
    try {
      current = await deps.readFile(OPENAPI_PATH);
    } catch {
      // A missing file is stale.
    }
    if (current !== expected) {
      deps.err(`${OPENAPI_PATH} is stale; run npm run openapi`);
      return 1;
    }
    deps.out(`${OPENAPI_PATH} is up to date`);
    return 0;
  }
  await deps.writeFile(OPENAPI_PATH, expected);
  deps.out(`wrote ${OPENAPI_PATH}`);
  return 0;
}
