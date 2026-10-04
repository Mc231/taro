import { describe, expect, it } from 'vitest';
import { WebCrypto } from '../../../src/adapters/cf/WebCrypto';
import { toBase64Url } from '../../../src/crypto/encoding';
import { callClientDataHash } from '../../../src/domain/challenge';
import {
  attestation,
  ATTESTATION_HEADER,
  DEBUG_ATTESTATION_HEADER,
  isDebugAttestation,
  parseAttestationHeader,
} from '../../../src/http/middleware/attestation';
import { InstallRepo } from '../../../src/repos/InstallRepo';
import {
  createHarness,
  TEST_DEBUG_ATTESTATION_TOKEN,
  type TestHarness,
} from '../../fakes/testDeps';
import { APP_HEADERS, errorOf, testApp } from '../../helpers/app';
import { db } from '../../helpers/db';
import { ANDROID_HEADERS, noneAttestation, registerOk } from '../../helpers/identity';

const crypto = new WebCrypto();
const installs = new InstallRepo(db);

function harness(options: Parameters<typeof createHarness>[0] = {}): TestHarness {
  const h = createHarness(options);
  h.config.set({ 'abuse.lowTrust.powBits': 8 });
  return h;
}

function refresh(
  h: TestHarness,
  token: string | undefined,
  extra: Record<string, string> = {},
  headers: Record<string, string> = APP_HEADERS,
) {
  return testApp(h).request('/v1/installs/token', {
    method: 'POST',
    headers: {
      ...headers,
      ...(token === undefined ? {} : { Authorization: `Bearer ${token}` }),
      ...extra,
    },
  });
}

const AA1 = { [ATTESTATION_HEADER]: 'aa1.YXNzZXJ0aW9u' };
const PI1 = { [ATTESTATION_HEADER]: 'pi1.standard-integrity-token' };

