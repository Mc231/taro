import {
  buildKvPayloads,
  ENVIRONMENTS,
  kvGetArgs,
  kvPutArgs,
  storedVersion,
  validateConfigText,
  versionIssue,
  type KvPayload,
  type KvTarget,
} from '../src/admin/configPush';
import { parseArgs, type CliDeps } from '../src/admin/cli';
import type { Environment } from '../src/env';

/**
 * `npm run config:push -- --env <dev|staging|prod> [--file <path>] [--dry-run] [--local] [--force]`
 *
 * Validates a remote-config file with the one schema (03 §8.1, RC8) and writes
 * `config:server`, then `config:public`, to `CONFIG_KV` with
 * `wrangler kv key put`. Without `--force` it refuses a version that is not
 * greater than the stored one. `--dry-run` validates and prints the commands
 * only; `--local` targets the local miniflare store of `wrangler dev`.
 * Exit codes: 0 ok, 1 invalid or failed, 2 usage.
 */
export const USAGE =
  'usage: config-push --env <dev|staging|prod> [--file <path>] [--dry-run] [--local] [--force]';
export const DEFAULT_FILE = 'config/remote_config.default.json';

function isEnvironment(value: string | undefined): value is Environment {
  return ENVIRONMENTS.includes(value as Environment);
}

function describe(payload: KvPayload): string {
  return `<${payload.key} v${String(payload.version)}, ${String(payload.value.length)} bytes>`;
}

export async function main(argv: readonly string[], deps: CliDeps): Promise<number> {
  const args = parseArgs(argv, {
    flags: ['--dry-run', '--local', '--force'],
    options: ['--env', '--file'],
  });
  if (!args.ok) {
    deps.err(`${args.error}\n${USAGE}`);
    return 2;
  }
  const env = args.options.get('--env');
  if (!isEnvironment(env)) {
    deps.err(`--env must be one of ${ENVIRONMENTS.join(', ')}\n${USAGE}`);
    return 2;
  }
  const file = args.options.get('--file') ?? DEFAULT_FILE;
  const target: KvTarget = args.flags.has('--local') ? 'local' : 'remote';

  let text: string;
  try {
    text = await deps.readFile(file);
  } catch (err) {
    deps.err(`cannot read ${file}: ${(err as Error).message}`);
    return 1;
  }
  const validation = validateConfigText(text);
  if (!validation.ok) {
    deps.err(`${file} is invalid:`);
    for (const issue of validation.issues) {
      deps.err(`  ${issue}`);
    }
    return 1;
  }
  const payloads = buildKvPayloads(validation.file);

  if (args.flags.has('--dry-run')) {
    for (const payload of payloads) {
      const command = kvPutArgs(payload, env, target).map((a) =>
        a === payload.value ? describe(payload) : a,
      );
      deps.out(`[dry-run] wrangler ${command.join(' ')}`);
    }
    deps.out(`${file} is valid; nothing written (--dry-run).`);
    return 0;
  }

  if (!args.flags.has('--force')) {
    const issues: string[] = [];
    for (const payload of payloads) {
      const current = await deps.run('npx', ['wrangler', ...kvGetArgs(payload.key, env, target)]);
      const issue = versionIssue(
        payload,
        current.code === 0 ? storedVersion(current.stdout) : null,
      );
      if (issue !== null) {
        issues.push(issue);
      }
    }
    if (issues.length > 0) {
      for (const issue of issues) {
        deps.err(issue);
      }
      deps.err('Raise "version" in both documents (or pass --force).');
      return 1;
    }
  }

  for (const payload of payloads) {
    const result = await deps.run('npx', ['wrangler', ...kvPutArgs(payload, env, target)]);
    if (result.code !== 0) {
      deps.err(`wrangler kv key put ${payload.key} failed (exit ${String(result.code)}):`);
      deps.err(result.stderr.trim());
      return 1;
    }
    deps.out(`pushed ${describe(payload)} to ${env} (${target})`);
  }
  return 0;
}
