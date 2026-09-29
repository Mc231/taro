/**
 * What an owner-run CLI in `scripts/` may touch (RC61). `scripts/run.mjs`
 * supplies the Node implementation; tests pass stubs, so every script is
 * covered through `main([...])` without a network or a real `wrangler`.
 */
export interface CommandResult {
  readonly code: number;
  readonly stdout: string;
  readonly stderr: string;
}

export interface CliDeps {
  /** Paths are relative to `worker/`. */
  readFile(path: string): Promise<string>;
  writeFile(path: string, text: string): Promise<void>;
  out(line: string): void;
  err(line: string): void;
  /** Runs a command without a shell (arguments are passed verbatim). */
  run(command: string, args: readonly string[]): Promise<CommandResult>;
  /**
   * Process environment (Node: `process.env`). Secrets a script needs, such
   * as `DEBUG_ATTESTATION_TOKEN` for the smoke test, come from here rather
   * than argv, so they never show up in a process list or a CI log line.
   */
  readonly env?: Readonly<Record<string, string | undefined>>;
}

export type ParsedArgs =
  | {
      readonly ok: true;
      readonly flags: ReadonlySet<string>;
      readonly options: ReadonlyMap<string, string>;
    }
  | { readonly ok: false; readonly error: string };

/**
 * Parses `--flag` and `--option value` / `--option=value`. Anything not
 * declared in `flags` or `options` is an error.
 */
export function parseArgs(
  argv: readonly string[],
  spec: { readonly flags: readonly string[]; readonly options: readonly string[] },
): ParsedArgs {
  const flags = new Set<string>();
  const options = new Map<string, string>();
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i] ?? '';
    const eq = arg.indexOf('=');
    const name = eq >= 0 ? arg.slice(0, eq) : arg;
    if (spec.flags.includes(name) && eq < 0) {
      flags.add(name);
      continue;
    }
    if (!spec.options.includes(name)) {
      return { ok: false, error: `unknown argument ${arg}` };
    }
    const value = eq >= 0 ? arg.slice(eq + 1) : argv[++i];
    if (value === undefined || value === '' || value.startsWith('--')) {
      return { ok: false, error: `${name} needs a value` };
    }
    options.set(name, value);
  }
  return { ok: true, flags, options };
}
