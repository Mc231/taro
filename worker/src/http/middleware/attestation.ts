import type { Context, MiddlewareHandler } from 'hono';
import { fromBase64, toBase64Url, utf8 } from '../../crypto/encoding';
import { resolveAllowedAppIds } from '../../domain/appIds';
import { callClientDataHash } from '../../domain/challenge';
import type { Trust } from '../../domain/types';
import type { Deps } from '../../deps';
import type { AttestRejected } from '../../ports/AppAttestVerifier';
import { InstallRepo, type InstallRow } from '../../repos/InstallRepo';
import type { AppEnv } from '../context';
import { ApiError } from '../errors';
import { IDEMPOTENCY_KEY_HEADER } from './idempotency';

/**
 * `[attest]` middleware (03 §3.4, RC11): applied to exactly
 * `POST /v1/installs/token`, `POST /v1/readings/holds`, `POST /v1/readings`
 * and `POST /v1/rewards/intents`, after `auth`.
 *
 * `X-Taro-Attestation`:
 * - `aa1.<base64 assertion>` (iOS): App Attest assertion by the stored key
 *   over `clientDataHash = SHA256(method ‖ path ‖ SHA256(body) ‖ Idempotency-Key)`;
 *   the counter must exceed the stored one and is advanced (compare-and-set);
 * - `pi1.<standard integrity token>` (Android): Standard API token whose
 *   `requestHash` is `base64url` of the same hash (RC87);
 * - `none`: low-trust installs; the request runs with low trust.
 *
 * Outcomes: a verified header keeps the install's trust (Play Integrity
 * without device integrity → low); a hard failure → `403 ATTESTATION_FAILED`;
 * a Google/Apple outage → low trust. A missing or malformed header, or
 * `none` from a high-trust install, is `401 ATTESTATION_REQUIRED` while
 * `attest.requiredOnReadings` is on, and a low-trust downgrade when it is
 * off (the Play Integrity outage switch).
 *
 * `X-Taro-Debug-Attestation` with `DEBUG_ATTESTATION_TOKEN` passes as
 * verified only where the deploy env sets `ALLOW_DEBUG_ATTESTATION` (RC86).
 *
 * Sets `c.var.requestTrust`.
 */
export const ATTESTATION_HEADER = 'X-Taro-Attestation';
export const DEBUG_ATTESTATION_HEADER = 'X-Taro-Debug-Attestation';

type Parsed =
  | { readonly kind: 'none' }
  | { readonly kind: 'aa1'; readonly assertion: Uint8Array }
  | { readonly kind: 'pi1'; readonly token: string }
  | { readonly kind: 'missing' };

const TOKEN_CHARS = /^[A-Za-z0-9_\-.+/=]+$/;

export function parseAttestationHeader(value: string | undefined): Parsed {
  const header = value?.trim() ?? '';
  if (header === 'none') {
    return { kind: 'none' };
  }
  const payload = header.slice(4);
  if (payload === '' || !TOKEN_CHARS.test(payload)) {
    return { kind: 'missing' };
  }
  if (header.startsWith('aa1.')) {
    try {
      return { kind: 'aa1', assertion: fromBase64(payload) };
    } catch {
      return { kind: 'missing' };
    }
  }
  return header.startsWith('pi1.') ? { kind: 'pi1', token: payload } : { kind: 'missing' };
}

/**
 * True when the request carries the debug token and the deploy env allows
 * it (`deps.debugAttestationToken` is undefined otherwise). Constant-time.
 */
export function isDebugAttestation(deps: Deps, header: string | undefined): boolean {
  const expected = deps.debugAttestationToken;
  if (expected === undefined || header === undefined) {
    return false;
  }
  return deps.crypto.timingSafeEqual(utf8(header.trim()), utf8(expected));
}

export function attestation(deps: Deps): MiddlewareHandler<AppEnv> {
  const repo = new InstallRepo(deps.db);
  return async (c, next) => {
    const install = c.get('install');
    if (install === undefined) {
      throw new ApiError('UNAUTHENTICATED');
    }
    c.set('requestTrust', await callTrust(deps, repo, c, install));
    await next();
  };
}

async function callTrust(
  deps: Deps,
  repo: InstallRepo,
  c: Context<AppEnv>,
  install: InstallRow,
): Promise<Trust> {
  if (isDebugAttestation(deps, c.req.header(DEBUG_ATTESTATION_HEADER))) {
    deps.logger.log('warn', 'debug_attestation_used', { route: `${c.req.method} ${c.req.path}` });
    return install.trust;
  }
  const parsed = parseAttestationHeader(c.req.header(ATTESTATION_HEADER));
  const config = await deps.config.snapshot();
  if (parsed.kind === 'missing' || parsed.kind === 'none') {
    if (parsed.kind === 'none' && install.trust === 'low') {
      return 'low';
    }
    if (config['attest.requiredOnReadings']) {
      throw new ApiError('ATTESTATION_REQUIRED');
    }
    return 'low';
  }

  const clientDataHash = await callClientDataHash(deps.crypto, {
    method: c.req.method,
    path: c.req.path,
    body: new Uint8Array(await c.req.arrayBuffer()),
    idempotencyKey: c.req.header(IDEMPOTENCY_KEY_HEADER)?.trim(),
  });
  const allowedAppIds = resolveAllowedAppIds(config['attest.allowedAppIds'], deps.appleTeamId);

  if (parsed.kind === 'aa1') {
    if (install.platform !== 'ios' || install.attestPublicKey === null) {
      return fail(deps, install, 'no_key');
    }
    const result = await deps.appAttest.verifyAssertion({
      assertion: parsed.assertion,
      clientDataHash,
      publicKey: install.attestPublicKey,
      previousCounter: install.attestCounter ?? 0,
      allowedAppIds,
    });
    if (!result.ok) {
      return rejected(deps, install, result);
    }
    if (!(await repo.advanceAttestCounter(install.id, result.counter))) {
      return fail(deps, install, 'counter_race');
    }
    return install.trust;
  }

  if (install.platform !== 'android') {
    return fail(deps, install, 'platform');
  }
  const result = await deps.playIntegrity.verify({
    token: parsed.token,
    expectedRequestHash: toBase64Url(clientDataHash),
    allowedPackageNames: allowedAppIds,
  });
  if (!result.ok) {
    return rejected(deps, install, result);
  }
  const genuine =
    result.deviceVerdict === 'device' && (result.appRecognized || deps.environment !== 'prod');
  return genuine ? install.trust : 'low';
}

/** `unavailable` (an outage) degrades to low trust (BE4); `invalid` is a hard failure. */
function rejected(deps: Deps, install: InstallRow, result: AttestRejected): Trust {
  if (result.reason === 'unavailable') {
    deps.metrics.write({
      event: 'attest_failed',
      platform: install.platform,
      code: 'unavailable',
    });
    return 'low';
  }
  return fail(deps, install, result.detail ?? 'invalid');
}

function fail(deps: Deps, install: InstallRow, detail: string): never {
  deps.metrics.write({ event: 'attest_failed', platform: install.platform, code: detail });
  throw new ApiError('ATTESTATION_FAILED');
}
