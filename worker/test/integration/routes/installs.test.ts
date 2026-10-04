import { afterEach, describe, expect, it, vi } from 'vitest';
import { WebCrypto } from '../../../src/adapters/cf/WebCrypto';
import { toBase64Url, toHex, utf8 } from '../../../src/crypto/encoding';
import { appleAccountToken, playAccountId } from '../../../src/domain/purchaseBinding';
import { REPLAYED_HEADER } from '../../../src/http/middleware/idempotency';
import {
  ipPrefixHash,
  REGISTRATIONS_PER_PREFIX_PER_DAY,
} from '../../../src/http/middleware/rateLimit';
import { DeviceUsageRepo } from '../../../src/repos/DeviceUsageRepo';
import { InstallRepo } from '../../../src/repos/InstallRepo';
import {
  bindings,
  createHarness,
  TEST_APPLE_ACCOUNT_NS,
  TEST_DEBUG_ATTESTATION_TOKEN,
  TEST_DEVICE_KEY_SECRET,
  TEST_PLAY_ACCOUNT_KEY,
  type TestHarness,
} from '../../fakes/testDeps';
import { APP_HEADERS, errorOf, testApp } from '../../helpers/app';
import { db } from '../../helpers/db';
import {
  ANDROID_HEADERS,
  idemKey,
  installIdV4,
  newDeviceKey,
  newSecret,
  register,
  registerOk,
  noneAttestation,
  uniqueIp,
} from '../../helpers/identity';

const crypto = new WebCrypto();
const installs = new InstallRepo(db);

function harness(options: Parameters<typeof createHarness>[0] = {}): TestHarness {
  const h = createHarness(options);
  // Fast proof-of-work in tests (the schema minimum).
  h.config.set({ 'abuse.lowTrust.powBits': 8 });
  return h;
}

async function balance(h: TestHarness, token: string, headers = APP_HEADERS) {
  return testApp(h).request('/v1/balance', {
    headers: { ...headers, Authorization: `Bearer ${token}` },
  });
}

async function seedPaidCredits(installId: string, credits: number): Promise<void> {
  await db
    .prepare(
      `INSERT INTO ledger (install_id, bucket, delta, reason, ref_type, ref_id, created_at)
       VALUES (?1, 'paid', ?2, 'admin_adjust', 'admin', ?3, '2026-09-26T09:00:00.000Z')`,
    )
    .bind(installId, credits, `seed-${installId}`)
    .run();
}

/**
 * Flips one character inside the HMAC part of a challenge. (Rewriting the
 * last characters is flaky: the final base64url character carries padding
 * bits, so some rewrites decode to the same bytes.)
 */
function tamper(challenge: string): string {
  const at = 45;
  const replacement = challenge[at] === 'A' ? 'B' : 'A';
  return `${challenge.slice(0, at)}${replacement}${challenge.slice(at + 1)}`;
}

