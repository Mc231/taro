# Worker rollback runbook

Scope per `06_QUALITY_TESTING_CI.md` §13; deploy flow per `03_BACKEND_WORKER.md` BE18, §14.2 and `.gitea/workflows/worker-deploy.yml`. Tested once on staging before launch (drill log below). First version: Phase 6 Sprint 6.5.

All commands run from `worker/` with `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` exported (values from `.secrets/secrets.json.gpg`, section `worker`; never paste them into a shell history file or a ticket). Always pass `--env staging|prod`: the top-level `wrangler.toml` name is the dev Worker, so a bare command never touches prod.

## Decide first

| Symptom | Action |
|---|---|
| Errors or wrong behaviour right after a deploy, data is fine | Roll back the code (next section). |
| A kill switch is enough (readings, rewarded, ads, store) | Flip it in remote config (see "Revert remote config"); no code change. |
| Rows were written wrongly (ledger, readings, usage) | Roll back the code **and** follow "D1 Time Travel restore". |
| A production canary (10%) misbehaves | Do **not** promote it. Roll back to the previous version at 100%. |

## Roll back a deployment

1. Find the last good version:

   ```bash
   npx wrangler deployments list --env prod        # newest first: version IDs and percentages
   npx wrangler deployments status --env prod      # what serves traffic right now
   npx wrangler versions list --env prod           # uploaded versions (messages carry "ci <sha>")
   ```

   The `worker-deploy.yml` job summary also records every deployed version ID with its commit.

2. Put the good version back at 100%. Either:

   ```bash
   npx wrangler rollback <good-version-id> --env prod --message "rollback: <reason>"
   ```

   or, equivalently, with the versions API (also ends a stuck 10% canary):

   ```bash
   npx wrangler versions deploy <good-version-id>@100% --env prod --yes --message "rollback: <reason>"
   ```

3. Verify: `tools/worker_smoke.sh prod` (health and config). For staging, `DEBUG_ATTESTATION_TOKEN=… tools/worker_smoke.sh staging` also registers an install, reads its balance and runs one real single-card reading (see `SECRET_ROTATION.md` § Staging smoke).
4. Record the rollback in `worker/CHANGELOG.md` (`Fixed` or `Security`) once the fix ships, and in the incident log (`INCIDENT.md`).

A rollback never reverts D1 migrations. That is why every migration must stay compatible with the previous Worker version (next section).

## Why migrations are expand/contract

`worker-deploy.yml` applies `wrangler d1 migrations apply DB --remote` **before** it uploads the new code, and a canary runs old and new code side by side (90/10). So every migration must work with both versions (03 BE18):

- **Expand** (release N): add tables, nullable columns or columns with defaults, and new indexes. Never rename or drop anything the running version reads or writes. Backfill in the Worker or in a later migration.
- **Contract** (release N+1 or later, once no deployed version uses the old shape): drop the old column or table.
- Migrations are forward-only (`migrations/000N_*.sql`); there is no "down" migration. `tools/check_migrations.py` runs in CI and before every deploy.

Because of this rule, rolling the code back to N-1 after migration N is always safe.

## D1 Time Travel restore

Use this only when data was corrupted (for example a ledger bug wrote wrong rows). It rewinds the **whole** database, so every write after the restore point is lost, including purchases granted since then (the store transactions can be re-verified: `POST /v1/purchases/verify` is idempotent per store transaction, BE8).

1. Stop new damage first: roll back the code (above) and, if needed, set `readings.enabled = false` in remote config.
2. Find the restore point (Time Travel keeps 30 days):

   ```bash
   npx wrangler d1 time-travel info taro-prod --env prod --timestamp "2026-10-01T12:00:00Z"
   ```

   This prints the bookmark for that instant. Note the **current** bookmark too (`time-travel info` without `--timestamp`), so the restore itself can be undone.
3. Restore:

   ```bash
   npx wrangler d1 time-travel restore taro-prod --env prod --bookmark <bookmark>
   ```

4. Re-run the smoke test, check `GET /v1/balance` for a few affected installs, and re-enable any kill switch.
5. List the purchases whose grants were lost (store notifications and the Voided Purchases backstop, 03 §6.4) and re-grant them through `worker/scripts/ledger-adjust.ts` (Phase 7) if the stores do not resend them.

## Revert remote config

Remote config lives in `CONFIG_KV` (`config:public`, `config:server`) and is pushed only by `worker/scripts/config-push.ts` (03 §8.1).

1. Take the last good document from git history (`worker/config/remote_config.default.json` or the per-env file that was pushed).
2. Give it a `version` **greater** than the one currently stored. Clients revalidate with `ETag: "v{version}"`, so an older number would never reach them; `config:push` also refuses a non-increasing version without `--force`.
3. Push and verify:

   ```bash
   npm run config:push -- --env prod --file <file> --dry-run   # validates, prints the commands
   npm run config:push -- --env prod --file <file>
   curl -sS https://api.taro.vshyrochuk.com/v1/config | head -c 300
   ```

The Worker caches config for 60 s per isolate and clients for up to 5 minutes (`Cache-Control: public, max-age=300`), so allow about 6 minutes for the change to be everywhere.

## Staging drill log

| Date | Who | What was rolled back | Result |
|---|---|---|---|
| — | — | Not run yet: Cloudflare resources do not exist until Phase 6 Sprint 6.0 | — |
