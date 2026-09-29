import { describe, expect, it } from 'vitest';
import { main as genKeys } from '../../../scripts/gen-keys';
import { Ed25519TokenSigner, importSigningKeys } from '../../../src/adapters/cf/Ed25519TokenSigner';
import type { CliDeps, CommandResult } from '../../../src/admin/cli';
import {
  GENERATED_SECRETS,
  generateEd25519Jwk,
  kidFor,
  toEd25519Jwk,
  uuidV4,
} from '../../../src/admin/genKeys';
import { parseHmacKey, parseKeyring, parseUuidSecret } from '../../../src/crypto/keyring';
import { FixedClock } from '../../fakes/FixedClock';
import { SeededCrypto } from '../../fakes/SeededCrypto';
import { TEST_IDEMPOTENCY_KEYRING, TEST_TOKEN_SIGNING_KEYS } from '../../fakes/testDeps';

class StubCli implements CliDeps {
  readonly files = new Map<string, string>();
  readonly stdout: string[] = [];
  readonly stderr: string[] = [];

  readFile(path: string): Promise<string> {
    const text = this.files.get(path);
    return text === undefined ? Promise.reject(new Error('ENOENT')) : Promise.resolve(text);
  }

  writeFile(): Promise<void> {
    return Promise.reject(new Error('gen-keys never writes files'));
  }

  out(line: string): void {
    this.stdout.push(line);
  }

  err(line: string): void {
    this.stderr.push(line);
  }

  run(): Promise<CommandResult> {
    return Promise.reject(new Error('gen-keys runs no commands'));
  }

  json(): Record<string, string> {
    expect(this.stdout).toHaveLength(1);
    return JSON.parse(this.stdout[0] ?? '') as Record<string, string>;
  }
}

const clock = new FixedClock('2026-09-29T08:00:00Z');

async function run(argv: string[], cli = new StubCli()) {
  const code = await genKeys(argv, cli, new SeededCrypto(42), clock);
  return { code, cli };
}

