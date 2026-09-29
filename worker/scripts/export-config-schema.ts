import {
  CONFIG_JSON_SCHEMA_PATH,
  renderRemoteConfigJsonSchema,
} from '../src/admin/configSchemaExport';
import { parseArgs, type CliDeps } from '../src/admin/cli';

/**
 * `npm run config:schema [-- --check]`
 *
 * Writes `config/remote_config.schema.json` from the zod schema (03 §8.1), or
 * with `--check` fails when the committed file is stale. The
 * `config/schema-export` test runs the same comparison in CI.
 * Exit codes: 0 ok, 1 stale, 2 usage.
 */
export const USAGE = 'usage: export-config-schema [--check]';

export async function main(argv: readonly string[], deps: CliDeps): Promise<number> {
  const args = parseArgs(argv, { flags: ['--check'], options: [] });
  if (!args.ok) {
    deps.err(`${args.error}\n${USAGE}`);
    return 2;
  }
  const expected = renderRemoteConfigJsonSchema();
  if (args.flags.has('--check')) {
    let current = '';
    try {
      current = await deps.readFile(CONFIG_JSON_SCHEMA_PATH);
    } catch {
      // A missing file is stale.
    }
    if (current !== expected) {
      deps.err(`${CONFIG_JSON_SCHEMA_PATH} is stale; run npm run config:schema`);
      return 1;
    }
    deps.out(`${CONFIG_JSON_SCHEMA_PATH} is up to date`);
    return 0;
  }
  await deps.writeFile(CONFIG_JSON_SCHEMA_PATH, expected);
  deps.out(`wrote ${CONFIG_JSON_SCHEMA_PATH}`);
  return 0;
}
