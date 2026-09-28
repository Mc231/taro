# Secrets bundle

Every CI and deploy secret for Taro lives in one file, `.secrets/secrets.json.gpg`. It is AES-256 symmetric GPG, unlocked by a single passphrase. This is the quiz_apps pattern (06 QA10). The Gitea repository holds only that passphrase, as the Actions secret `SECRETS_PASSPHRASE`.

| File | What | Committed |
|---|---|---|
| `.secrets/secrets.json.gpg` | encrypted bundle | yes (it goes to the GitHub origin, and Gitea mirrors it) |
| `.secrets/secrets.json` | decrypted working copy | **never** (`.gitignore`: `.secrets/*.json`) |
| `tools/secrets-manager.sh` | management script | yes |

The bundle has not been created yet. Creating it is a manual owner step (Phase 3 Sprint 3.4), described below.

## Create the bundle (owner, once)

Prerequisites: `brew install gnupg jq`.

1. Pick a long random passphrase, for example `openssl rand -base64 48`. Store it in your password manager. **Do not reuse the quiz_apps passphrase**, so that one leaked passphrase does not unlock both bundles.
2. Create the skeleton. It has the empty sections `shared`, `taro` and `worker`:
   ```bash
   tools/secrets-manager.sh init
   ```
3. Fill in what you already have. The rest is added in later phases (Worker in Phase 6, stores in Phase 10, release in Phase 21):
   ```bash
   tools/secrets-manager.sh set shared apple_team_id <TEAM_ID>
   tools/secrets-manager.sh set taro ios_bundle_id com.vshyrochuk.taro
   tools/secrets-manager.sh set taro android_package_name com.vshyrochuk.taro
   tools/secrets-manager.sh set-file taro android_keystore_base64 ~/pet/secure/taro/upload.jks
   ```
4. Encrypt. You are prompted for the passphrase twice. The plaintext is removed afterwards:
   ```bash
   tools/secrets-manager.sh encrypt
   git add .secrets/secrets.json.gpg
   ```
5. Add the passphrase to Gitea: open `http://localhost:3001/<owner>/taro` → **Settings → Actions → Secrets → Add Secret**. Set the name to `SECRETS_PASSPHRASE` and paste the passphrase as the value.

Confirm that the passphrase works non-interactively, which is how CI uses it:
```bash
SECRETS_PASSPHRASE='…' tools/secrets-manager.sh list
tools/secrets-manager.sh clean
```

## Day-to-day

```bash
tools/secrets-manager.sh list                         # sections + key names (no values)
tools/secrets-manager.sh get worker cloudflare_account_id
tools/secrets-manager.sh set worker anthropic_api_key sk-…
tools/secrets-manager.sh encrypt                      # always: re-encrypt + remove plaintext
tools/secrets-manager.sh validate                     # lists expected keys that are still empty
```

If `.secrets/secrets.json` is newer than the bundle, `decrypt` refuses to run, because running it would overwrite changes that were never encrypted. This guard was added after quiz_apps lost its R2 keys this way. Run `encrypt` to keep those changes, or `FORCE_DECRYPT=1 … decrypt` to discard them.

## Structure

```json
{
  "shared": { "apple_team_id": "", "app_store_connect_api_key_base64": "", "google_play_service_account_base64": "", … },
  "taro":   { "ios_bundle_id": "", "android_package_name": "", "android_keystore_base64": "", … },
  "worker": { "cloudflare_account_id": "", "cloudflare_api_token": "", "anthropic_api_key": "", … }
}
```

`tools/secrets-manager.sh` holds the canonical list of expected keys in `SHARED_KEYS`, `TARO_KEYS` and `WORKER_KEYS`. Add a key there when a phase starts to depend on it.

## CI usage (deploy workflows, Phase 6+ / 21)

The rule comes from 06 §8. Secrets are decrypted into `$RUNNER_TEMP`, never into `/tmp` and never into the workspace. Every value is masked, and the plaintext is removed in an `always()` step:

```yaml
- name: Decrypt secrets
  env:
    SECRETS_PASSPHRASE: ${{ secrets.SECRETS_PASSPHRASE }}
  run: |
    tools/secrets-manager.sh decrypt-to "$RUNNER_TEMP/secrets.json"
    v=$(jq -r '.worker.cloudflare_api_token' "$RUNNER_TEMP/secrets.json")
    echo "::add-mask::$v"
    echo "CLOUDFLARE_API_TOKEN=$v" >> "$GITHUB_ENV"

- name: Remove secrets
  if: ${{ always() }}
  run: rm -P "$RUNNER_TEMP/secrets.json" 2>/dev/null || rm -f "$RUNNER_TEMP/secrets.json"
```

The `ci` workflow does not need any secrets. `sonarqube-main.yml` uses the separate repository secrets `SONAR_TOKEN` and `SONAR_HOST_URL`, the same as quiz_apps.
