import { SystemClock } from '../src/adapters/cf/SystemClock';
import { WebCrypto } from '../src/adapters/cf/WebCrypto';
import { parseArgs, type CliDeps } from '../src/admin/cli';
import {
  generateSecrets,
  GenKeysError,
  isGeneratedSecret,
  kidFor,
  ROTATABLE,
  type GeneratedSecret,
  type GenerateOptions,
} from '../src/admin/genKeys';
import type { Environment } from '../src/env';
import type { Clock } from '../src/ports/Clock';
import type { Crypto } from '../src/ports/Crypto';

/**
 * `npm run gen-keys -- --env <dev|staging|prod> [--only NAME[,NAME…]] [--kid <kid>] [--rotate <file>]`
 *
 * Prints fresh Worker secrets (Sprint 6.0, 03 §11) as one JSON object
 * `{ "NAME": "value", … }` on **stdout only**; nothing secret goes to stderr.
 * Pipe it into the GPG bundle or `wrangler secret put`, never into a file in
 * the repo (docs/runbooks/SECRET_ROTATION.md).
 *
 * `--rotate <file>` reads the current values (a JSON object of the same
 * shape) and prepends a new key to `TOKEN_SIGNING_KEYS` and
 * `IDEMPOTENCY_ENC_KEY`, keeping the previous current key second. With
 * `--rotate`, only those two are generated unless `--only` says otherwise.
 * `--env prod` never emits `DEBUG_ATTESTATION_TOKEN` (RC86).
 * Exit codes: 0 ok, 1 failed, 2 usage.
 */
export const USAGE =
  'usage: gen-keys --env <dev|staging|prod> [--only NAME[,NAME...]] [--kid <kid>] [--rotate <file>]';

const ENVIRONMENTS: readonly Environment[] = ['dev', 'staging', 'prod'];
const KID = /^[A-Za-z0-9_-]{1,32}$/;

function parseOnly(raw: string | undefined): GeneratedSecret[] | string | undefined {
  if (raw === undefined) {
    return undefined;
  }
  const names = raw.split(',').map((n) => n.trim());
  const unknown = names.filter((n) => !isGeneratedSecret(n));
  return unknown.length > 0 ? `unknown secret ${unknown.join(', ')}` : (names as GeneratedSecret[]);
}

async function readPrevious(
  deps: CliDeps,
  path: string,
): Promise<Partial<Record<GeneratedSecret, string>>> {
  let parsed: unknown;
  try {
    parsed = JSON.parse(await deps.readFile(path));
  } catch {
    throw new GenKeysError(`--rotate ${path} is not a readable JSON object`);
  }
  if (typeof parsed !== 'object' || parsed === null || Array.isArray(parsed)) {
    throw new GenKeysError(`--rotate ${path} is not a readable JSON object`);
  }
  const previous: Partial<Record<GeneratedSecret, string>> = {};
  for (const name of ROTATABLE) {
    const value = (parsed as Record<string, unknown>)[name];
    if (typeof value === 'string') {
      previous[name] = value;
    }
  }
  return previous;
}

export async function main(
  argv: readonly string[],
  deps: CliDeps,
  crypto: Crypto = new WebCrypto(),
  clock: Clock = new SystemClock(),
  ed25519?: GenerateOptions['ed25519'],
): Promise<number> {
  const args = parseArgs(argv, { flags: [], options: ['--env', '--only', '--kid', '--rotate'] });
  if (!args.ok) {
    deps.err(`${args.error}\n${USAGE}`);
    return 2;
  }
  const environment = args.options.get('--env');
  if (!ENVIRONMENTS.includes(environment as Environment)) {
    deps.err(`--env must be one of ${ENVIRONMENTS.join(', ')}\n${USAGE}`);
    return 2;
  }
  const only = parseOnly(args.options.get('--only'));
  if (typeof only === 'string') {
    deps.err(`${only}\n${USAGE}`);
    return 2;
  }
  const kid = args.options.get('--kid') ?? kidFor(clock.now());
  if (!KID.test(kid)) {
    deps.err(`--kid must match ${KID.source}\n${USAGE}`);
    return 2;
  }
  const rotate = args.options.get('--rotate');
  try {
    const previous = rotate === undefined ? undefined : await readPrevious(deps, rotate);
    const secrets = await generateSecrets({
      environment: environment as Environment,
      kid,
      crypto,
      ...(only !== undefined ? { only } : rotate !== undefined ? { only: ROTATABLE } : {}),
      ...(previous !== undefined ? { previous } : {}),
      ...(ed25519 !== undefined ? { ed25519 } : {}),
    });
    deps.out(JSON.stringify(secrets, null, 2));
    return 0;
  } catch (err) {
    deps.err(err instanceof GenKeysError ? err.message : 'gen-keys failed');
    return 1;
  }
}
