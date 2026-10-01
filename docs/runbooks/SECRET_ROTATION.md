# Secret rotation runbook

Scope per `06_QUALITY_TESTING_CI.md` §13; secret names per `03_BACKEND_WORKER.md` §11 and GLOSSARY §13. **Never write secret values here**, in an issue, in a commit or in a CI log. First version: Phase 6 Sprint 6.0/6.5 (Worker secrets); store and signing secrets are completed in Phase 10.

## General procedure

1. **Create** the new value: generated secrets with `worker/scripts/gen-keys.ts` (below), vendor keys in their console.
2. **Store** it in the bundle: `SECRETS_PASSPHRASE=$TARO_SECRETS tools/secrets-manager.sh decrypt`, edit `.secrets/secrets.json`, then `… encrypt` (06 QA10). Commit only `.secrets/secrets.json.gpg`.
3. **Set** it on the Worker, staging first: `npx wrangler secret put <NAME> --env staging` (paste on stdin; never as an argument). Setting a secret deploys a new Worker version immediately.
4. **Verify**: `DEBUG_ATTESTATION_TOKEN=… tools/worker_smoke.sh staging`, then the same for prod (`tools/worker_smoke.sh prod`).
5. **Revoke** the old value only after its grace period (per secret below) and after prod is verified.
6. Note the rotation in the drill log (date and secret name only).

### Staging smoke

`tools/worker_smoke.sh <env>` (or `cd worker && npm run smoke -- --env <env> [--base-url <url>]`) checks `GET /v1/health` and `GET /v1/config` everywhere. On dev and staging, when the environment variable `DEBUG_ATTESTATION_TOKEN` holds the target's debug attestation token (bundle key `worker.staging_debug_attestation_token`; never pass it as an argument), it also runs: challenge → `POST /v1/installs` (a fresh smoke install) → `GET /v1/balance` → `POST /v1/readings/holds` (spread `single`) → `POST /v1/readings` (`major_00` upright, "What should I focus on this week?", `en`; `Idempotency-Key == clientReadingId`, `X-Taro-AI-Consent` = the config's `ai.consentVersion`) → `POST /v1/readings/{id}/ack` (`204`). The reading line reports status, latency, classification, charge source, `promptVersion`, the balance after and the first 80 characters of the overview; the serving model is not on the wire (see `reading_completed` in `wrangler tail`). One real AI call per run, charged to the smoke install's free reading. A declined reading, `402` or `503` (`AI_UNAVAILABLE`, `AI_BUDGET_EXHAUSTED`, `READINGS_DISABLED`) exits 1. Prod never runs the install or reading steps (RC86). Tokens, the install secret and the debug token are never printed.

```bash
DEBUG_ATTESTATION_TOKEN="$(SECRETS_PASSPHRASE=$TARO_SECRETS tools/secrets-manager.sh get worker staging_debug_attestation_token)" tools/worker_smoke.sh staging
```

Generating Worker secrets (prints one JSON object on stdout only; pipe it, do not save it in the repo):

```bash
cd worker
npm run gen-keys -- --env staging                      # every generated secret, first setup
npm run gen-keys -- --env prod                         # prod: never includes DEBUG_ATTESTATION_TOKEN (RC86)
npm run gen-keys -- --env prod --only CHALLENGE_KEY    # one secret
npm run gen-keys -- --env prod --rotate "$RUNNER_TEMP/current.json"   # keyrings: prepend a new key
```

`--rotate <file>` takes a JSON object with the **current** `TOKEN_SIGNING_KEYS` and `IDEMPOTENCY_ENC_KEY` (for example extracted from the decrypted bundle into a temp file with mode 600, deleted afterwards) and prints both with a new current key first and the previous current key second. The key ID defaults to `k<yyyymmdd>` (`--kid` overrides it).

## Worker secrets (03 §11)