describe('POST /v1/installs — new installs (03 §3.3)', () => {
  it('registers an iOS install with App Attest: 201, high trust, token, binding, balance and config', async () => {
    const h = harness();
    const app = testApp(h);
    const { res, installId, secret, challenge } = await register(app, {
      deviceCheckToken: 'dc-token-1',
    });
    expect(res.status).toBe(201);
    const body = await res.json<Record<string, unknown>>();
    expect(body).toMatchObject({
      trust: 'high',
      purchaseBinding: {
        appleAccountToken: await appleAccountToken(crypto, TEST_APPLE_ACCOUNT_NS, installId),
      },
      balance: {
        bonus: 0,
        paid: 0,
        canRead: true,
        free: { remaining: 1, timezone: 'Europe/Berlin' },
      },
      config: { version: expect.any(Number) as number, 'readings.freeDaily': 1 },
    });
    expect(body['purchaseBinding']).not.toHaveProperty('playAccountId');
    const token = String(body['installToken']);
    expect(await h.deps.tokenSigner.verify(token, h.clock.now())).toEqual({
      ok: true,
      claims: { sub: installId, gen: 1, trust: 'high', plat: 'ios' },
      expired: false,
    });
    expect(body['expiresAt']).toBe('2026-10-03T10:00:00.000Z');

    const [call] = h.appAttest.attestationCalls;
    expect(call?.clientDataHash).toEqual(await crypto.sha256(`${challenge}${installId}dc-token-1`));
    expect(call?.allowedAppIds).toEqual(['TEAMID1234.com.vshyrochuk.taro', 'com.vshyrochuk.taro']);

    const row = await installs.findById(installId);
    expect(row).toMatchObject({
      platform: 'ios',
      status: 'active',
      trust: 'high',
      tokenGeneration: 1,
      installSecretHash: toHex(await crypto.sha256(secret)),
      attestKeyId: 'a2V5LWlk',
      attestPublicKey: new Uint8Array([1, 2, 3]),
      attestCounter: 0,
      attestEnv: 'production',
      deviceKeyHash: null,
      deviceReused: false,
      locale: 'de',
      timezone: 'Europe/Berlin',
      appVersion: '1.2.0+14',
    });
    expect(h.metrics.points).toContainEqual(
      expect.objectContaining({ event: 'install_registered', platform: 'ios', code: 'high' }),
    );
    expect(h.logger.find('install_attest_verdict')).toEqual([
      {
        level: 'info',
        event: 'install_attest_verdict',
        fields: expect.objectContaining({
          plat: 'ios',
          att: 'app_attest',
          trust: 'high',
        }) as object,
      },
    ]);
    h.logger.expectNoSensitive(secret, installId, token);
  });

  it('registers an Android install with Play Integrity bound to challenge ‖ installId ‖ deviceKey (RC87)', async () => {
    const h = harness();
    const deviceKey = newDeviceKey();
    const { res, installId, challenge, secret } = await register(testApp(h), {
      platform: 'android',
      deviceKey,
    });
    expect(res.status).toBe(201);
    const body = await res.json<{ trust: string; purchaseBinding: Record<string, string> }>();
    expect(body.trust).toBe('high');
    expect(body.purchaseBinding).toEqual({
      playAccountId: await playAccountId(crypto, utf8(TEST_PLAY_ACCOUNT_KEY), installId),
    });
    expect(h.playIntegrity.calls[0]).toMatchObject({
      token: 'integrity.token',
      expectedRequestHash: toBase64Url(await crypto.sha256(`${challenge}${installId}${deviceKey}`)),
    });
    expect(await installs.findById(installId)).toMatchObject({
      platform: 'android',
      trust: 'high',
      integrityVerdict: 'device',
      deviceKeyHash: toHex(await crypto.hmacSha256(utf8(TEST_DEVICE_KEY_SECRET), deviceKey)),
      playAccountHash: body.purchaseBinding['playAccountId'],
      appleAccountToken: null,
      attestPublicKey: null,
    });
    h.logger.expectNoSensitive(secret, installId, deviceKey);
  });

  it('gives low trust for basic integrity or an unrecognised app in prod, high for it in dev', async () => {
    const h = harness();
    h.playIntegrity.enqueue({
      ok: true,
      deviceVerdict: 'basic',
      appRecognized: true,
      packageName: 'com.vshyrochuk.taro',
    });
    const basic = await registerOk(testApp(h), { platform: 'android' });
    expect(basic.body.trust).toBe('low');
    expect((await installs.findById(basic.installId))?.integrityVerdict).toBe('basic');

    const unrecognized = {
      ok: true,
      deviceVerdict: 'device',
      appRecognized: false,
      packageName: 'com.vshyrochuk.taro',
    } as const;
    h.playIntegrity.enqueue(unrecognized);
    expect((await registerOk(testApp(h), { platform: 'android' })).body.trust).toBe('high');

    const prod = harness({ overrides: { environment: 'prod' } });
    prod.playIntegrity.enqueue(unrecognized);
    expect((await registerOk(testApp(prod), { platform: 'android' })).body.trust).toBe('low');
  });

  it('rejects a hard attestation failure with 403 and writes nothing; an outage degrades to low', async () => {
    const h = harness();
    h.appAttest.enqueueAttestation({ ok: false, reason: 'invalid', detail: 'chain' });
    const failed = await register(testApp(h));
    expect(failed.res.status).toBe(403);
    expect((await errorOf(failed.res)).code).toBe('ATTESTATION_FAILED');
    expect(await installs.findById(failed.installId)).toBeNull();
    expect(h.metrics.points).toContainEqual(
      expect.objectContaining({ event: 'attest_failed', code: 'chain' }),
    );
    expect(h.logger.find('install_attest_rejected').at(-1)?.fields).toEqual({
      plat: 'ios',
      detail: 'chain',
    });

    h.playIntegrity.enqueue({ ok: false, reason: 'invalid' });
    expect((await register(testApp(h), { platform: 'android' })).res.status).toBe(403);

    h.appAttest.enqueueAttestation({ ok: false, reason: 'unavailable' });
    const degraded = await registerOk(testApp(h));
    expect(degraded.body.trust).toBe('low');
    expect(await installs.findById(degraded.installId)).toMatchObject({
      trust: 'low',
      attestPublicKey: null,
    });
    h.playIntegrity.enqueue({ ok: false, reason: 'unavailable' });
    expect((await registerOk(testApp(h), { platform: 'android' })).body.trust).toBe('low');
  });

  it('rejects replayed, tampered and expired challenges with 403 (used_challenges)', async () => {
    const h = harness();
    const app = testApp(h);
    const first = await registerOk(app);
    const replay = await register(app, {
      attestation: () => ({
        type: 'app_attest',
        challenge: first.challenge,
        keyId: 'a2V5LWlk',
        attestationObject: 'b2JqZWN0',
      }),
    });
    expect(replay.res.status).toBe(403);
    expect(h.metrics.points.at(-1)).toMatchObject({
      event: 'attest_failed',
      code: 'challenge_replay',
    });

    const tampered = await register(app, {
      attestation: (challenge) => ({
        type: 'app_attest',
        challenge: tamper(challenge),
        keyId: 'a2V5LWlk',
        attestationObject: 'b2JqZWN0',
      }),
    });
    expect(tampered.res.status).toBe(403);

    const { challenge } = await (
      await app.request('/v1/attest/challenge', { method: 'POST', headers: APP_HEADERS })
    ).json<{ challenge: string }>();
    h.clock.advance({ seconds: 301 });
    const expired = await register(app, {
      attestation: () => ({
        type: 'app_attest',
        challenge,
        keyId: 'a2V5LWlk',
        attestationObject: 'b2JqZWN0',
      }),
    });
    expect(expired.res.status).toBe(403);
    expect(h.metrics.points.at(-1)).toMatchObject({ code: 'challenge_expired' });
  });

  it('`type: none` needs a valid proof-of-work (RC65): missing or wrong → 403, valid → 201 low', async () => {
    const h = harness();
    const app = testApp(h);
    const missing = await register(app, {
      attestation: (challenge) => ({ type: 'none', challenge, reason: 'unsupported' }),
    });
    expect(missing.res.status).toBe(403);
    expect(await installs.findById(missing.installId)).toBeNull();
    expect(h.metrics.points.at(-1)).toMatchObject({ event: 'attest_failed', code: 'pow' });

    // Solved for 8 bits but checked against 28: wrong.
    h.config.set({ 'abuse.lowTrust.powBits': 28 });
    const weak = await register(app, { attestation: noneAttestation(8) });
    expect(weak.res.status).toBe(403);
    h.config.set({ 'abuse.lowTrust.powBits': 8 });
    const valid = await registerOk(app, { attestation: noneAttestation(8) });
    expect(valid.res.status).toBe(201);
    expect(valid.body.trust).toBe('low');
    expect(h.appAttest.attestationCalls).toHaveLength(0);
    // The reason of a low-trust registration is visible in the logs.
    expect(h.logger.find('install_attest_verdict').at(-1)).toMatchObject({
      level: 'warn',
      fields: { plat: 'ios', att: 'none', noneReason: 'unsupported', trust: 'low' },
    });
  });

  it('caps `type: none` registrations per IP prefix (5/day) with 429 lowTrustCap', async () => {
    const h = harness();
    h.config.set({ 'abuse.lowTrust.registrationsPerPrefixPerDay': 1 });
    const app = testApp(h);
    const ip = uniqueIp();
    const headers = { ...APP_HEADERS, 'CF-Connecting-IP': ip };
    expect((await register(app, { headers, attestation: noneAttestation(8) })).res.status).toBe(
      201,
    );
    const capped = await register(app, { headers, attestation: noneAttestation(8) });
    expect(capped.res.status).toBe(429);
    expect(await errorOf(capped.res)).toMatchObject({
      code: 'RATE_LIMITED',
      details: { reason: 'lowTrustCap' },
      retryAfterSec: 14 * 3600,
    });
    expect(await installs.findById(capped.installId)).toBeNull();
    // Attested registrations from the same prefix are not affected by the none cap.
    expect((await register(app, { headers })).res.status).toBe(201);
  });

  it('validates the body: platform vs header, attestation type per platform, Android deviceKey, timezone', async () => {
    const app = testApp(harness());
    const mismatch = await register(app, {
      headers: { ...ANDROID_HEADERS, 'CF-Connecting-IP': uniqueIp() },
    });
    expect(mismatch.res.status).toBe(400);
    expect(await errorOf(mismatch.res)).toMatchObject({
      code: 'VALIDATION_FAILED',
      details: { issues: [{ path: 'platform' }] },
    });

    const wrongType = await register(app, {
      attestation: (challenge) => ({ type: 'play_integrity', challenge, integrityToken: 't' }),
    });
    expect(wrongType.res.status).toBe(400);

    const noDeviceKey = await register(app, {
      platform: 'android',
      body: (challenge) => ({
        installId: installIdV4(),
        installSecret: newSecret(),
        platform: 'android',
        appVersion: '1.2.0',
        locale: 'en',
        timezone: 'UTC',
        attestation: { type: 'play_integrity', challenge, integrityToken: 't' },
      }),
    });
    expect(noDeviceKey.res.status).toBe(400);
    expect((await errorOf(noDeviceKey.res)).details).toMatchObject({
      issues: [{ path: 'deviceKey' }],
    });

    const badZone = await register(app, {
      body: (challenge) => ({
        installId: installIdV4(),
        installSecret: newSecret(),
        platform: 'ios',
        appVersion: '1.2.0',
        locale: 'en',
        timezone: 'Mars/Olympus',
        attestation: { type: 'none', challenge, reason: 'unsupported' },
      }),
    });
    expect(badZone.res.status).toBe(400);

    const noKey = await app.request('/v1/installs', {
      method: 'POST',
      headers: { ...APP_HEADERS, 'content-type': 'application/json' },
      body: '{}',
    });
    expect((await errorOf(noKey)).code).toBe('IDEMPOTENCY_KEY_REQUIRED');
  });
});

