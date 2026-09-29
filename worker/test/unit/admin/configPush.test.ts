import { describe, expect, it } from 'vitest';
import defaultsFile from '../../../config/remote_config.default.json';
import { parseArgs } from '../../../src/admin/cli';
import {
  buildKvPayloads,
  kvGetArgs,
  kvPutArgs,
  storedVersion,
  validateConfigText,
  versionIssue,
} from '../../../src/admin/configPush';
import { DEFAULT_CONFIG_FILE } from '../../../src/config/defaults';

const text = JSON.stringify(defaultsFile);

describe('validateConfigText', () => {
  it('accepts the defaults file', () => {
    const result = validateConfigText(text);
    expect(result.ok).toBe(true);
  });

  it('rejects invalid JSON', () => {
    const result = validateConfigText('{');
    expect(result).toMatchObject({ ok: false });
    expect(result.ok ? [] : result.issues[0]).toMatch(/^not valid JSON/);
  });

  it('lists every out-of-range or unknown value with its path', () => {
    const broken = {
      ...defaultsFile,
      extra: 1,
      public: { ...defaultsFile.public, 'readings.freeDaily': 0 },
      server: { ...defaultsFile.server, 'ai.maxRetries': 9 },
    };
    const result = validateConfigText(JSON.stringify(broken));
    expect(result.ok ? [] : result.issues).toEqual([
      expect.stringMatching(/^public > readings\.freeDaily: /),
      expect.stringMatching(/^server > ai\.maxRetries: /),
      expect.stringMatching(/^\(root\): Unrecognized key/),
    ]);
  });

  it('rejects stored pack credits (injected by the Worker, RC3)', () => {
    const packs = defaultsFile.public['store.packs'].map((p) => ({ ...p, credits: 99 }));
    const result = validateConfigText(
      JSON.stringify({ ...defaultsFile, public: { ...defaultsFile.public, 'store.packs': packs } }),
    );
    expect(result.ok).toBe(false);
  });
});

describe('KV payloads and wrangler arguments', () => {
  const payloads = buildKvPayloads(DEFAULT_CONFIG_FILE);

  it('writes config:server before config:public, compact and without $schema', () => {
    expect(payloads.map((p) => [p.kind, p.key, p.version])).toEqual([
      ['server', 'config:server', 1],
      ['public', 'config:public', 1],
    ]);
    const pub = JSON.parse(payloads[1]?.value ?? '') as Record<string, unknown>;
    expect(pub).toEqual(defaultsFile.public);
    expect(payloads[1]?.value).not.toContain('\n');
  });

  it('builds kv put/get commands for the env and target', () => {
    const [server] = payloads;
    if (server === undefined) {
      throw new Error('no payload');
    }
    expect(kvPutArgs(server, 'prod', 'remote')).toEqual([
      'kv',
      'key',
      'put',
      'config:server',
      server.value,
      '--binding',
      'CONFIG_KV',
      '--env',
      'prod',
      '--remote',
    ]);
    expect(kvGetArgs('config:public', 'dev', 'local')).toEqual([
      'kv',
      'key',
      'get',
      'config:public',
      '--text',
      '--binding',
      'CONFIG_KV',
      '--env',
      'dev',
      '--local',
    ]);
  });

  it('reads the stored version from wrangler output', () => {
    expect(storedVersion('{"version":4}')).toBe(4);
    expect(storedVersion('Value not found')).toBeNull();
    expect(storedVersion('null')).toBeNull();
    expect(storedVersion('{"version":"4"}')).toBeNull();
  });

  it('requires a strictly greater version', () => {
    const [server] = payloads;
    if (server === undefined) {
      throw new Error('no payload');
    }
    expect(versionIssue(server, null)).toBeNull();
    expect(versionIssue(server, 0)).toBeNull();
    expect(versionIssue(server, 1)).toBe(
      'config:server: version 1 must be greater than the stored 1',
    );
  });
});

describe('parseArgs', () => {
  const spec = { flags: ['--dry-run'], options: ['--env', '--file'] };

  it('parses flags and both option spellings', () => {
    const parsed = parseArgs(['--dry-run', '--env', 'staging', '--file=x.json'], spec);
    expect(parsed.ok && [...parsed.flags]).toEqual(['--dry-run']);
    expect(parsed.ok && Object.fromEntries(parsed.options)).toEqual({
      '--env': 'staging',
      '--file': 'x.json',
    });
  });

  it.each([
    [['--nope'], 'unknown argument --nope'],
    [['--dry-run=1'], 'unknown argument --dry-run=1'],
    [['--env'], '--env needs a value'],
    [['--env', '--dry-run'], '--env needs a value'],
    [['--file='], '--file needs a value'],
  ])('rejects %j', (argv, error) => {
    expect(parseArgs(argv, spec)).toEqual({ ok: false, error });
  });
});
