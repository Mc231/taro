import type { CliDeps, CommandResult } from '../../src/admin/cli';
import { STATEMENT_SEPARATOR } from '../../src/admin/d1';
import { db } from './db';

/**
 * `CliDeps` whose `run` plays `npx wrangler d1 execute DB … --json --command
 * <sql>` against the test's real D1 (miniflare): statements are split on
 * `STATEMENT_SEPARATOR` and the output has wrangler's JSON shape. Hooks let a
 * test fail a call, run only part of a command, or change the database
 * between two calls (a race).
 */
export class D1StubCli implements CliDeps {
  readonly stdout: string[] = [];
  readonly stderr: string[] = [];
  /** Every command's arguments, in order. */
  readonly calls: string[][] = [];
  /** Returns a result to use instead of executing (called with the call index). */
  intercept: ((index: number, statements: string[]) => Promise<CommandResult | null>) | null = null;

  constructor(readonly env: Readonly<Record<string, string | undefined>> = {}) {}

  readFile(): Promise<string> {
    return Promise.reject(new Error('reads no files'));
  }

  writeFile(): Promise<void> {
    return Promise.reject(new Error('writes no files'));
  }

  out(line: string): void {
    this.stdout.push(line);
  }

  err(line: string): void {
    this.stderr.push(line);
  }

  /** Output and errors together, for "never prints a full ID" assertions. */
  get text(): string {
    return [...this.stdout, ...this.stderr].join('\n');
  }

  /** The SQL-writing calls (anything but a pure SELECT). */
  get writes(): string[][] {
    return this.calls.filter((args) => !(args.at(-1) ?? '').trimStart().startsWith('SELECT'));
  }

  async run(command: string, args: readonly string[]): Promise<CommandResult> {
    this.calls.push([...args]);
    if (command !== 'npx' || args.slice(0, 4).join(' ') !== 'wrangler d1 execute DB') {
      return { code: 127, stdout: '', stderr: `unexpected command ${command} ${args.join(' ')}` };
    }
    const sql = args[args.indexOf('--command') + 1] ?? '';
    const statements = sql.split(STATEMENT_SEPARATOR);
    const intercepted = await this.intercept?.(this.calls.length - 1, statements);
    if (intercepted !== null && intercepted !== undefined) {
      return intercepted;
    }
    return D1StubCli.execute(statements);
  }

  static async execute(statements: readonly string[]): Promise<CommandResult> {
    const out: unknown[] = [];
    try {
      for (const statement of statements) {
        const result = await db.prepare(statement).all();
        out.push({
          results: result.results,
          success: true,
          meta: { changes: result.meta.changes },
        });
      }
    } catch (err) {
      return { code: 1, stdout: '', stderr: (err as Error).message };
    }
    return { code: 0, stdout: JSON.stringify(out), stderr: '' };
  }
}