describe('POST /v1/installs/token [attest] (03 §3.4)', () => {
  it('issues a fresh 7-day token for an iOS assertion and advances the stored counter', async () => {
    const h = harness();
    const reg = await registerOk(testApp(h));
    h.clock.advance({ days: 6 });
    const res = await refresh(h, reg.body.installToken, AA1);
    expect(res.status).toBe(200);
    const body = await res.json<{ installToken: string; expiresAt: string; trust: string }>();
    expect(body.trust).toBe('high');
    expect(body.expiresAt).toBe('2026-10-09T10:00:00.000Z');
    expect(await h.deps.tokenSigner.verify(body.installToken, h.clock.now())).toMatchObject({
      ok: true,
      claims: { sub: reg.installId, gen: 1 },
    });
    const call = h.appAttest.assertionCalls[0];
    expect(call?.clientDataHash).toEqual(
      await callClientDataHash(crypto, {
        method: 'POST',
        path: '/v1/installs/token',
        body: new Uint8Array(),
        idempotencyKey: undefined,
      }),
    );
    expect(call?.previousCounter).toBe(0);
    expect((await installs.findById(reg.installId))?.attestCounter).toBe(1);
    h.logger.expectNoSensitive(reg.secret, reg.installId, reg.body.installToken, body.installToken);
  });

  it('accepts an expired but otherwise valid token (other routes answer TOKEN_EXPIRED)', async () => {
    const h = harness();
    const reg = await registerOk(testApp(h));
    h.clock.advance({ days: 8 });
    const balance = await testApp(h).request('/v1/balance', {
      headers: { ...APP_HEADERS, Authorization: `Bearer ${reg.body.installToken}` },
    });
    expect(balance.status).toBe(401);
    expect((await errorOf(balance)).code).toBe('TOKEN_EXPIRED');
    expect((await refresh(h, reg.body.installToken, AA1)).status).toBe(200);
  });

  it('binds the Idempotency-Key and body into the assertion hash when present', async () => {
    const h = harness();
    const reg = await registerOk(testApp(h));
    await refresh(h, reg.body.installToken, { ...AA1, 'Idempotency-Key': 'k-1' });
    expect(h.appAttest.assertionCalls[0]?.clientDataHash).toEqual(
      await callClientDataHash(crypto, {
        method: 'POST',
        path: '/v1/installs/token',
        body: new Uint8Array(),
        idempotencyKey: 'k-1',
      }),
    );
  });

  it('requires attestation while attest.requiredOnReadings is on, and downgrades when it is off', async () => {
    const h = harness();
    const reg = await registerOk(testApp(h));
    for (const extra of [
      {},
      { [ATTESTATION_HEADER]: 'none' },
      { [ATTESTATION_HEADER]: 'aa1.!!' },
      { [ATTESTATION_HEADER]: 'xyz.abc' },
    ]) {
      const res = await refresh(h, reg.body.installToken, extra);
      expect(res.status).toBe(401);
      expect((await errorOf(res)).code).toBe('ATTESTATION_REQUIRED');
      expect(h.logger.find('call_attest_required').at(-1)?.fields).toMatchObject({
        plat: 'ios',
        trust: 'high',
      });
    }
    h.config.set({ 'attest.requiredOnReadings': false });
    const res = await refresh(h, reg.body.installToken);
    expect(res.status).toBe(200);
    expect((await res.json<{ trust: string }>()).trust).toBe('high');
  });

  it('accepts `none` from a low-trust install', async () => {
    const h = harness();
    const reg = await registerOk(testApp(h), { attestation: noneAttestation(8) });
    expect(reg.body.trust).toBe('low');
    const res = await refresh(h, reg.body.installToken, { [ATTESTATION_HEADER]: 'none' });
    expect(res.status).toBe(200);
    expect((await res.json<{ trust: string }>()).trust).toBe('low');
    // It has no App Attest key, so an assertion cannot be verified.
    const aa1 = await refresh(h, reg.body.installToken, AA1);
    expect(aa1.status).toBe(403);
    expect(h.metrics.points.at(-1)).toMatchObject({ event: 'attest_failed', code: 'no_key' });
    expect(h.logger.find('call_attest_rejected').at(-1)?.fields).toEqual({
      plat: 'ios',
      detail: 'no_key',
    });
  });

  it('rejects an invalid assertion (403) and degrades an outage to low trust', async () => {
    const h = harness();
    const reg = await registerOk(testApp(h));
    h.appAttest.enqueueAssertion({ ok: false, reason: 'invalid', detail: 'signature' });
    const bad = await refresh(h, reg.body.installToken, AA1);
    expect(bad.status).toBe(403);
    expect((await errorOf(bad)).code).toBe('ATTESTATION_FAILED');
    expect(h.metrics.points.at(-1)).toMatchObject({ event: 'attest_failed', code: 'signature' });

    h.appAttest.enqueueAssertion({ ok: false, reason: 'invalid' });
    expect((await refresh(h, reg.body.installToken, AA1)).status).toBe(403);
    expect(h.metrics.points.at(-1)).toMatchObject({ code: 'invalid' });

    h.appAttest.enqueueAssertion({ ok: false, reason: 'unavailable' });
    expect((await refresh(h, reg.body.installToken, AA1)).status).toBe(200);
    expect(h.metrics.points.at(-1)).toMatchObject({ event: 'attest_failed', code: 'unavailable' });
  });

  it('rejects a counter that another request already used (compare-and-set)', async () => {
    const h = harness();
    const reg = await registerOk(testApp(h));
    h.appAttest.enqueueAssertion({ ok: true, counter: 0 });
    const res = await refresh(h, reg.body.installToken, AA1);
    expect(res.status).toBe(403);
    expect(h.metrics.points.at(-1)).toMatchObject({ code: 'counter_race' });
  });

  it('verifies Android Play Integrity tokens against the per-call request hash', async () => {
    const h = harness();
    const reg = await registerOk(testApp(h), { platform: 'android' });
    const res = await refresh(h, reg.body.installToken, PI1, ANDROID_HEADERS);
    expect(res.status).toBe(200);
    const call = h.playIntegrity.calls.at(-1);
    expect(call?.token).toBe('standard-integrity-token');
    expect(call?.expectedRequestHash).toBe(
      toBase64Url(
        await callClientDataHash(crypto, {
          method: 'POST',
          path: '/v1/installs/token',
          body: new Uint8Array(),
          idempotencyKey: undefined,
        }),
      ),
    );

    h.playIntegrity.enqueue({
      ok: true,
      deviceVerdict: 'basic',
      appRecognized: true,
      packageName: 'p',
    });
    expect((await refresh(h, reg.body.installToken, PI1, ANDROID_HEADERS)).status).toBe(200);
    h.playIntegrity.enqueue({ ok: false, reason: 'unavailable' });
    expect((await refresh(h, reg.body.installToken, PI1, ANDROID_HEADERS)).status).toBe(200);
    h.playIntegrity.enqueue({ ok: false, reason: 'invalid', detail: 'request_hash' });
    expect((await refresh(h, reg.body.installToken, PI1, ANDROID_HEADERS)).status).toBe(403);
    expect(h.metrics.points.at(-1)).toMatchObject({ code: 'request_hash' });

    const prod = harness({ overrides: { environment: 'prod' } });
    const prodReg = await registerOk(testApp(prod), { platform: 'android' });
    prod.playIntegrity.enqueue({
      ok: true,
      deviceVerdict: 'device',
      appRecognized: false,
      packageName: 'p',
    });
    expect((await refresh(prod, prodReg.body.installToken, PI1, ANDROID_HEADERS)).status).toBe(200);
  });

  it('rejects an attestation kind of the other platform', async () => {
    const h = harness();
    const ios = await registerOk(testApp(h));
    expect((await refresh(h, ios.body.installToken, PI1)).status).toBe(403);
    expect(h.metrics.points.at(-1)).toMatchObject({ code: 'platform' });
    const android = await registerOk(testApp(h), { platform: 'android' });
    expect((await refresh(h, android.body.installToken, AA1, ANDROID_HEADERS)).status).toBe(403);
  });

  it('honours X-Taro-Debug-Attestation only where the deploy env allows it (RC86)', async () => {
    const allowed = harness({ debugAttestation: true });
    const reg = await registerOk(testApp(allowed));
    const debug = { [DEBUG_ATTESTATION_HEADER]: TEST_DEBUG_ATTESTATION_TOKEN };
    expect((await refresh(allowed, reg.body.installToken, debug)).status).toBe(200);
    expect(allowed.appAttest.assertionCalls).toHaveLength(0);
    expect(allowed.logger.find('debug_attestation_used')).toHaveLength(1);

    const denied = harness();
    const other = await registerOk(testApp(denied));
    const res = await refresh(denied, other.body.installToken, debug);
    expect(res.status).toBe(401);
    expect((await errorOf(res)).code).toBe('ATTESTATION_REQUIRED');
  });
});

