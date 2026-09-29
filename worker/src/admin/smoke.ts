import { toBase64Url } from '../crypto/encoding';
import type { Environment } from '../env';
import type { Crypto } from '../ports/Crypto';
import { uuidV4 } from './genKeys';

/**
 * Post-deploy smoke checks (03 §14.2, 06 §8) for `scripts/smoke.ts` and
 * `tools/worker_smoke.sh`:
 *
 * 1. `GET /v1/health` → `200 { status: "ok", environment: <env> }`;
 * 2. `GET /v1/config` → `200` with an `ETag` and a numeric `version`;
 * 3. **staging (and dev) only**, when a debug attestation token is given:
 *    challenge → `POST /v1/installs` with `X-Taro-Debug-Attestation` (a fresh
 *    smoke install, `type: none`) → `GET /v1/balance` with the new token.
 *    The Worker honours the header only because its deploy env sets
 *    `ALLOW_DEBUG_ATTESTATION` (BE20, RC86); a header alone never does, and
 *    prod refuses to run this step.
 *
 * Phase 7/8 extend step 3 with a hold and one single-card reading. The
 * install secret and tokens never reach the report.
 */
export type SmokeFetch = (url: string, init?: RequestInit) => Promise<Response>;

export const API_HOSTS: Readonly<Record<Environment, string>> = {
  dev: 'http://localhost:8787',
  staging: 'https://api-staging.taro.vshyrochuk.com',
  prod: 'https://api.taro.vshyrochuk.com',
};

/** App headers the smoke client sends (03 §2.1); the version passes every min-version gate. */
export const SMOKE_HEADERS = {
  'X-Taro-Platform': 'ios',
  'X-Taro-App-Version': '999.0.0+1',
  'X-Taro-Locale': 'en',
} as const;

export interface SmokeOptions {
  readonly environment: Environment;
  readonly baseUrl: string;
  readonly fetch: SmokeFetch;
  readonly crypto: Crypto;
  /** `DEBUG_ATTESTATION_TOKEN` of the target env; enables the registration step (not in prod). */
  readonly debugAttestationToken?: string;
}

export interface SmokeStep {
  readonly name: string;
  readonly ok: boolean;
  readonly detail: string;
}

export interface SmokeReport {
  readonly ok: boolean;
  readonly steps: readonly SmokeStep[];
}

class StepFailure extends Error {
  override readonly name = 'StepFailure';
}

async function jsonOf(res: Response): Promise<Record<string, unknown>> {
  try {
    const body: unknown = await res.json();
    return typeof body === 'object' && body !== null ? (body as Record<string, unknown>) : {};
  } catch {
    return {};
  }
}

function errorCode(body: Record<string, unknown>): string {
  const error = body['error'];
  const code =
    typeof error === 'object' && error !== null ? (error as Record<string, unknown>)['code'] : '';
  return typeof code === 'string' && code !== '' ? ` ${code}` : '';
}

async function expectStatus(
  res: Response,
  status: number,
  what: string,
): Promise<Record<string, unknown>> {
  const body = await jsonOf(res);
  if (res.status !== status) {
    throw new StepFailure(`${what}: HTTP ${String(res.status)}${errorCode(body)}`);
  }
  return body;
}

/** Runs the smoke steps in order and stops at the first failure. */
export async function runSmoke(options: SmokeOptions): Promise<SmokeReport> {
  const base = options.baseUrl.replace(/\/+$/, '');
  const call = (path: string, init: RequestInit = {}) =>
    options.fetch(`${base}${path}`, {
      ...init,
      headers: { ...SMOKE_HEADERS, ...(init.headers as Record<string, string> | undefined) },
    });
  const steps: SmokeStep[] = [];
  const step = async (name: string, body: () => Promise<string>): Promise<boolean> => {
    try {
      steps.push({ name, ok: true, detail: await body() });
      return true;
    } catch (err) {
      const detail = err instanceof StepFailure ? err.message : `${name}: request failed`;
      steps.push({ name, ok: false, detail });
      return false;
    }
  };

  const healthy = await step('health', async () => {
    const body = await expectStatus(await call('/v1/health'), 200, 'health');
    if (body['status'] !== 'ok' || body['environment'] !== options.environment) {
      throw new StepFailure(
        `health: expected status ok in ${options.environment}, got ${JSON.stringify({ status: body['status'], environment: body['environment'] })}`,
      );
    }
    return `workerVersion ${String(body['workerVersion'])} (${options.environment})`;
  });
  if (!healthy) {
    return { ok: false, steps };
  }

  const configured = await step('config', async () => {
    const res = await call('/v1/config');
    const body = await expectStatus(res, 200, 'config');
    const etag = res.headers.get('ETag');
    if (typeof body['version'] !== 'number' || etag === null) {
      throw new StepFailure('config: missing version or ETag');
    }
    return `version ${String(body['version'])}, ETag ${etag}`;
  });
  if (!configured) {
    return { ok: false, steps };
  }

  const token = options.debugAttestationToken;
  if (token === undefined || token === '' || options.environment === 'prod') {
    steps.push({
      name: 'register',
      ok: true,
      detail:
        options.environment === 'prod'
          ? 'skipped: prod has no debug attestation (RC86)'
          : 'skipped: no DEBUG_ATTESTATION_TOKEN',
    });
    return { ok: true, steps };
  }

  let installToken = '';
  const registered = await step('register', async () => {
    const { challenge } = (await expectStatus(
      await call('/v1/attest/challenge', { method: 'POST' }),
      200,
      'challenge',
    )) as { challenge?: unknown };
    const res = await call('/v1/installs', {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'Idempotency-Key': uuidV4(options.crypto),
        'X-Taro-Debug-Attestation': token,
      },
      body: JSON.stringify({
        installId: uuidV4(options.crypto),
        installSecret: toBase64Url(options.crypto.randomBytes(32)),
        platform: SMOKE_HEADERS['X-Taro-Platform'],
        appVersion: SMOKE_HEADERS['X-Taro-App-Version'],
        locale: SMOKE_HEADERS['X-Taro-Locale'],
        timezone: 'UTC',
        attestation: { type: 'none', challenge: String(challenge), reason: 'unsupported' },
      }),
    });
    const body = await expectStatus(res, 201, 'register');
    installToken = String(body['installToken']);
    return `trust ${String(body['trust'])}`;
  });
  if (!registered) {
    return { ok: false, steps };
  }

  const balanced = await step('balance', async () => {
    const body = await expectStatus(
      await call('/v1/balance', { headers: { Authorization: `Bearer ${installToken}` } }),
      200,
      'balance',
    );
    return `canRead ${String(body['canRead'])}, ledgerVersion ${String(body['ledgerVersion'])}`;
  });
  return { ok: balanced, steps };
}
