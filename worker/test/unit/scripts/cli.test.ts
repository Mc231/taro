import { describe, expect, it } from 'vitest';
import defaultsFile from '../../../config/remote_config.default.json';
import committedSchema from '../../../config/remote_config.schema.json';
import { main as configPush, DEFAULT_FILE } from '../../../scripts/config-push';
import { main as exportSchema } from '../../../scripts/export-config-schema';
import type { CliDeps, CommandResult } from '../../../src/admin/cli';
import { CONFIG_JSON_SCHEMA_PATH } from '../../../src/admin/configSchemaExport';

/** Stubbed file system and command runner for `main([...])` (RC61). */
class StubCli implements CliDeps {
  readonly files = new Map<string, string>([
    [DEFAULT_FILE, JSON.stringify(defaultsFile)],
    [CONFIG_JSON_SCHEMA_PATH, `${JSON.stringify(committedSchema, null, 2)}\n`],
  ]);
  readonly written = new Map<string, string>();
  readonly stdout: string[] = [];
  readonly stderr: string[] = [];
  readonly commands: string[][] = [];
  /** Result per `kv key <verb> <key>`; default exit 0 with "Value not found". */
  readonly results = new Map<string, CommandResult>();

  readFile(path: string): Promise<string> {
    const text = this.files.get(path);
    return text === undefined ? Promise.reject(new Error('ENOENT')) : Promise.resolve(text);
  }

  writeFile(path: string, text: string): Promise<void> {
    this.written.set(path, text);
    return Promise.resolve();
  }

  out(line: string): void {
    this.stdout.push(line);
  }

  err(line: string): void {
    this.stderr.push(line);
  }

  run(command: string, args: readonly string[]): Promise<CommandResult> {
    this.commands.push([command, ...args]);
    const id = `${args[3] ?? ''} ${args[4] ?? ''}`;
    return Promise.resolve(
      this.results.get(id) ?? { code: 0, stdout: 'Value not found', stderr: '' },
    );
  }
}

describe('scripts/config-push.ts main([...])', () => {
  it('validates, checks stored versions and puts server then public', async () => {
    const cli = new StubCli();
    expect(await configPush(['--env', 'staging'], cli)).toBe(0);
    expect(cli.commands.map((c) => c.slice(0, 6).join(' '))).toEqual([
      'npx wrangler kv key get config:server',
      'npx wrangler kv key get config:public',
      'npx wrangler kv key put config:server',
      'npx wrangler kv key put config:public',
    ]);
    expect(JSON.parse(cli.commands[3]?.[6] ?? '')).toEqual(defaultsFile.public);
    expect(cli.commands[2]?.slice(-5)).toEqual([
      '--binding',
      'CONFIG_KV',
      '--env',
      'staging',
      '--remote',
    ]);
    expect(cli.stdout).toEqual([
      expect.stringMatching(/^pushed <config:server v1, \d+ bytes> to staging \(remote\)$/),
      expect.stringMatching(/^pushed <config:public v1, \d+ bytes> to staging \(remote\)$/),
    ]);
  });

  it('prints the commands and writes nothing with --dry-run', async () => {
    const cli = new StubCli();
    expect(await configPush(['--env', 'prod', '--dry-run'], cli)).toBe(0);
    expect(cli.commands).toEqual([]);
    expect(cli.stdout[0]).toMatch(
      /^\[dry-run\] wrangler kv key put config:server <config:server v1, \d+ bytes> --binding CONFIG_KV --env prod --remote$/,
    );
    expect(cli.stdout.at(-1)).toContain('nothing written');
  });

  it('refuses a version that is not above the stored one unless --force', async () => {
    const cli = new StubCli();
    cli.results.set('get config:public', { code: 0, stdout: '{"version":3}', stderr: '' });
    cli.results.set('get config:server', { code: 1, stdout: '', stderr: 'auth' });
    expect(await configPush(['--env', 'prod'], cli)).toBe(1);
    expect(cli.stderr[0]).toBe('config:public: version 1 must be greater than the stored 3');
    expect(cli.commands.some((c) => c[4] === 'put')).toBe(false);

    const forced = new StubCli();
    forced.results.set('get config:public', { code: 0, stdout: '{"version":3}', stderr: '' });
    expect(await configPush(['--env', 'prod', '--force', '--local'], forced)).toBe(0);
    expect(forced.commands.every((c) => c[4] === 'put' && c.at(-1) === '--local')).toBe(true);
  });

  it('reads --file and reports every schema issue', async () => {
    const cli = new StubCli();
    cli.files.set('bad.json', JSON.stringify({ public: {}, server: {} }));
    expect(await configPush(['--env', 'dev', '--file', 'bad.json'], cli)).toBe(1);
    expect(cli.stderr[0]).toBe('bad.json is invalid:');
    expect(cli.stderr.length).toBeGreaterThan(10);
  });

  it('fails when the file cannot be read or wrangler fails', async () => {
    const missing = new StubCli();
    expect(await configPush(['--env', 'dev', '--file=nope.json'], missing)).toBe(1);
    expect(missing.stderr[0]).toBe('cannot read nope.json: ENOENT');

    const failing = new StubCli();
    failing.results.set('put config:server', { code: 1, stdout: '', stderr: ' not authorized \n' });
    expect(await configPush(['--env', 'staging'], failing)).toBe(1);
    expect(failing.stderr).toEqual([
      'wrangler kv key put config:server failed (exit 1):',
      'not authorized',
    ]);
    expect(failing.commands.filter((c) => c[4] === 'put')).toHaveLength(1);
  });

  it.each([[[]], [['--env', 'qa']], [['--env', 'dev', '--yes']]])(
    'exits 2 on usage errors %j',
    async (argv) => {
      const cli = new StubCli();
      expect(await configPush(argv, cli)).toBe(2);
      expect(cli.stderr.join('\n')).toContain('usage: config-push');
    },
  );
});

describe('scripts/export-config-schema.ts main([...])', () => {
  it('writes the schema export', async () => {
    const cli = new StubCli();
    expect(await exportSchema([], cli)).toBe(0);
    expect(cli.written.get(CONFIG_JSON_SCHEMA_PATH)).toBe(cli.files.get(CONFIG_JSON_SCHEMA_PATH));
    expect(cli.stdout).toEqual([`wrote ${CONFIG_JSON_SCHEMA_PATH}`]);
  });

  it('--check passes for the committed file and fails when stale or missing', async () => {
    const cli = new StubCli();
    expect(await exportSchema(['--check'], cli)).toBe(0);

    cli.files.set(CONFIG_JSON_SCHEMA_PATH, '{}\n');
    expect(await exportSchema(['--check'], cli)).toBe(1);
    cli.files.delete(CONFIG_JSON_SCHEMA_PATH);
    expect(await exportSchema(['--check'], cli)).toBe(1);
    expect(cli.stderr.at(-1)).toContain('is stale');
  });

  it('exits 2 on unknown arguments', async () => {
    const cli = new StubCli();
    expect(await exportSchema(['--write'], cli)).toBe(2);
  });
});
