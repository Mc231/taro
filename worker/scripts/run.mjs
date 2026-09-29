// @ts-check
// Runs an owner CLI `scripts/<name>.ts` under Node (RC61): esbuild bundles it
// (dependencies stay external), then its `main(argv, deps)` gets the real
// file system, stdout/stderr and a shell-less process runner. Kept tiny and
// outside the coverage gate: all logic lives in the covered `main`.
//   node scripts/run.mjs config-push --env staging --dry-run
import { spawn } from 'node:child_process';
import { existsSync } from 'node:fs';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { pathToFileURL } from 'node:url';
import { build } from 'esbuild';

const root = path.resolve(import.meta.dirname, '..');
const [name = '', ...argv] = process.argv.slice(2);
const entry = path.join(root, 'scripts', `${name}.ts`);
if (!/^[a-z][a-z-]*$/.test(name) || !existsSync(entry)) {
  process.stderr.write(`usage: node scripts/run.mjs <script> [args…] (no scripts/${name}.ts)\n`);
  process.exit(2);
}

const outfile = path.join(root, 'dist', 'scripts', `${name}.mjs`);
await mkdir(path.dirname(outfile), { recursive: true });
await build({
  entryPoints: [entry],
  outfile,
  bundle: true,
  platform: 'node',
  format: 'esm',
  packages: 'external',
  logLevel: 'warning',
});

/** @type {import('../src/admin/cli').CliDeps} */
const deps = {
  env: process.env,
  readFile: (file) => readFile(path.resolve(root, file), 'utf8'),
  writeFile: (file, text) => writeFile(path.resolve(root, file), text, 'utf8'),
  out: (line) => {
    process.stdout.write(`${line}\n`);
  },
  err: (line) => {
    process.stderr.write(`${line}\n`);
  },
  run: (command, args) =>
    new Promise((resolve) => {
      const child = spawn(command, [...args], { cwd: root, stdio: ['ignore', 'pipe', 'pipe'] });
      let stdout = '';
      let stderr = '';
      child.stdout.on('data', (chunk) => {
        stdout += String(chunk);
      });
      child.stderr.on('data', (chunk) => {
        stderr += String(chunk);
      });
      child.on('error', (error) => {
        resolve({ code: 127, stdout, stderr: error.message });
      });
      child.on('close', (code) => {
        resolve({ code: code ?? 1, stdout, stderr });
      });
    }),
};

/** @type {unknown} */
const loaded = await import(pathToFileURL(outfile).href);
const script =
  /** @type {{ main: (argv: readonly string[], deps: import('../src/admin/cli').CliDeps) => Promise<number> }} */ (
    loaded
  );
process.exitCode = await script.main(argv, deps);
