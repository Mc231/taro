import {
  decodeJwt,
  decodeProtectedHeader,
  importJWK,
  SignJWT,
  type JWTHeaderParameters,
} from 'jose';
import { describe, expect, it } from 'vitest';
import {
  Ed25519TokenSigner,
  importSigningKeys,
  INSTALL_TOKEN_TTL_SEC,
} from '../../../src/adapters/cf/Ed25519TokenSigner';
import { SecretConfigError } from '../../../src/crypto/keyring';
import type { InstallTokenClaims } from '../../../src/ports/TokenSigner';
import { TEST_TOKEN_SIGNING_KEYS } from '../../fakes/testDeps';

const NOW = new Date('2026-09-26T10:00:00.000Z');
const CLAIMS: InstallTokenClaims = { sub: 'install-1', gen: 3, trust: 'high', plat: 'ios' };
const jwks = JSON.parse(TEST_TOKEN_SIGNING_KEYS) as { keys: Record<string, string>[] };
const [current, previous] = jwks.keys as [Record<string, string>, Record<string, string>];

function signer(keys: string | undefined = TEST_TOKEN_SIGNING_KEYS) {
  return new Ed25519TokenSigner(() => keys);
}

describe('Ed25519TokenSigner (03 §3.4)', () => {
  it('signs EdDSA JWTs with kid, iss, aud and a 7-day expiry', async () => {
    const { token, expiresAt } = await signer().sign(CLAIMS, NOW);
    expect(expiresAt.getTime() - NOW.getTime()).toBe(INSTALL_TOKEN_TTL_SEC * 1000);
    expect(decodeProtectedHeader(token)).toEqual({ alg: 'EdDSA', kid: 'kt2', typ: 'JWT' });
    expect(decodeJwt(token)).toEqual({
      sub: 'install-1',
      gen: 3,
      trust: 'high',
      plat: 'ios',
      iss: 'taro-api',
      aud: 'taro-app',
      iat: 1790416800,
      exp: 1790416800 + INSTALL_TOKEN_TTL_SEC,
    });
    expect(await signer().verify(token, NOW)).toEqual({ ok: true, claims: CLAIMS, expired: false });
  });

  it('reports an expired but valid token as expired', async () => {
    const { token } = await signer().sign(CLAIMS, NOW);
    const later = new Date(NOW.getTime() + (INSTALL_TOKEN_TTL_SEC + 1) * 1000);
    expect(await signer().verify(token, later)).toEqual({
      ok: true,
      claims: CLAIMS,
      expired: true,
    });
  });

  it('verifies tokens of the previous kid after rotation and rejects removed keys', async () => {
    const old = JSON.stringify({ keys: [previous] });
    const { token } = await signer(old).sign(CLAIMS, NOW);
    expect(decodeProtectedHeader(token).kid).toBe('kt1');
    expect(await signer().verify(token, NOW)).toMatchObject({ ok: true });
    const onlyNew = JSON.stringify({ keys: [current] });
    expect(await signer(onlyNew).verify(token, NOW)).toEqual({ ok: false });
  });

  it('rejects tampered, foreign, unsigned and badly-claimed tokens', async () => {
    const s = signer();
    const { token } = await s.sign(CLAIMS, NOW);
    const [header, payload, signature] = token.split('.');
    const forged = btoa(JSON.stringify({ ...decodeJwt(token), gen: 99 }))
      .replace(/=+$/, '')
      .replace(/\+/g, '-')
      .replace(/\//g, '_');
    expect(await s.verify(`${String(header)}.${forged}.${String(signature)}`, NOW)).toEqual({
      ok: false,
    });
    expect(await s.verify(`${String(header)}.${String(payload)}.`, NOW)).toEqual({ ok: false });
    expect(await s.verify('not-a-jwt', NOW)).toEqual({ ok: false });

    const key = await importJWK(current, 'EdDSA');
    const sign = (
      claims: Record<string, unknown>,
      header: JWTHeaderParameters = { alg: 'EdDSA', kid: 'kt2' },
    ) =>
      new SignJWT(claims)
        .setProtectedHeader(header)
        .setSubject('install-1')
        .setIssuer('taro-api')
        .setAudience('taro-app')
        .setIssuedAt(Math.floor(NOW.getTime() / 1000))
        .setExpirationTime(Math.floor(NOW.getTime() / 1000) + 60)
        .sign(key);
    expect(await s.verify(await sign({ gen: 1.5, trust: 'high', plat: 'ios' }), NOW)).toEqual({
      ok: false,
    });
    expect(await s.verify(await sign({ gen: 1, trust: 'max', plat: 'ios' }), NOW)).toEqual({
      ok: false,
    });
    expect(await s.verify(await sign({ gen: 1, trust: 'low', plat: 'web' }), NOW)).toEqual({
      ok: false,
    });
    expect(
      await s.verify(await sign({ gen: 1, trust: 'low', plat: 'android' }, { alg: 'EdDSA' }), NOW),
    ).toEqual({ ok: false });
    expect(
      await s.verify(await sign({ gen: 1, trust: 'low', plat: 'android' }), NOW),
    ).toMatchObject({ ok: true });
    const wrongAudience = await new SignJWT({ gen: 1, trust: 'low', plat: 'ios' })
      .setProtectedHeader({ alg: 'EdDSA', kid: 'kt2' })
      .setSubject('x')
      .setIssuer('taro-api')
      .setAudience('someone-else')
      .setIssuedAt()
      .setExpirationTime('1h')
      .sign(key);
    expect(await s.verify(wrongAudience, NOW)).toEqual({ ok: false });
  });

  it('rejects unusable TOKEN_SIGNING_KEYS with SecretConfigError, and retries after a failure', async () => {
    for (const raw of [
      undefined,
      ' ',
      'not json',
      JSON.stringify({ keys: [] }),
      JSON.stringify({}),
      JSON.stringify({ keys: [{ ...current, d: undefined }] }),
      JSON.stringify({ keys: [{ ...current, kid: undefined }] }),
      JSON.stringify({ keys: [{ ...current, x: undefined }] }),
      JSON.stringify({ keys: [{ ...current, crv: 'X25519' }] }),
      JSON.stringify({ keys: [current, current] }),
    ]) {
      await expect(importSigningKeys(raw)).rejects.toBeInstanceOf(SecretConfigError);
    }
    const secret: { raw?: string } = {};
    const lazy = new Ed25519TokenSigner(() => secret.raw);
    await expect(lazy.sign(CLAIMS, NOW)).rejects.toBeInstanceOf(SecretConfigError);
    secret.raw = TEST_TOKEN_SIGNING_KEYS;
    await expect(lazy.sign(CLAIMS, NOW)).resolves.toMatchObject({
      token: expect.any(String) as string,
    });
  });
});