describe('POST /v1/installs — re-registration (RC54, RC55)', () => {
  it('rejects re-registration without the install secret (403, nothing changes)', async () => {
    const h = harness();
    const app = testApp(h);
    const first = await registerOk(app);
    const before = await installs.findById(first.installId);
    const attempt = await register(app, { installId: first.installId, secret: newSecret() });
    expect(attempt.res.status).toBe(403);
    expect((await errorOf(attempt.res)).code).toBe('ATTESTATION_FAILED');
    expect(await installs.findById(first.installId)).toEqual(before);
    expect((await balance(h, first.body.installToken)).status).toBe(200);
    h.logger.expectNoSensitive(first.secret, attempt.secret, first.installId);
  });

  it('accepts it with the secret: 200, balance kept, token generation bumped, old tokens revoked', async () => {
    const h = harness();
    const app = testApp(h);
    const first = await registerOk(app);
    await seedPaidCredits(first.installId, 3);
    const again = await register(app, { installId: first.installId, secret: first.secret });
    expect(again.res.status).toBe(200);
    const body = await again.res.json<{
      installToken: string;
      balance: { paid: number };
      trust: string;
    }>();
    expect(body.balance.paid).toBe(3);
    expect(body.trust).toBe('high');
    expect(await installs.findById(first.installId)).toMatchObject({ tokenGeneration: 2 });

    const old = await balance(h, first.body.installToken);
    expect(old.status).toBe(401);
    expect((await errorOf(old)).code).toBe('UNAUTHENTICATED');
    expect((await balance(h, body.installToken)).status).toBe(200);
    expect(h.metrics.count('install_registered')).toBe(1);
    h.logger.expectNoSensitive(first.secret, first.installId, body.installToken);
  });

  it('iOS reinstall within 7 days with a fresh idempotency key re-registers (RC55)', async () => {
    const h = harness();
    const app = testApp(h);
    const first = await registerOk(app);
    h.clock.advance({ days: 3 });
    h.appAttest.enqueueAttestation({
      ok: true,
      publicKey: new Uint8Array([9, 9, 9]),
      counter: 0,
      env: 'production',
    });
    const reinstall = await register(app, {
      installId: first.installId,
      secret: first.secret,
      idempotencyKey: idemKey(),
    });
    expect(reinstall.res.status).toBe(200);
    expect(await installs.findById(first.installId)).toMatchObject({
      attestPublicKey: new Uint8Array([9, 9, 9]),
      attestCounter: 0,
      tokenGeneration: 2,
    });
  });

  it('replays a retried registration byte for byte for the same Idempotency-Key', async () => {
    const h = harness();
    const app = testApp(h);
    const key = idemKey();
    const installId = installIdV4();
    const secret = newSecret();
    const { challenge } = await (
      await app.request('/v1/attest/challenge', { method: 'POST', headers: APP_HEADERS })
    ).json<{ challenge: string }>();
    const send = () =>
      app.request('/v1/installs', {
        method: 'POST',
        headers: { ...APP_HEADERS, 'content-type': 'application/json', 'Idempotency-Key': key },
        body: JSON.stringify({
          installId,
          installSecret: secret,
          platform: 'ios',
          appVersion: '1.2.0',
          locale: 'en',
          timezone: 'UTC',
          attestation: { type: 'app_attest', challenge, keyId: 'a2V5', attestationObject: 'b2Jq' },
        }),
      });
    const first = await send();
    const retry = await send();
    expect(first.status).toBe(201);
    expect(retry.status).toBe(201);
    expect(retry.headers.get(REPLAYED_HEADER)).toBe('true');
    expect(await retry.text()).toBe(await first.text());
    expect(h.appAttest.attestationCalls).toHaveLength(1);
    expect((await installs.findById(installId))?.tokenGeneration).toBe(1);
  });

  it('reactivates a `deleted` (pseudonymised) row by a proven re-registration', async () => {
    const h = harness();
    const app = testApp(h);
    const first = await registerOk(app);
    await seedPaidCredits(first.installId, 2);
    await db
      .prepare(
        `UPDATE installs SET status = 'deleted', timezone = NULL, locale = NULL,
           apple_account_token = NULL, attest_public_key = NULL WHERE id = ?1`,
      )
      .bind(first.installId)
      .run();
    expect((await balance(h, first.body.installToken)).status).toBe(401);

    const back = await register(app, { installId: first.installId, secret: first.secret });
    expect(back.res.status).toBe(200);
    const body = await back.res.json<{ balance: { paid: number }; installToken: string }>();
    expect(body.balance.paid).toBe(2);
    expect(await installs.findById(first.installId)).toMatchObject({
      status: 'active',
      tokenGeneration: 2,
      timezone: 'Europe/Berlin',
      locale: 'de',
      appleAccountToken: first.body.purchaseBinding.appleAccountToken,
    });
    expect(h.logger.find('install_reregistered').at(-1)?.fields).toMatchObject({
      reactivated: true,
    });
    expect((await balance(h, body.installToken)).status).toBe(200);
  });

  it('keeps a blocked install blocked and never changes its timezone', async () => {
    const h = harness();
    const app = testApp(h);
    const first = await registerOk(app);
    await installs.setStatus(first.installId, 'blocked');
    const again = await register(app, {
      installId: first.installId,
      secret: first.secret,
      body: (challenge) => ({
        installId: first.installId,
        installSecret: first.secret,
        platform: 'ios',
        appVersion: '1.3.0',
        locale: 'fr',
        timezone: 'America/New_York',
        attestation: { type: 'app_attest', challenge, keyId: 'a2V5', attestationObject: 'b2Jq' },
      }),
    });
    expect(again.res.status).toBe(200);
    expect(await installs.findById(first.installId)).toMatchObject({
      status: 'blocked',
      timezone: 'Europe/Berlin',
      locale: 'fr',
    });
  });

  it('accepts an iOS assertion by the stored key instead of the lost secret', async () => {
    const h = harness();
    const app = testApp(h);
    const first = await registerOk(app);
    const withAssertion = (challenge: string) => ({
      type: 'app_attest',
      challenge,
      keyId: 'bmV3',
      attestationObject: 'b2Jq',
      previousKeyAssertion: 'YXNzZXJ0aW9u',
    });
    const proven = await register(app, {
      installId: first.installId,
      secret: newSecret(),
      attestation: withAssertion,
    });
    expect(proven.res.status).toBe(200);
    const call = h.appAttest.assertionCalls.at(-1);
    expect(call?.publicKey).toEqual(new Uint8Array([1, 2, 3]));
    expect(call?.previousCounter).toBe(0);

    h.appAttest.enqueueAssertion({ ok: false, reason: 'invalid', detail: 'signature' });
    const forged = await register(app, {
      installId: first.installId,
      secret: newSecret(),
      attestation: withAssertion,
    });
    expect(forged.res.status).toBe(403);
  });

  it('refuses a re-registration from the other platform', async () => {
    const app = testApp(harness());
    const first = await registerOk(app);
    const android = await register(app, {
      platform: 'android',
      installId: first.installId,
      secret: first.secret,
    });
    expect(android.res.status).toBe(403);
  });

  it('allows 5 re-registrations per install per UTC day, then 429 until midnight', async () => {
    const h = harness();
    const app = testApp(h);
    const first = await registerOk(app);
    for (let i = 0; i < 5; i++) {
      expect(
        (await register(app, { installId: first.installId, secret: first.secret })).res.status,
      ).toBe(200);
    }
    const sixth = await register(app, { installId: first.installId, secret: first.secret });
    expect(sixth.res.status).toBe(429);
    expect(await errorOf(sixth.res)).toMatchObject({ details: { reason: 'burst' } });
    h.clock.advance({ hours: 14 });
    expect(
      (await register(app, { installId: first.installId, secret: first.secret })).res.status,
    ).toBe(200);
    expect((await installs.findById(first.installId))?.reregisterCountDay).toBe('2026-09-27:1');
  });
});