describe('auth middleware (03 §3.4)', () => {
  it('rejects missing, malformed and foreign tokens with 401 UNAUTHENTICATED', async () => {
    const h = harness();
    for (const token of [undefined, 'garbage', 'eyJhbGciOiJFZERTQSJ9.e30.c2ln']) {
      const res = await refresh(h, token, AA1);
      expect(res.status).toBe(401);
      expect((await errorOf(res)).code).toBe('UNAUTHENTICATED');
    }
  });

  it('rejects a revoked generation, a deleted install, an unknown install and a platform mismatch', async () => {
    const h = harness();
    const app = testApp(h);
    const reg = await registerOk(app);
    await registerOk(app, { installId: reg.installId, secret: reg.secret });
    expect((await refresh(h, reg.body.installToken, AA1)).status).toBe(401);

    const deleted = await registerOk(app);
    await installs.setStatus(deleted.installId, 'deleted');
    expect((await refresh(h, deleted.body.installToken, AA1)).status).toBe(401);

    const ghost = await h.deps.tokenSigner.sign(
      { sub: '00000000-0000-4000-8000-00000000dead', gen: 1, trust: 'high', plat: 'ios' },
      h.clock.now(),
    );
    expect((await refresh(h, ghost.token, AA1)).status).toBe(401);

    const live = await registerOk(app);
    const wrongPlatform = await h.deps.tokenSigner.sign(
      { sub: live.installId, gen: 1, trust: 'high', plat: 'android' },
      h.clock.now(),
    );
    expect((await refresh(h, wrongPlatform.token, AA1)).status).toBe(401);
  });

  it('keeps a blocked install authenticated (RC66)', async () => {
    const h = harness();
    const reg = await registerOk(testApp(h));
    await installs.setStatus(reg.installId, 'blocked');
    expect((await refresh(h, reg.body.installToken, AA1)).status).toBe(200);
  });
});

describe('attestation middleware internals', () => {
  it('parses the three header forms', () => {
    expect(parseAttestationHeader('none')).toEqual({ kind: 'none' });
    expect(parseAttestationHeader(' aa1.AQID ')).toEqual({
      kind: 'aa1',
      assertion: Uint8Array.of(1, 2, 3),
    });
    expect(parseAttestationHeader('pi1.tok.en')).toEqual({ kind: 'pi1', token: 'tok.en' });
    expect(parseAttestationHeader('aa1.A')).toEqual({ kind: 'missing' });
    expect(parseAttestationHeader('aa1.')).toEqual({ kind: 'missing' });
    expect(parseAttestationHeader(undefined)).toEqual({ kind: 'missing' });
    expect(parseAttestationHeader('zz1.abc')).toEqual({ kind: 'missing' });
  });

  it('compares the debug token in constant time and only when configured', () => {
    const allowed = createHarness({ debugAttestation: true }).deps;
    expect(isDebugAttestation(allowed, TEST_DEBUG_ATTESTATION_TOKEN)).toBe(true);
    expect(isDebugAttestation(allowed, `${TEST_DEBUG_ATTESTATION_TOKEN}x`)).toBe(false);
    expect(isDebugAttestation(allowed, undefined)).toBe(false);
    expect(isDebugAttestation(createHarness().deps, TEST_DEBUG_ATTESTATION_TOKEN)).toBe(false);
  });

  it('fails closed without the auth middleware in front', async () => {
    const h = createHarness();
    const app = testApp(h, (a) => {
      a.post('/test/attest', attestation(h.deps), (c) => c.text('ok'));
    });
    const res = await app.request('/test/attest', { method: 'POST', headers: AA1 });
    expect(res.status).toBe(401);
    expect((await errorOf(res)).code).toBe('UNAUTHENTICATED');
  });
});
