import type { MiddlewareHandler } from 'hono';
import { buildApp, type App } from '../../src/app';
import type { AppEnv } from '../../src/http/context';
import { DEBUG_ATTESTATION_HEADER } from '../../src/http/middleware/attestation';
import { InstallRepo } from '../../src/repos/InstallRepo';
import { SeqIdGenerator } from '../fakes/SeqIdGenerator';
import {
  createHarness,
  TEST_DEBUG_ATTESTATION_TOKEN,
  uniqueId,
  type HarnessOptions,
  type TestHarness,
} from '../fakes/testDeps';
import { APP_HEADERS } from './app';
import { db } from './db';

/**
 * Route-test helpers for the AI reading routes (03 §9.0, §9.1): an auth shim
 * that trusts `X-Test-Install` and loads the install row (the `[attest]`
 * middleware needs it), the debug attestation header, consent, and a
 * `request.cf.country` stand-in.
 */
export const readingAuth: MiddlewareHandler<AppEnv> = async (c, next) => {
  const id = c.req.header('X-Test-Install');
  if (id !== undefined) {
    c.set('installId', id);
    const install = await new InstallRepo(db).findById(id);
    if (install !== null) {
      c.set('install', install);
    }
  }
  await next();
};

/** Server IDs unique across the harnesses of one file (shared D1). */
export class UniqueIds extends SeqIdGenerator {
  override uuidV7(): string {
    return uniqueId('7ead');
  }
}

export interface ReadingHarness extends TestHarness {
  readonly app: App;
}

export function readingHarness(options: HarnessOptions = {}): ReadingHarness {
  const h = createHarness({
    debugAttestation: true,
    ...options,
    overrides: { ids: new UniqueIds(), ...options.overrides },
  });
  return { ...h, app: buildApp(h.deps, { auth: readingAuth }) };
}

export interface CallOptions {
  readonly headers?: Record<string, string | undefined>;
  readonly country?: string;
  readonly key?: string;
}

function headersFor(installId: string, key: string, extra: CallOptions['headers'] = {}) {
  const headers: Record<string, string> = {
    ...APP_HEADERS,
    'content-type': 'application/json',
    'X-Test-Install': installId,
    'Idempotency-Key': key,
    [DEBUG_ATTESTATION_HEADER]: TEST_DEBUG_ATTESTATION_TOKEN,
    'X-Taro-AI-Consent': '2',
  };
  for (const [name, value] of Object.entries(extra)) {
    if (value === undefined) {
      // eslint-disable-next-line @typescript-eslint/no-dynamic-delete
      delete headers[name];
    } else {
      headers[name] = value;
    }
  }
  return headers;
}

/** A request carrying `request.cf.country` like Cloudflare sets it. */
export function withCountry(request: Request, country: string | undefined): Request {
  if (country !== undefined) {
    Object.defineProperty(request, 'cf', { value: { country } });
  }
  return request;
}

export const SINGLE_CARD = [{ positionId: 'focus', cardId: 'major_17', reversed: false }] as const;
export const THREE_CARDS = [
  { positionId: 'past', cardId: 'major_16', reversed: false },
  { positionId: 'present', cardId: 'cups_03', reversed: true },
  { positionId: 'future', cardId: 'pentacles_14', reversed: false },
] as const;

export function holdBody(clientReadingId: string, extra: Record<string, unknown> = {}) {
  return { clientReadingId, spread: { id: 'single', version: 1 }, locale: 'en', ...extra };
}

export function readingBody(clientReadingId: string, extra: Record<string, unknown> = {}) {
  return {
    clientReadingId,
    spread: { id: 'single', version: 1 },
    cards: SINGLE_CARD,
    question: 'How can I approach the change at work?',
    locale: 'en',
    drawnAt: '2026-09-26T09:59:00Z',
    ...extra,
  };
}

export async function postHold(
  h: ReadingHarness,
  installId: string,
  clientReadingId: string,
  body: Record<string, unknown> = holdBody(clientReadingId),
  options: CallOptions = {},
): Promise<Response> {
  return await h.app.request(
    withCountry(
      new Request('http://worker.test/v1/readings/holds', {
        method: 'POST',
        headers: headersFor(installId, options.key ?? clientReadingId, options.headers),
        body: JSON.stringify(body),
      }),
      options.country,
    ),
  );
}

export async function postReading(
  h: ReadingHarness,
  installId: string,
  clientReadingId: string,
  body: Record<string, unknown> = readingBody(clientReadingId),
  options: CallOptions = {},
): Promise<Response> {
  return await h.app.request(
    withCountry(
      new Request('http://worker.test/v1/readings', {
        method: 'POST',
        headers: headersFor(installId, options.key ?? clientReadingId, options.headers),
        body: JSON.stringify(body),
      }),
      options.country,
    ),
  );
}

export async function getReading(
  h: ReadingHarness,
  installId: string,
  clientReadingId: string,
  country?: string,
): Promise<Response> {
  return await h.app.request(
    withCountry(
      new Request(`http://worker.test/v1/readings/${clientReadingId}`, {
        headers: { ...APP_HEADERS, 'X-Test-Install': installId },
      }),
      country,
    ),
  );
}

export async function ackReading(
  h: ReadingHarness,
  installId: string,
  clientReadingId: string,
): Promise<Response> {
  return await h.app.request(`/v1/readings/${clientReadingId}/ack`, {
    method: 'POST',
    headers: { ...APP_HEADERS, 'X-Test-Install': installId },
  });
}

/** A fresh client reading ID (UUID-shaped, unique in the file). */
export function crid(): string {
  return uniqueId('c1d0');
}