describe('device-scoped abuse key (03 §3.7, RC53)', () => {
  it('Android: a second installId with the same deviceKey shares today’s device_daily_usage', async () => {
    const h = harness();
    const app = testApp(h);
    const deviceKey = newDeviceKey();
    const a = await registerOk(app, { platform: 'android', deviceKey });
    const hashA = (await installs.findById(a.installId))?.deviceKeyHash ?? '';
    // Install A takes today's free reading on this device (Europe/Berlin, 2026-09-26).
    await new DeviceUsageRepo(db)
      .takeFreeStmt({ deviceKeyHash: hashA, localDate: '2026-09-26' }, 1)
      .run();

    const b = await registerOk(app, { platform: 'android', deviceKey });
    expect(b.installId).not.toBe(a.installId);
    expect((await installs.findById(b.installId))?.deviceKeyHash).toBe(hashA);
    expect(b.body.balance).toMatchObject({ free: { remaining: 0 } });
    expect(a.body.balance).toMatchObject({ free: { remaining: 1 } });

    const other = await registerOk(app, { platform: 'android', deviceKey: newDeviceKey() });
    expect(other.body.balance).toMatchObject({ free: { remaining: 1 } });
  });

  it('iOS: DeviceCheck bit0 marks a reused device, and the first registration sets it', async () => {
    const h = harness();
    const app = testApp(h);
    const first = await registerOk(app, { deviceCheckToken: 'device-1' });
    expect((await installs.findById(first.installId))?.deviceReused).toBe(false);
    expect(h.deviceCheck.bits.get('device-1')).toEqual({ bit0: true, bit1: false });

    const second = await registerOk(app, { deviceCheckToken: 'device-1' });
    expect((await installs.findById(second.installId))?.deviceReused).toBe(true);
    expect(second.body.balance).toMatchObject({ free: { remaining: 0 } });
    expect(h.deviceCheck.updates).toHaveLength(1);
  });

  it('iOS: DeviceCheck failures degrade to "not reused" and are counted', async () => {
    const h = harness();
    h.deviceCheck.failing = true;
    const reg = await registerOk(testApp(h), { deviceCheckToken: 'device-2' });
    expect((await installs.findById(reg.installId))?.deviceReused).toBe(false);
    expect(
      h.metrics.points.filter((p) => p.event === 'devicecheck_error').map((p) => p.code),
    ).toEqual(['query', 'update']);
  });
});

