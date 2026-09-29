import { WebCrypto } from '../src/adapters/cf/WebCrypto';
import { parseArgs, type CliDeps } from '../src/admin/cli';
import { API_HOSTS, runSmoke, type SmokeFetch } from '../src/admin/smoke';
import type { Environment } from '../src/env';
import type { Crypto } from '../src/ports/Crypto';

/**
 * `npm run smoke -- --env <dev|staging|prod> [--base-url <url>]`
 * (called by `tools/worker_smoke.sh` and `.gitea/workflows/worker-deploy.yml`)
 *
 * Runs `src/admin/smoke.ts` against the deployed Worker: health and config
 * everywhere; on dev/staging also a debug-attested registration and a balance
 * read when `DEBUG_ATTESTATION_TOKEN` is set in the environment (never passed
 * on the command line; ignored for prod, RC86). One line per step on stdout.
 * Exit codes: 0 ok, 1 a step failed, 2 usage.
 */
export const USAGE = 'usage: smoke --env <dev|staging|prod> [--base-url <url>]';

const ENVIRONMENTS: readonly Environment[] = ['dev', 'staging', 'prod'];

export async function main(
  argv: readonly string[],
  deps: CliDeps,
  fetchFn: SmokeFetch = (url, init) => fetch(url, init),
  crypto: Crypto = new WebCrypto(),
): Promise<number> {
  const args = parseArgs(argv, { flags: [], options: ['--env', '--base-url'] });
  if (!args.ok) {
    deps.err(`${args.error}\n${USAGE}`);
    return 2;
  }
  const environment = args.options.get('--env') as Environment | undefined;
  if (environment === undefined || !ENVIRONMENTS.includes(environment)) {
    deps.err(`--env must be one of ${ENVIRONMENTS.join(', ')}\n${USAGE}`);
    return 2;
  }
  const baseUrl = args.options.get('--base-url') ?? API_HOSTS[environment];
  if (!/^https?:\/\/[^\s/]+/.test(baseUrl)) {
    deps.err(`--base-url must be an http(s) URL\n${USAGE}`);
    return 2;
  }
  const token = deps.env?.['DEBUG_ATTESTATION_TOKEN']?.trim();
  const report = await runSmoke({
    environment,
    baseUrl,
    fetch: fetchFn,
    crypto,
    ...(token !== undefined && token !== '' ? { debugAttestationToken: token } : {}),
  });
  deps.out(`smoke ${environment} ${baseUrl}`);
  for (const step of report.steps) {
    const line = `${step.ok ? 'ok  ' : 'FAIL'} ${step.name}: ${step.detail}`;
    if (step.ok) {
      deps.out(line);
    } else {
      deps.err(line);
    }
  }
  return report.ok ? 0 : 1;
}
