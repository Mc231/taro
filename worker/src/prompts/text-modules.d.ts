// Prompt templates (`prompts/**/*.md`, 03 §9.2) are imported as text: wrangler
// bundles them through the `Text` module rule in wrangler.toml (also used by
// vitest-pool-workers), and `scripts/run.mjs` gives esbuild the `text` loader.
declare module '*.md' {
  const text: string;
  export default text;
}
