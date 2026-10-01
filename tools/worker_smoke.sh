#!/usr/bin/env bash
# =============================================================================
# tools/worker_smoke.sh: post-deploy smoke test of the Worker (03 §14.2, 06 §8).
#
#   tools/worker_smoke.sh <dev|staging|prod> [--base-url <url>]
#
# Runs `worker/scripts/smoke.ts` (logic in `worker/src/admin/smoke.ts`):
# GET /v1/health and GET /v1/config everywhere; on dev/staging also a
# registration with the debug attestation token, a balance read and one real
# single-card reading (hold -> reading -> ack; one AI call). The
# token is read from the DEBUG_ATTESTATION_TOKEN environment variable (never
# an argument, so it stays out of process lists and logs). The Worker honours
# it only because its deploy env sets ALLOW_DEBUG_ATTESTATION (BE20, RC86);
# prod never runs the registration step.
#
# Defaults: base URL from the environment (api[-staging].taro.vshyrochuk.com,
# http://localhost:8787 for dev); WORKER_SMOKE_BASE_URL overrides it.
# Exit codes: 0 all steps passed, 1 a step failed, 2 bad arguments.
# =============================================================================

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  echo "usage: tools/worker_smoke.sh <dev|staging|prod> [--base-url <url>]" >&2
  exit 2
}

[ "$#" -ge 1 ] || usage
ENV_NAME="$1"
shift
case "$ENV_NAME" in
  dev | staging | prod) ;;
  *) usage ;;
esac

BASE_URL="${WORKER_SMOKE_BASE_URL:-}"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --base-url)
      [ "$#" -ge 2 ] || usage
      BASE_URL="$2"
      shift 2
      ;;
    *) usage ;;
  esac
done

if [ "$ENV_NAME" = "prod" ]; then
  # Never hand the debug token to a prod smoke run (RC86).
  unset DEBUG_ATTESTATION_TOKEN
fi

args=(scripts/run.mjs smoke --env "$ENV_NAME")
if [ -n "$BASE_URL" ]; then
  args+=(--base-url "$BASE_URL")
fi

cd "$ROOT/worker"
exec node "${args[@]}"