| Secret | Format | How to rotate | Grace period |
|---|---|---|---|
| `TOKEN_SIGNING_KEYS` | Ed25519 JWKS, first key signs | `gen-keys --rotate`, `secret put`; tokens signed by the old key still verify with the second entry. After **7 days** (token TTL) remove the second entry and `secret put` again. | 7 days |
| `IDEMPOTENCY_ENC_KEY` | `kid:base64url32,…`, first encrypts | `gen-keys --rotate`, `secret put`; stored replay bodies stay readable with the previous key. Remove the previous key after **7 days** (row TTL). | 7 days |
| `CHALLENGE_KEY` | ≥ 16 chars (base64url 32 bytes) | `gen-keys --only CHALLENGE_KEY`, `secret put`. Challenges issued in the last 5 minutes fail once; clients fetch a new one. | 5 minutes |
| `IP_HASH_KEY` | same | Rotate at will; KV soft counters restart (≤ 48 h TTL). | none |
| `DEVICE_KEY_SECRET` | same | **Avoid**: `device_key_hash` rows would stop matching, so a reinstalled Android device looks new for today's free reading and rewarded cap (03 §3.7). Rotate only after a leak. | none |
| `PLAY_ACCOUNT_KEY` | same | **Do not rotate** unless leaked: it derives `playAccountId` (`obfuscatedAccountId`) bound to past Google purchases (RC9). After a leak, rotate and accept that old purchases fall back to first-claim-wins. | — |
| `APPLE_ACCOUNT_NS` | UUID | **Never rotate**: it derives every `appAccountToken` (RC9). It is a namespace, not a key; a leak alone grants nothing. | — |
| `TRANSFER_TOKEN_KEY` | ≥ 16 chars | `gen-keys --only TRANSFER_TOKEN_KEY`; open support transfer tokens become invalid (support re-issues them, 03 §6.6). | none |
| `REPORT_ENC_KEY` | keyring (Phase 8) | Added in Phase 8 with its keyring format; reports are kept 90 days. | 90 days |
| `DEBUG_ATTESTATION_TOKEN` | ≥ 16 chars, **dev/staging only** | `gen-keys --env staging --only DEBUG_ATTESTATION_TOKEN`, `secret put --env staging`, update `worker.staging_debug_attestation_token` in the bundle (used by the staging smoke test). Never set it on prod (`check_worker_env.py`, RC86). | none |
| `ALERT_WEBHOOK_URL` | URL | Create a new incoming webhook, `secret put`, send a test alert, delete the old webhook. | none |
| `ANTHROPIC_API_KEY` | vendor, optional (RC97) | See "Anthropic API key". | minutes |
| `OPENAI_API_KEY` | vendor, optional (RC97) | See "OpenAI API key". | minutes |
| `APPLE_DEVICECHECK_KEY_ID` / `_PRIVATE_KEY`, `APPLE_ASC_*`, `GOOGLE_*` | vendor | Phase 10 (sections below). | — |

## Anthropic API key

Per workspace (`taro-staging`, `taro-prod`): create a new key in the Anthropic Console under the same workspace, `npx wrangler secret put ANTHROPIC_API_KEY --env <env>`, verify with a staging reading (Phase 8 smoke step), then revoke the old key in the Console. Keep the workspace spend limits unchanged (03 §10.2).

Either AI key may be absent (RC97, 03 §11): a tier routed to a provider without a key is disabled (`503 AI_UNAVAILABLE`, alert `ai_provider_unavailable`). Set the new key before revoking the old one, so a tier never loses its provider; if a key is revoked by mistake, route the affected tiers to the other provider with `ai.provider.*` (it must be in `ai.disclosedProviders`) until the new key is set.

## OpenAI API key

Per project (`taro-staging`, `taro-prod`, Phase 8 Sprint 8.0): create a new project API key in the OpenAI platform dashboard under the same project, `npx wrangler secret put OPENAI_API_KEY --env <env>`, update the copy in the `.secrets/` bundle, verify with a staging reading routed to OpenAI (Phase 8 smoke step), then revoke the old key in the dashboard. Keep the project monthly spend limits unchanged (03 §10.2). Set the key only for an environment whose config may route to OpenAI and only while `openai` is in `ai.disclosedProviders`.

## App Store Server API key

Phase 10: new In-App Purchase key in App Store Connect → `APPLE_ASC_KEY_ID`, `APPLE_ASC_PRIVATE_KEY` (`secret put`), verify a sandbox purchase on staging, revoke the old key.

## App Store Connect API key

Phase 10: used by fastlane only (bundle `shared.app_store_connect_api_*`); create a new key, update the bundle, run a `deploy-ios.yml` dry lane, revoke the old key.

## Play service account

Phase 10: add a new JSON key to the service account in Google Cloud, update `GOOGLE_SERVICE_ACCOUNT_JSON` (`secret put`) and the bundle, verify Play Integrity decode and a test purchase on staging, delete the old key. The Worker caches the OAuth token in `CACHE_KV` for up to 50 minutes; it expires on its own.

## Upload keystore

Never rotated. If it is lost or leaked, use the Play Console upload-key reset procedure (06 §13).

## Cloudflare API token

Scoped to Workers, D1 and KV edit on this account only (03 §14.2). Create a new token with the same scopes, update the Gitea repository secret `CLOUDFLARE_API_TOKEN` and the bundle (`worker.cloudflare_api_token`), re-run `worker-deploy.yml` for staging (`workflow_dispatch`, `env: staging`), then roll the old token in the Cloudflare dashboard. `worker-deploy.yml` skips with a warning while the secret is absent.

## Sonar token

Advisory only (RC88). `tools/ci/setup_sonar.sh` creates a new token; update `SONAR_TOKEN` in Gitea and `shared.sonar_token` in the bundle; revoke the old one in SonarQube.

## GPG bundle passphrase

Decrypt with the old passphrase, re-encrypt with the new one (`tools/secrets-manager.sh decrypt` then `encrypt` with the new `SECRETS_PASSPHRASE`), update `TARO_SECRETS` in `~/.zshrc` and the Gitea secret `SECRETS_PASSPHRASE`, and check a CI run that decrypts the bundle.

## Staging drill log

| Date | Secret | Result |
|---|---|---|
| — | Not run yet: Cloudflare resources and secrets are created in Phase 6 Sprint 6.0 | — |