describe('debug attestation bypass (BE20, RC86)', () => {
  const debugHeaders = () => ({
    ...APP_HEADERS,
    'CF-Connecting-IP': uniqueIp(),
    'X-Taro-Debug-Attestation': TEST_DEBUG_ATTESTATION_TOKEN,
  });
  const noneWithoutPow = (challenge: string) => ({
    type: 'none',
    challenge,
    reason: 'unsupported',
  });

  it('registers with high trust when the deploy env allows it', async () => {
    const h = harness({ debugAttestation: true });
    const reg = await register(testApp(h), {
      headers: debugHeaders(),
      attestation: noneWithoutPow,
    });
    expect(reg.res.status).toBe(201);
    expect((await reg.res.json<{ trust: string }>()).trust).toBe('high');
    expect(h.logger.find('debug_attestation_used')).toHaveLength(1);
    expect(h.appAttest.attestationCalls).toHaveLength(0);
    h.logger.expectNoSensitive(TEST_DEBUG_ATTESTATION_TOKEN);

    const android = await register(testApp(h), {
      platform: 'android',
      headers: { ...debugHeaders(), 'X-Taro-Platform': 'android' },
      attestation: noneWithoutPow,
    });
    expect(android.res.status).toBe(201);
    expect((await installs.findById(android.installId))?.integrityVerdict).toBe('debug');
  });

  it('ignores the header when ALLOW_DEBUG_ATTESTATION is not set', async () => {
    const h = harness();
    const reg = await register(testApp(h), {
      headers: debugHeaders(),
      attestation: noneWithoutPow,
    });
    expect(reg.res.status).toBe(403);
    expect(h.logger.find('debug_attestation_used')).toHaveLength(0);
  });

  it('ignores a wrong token even where it is allowed', async () => {
    const h = harness({ debugAttestation: true });
    const reg = await register(testApp(h), {
      headers: { ...debugHeaders(), 'X-Taro-Debug-Attestation': 'wrong-token-0123456789' },
      attestation: noneWithoutPow,
    });
    expect(reg.res.status).toBe(403);
  });
});

