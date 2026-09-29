// Vite `?raw` imports (file text as a string), used by tests that compare
// committed config files with the code (e.g. wrangler.toml cron triggers).
declare module '*?raw' {
  const text: string;
  export default text;
}
