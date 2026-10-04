#!/usr/bin/env bash
# One-time prod Worker secret setup (Phase 10 / 22, 03 §11). Run by the owner:
#   bash tools/ci/set_prod_worker_secrets.sh
# Generates the prod keys (gen-keys + REPORT_ENC_KEY), adds the vendor secrets
# from ~/pet/secure/taro and ~/.zshrc, uploads them with `wrangler secret bulk`,
# stores a copy in the GPG bundle (worker.prod_worker_secrets_json_base64) and
# deletes the temp file. Prints key names only, never values.
set -euo pipefail

repo="$(cd "$(dirname "$0")/../.." && pwd)"
secure="$HOME/pet/secure/taro"
eval "$(grep -E '^export (TARO_CLAUDEFLRE_TOKEN|TARO_SECRETS|TARO_OPEN_AI_KEY)=' "$HOME/.zshrc")"
export CLOUDFLARE_API_TOKEN="$TARO_CLAUDEFLRE_TOKEN"

umask 077
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

cd "$repo/worker"
npm run --silent gen-keys -- --env prod 2>/dev/null \
  | OPENAI="$TARO_OPEN_AI_KEY" SECURE="$secure" OUT="$tmp" python3 -c '
import base64, json, os, secrets, sys
d = json.load(sys.stdin)
s = os.environ["SECURE"] + "/"
d["REPORT_ENC_KEY"] = "k20261004:" + base64.urlsafe_b64encode(secrets.token_bytes(32)).decode().rstrip("=")
d["OPENAI_API_KEY"] = os.environ["OPENAI"]
d["APPLE_TEAM_ID"] = "M3FHKUJ7Z3"
d["APPLE_ASC_KEY_ID"] = "822W5796Q2"
d["APPLE_ASC_ISSUER_ID"] = "c4b7ee46-0010-43cd-b67e-84d0c6268c9f"
d["APPLE_ASC_PRIVATE_KEY"] = open(s + "SubscriptionKey_822W5796Q2.p8").read()
d["APPLE_DEVICECHECK_KEY_ID"] = "GR7LBHKHFS"
d["APPLE_DEVICECHECK_PRIVATE_KEY"] = open(s + "AuthKey_GR7LBHKHFS.p8").read()
d["GOOGLE_SERVICE_ACCOUNT_JSON"] = open(s + "taro-worker-sa.json").read()
d["GOOGLE_PUBSUB_AUDIENCE"] = "https://api.taro.vshyrochuk.com/v1/webhooks/googleplay"
d["GOOGLE_PUBSUB_SA"] = "taro-pubsub-push@taro-app-prod.iam.gserviceaccount.com"
assert "DEBUG_ATTESTATION_TOKEN" not in d  # never on prod (RC86)
json.dump(d, open(os.environ["OUT"], "w"))
print("prepared:", ", ".join(sorted(d)))
'

npx wrangler secret bulk "$tmp" --env prod
cd "$repo"
SECRETS_PASSPHRASE="$TARO_SECRETS" tools/secrets-manager.sh set-file worker prod_worker_secrets_json_base64 "$tmp" >/dev/null
SECRETS_PASSPHRASE="$TARO_SECRETS" tools/secrets-manager.sh encrypt >/dev/null

# Staging also lacks REPORT_ENC_KEY (gen-keys does not generate it yet).
cd "$repo/worker"
printf 'k20261004:%s' "$(python3 -c 'import base64,secrets;print(base64.urlsafe_b64encode(secrets.token_bytes(32)).decode().rstrip("="))')" \
  | npx wrangler secret put REPORT_ENC_KEY --env staging
echo "done: prod Worker secrets set, bundle updated, staging REPORT_ENC_KEY set"
