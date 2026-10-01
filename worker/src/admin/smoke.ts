import { toBase64Url } from '../crypto/encoding';
import { SystemClock } from '../adapters/cf/SystemClock';
import type { Environment } from '../env';
import type { Clock } from '../ports/Clock';
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
 * 4. then one real single-card reading (03 §9.0, §9.1; RC42, RC49–RC51):
 *    `POST /v1/readings/holds` → `POST /v1/readings` (both with
 *    `Idempotency-Key == clientReadingId`, the debug attestation header and
 *    `X-Taro-AI-Consent` = the config's `ai.consentVersion`) → expect `200
 *    completed` → `POST /v1/readings/{id}/ack` → `204`. A declined reading,
 *    `402` or `503` (e.g. `AI_UNAVAILABLE`) fails the run. The model is not on
 *    the wire; the report gives `promptVersion` and the client-side latency.
 *
 * The install secret, tokens and the debug token never reach the report.
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
  /** Measures the reading latency and stamps `drawnAt`; defaults to the system clock. */
  readonly clock?: Clock;
}

/** The smoke reading (one card, a benign English question; 03 §9.1). */
export const SMOKE_READING = {
  spread: { id: 'single', version: 1 },
  cards: [{ positionId: 'focus', cardId: 'major_00', reversed: false }],
  question: 'What should I focus on this week?',
  locale: 'en',
} as const;

const SNIPPET_CHARS = 80;

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

function record(value: unknown): Record<string, unknown> {
  return typeof value === 'object' && value !== null ? (value as Record<string, unknown>) : {};
}

/** ` CODE` plus `(reason|tier …)` from `error.details` when present. */
function errorCode(body: Record<string, unknown>): string {
  const error = record(body['error']);
  const code = error['code'];
  if (typeof code !== 'string' || code === '') {
    return '';
  }
  const details = record(error['details']);
  const extra = ['reason', 'tier']
    .filter((key) => typeof details[key] === 'string')
    .map((key) => `${key} ${String(details[key])}`);
  return extra.length === 0 ? ` ${code}` : ` ${code} (${extra.join(', ')})`;
}

function balanceSummary(value: unknown): string {
  const balance = record(value);
  const free = record(balance['free']);
  return `free ${String(free['remaining'])}/${String(free['limit'])}, bonus ${String(balance['bonus'])}, paid ${String(balance['paid'])}`;
}

function snippet(text: unknown): string {
  const flat = String(text).replace(/\s+/g, ' ').trim();
  return JSON.stringify(flat.length > SNIPPET_CHARS ? `${flat.slice(0, SNIPPET_CHARS)}…` : flat);
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

  let configBody: Record<string, unknown> = {};
  const configured = await step('config', async () => {
    const res = await call('/v1/config');
    const body = await expectStatus(res, 200, 'config');
    configBody = body;
    const etag = res.headers.get('ETag');
    if (typeof body['version'] !== 'number' || etag === null) {
      throw new StepFailure('config: missing version or ETag');
    }
    return `version ${String(body['version'])}, ETag ${etag}`;
  });
  if (!configured) {
    return { ok: false, steps };
  }
  const consentVersion = configBody['ai.consentVersion'];

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

  const authorization = { Authorization: `Bearer ${installToken}` };
  const balanced = await step('balance', async () => {
    const body = await expectStatus(
      await call('/v1/balance', { headers: authorization }),
      200,
      'balance',
    );
    return `canRead ${String(body['canRead'])}, ledgerVersion ${String(body['ledgerVersion'])}`;
  });
  if (!balanced) {
    return { ok: false, steps };
  }

  const clock = options.clock ?? new SystemClock();
  const clientReadingId = uuidV4(options.crypto);
  const readingHeaders = {
    ...authorization,
    'content-type': 'application/json',
    'Idempotency-Key': clientReadingId,
    'X-Taro-Debug-Attestation': token,
    'X-Taro-AI-Consent': String(consentVersion),
  };

  const held = await step('hold', async () => {
    if (typeof consentVersion !== 'number') {
      throw new StepFailure('hold: config has no numeric ai.consentVersion');
    }
    const body = await expectStatus(
      await call('/v1/readings/holds', {
        method: 'POST',
        headers: readingHeaders,
        body: JSON.stringify({
          clientReadingId,
          spread: SMOKE_READING.spread,
          locale: SMOKE_READING.locale,
        }),
      }),
      201,
      'hold',
    );
    return `chargeSource ${String(body['chargeSource'])}, expiresAt ${String(body['expiresAt'])}`;
  });
  if (!held) {
    return { ok: false, steps };
  }

  const read = await step('reading', async () => {
    const started = clock.now();
    const res = await call('/v1/readings', {
      method: 'POST',
      headers: readingHeaders,
      body: JSON.stringify({
        clientReadingId,
        spread: SMOKE_READING.spread,
        cards: SMOKE_READING.cards,
        question: SMOKE_READING.question,
        locale: SMOKE_READING.locale,
        drawnAt: started.toISOString(),
      }),
    });
    const latencyMs = clock.now().getTime() - started.getTime();
    const body = await expectStatus(res, 200, 'reading');
    const head = `status ${String(body['status'])}, ${String(latencyMs)} ms`;
    if (body['status'] === 'declined') {
      const safety = record(body['safety']);
      throw new StepFailure(
        `reading: ${head}, classification ${String(safety['category'])} (declined, not charged), balance ${balanceSummary(body['balance'])}`,
      );
    }
    if (body['status'] !== 'completed') {
      throw new StepFailure(`reading: unexpected ${head}`);
    }
    return [
      head,
      'classification none',
      `chargeSource ${String(body['chargeSource'])}`,
      `promptVersion ${String(body['promptVersion'])}`,
      `balance ${balanceSummary(body['balance'])}`,
      `text ${snippet(record(body['reading'])['overview'])}`,
    ].join(', ');
  });
  if (!read) {
    return { ok: false, steps };
  }

  const acked = await step('ack', async () => {
    const res = await call(`/v1/readings/${clientReadingId}/ack`, {
      method: 'POST',
      headers: authorization,
    });
    await expectStatus(res, 204, 'ack');
    return 'HTTP 204';
  });
  return { ok: acked, steps };
}
