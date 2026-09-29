import { describe, expect, it } from 'vitest';
import committed from '../../openapi/openapi.json';
import { main as exportOpenApi } from '../../scripts/export-openapi';
import type { CliDeps, CommandResult } from '../../src/admin/cli';
import { API_VERSION, documentDeps, OPENAPI_PATH, renderOpenApi } from '../../src/admin/openapi';

/** The committed document, re-serialised exactly as the exporter writes it. */
const committedText = `${JSON.stringify(committed, null, 2)}\n`;

class StubCli implements CliDeps {
  readonly files = new Map<string, string>();
  readonly written = new Map<string, string>();
  readonly stdout: string[] = [];
  readonly stderr: string[] = [];

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

  run(): Promise<CommandResult> {
    return Promise.reject(new Error('export-openapi runs no commands'));
  }
}

describe('openapi/openapi.json (03 BE1, §14.2; RC38)', () => {
  it('equals the document generated from the zod routes (run `npm run openapi` on drift)', () => {
    expect(renderOpenApi()).toBe(committedText);
  });

  it('is OpenAPI 3.1 for the /v1 surface with the install-token scheme', () => {
    expect(committed.openapi).toBe('3.1.0');
    expect(committed.info.version).toBe(API_VERSION);
    expect(Object.keys(committed.paths).every((path) => path.startsWith('/v1/'))).toBe(true);
    expect(committed.components.securitySchemes.installToken).toMatchObject({
      type: 'http',
      scheme: 'bearer',
    });
  });

  it('builds the route table from document-only deps that reject when reached', async () => {
    await expect(documentDeps().clock.now()).rejects.toThrow(/document only/);
  });
});

describe('scripts/export-openapi.ts main([...])', () => {
  it('writes the document', async () => {
    const cli = new StubCli();
    expect(await exportOpenApi([], cli)).toBe(0);
    expect(cli.written.get(OPENAPI_PATH)).toBe(committedText);
    expect(cli.stdout).toEqual([`wrote ${OPENAPI_PATH}`]);
  });

  it('--check passes on the committed file and fails when stale or missing', async () => {
    const cli = new StubCli();
    cli.files.set(OPENAPI_PATH, committedText);
    expect(await exportOpenApi(['--check'], cli)).toBe(0);
    expect(cli.stdout).toEqual([`${OPENAPI_PATH} is up to date`]);

    cli.files.set(OPENAPI_PATH, '{}\n');
    expect(await exportOpenApi(['--check'], cli)).toBe(1);
    cli.files.delete(OPENAPI_PATH);
    expect(await exportOpenApi(['--check'], cli)).toBe(1);
    expect(cli.stderr).toEqual([
      `${OPENAPI_PATH} is stale; run npm run openapi`,
      `${OPENAPI_PATH} is stale; run npm run openapi`,
    ]);
    expect(cli.written.size).toBe(0);
  });

  it('rejects unknown arguments with exit code 2', async () => {
    const cli = new StubCli();
    expect(await exportOpenApi(['--write'], cli)).toBe(2);
    expect(cli.stderr[0]).toContain('usage: export-openapi');
  });
});
