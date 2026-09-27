// Types `exports` from "cloudflare:workers" in tests. `wrangler types` does not
// emit GlobalProps for a multi-env config, so it is declared here.
declare namespace Cloudflare {
  interface GlobalProps {
    mainModule: typeof import('../src/index');
  }
}
