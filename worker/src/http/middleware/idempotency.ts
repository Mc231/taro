import type { Context, MiddlewareHandler } from 'hono';
import { concatBytes, fromBase64, fromUtf8, toBase64, toHex, utf8 } from '../../crypto/encoding';
import type { Keyring } from '../../crypto/keyring';
import type { Deps } from '../../deps';
import {
  IdempotencyRepo,
  type ClaimInput,
  type IdempotencyKeyRef,
} from '../../repos/IdempotencyRepo';
import { canonicalJson } from '../canonicalJson';
import type { AppEnv } from '../context';
import { ApiError } from '../errors';

/**
 * `[idem]` middleware (03 §2.3; RC42, RC49, RC51, RC52, RC55).
 *
 * - Scope `(install_id, route, key)`; `requestHash = SHA-256(method ‖ path ‖ canonicalJSON(body))`.
 * - No row → `in_progress` row, run the handler.
 * - Only terminal outcomes are stored for replay: `2xx`, `400`, `422`. Every
 *   other status deletes the row, so a retry runs the handler again (RC49).
 * - `done` + same hash → byte-for-byte replay with `Idempotent-Replayed: true`.
 * - `in_progress` → `409 REQUEST_IN_PROGRESS` (`Retry-After: 3`); older than
 *   120 s → taken over (above the 55 s reading deadline, so never a live one).
 * - Hash mismatch → `422 IDEMPOTENCY_KEY_REUSED`.
 * - Bodies are AES-256-GCM encrypted with the `IDEMPOTENCY_ENC_KEY` keyring,
 *   AAD `install_id‖route‖key`; rows live 7 days.
 * - `deleteIdempotentBody` drops a body (reading ack, RC51). A `done` row
 *   without a readable body is passed through: the handler runs and its
 *   result is not stored; it must answer from its own state (RC52).
 */

export const IDEMPOTENCY_KEY_HEADER = 'Idempotency-Key';
export const REPLAYED_HEADER = 'Idempotent-Replayed';
export const IDEMPOTENCY_TTL_SEC = 7 * 24 * 3600;
export const TAKEOVER_AFTER_SEC = 120;
export const IN_PROGRESS_RETRY_AFTER_SEC = 3;
/** Scope for public routes that give no install ID (keys are fresh UUIDs, RC55). */
export const ANON_SCOPE = '-';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const SEALED_VERSION = 1;
const IV_BYTES = 12;

export interface IdempotencyOptions {
  /**
   * The install the key is scoped to. Defaults to `c.var.installId` (set by
   * auth); `POST /v1/installs` passes the body's `installId`.
   */
  readonly scope?: (c: Context<AppEnv>) => string | undefined | Promise<string | undefined>;
  /** Route label stored in the row; defaults to `"{METHOD} {path}"`. */
  readonly route?: string;
}

/** `2xx` and the deterministic client errors `400` / `422` (RC49). */
export function isTerminalStatus(status: number): boolean {
  return (status >= 200 && status < 300) || status === 400 || status === 422;
}

type Decision =
  | { readonly kind: 'owner' }
  | { readonly kind: 'replay'; readonly status: number; readonly blob: Uint8Array }
  | { readonly kind: 'passthrough' }
  | { readonly kind: 'in_progress' }
  | { readonly kind: 'reused' };

export function idempotency(
  deps: Deps,
  options: IdempotencyOptions = {},
): MiddlewareHandler<AppEnv> {
  const repo = new IdempotencyRepo(deps.db);
  return async (c, next) => {
    const key = c.req.header(IDEMPOTENCY_KEY_HEADER)?.trim();
    if (key === undefined || key === '') {
      throw new ApiError('IDEMPOTENCY_KEY_REQUIRED');
    }
    if (!UUID.test(key)) {
      throw new ApiError('VALIDATION_FAILED', {
        details: {
          issues: [{ path: IDEMPOTENCY_KEY_HEADER, code: 'invalid_header', message: 'not a UUID' }],
        },
      });
    }
    // Resolve the keyring before the handler runs: a missing secret must not
    // leave a handler's side effects behind an unfinishable row.
    const keyring = deps.keys.idempotency();
    const installId = (await options.scope?.(c)) ?? c.get('installId') ?? ANON_SCOPE;
    const route = options.route ?? `${c.req.method} ${c.req.path}`;
    const requestHash = await hashRequest(deps, c.req.method, c.req.path, await c.req.text());
    const now = deps.clock.now();
    const claim: ClaimInput = {
      installId,
      route,
      key,
      requestHash,
      createdAt: now.toISOString(),
      expiresAt: new Date(now.getTime() + IDEMPOTENCY_TTL_SEC * 1000).toISOString(),
    };

    c.set('idempotency', { installId, route, key });
    const decision = await acquire(deps, repo, claim, now);
    switch (decision.kind) {
      case 'in_progress':
        throw new ApiError('REQUEST_IN_PROGRESS', { retryAfterSec: IN_PROGRESS_RETRY_AFTER_SEC });
      case 'reused':
        throw new ApiError('IDEMPOTENCY_KEY_REUSED');
      case 'replay': {
        const replayed = await openReplay(deps, keyring, claim, decision.status, decision.blob);
        if (replayed !== undefined) {
          return replayed;
        }
        await next();
        return undefined;
      }
      case 'passthrough':
        await next();
        return undefined;
      case 'owner':
        break;
    }

    await next();
    const status = c.res.status;
    if (isTerminalStatus(status)) {
      const body = new Uint8Array(await c.res.clone().arrayBuffer());
      const sealed = await seal(deps, keyring, claim, {
        contentType: c.res.headers.get('content-type'),
        body,
      });
      if (!(await repo.complete(claim, status, sealed))) {
        deps.logger.log('warn', 'idempotency_ownership_lost', { route });
      }
    } else if (!(await repo.release(claim))) {
      deps.logger.log('warn', 'idempotency_ownership_lost', { route });
    }
    return undefined;
  };
}