describe('POST /v1/installs — races and edge cases', () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('answers 409 when a concurrent registration of the same ID wins the insert and then vanishes', async () => {
    const h = harness();
    vi.spyOn(InstallRepo.prototype, 'insert').mockResolvedValueOnce(false);
    const reg = await register(testApp(h));
    expect(reg.res.status).toBe(409);
    expect(await errorOf(reg.res)).toMatchObject({ code: 'REQUEST_IN_PROGRESS', retryAfterSec: 3 });
  });

  it('treats a lost insert race as a re-registration that needs the secret', async () => {
    const h = harness();
    const app = testApp(h);
    const first = await registerOk(app);
    // The first lookup misses: the row "appears" between the lookup and the insert.
    vi.spyOn(InstallRepo.prototype, 'findById').mockResolvedValueOnce(null);
    const raced = await register(app, { installId: first.installId, secret: first.secret });
    expect(raced.res.status).toBe(200);
  });

  it('answers 409 when a concurrent re-registration bumped the generation first', async () => {
    const h = harness();
    const app = testApp(h);
    const first = await registerOk(app);
    vi.spyOn(InstallRepo.prototype, 'reregister').mockResolvedValueOnce(null);
    const again = await register(app, { installId: first.installId, secret: first.secret });
    expect(again.res.status).toBe(409);
  });

  it('caps registrations of any type per IP prefix at 50 per UTC day (reason burst)', async () => {
    const h = harness();
    const ip = uniqueIp();
    const hash = await ipPrefixHash(h.deps, ip);
    await bindings.RL_KV.put(`reg:all:${hash}:20260926`, String(REGISTRATIONS_PER_PREFIX_PER_DAY));
    const reg = await register(testApp(h), { headers: { ...APP_HEADERS, 'CF-Connecting-IP': ip } });
    expect(reg.res.status).toBe(429);
    expect(await errorOf(reg.res)).toMatchObject({ details: { reason: 'burst' } });
  });

  it('proves ownership of a row without a secret hash only by an assertion', async () => {
    const h = harness();
    const app = testApp(h);
    const first = await registerOk(app);
    await db
      .prepare(`UPDATE installs SET install_secret_hash = NULL WHERE id = ?1`)
      .bind(first.installId)
      .run();
    expect(
      (await register(app, { installId: first.installId, secret: first.secret })).res.status,
    ).toBe(403);
    await db
      .prepare(`UPDATE installs SET install_secret_hash = 'not-hex' WHERE id = ?1`)
      .bind(first.installId)
      .run();
    expect(
      (await register(app, { installId: first.installId, secret: first.secret })).res.status,
    ).toBe(403);
    const withPow = await register(app, {
      installId: first.installId,
      secret: first.secret,
      attestation: async (challenge, installId) => ({
        ...(await noneAttestation(8)(challenge, installId)),
        previousKeyAssertion: 'YXNzZXJ0aW9u',
      }),
    });
    expect(withPow.res.status).toBe(200);
    // The new registration had no key, so it now has low trust and no stored key.
    expect(await installs.findById(first.installId)).toMatchObject({
      trust: 'low',
      attestPublicKey: null,
    });
  });

  it('stores a 400 for a body that is not JSON under the anonymous scope', async () => {
    const app = testApp(harness());
    const key = idemKey();
    const send = () =>
      app.request('/v1/installs', {
        method: 'POST',
        headers: { ...APP_HEADERS, 'content-type': 'application/json', 'Idempotency-Key': key },
        body: 'not json',
      });
    expect((await send()).status).toBe(400);
    const replay = await send();
    expect(replay.status).toBe(400);
    expect(replay.headers.get(REPLAYED_HEADER)).toBe('true');
  });
});
