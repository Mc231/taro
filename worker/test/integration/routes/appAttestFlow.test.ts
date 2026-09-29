import { beforeAll, describe, expect, it } from 'vitest';
import { AppleAppAttestVerifier } from '../../../src/adapters/apple/AppAttestVerifier';
import { WebCrypto } from '../../../src/adapters/cf/WebCrypto';
import { toBase64 } from '../../../src/crypto/encoding';
import { callClientDataHash, registrationClientDataHash } from '../../../src/domain/challenge';
import { ATTESTATION_HEADER } from '../../../src/http/middleware/attestation';
import { InstallRepo } from '../../../src/repos/InstallRepo';
import { createHarness, type TestHarness } from '../../fakes/testDeps';
import { APP_HEADERS, testApp } from '../../helpers/app';
import { createTestCa, makeAssertion, makeAttestation, type TestCa } from '../../helpers/appAttest';
import { db } from '../../helpers/db';
import { newSecret, register, registerOk } from '../../helpers/identity';

/**
 * Registration and token refresh through the routes with the real
 * `AppleAppAttestVerifier`, trusting a test root generated here (06 §7).
 */
const crypto = new WebCrypto();
let ca: TestCa;

beforeAll(async () => {
  ca = await createTestCa();
});

function harness(): TestHarness {
  const base = createHarness();
  return createHarness({
    overrides: {
      appAttest: new AppleAppAttestVerifier({
        crypto,
        clock: base.clock,
        allowDevelopment: true,
        rootCertificatePem: ca.rootPem,
      }),
    },
  });
}

async function refresh(h: TestHarness, token: string, assertion: Uint8Array) {
  return testApp(h).request('/v1/installs/token', {
    method: 'POST',
    headers: {
      ...APP_HEADERS,
      Authorization: `Bearer ${token}`,
      [ATTESTATION_HEADER]: `aa1.${toBase64(assertion)}`,
    },
  });
}

const TOKEN_HASH = () =>
  callClientDataHash(crypto, {
    method: 'POST',
    path: '/v1/installs/token',
    body: new Uint8Array(),
    idempotencyKey: undefined,
  });

describe('App Attest end to end (03 §3.3, §3.4)', () => {
  it('registers with a real attestation, then refreshes with rising assertions only', async () => {
    const h = harness();
    const app = testApp(h);
    let keys: CryptoKeyPair | undefined;
    const reg = await registerOk(app, {
      deviceCheckToken: 'dc',
      attestation: async (challenge, installId) => {
        const att = await makeAttestation({
          ca,
          aaguid: 'appattestdevelop',
          clientDataHash: await registrationClientDataHash(crypto, challenge, installId, 'dc'),
        });
        keys = att.keys;
        return {
          type: 'app_attest',
          challenge,
          keyId: att.keyId,
          attestationObject: toBase64(att.attestationObject),
        };
      },
    });
    expect(reg.res.status).toBe(201);
    expect(reg.body.trust).toBe('high');
    const row = await new InstallRepo(db).findById(reg.installId);
    expect(row).toMatchObject({ attestEnv: 'development', attestCounter: 0 });
    if (keys === undefined) {
      throw new Error('attestation keys were not generated');
    }
    const { privateKey } = keys;

    const first = await makeAssertion({
      privateKey,
      clientDataHash: await TOKEN_HASH(),
      counter: 1,
    });
    expect((await refresh(h, reg.body.installToken, first)).status).toBe(200);
    // The same assertion again: counter not greater than stored → replay.
    expect((await refresh(h, reg.body.installToken, first)).status).toBe(403);
    const second = await makeAssertion({
      privateKey,
      clientDataHash: await TOKEN_HASH(),
      counter: 7,
    });
    expect((await refresh(h, reg.body.installToken, second)).status).toBe(200);
    expect((await new InstallRepo(db).findById(reg.installId))?.attestCounter).toBe(7);

    // An assertion over another request (wrong hash) fails.
    const wrong = await makeAssertion({
      privateKey,
      clientDataHash: new Uint8Array(32),
      counter: 8,
    });
    expect((await refresh(h, reg.body.installToken, wrong)).status).toBe(403);

    // Lost secret: the stored key proves ownership over the new registration hash (RC54).
    const again = await register(app, {
      installId: reg.installId,
      secret: newSecret(),
      deviceCheckToken: 'dc',
      attestation: async (challenge, installId) => {
        const hash = await registrationClientDataHash(crypto, challenge, installId, 'dc');
        const att = await makeAttestation({ ca, aaguid: 'appattestdevelop', clientDataHash: hash });
        return {
          type: 'app_attest',
          challenge,
          keyId: att.keyId,
          attestationObject: toBase64(att.attestationObject),
          previousKeyAssertion: toBase64(
            await makeAssertion({ privateKey, clientDataHash: hash, counter: 9 }),
          ),
        };
      },
    });
    expect(again.res.status).toBe(200);
  });

  it('rejects an attestation made for another challenge (403, nothing stored)', async () => {
    const h = harness();
    const reg = await register(testApp(h), {
      attestation: async (challenge) => {
        const att = await makeAttestation({ ca, clientDataHash: new Uint8Array(32) });
        return {
          type: 'app_attest',
          challenge,
          keyId: att.keyId,
          attestationObject: toBase64(att.attestationObject),
        };
      },
    });
    expect(reg.res.status).toBe(403);
    expect(h.metrics.points.at(-1)).toMatchObject({ event: 'attest_failed', code: 'nonce' });
    expect(await new InstallRepo(db).findById(reg.installId)).toBeNull();
  });
});