/** Deletes the stored replay body of a completed request (reading ack, RC51). */
export function deleteIdempotentBody(deps: Deps, ref: IdempotencyKeyRef): Promise<boolean> {
  return new IdempotencyRepo(deps.db).deleteBody(ref);
}

async function hashRequest(
  deps: Deps,
  method: string,
  path: string,
  body: string,
): Promise<string> {
  return toHex(await deps.crypto.sha256(`${method}\n${path}\n${canonicalJson(body)}`));
}

async function acquire(
  deps: Deps,
  repo: IdempotencyRepo,
  claim: ClaimInput,
  now: Date,
): Promise<Decision> {
  if (await repo.insert(claim)) {
    return { kind: 'owner' };
  }
  const row = await repo.find(claim);
  if (row === null) {
    // Released between our insert and read: one more attempt, else report busy.
    return (await repo.insert(claim)) ? { kind: 'owner' } : { kind: 'in_progress' };
  }
  if (row.expiresAt <= claim.createdAt) {
    return (await repo.reclaim(row, claim)) ? { kind: 'owner' } : { kind: 'in_progress' };
  }
  if (row.requestHash !== claim.requestHash) {
    return { kind: 'reused' };
  }
  if (row.state === 'done') {
    return row.responseBodyEnc === null || row.responseStatus === null
      ? { kind: 'passthrough' }
      : { kind: 'replay', status: row.responseStatus, blob: row.responseBodyEnc };
  }
  const ageMs = now.getTime() - Date.parse(row.createdAt);
  if (ageMs >= TAKEOVER_AFTER_SEC * 1000 && (await repo.reclaim(row, claim))) {
    deps.logger.log('warn', 'idempotency_takeover', { route: claim.route, ageMs });
    return { kind: 'owner' };
  }
  return { kind: 'in_progress' };
}

interface StoredResponse {
  readonly contentType: string | null;
  readonly body: Uint8Array;
}

function aadFor(ref: IdempotencyKeyRef): Uint8Array {
  return utf8(`${ref.installId}‖${ref.route}‖${ref.key}`);
}

/** Blob layout: `version(1) ‖ kidLen(1) ‖ kid ‖ iv(12) ‖ ciphertext+tag`. */
async function seal(
  deps: Deps,
  keyring: Keyring,
  ref: IdempotencyKeyRef,
  response: StoredResponse,
): Promise<Uint8Array> {
  const plaintext = utf8(JSON.stringify({ t: response.contentType, b: toBase64(response.body) }));
  const { kid, key } = keyring.current;
  const sealed = await deps.crypto.aesGcmEncrypt(key, plaintext, aadFor(ref));
  const kidBytes = utf8(kid);
  return concatBytes(
    Uint8Array.of(SEALED_VERSION, kidBytes.length),
    kidBytes,
    sealed.iv,
    sealed.ciphertext,
  );
}

async function unseal(
  deps: Deps,
  keyring: Keyring,
  ref: IdempotencyKeyRef,
  blob: Uint8Array,
): Promise<StoredResponse | undefined> {
  if (blob[0] !== SEALED_VERSION || blob.length < 2) {
    return undefined;
  }
  const kidLength = blob[1] ?? 0;
  const kid = fromUtf8(blob.subarray(2, 2 + kidLength));
  const entry = keyring.get(kid);
  if (entry === undefined) {
    return undefined;
  }
  const ivStart = 2 + kidLength;
  try {
    const plaintext = await deps.crypto.aesGcmDecrypt(
      entry.key,
      {
        iv: blob.subarray(ivStart, ivStart + IV_BYTES),
        ciphertext: blob.subarray(ivStart + IV_BYTES),
      },
      aadFor(ref),
    );
    const parsed = JSON.parse(fromUtf8(plaintext)) as { t: string | null; b: string };
    return { contentType: parsed.t, body: fromBase64(parsed.b) };
  } catch {
    return undefined;
  }
}

async function openReplay(
  deps: Deps,
  keyring: Keyring,
  ref: IdempotencyKeyRef,
  status: number,
  blob: Uint8Array,
): Promise<Response | undefined> {
  const stored = await unseal(deps, keyring, ref, blob);
  if (stored === undefined) {
    deps.logger.log('warn', 'idempotency_body_unreadable', { route: ref.route });
    return undefined;
  }
  const headers = new Headers({ [REPLAYED_HEADER]: 'true' });
  if (stored.contentType !== null) {
    headers.set('content-type', stored.contentType);
  }
  const empty = status === 204 || status === 205;
  return new Response(empty ? null : stored.body, { status, headers });
}