describe('scripts/gen-keys.ts main([...]) (Sprint 6.0, 03 §11)', () => {
  it('prints every staging secret as JSON on stdout only, each accepted by its parser', async () => {
    const { code, cli } = await run(['--env', 'staging']);
    expect(code).toBe(0);
    expect(cli.stderr).toEqual([]);
    const out = cli.json();
    expect(Object.keys(out)).toEqual([...GENERATED_SECRETS]);

    const signer = new Ed25519TokenSigner(() => out['TOKEN_SIGNING_KEYS']);
    const { token } = await signer.sign(
      { sub: 'i', gen: 1, trust: 'high', plat: 'ios' },
      clock.now(),
    );
    expect(await signer.verify(token, clock.now())).toMatchObject({ ok: true, expired: false });
    expect((await importSigningKeys(out['TOKEN_SIGNING_KEYS'])).currentKid).toBe('k20260929');

    expect(parseKeyring(out['IDEMPOTENCY_ENC_KEY'], 'IDEMPOTENCY_ENC_KEY').current.kid).toBe(
      'k20260929',
    );
    for (const name of [
      'CHALLENGE_KEY',
      'IP_HASH_KEY',
      'PLAY_ACCOUNT_KEY',
      'DEVICE_KEY_SECRET',
      'TRANSFER_TOKEN_KEY',
      'DEBUG_ATTESTATION_TOKEN',
    ]) {
      expect(out[name], name).toMatch(/^[A-Za-z0-9_-]{43}$/);
      expect(parseHmacKey(out[name], name)).toHaveLength(43);
    }
    expect(parseUuidSecret(out['APPLE_ACCOUNT_NS'], 'APPLE_ACCOUNT_NS')).toMatch(
      /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/,
    );
    expect(new Set(Object.values(out)).size).toBe(GENERATED_SECRETS.length);
  });

  it('never emits DEBUG_ATTESTATION_TOKEN for prod (RC86)', async () => {
    const { code, cli } = await run(['--env', 'prod']);
    expect(code).toBe(0);
    expect(Object.keys(cli.json())).not.toContain('DEBUG_ATTESTATION_TOKEN');
    expect(Object.keys(cli.json())).toHaveLength(GENERATED_SECRETS.length - 1);

    const refused = await run(['--env', 'prod', '--only', 'CHALLENGE_KEY,DEBUG_ATTESTATION_TOKEN']);
    expect(refused.code).toBe(1);
    expect(refused.cli.stdout).toEqual([]);
    expect(refused.cli.stderr).toEqual([
      'DEBUG_ATTESTATION_TOKEN must never be set in prod (RC86)',
    ]);
  });

  it('--only and --kid pick the secrets and the key ID', async () => {
    const { code, cli } = await run([
      '--env',
      'dev',
      '--only',
      'IDEMPOTENCY_ENC_KEY, IP_HASH_KEY',
      '--kid',
      'k2',
    ]);
    expect(code).toBe(0);
    const out = cli.json();
    expect(Object.keys(out)).toEqual(['IDEMPOTENCY_ENC_KEY', 'IP_HASH_KEY']);
    expect(out['IDEMPOTENCY_ENC_KEY']).toMatch(/^k2:[A-Za-z0-9_-]{43}$/);
  });

  it('--rotate prepends new keyring keys and keeps only the previous current one', async () => {
    const cli = new StubCli();
    cli.files.set(
      'current.json',
      JSON.stringify({
        TOKEN_SIGNING_KEYS: TEST_TOKEN_SIGNING_KEYS,
        IDEMPOTENCY_ENC_KEY: TEST_IDEMPOTENCY_KEYRING,
        CHALLENGE_KEY: 'ignored-not-rotatable-000000000',
      }),
    );
    const { code } = await run(['--env', 'staging', '--rotate', 'current.json'], cli);
    expect(code).toBe(0);
    const out = cli.json();
    expect(Object.keys(out)).toEqual(['TOKEN_SIGNING_KEYS', 'IDEMPOTENCY_ENC_KEY']);
    const jwks = JSON.parse(out['TOKEN_SIGNING_KEYS'] ?? '') as { keys: { kid: string }[] };
    expect(jwks.keys.map((k) => k.kid)).toEqual(['k20260929', 'kt2']);
    expect(out['IDEMPOTENCY_ENC_KEY']?.split(',').map((e) => e.split(':')[0])).toEqual([
      'k20260929',
      'kt2',
    ]);
    const ring = parseKeyring(out['IDEMPOTENCY_ENC_KEY'], 'IDEMPOTENCY_ENC_KEY');
    expect(ring.get('kt2')).toBeDefined();

    const empty = new StubCli();
    empty.files.set('none.json', '{}');
    expect((await run(['--env', 'dev', '--rotate', 'none.json'], empty)).code).toBe(0);
    const fresh = empty.json();
    expect(
      (JSON.parse(fresh['TOKEN_SIGNING_KEYS'] ?? '') as { keys: unknown[] }).keys,
    ).toHaveLength(1);
    expect(fresh['IDEMPOTENCY_ENC_KEY']?.split(',')).toHaveLength(1);
  });

  it('refuses a rotation that reuses the current kid or reads a bad file', async () => {
    const cases: [string, string, string[]][] = [
      [
        JSON.stringify({ TOKEN_SIGNING_KEYS: TEST_TOKEN_SIGNING_KEYS }),
        'kid kt2 is already the current TOKEN_SIGNING_KEYS kid',
        ['--kid', 'kt2'],
      ],
      [
        JSON.stringify({ IDEMPOTENCY_ENC_KEY: TEST_IDEMPOTENCY_KEYRING }),
        'kid kt2 is already the current IDEMPOTENCY_ENC_KEY kid',
        ['--kid', 'kt2', '--only', 'IDEMPOTENCY_ENC_KEY'],
      ],
      [JSON.stringify({ TOKEN_SIGNING_KEYS: '{' }), 'previous TOKEN_SIGNING_KEYS is not JSON', []],
      [
        JSON.stringify({ TOKEN_SIGNING_KEYS: '{"keys":[]}' }),
        'previous TOKEN_SIGNING_KEYS has no keys',
        [],
      ],
      ['[1]', '--rotate prev.json is not a readable JSON object', []],
      ['null', '--rotate prev.json is not a readable JSON object', []],
      ['not json', '--rotate prev.json is not a readable JSON object', []],
    ];
    for (const [file, message, extra] of cases) {
      const cli = new StubCli();
      cli.files.set('prev.json', file);
      const { code } = await run(['--env', 'staging', '--rotate', 'prev.json', ...extra], cli);
      expect({ code, stderr: cli.stderr, stdout: cli.stdout }).toEqual({
        code: 1,
        stderr: [message],
        stdout: [],
      });
    }
    const missing = await run(['--env', 'staging', '--rotate', 'missing.json']);
    expect(missing.cli.stderr).toEqual(['--rotate missing.json is not a readable JSON object']);
  });

  it('rejects bad usage with exit code 2', async () => {
    for (const argv of [
      [],
      ['--env', 'qa'],
      ['--env', 'dev', '--only', 'NOPE'],
      ['--env', 'dev', '--kid', 'bad kid!'],
      ['--env', 'dev', '--force'],
    ]) {
      const { code, cli } = await run(argv);
      expect({ argv, code }).toEqual({ argv, code: 2 });
      expect(cli.stderr.at(-1)).toContain('usage: gen-keys');
      expect(cli.stdout).toEqual([]);
    }
  });

  it('reports an unexpected key-generation failure without details', async () => {
    const cli = new StubCli();
    const code = await genKeys(['--env', 'dev'], cli, new SeededCrypto(1), clock, () =>
      Promise.reject(new Error('secret-bearing internal message')),
    );
    expect(code).toBe(1);
    expect(cli.stderr).toEqual(['gen-keys failed']);
  });

  it('defaults to the real WebCrypto and system clock', async () => {
    const cli = new StubCli();
    expect(await genKeys(['--env', 'dev', '--only', 'APPLE_ACCOUNT_NS'], cli)).toBe(0);
    expect(cli.json()['APPLE_ACCOUNT_NS']).toMatch(/^[0-9a-f-]{36}$/);
  });
});

describe('genKeys helpers', () => {
  it('kidFor, uuidV4 and the Ed25519 JWK shape', async () => {
    expect(kidFor(new Date('2027-01-02T23:59:59Z'))).toBe('k20270102');
    expect(uuidV4(new SeededCrypto(3))).toMatch(
      /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/,
    );
    const jwk = await generateEd25519Jwk('kx');
    expect(jwk).toMatchObject({ kty: 'OKP', crv: 'Ed25519', kid: 'kx' });
    expect(() => toEd25519Jwk('kx', { x: 'a' })).toThrow('Ed25519 export did not return x and d');
    expect(() => toEd25519Jwk('kx', { d: 'a' })).toThrow('Ed25519 export did not return x and d');
  });
});
