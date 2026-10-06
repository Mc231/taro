# Incident runbook

Scope per `06_QUALITY_TESTING_CI.md` §13. First full version: Phase 19.3. Reviewed quarterly and after every SEV1/SEV2.

Related runbooks: `AI_SAFETY.md` (unsafe output, eval gate, report triage), `WORKER_ROLLBACK.md` (code rollback, D1 Time Travel, config revert), `SECRET_ROTATION.md` (keys), `SUPPORT_CREDITS.md` (credit fixes for single users). Decisions: RC8 (one reading kill switch), RC47 (a stop is never a paywall), RC64 (budget tiers), RC97 (provider routing within `ai.disclosedProviders`; at launch `["openai"]`, moderation `openai`, 00_DECISIONS 2026-10-01).

**Golden rule:** stop the damage first (a kill switch or a rollback), then find the cause. A kill switch is a config push, not a release: no eval and no review needed. Turning something back **on** follows the normal rules (an eval for AI changes, a smoke run for everything).

## Severity levels

| Level | Meaning | Examples | Response |
|---|---|---|---|
| **SEV1** | Harm to users, money or data, or a store-policy breach live in prod | unsafe or banned AI output seen in prod; credits charged without readings at scale; purchases not granted; data exposed or leaked; a secret leaked | Kill switch within **15 min**; owner works it until stable; post-mortem within 3 days |
| **SEV2** | A core flow broken for many users, no harm | readings failing (`reading_failed_rate` alert); provider outage; budget hard stop on a normal day; Store or ads broken | Mitigate within **2 h**; post-mortem if it lasted > 1 h |
| **SEV3** | Degraded or cosmetic, workaround exists | slow readings; one locale's copy wrong; a single spread misbehaving | Fix in the next release or config push |

A SEV is set by impact, not by cause. Raise it when in doubt; lower it later.

## First 15 minutes

1. **Write down the time** (UTC) and open an incident note (a private gist or the owner's notes; never paste user text, install IDs or tokens there).
2. **Health:** `curl -sS https://api.taro.vshyrochuk.com/v1/health` (expects `status: ok`, `environment: prod`, the `workerVersion`). Then `cd worker && npm run smoke -- --env prod` (health + config; prod never registers or reads).
3. **Dashboard:** Cloudflare → Workers → `taro-api` → Metrics (requests, 5xx, CPU) and Logs (`wrangler tail --env prod --format pretty`, filter on `level: error`).
4. **Metrics:** `npm run metrics -- --env prod --query events` (`reading_failed` by `code`, `reading_declined`, `budget_block`, `http_response` 5xx, `purchase_*`).
5. **Providers:** the status page of every provider in `ai.disclosedProviders` (at launch only OpenAI: status.openai.com). Cloudflare: cloudflarestatus.com. Stores: Apple System Status (developer), Google Play Console status.
6. **What changed?** The last Worker deploy (`npx wrangler deployments list --env prod`), the last config push (stored `version` in `GET /v1/config`), the last app release. A change in the last 24 h is the first suspect: roll it back (`WORKER_ROLLBACK.md`) before debugging.
7. **Pick the kill switch** from the table below, push it, and confirm it is served (`curl -sS https://api.taro.vshyrochuk.com/v1/config | jq '.version, ."readings.enabled"'`).

## Kill switches (remote config)

All switches are keys in `worker/config/remote_config.default.json` (`public` or `server` document, 03 §8.2), pushed with `config:push` (03 §8.1). There is no admin HTTP route (RC84).

**How to push any switch:**

```bash
cd worker
cp config/remote_config.default.json /tmp/incident.json   # or the last pushed file for this env
# edit the key(s); raise "version" in BOTH documents above the stored one
npm run config:push -- --env prod --file /tmp/incident.json --dry-run   # validate, print the commands
npm run config:push -- --env prod --file /tmp/incident.json
curl -sS https://api.taro.vshyrochuk.com/v1/config | jq '.version'
```

The Worker caches config per isolate for 60 s (`CONFIG_CACHE_TTL_MS`); clients revalidate on launch and resume and cache `GET /v1/config` for up to 5 minutes. Allow about 6 minutes before judging the effect. Server-only keys (`ai.*`, `ai.budget.*`) apply as soon as the Worker cache expires. To undo, push the previous values with a **higher** `version` (`WORKER_ROLLBACK.md` "Revert remote config").

| Switch | Key (document) | Effect | User sees | Use for |
|---|---|---|---|---|
| **Readings off** (the only reading kill switch, RC8) | `readings.enabled = false` (public) | Every hold answers `503 READINGS_DISABLED`; nothing is charged; in-flight holds are refunded by the stale-hold cron | S31 "readings are resting" with "Try a classic reading" (F8). **Never a paywall** (RC47) | unsafe AI output, provider harmful-output incident, legal request, ledger bug |
| **Store off** | `store.enabled = false` (public) | The Store hides pack buttons; `purchasesBlockedReason = storeDisabled`. `POST /v1/purchases/verify` **still grants** (a paid transaction is never refused) | S11 `purchasesBlocked`: neutral note + support contact | wrong price/pack config, grant bug, store-side incident |
| **Remove Ads off** | `store.removeAdsEnabled = false` (public) | The `remove_ads` offer is hidden; owned entitlements stay | no "Remove Banner Ads" button | entitlement bug |
| **Ads off** | `ads.enabled = false` (public) | Global ads kill switch: banners and rewarded both hidden | no ads; rewarded option gone from S10 | policy-violating ad creative, AdMob account issue, UMP/ATT bug |
| **Banners off** | `ads.bannerEnabled = false` (public) | Banners only; rewarded stays | no banners | a banner overlapping content (rule 12) |
| **Rewarded off** | `rewarded.enabled = false` (public) | Rewarded offer hidden; new intents answer `403 REWARDED_DISABLED` | S10 without the ad option | reward-grant bug, SSV failures |
| **Spread off** | `spreads.enabled` without the spread (public) | `422 SPREAD_INVALID reason=disabled` | spread hidden on S06 | one spread's prompt or layout broken |
| **Model downgrade** | `ai.model.free` / `ai.model.freeFallback` (server) | Free tier on another model of a disclosed provider | nothing | cost spike, slow model |
| **Provider switch** | `ai.provider.paid/free/freeFallback`, `ai.outageFallback.*` (server) | Routes tiers within `ai.disclosedProviders` only (`config:push` rejects others, RC97) | nothing | provider outage (see below). Needs a passing eval for that provider + model (`AI_SAFETY.md`) |
| **Budget** | `ai.budget.*` (server) | Raises or lowers the tier thresholds (below) | — | cost incident |

Not kill switches: the budget tiers (they trip on their own), `attest.requiredOnReadings` (fraud control; turning it off widens abuse), `ai.blockedCountries` (legal availability, changed only with the owner's sign-off).

### Budget tiers (03 §10.2, RC64)

The 15-minute cron compares today's (UTC) `ai_spend_daily` with the thresholds and alerts once per level per hour:

| Alert | Tier | Effect | User sees |
|---|---|---|---|
| `budget_alert` (50 % / 80 % of soft) | normal | none | — |
| `budget_soft_hit` | soft | free readings move to `ai.model.freeFallback` | — |
| `budget_free_stop` | freeStop | free allowance paused; bonus and paid credits still read; free-only installs get `503 AI_BUDGET_EXHAUSTED tier=freeStop` | S31 free variant ("free readings are resting") |
| `budget_hard_hit` | hard | every hold `503 AI_BUDGET_EXHAUSTED tier=hard`; in-flight readings refunded | S31 "readings are resting" + Classic. **Never a paywall** (RC47) |

Response:
1. A tier hit on a normal traffic day means cost per reading drifted: compare `reading_completed` cost per model (`npm run metrics -- --env prod --query events`) and look for `pricing_unknown` log lines (an unpriced model is billed at the highest known price).
2. If the spend is real abuse (one install or IP range), it is a fraud incident: check `budget_block` and the rate-limit metrics; tighten `readings.maxPerInstallPerDay` or require attestation before raising the budget.
3. Raising limits is a config push of `ai.budget.softFloorUsd ≤ freeStopFloorUsd ≤ dailyHardUsd` (the schema enforces the order). Keep each provider account's monthly spend limit above `31 × ai.budget.dailyHardUsd`.
4. Never "fix" a stop with a paywall or by hiding the S31 copy (RC47).

### Provider outage

Symptoms: `reading_failed_rate` alert with `code` in `timeout | rate_limited | upstream`; `ai_provider_unavailable` alert (key missing); the provider status page.

1. Readings fail safe: the reading is refunded and S08 shows "Try again" with the cards kept (F6). No kill switch is needed for a short outage.
2. If it lasts > 30 min and another provider is **disclosed and eval-passed**, set `ai.outageFallback.provider/model` or move the tier (`AI_SAFETY.md` "Moving a tier"). At launch only OpenAI is disclosed: switching to Anthropic needs a copy change, an `ai.consentVersion` bump and an app release (RC97 (9)), so it is not an incident lever.
3. If failures pile up (users retrying into errors), set `readings.enabled = false` until the provider recovers; the Classic reading keeps the app useful.
4. After recovery: re-enable, run `smoke` on staging (one real reading), watch `reading_failed` for an hour.

### Key rotation (leak or suspected leak)

1. Treat any leaked secret as SEV1. Follow `SECRET_ROTATION.md` for that secret (create new → `wrangler secret put --env prod` → deploy if needed → verify → revoke old).
2. AI provider key (`OPENAI_API_KEY`; `ANTHROPIC_API_KEY` only if re-enabled): revoke the old key in the provider console **first** if it is being abused (readings fail safe and are refunded meanwhile), then put the new one; check the provider's usage page for spend from the leak.
3. Signing and encryption keys (`TOKEN_SIGNING_KEYS`, `IDEMPOTENCY_ENC_KEY`, `REPORT_ENC_KEY`) are keyrings: rotate with `gen-keys --rotate`; drop the old entry early only if it leaked (sessions then re-register; old reports become unreadable, which is acceptable).
4. Never rotate `APPLE_ACCOUNT_NS` or `PLAY_ACCOUNT_KEY` (RC9) unless leaked; see the table in `SECRET_ROTATION.md` for the consequences.
5. Update `.secrets/secrets.json.gpg` and the Gitea secrets in the same hour; record the rotation in the `SECRET_ROTATION.md` log.

### Data incident (personal data exposed, lost or corrupted)

Personal data we hold (03 §13): install ID and hashes, balances and ledger, purchase records, reports (sealed, 90 days), reading text until delivered (≤ 7 days), logs (7 days). Questions are not stored (RC69).

1. **Contain:** roll back the code (`WORKER_ROLLBACK.md`), set `readings.enabled = false` if the reading path is involved, rotate any exposed key (above).
2. **Corrupted data:** D1 Time Travel restore (`WORKER_ROLLBACK.md`), then re-grant lost purchases.
3. **Assess within 24 h:** what data, how many installs, since when, who could see it. Write it down with timestamps.
4. **Notify:** if personal data of EU/UK users may be exposed, the owner (controller) notifies the competent supervisory authority **within 72 h** of becoming aware (GDPR Art. 33), unless the breach is unlikely to result in a risk; if the risk is high, users are informed without undue delay (Art. 34), via the app (a notice on Home) and the support page. Processors (Cloudflare, OpenAI, Google) are informed if their systems are involved.
5. Record the decision and reasoning even when no notification is needed.

## Alerts (Telegram)

The Worker posts alerts (`AlertKind`, 03 §14.1; each kind at most once per hour) to the Worker secret **`ALERT_WEBHOOK_URL`**, set per environment (`staging`, `prod`). The owner's channel is the Telegram bot **@taro_alerts_vsh_bot**; the secret holds its Bot API URL:

```
https://api.telegram.org/bot<TOKEN>/sendMessage?chat_id=<CHAT_ID>
```

For such a URL `WebhookAlerter` posts `{chat_id, text, disable_web_page_preview: true}` to `…/bot<TOKEN>/sendMessage`, with text `🔔 taro-api (<env>) — <kind>`, the message and one `key: value` line per redacted field (cut at 4096 characters). Any other URL gets the Slack-style `{text, fields}`. The URL contains the bot token: it is never logged, and failures log only the kind and the HTTP status or error name. Find `CHAT_ID` by messaging the bot and reading `https://api.telegram.org/bot<TOKEN>/getUpdates` (`message.chat.id`; a group or channel ID starts with `-100`).

**Send a test alert** (no deploy; the URL comes from the shell, not from wrangler secrets, and is never printed):

```bash
cd worker
read -rs ALERT_WEBHOOK_URL && export ALERT_WEBHOOK_URL   # paste the URL; not stored in shell history
npm run alert:test -- --env staging   # "ok   test alert (staging) sent via telegram"; exit 1 on a failed delivery
unset ALERT_WEBHOOK_URL
```

**Rotate the bot token** (leaked token, or yearly):

1. In Telegram, @BotFather → `/revoke` → pick @taro_alerts_vsh_bot. The old token stops working at once (alerts are only logged until step 3).
2. Build the new URL with the new token and the same `chat_id`; check it with `npm run alert:test` as above.
3. `npx wrangler secret put ALERT_WEBHOOK_URL --env staging`, then `--env prod` (paste on stdin, never as an argument). Each `secret put` deploys a new Worker version.
4. Update the encrypted bundle if it holds the URL (`tools/secrets-manager.sh`, `.secrets/README.md`). General rotation rules: `SECRET_ROTATION.md`.

## Staging kill-switch drill

Before launch (Phase 19.3) and after any change to the gate or the S31 screen:

```bash
# Plan only: reads the stored staging config, validates overlay + restore, writes nothing
tools/kill_switch_drill.py --env staging --switch readings --dry-run
# Live: push readings.enabled=false, wait until served, hold 5 min, restore
tools/kill_switch_drill.py --env staging --switch readings --hold 300 --snapshot /tmp/taro-drill.json
# Budget hard stop: soft/freeStop/hard floors = 0 for the hold window
tools/kill_switch_drill.py --env staging --switch budget-hard --hold 300 --snapshot /tmp/taro-drill.json
# If a drill was interrupted:
tools/kill_switch_drill.py --env staging --restore /tmp/taro-drill.json
```

During the hold, on a staging build (relaunch or resume so it refetches config): Begin → S31 "readings are resting" with "Try a classic reading"; no S10 paywall; Classic reading works. The budget drill also triggers a `budget_hard_hit` alert on staging; that is expected. The script refuses `--env prod`. Record each drill below.

| Date | Env | Switch | Result | By |
|---|---|---|---|---|

## User communication template

Use only for SEV1/SEV2 lasting > 1 h. Channels: the support page (`taro.vshyrochuk.com/support`), replies to support mail, and the store "What's New" text if a release fixes it. Never mention credits as "lost"; say they are safe. Translate for the affected locales.

```text
Subject: Taro readings are paused for a short while

We paused AI readings while we fix a problem with <short, plain description>.
Your readings, journal and credits are safe. Nothing was charged for readings
that did not finish; those credits are back in your balance.
While readings are paused you can still use a Classic reading with card meanings.
We expect readings back by <time, UTC> and will update this page.
Questions: volodymyr.shyrochuk@gmail.com
```

## Post-mortem template

Blameless; within 3 days of a SEV1, or of a SEV2 longer than 1 h. Store under `docs/postmortems/<date>-<slug>.md` (no user text, install IDs or tokens).

```markdown
# <date> <title> (SEV<n>)

- Detected: <UTC time, how (alert/report/user)>
- Mitigated: <UTC time, which switch/rollback>
- Resolved: <UTC time>
- Impact: <users/installs affected, readings failed, credits refunded, money>

## Timeline (UTC)

## Root cause

## What went well / what went badly

## Action items (each with an owner and a test or check that prevents a repeat)
| Action | Type (test/check/runbook/config) | Due |
|---|---|---|
```

## Drill log

| Date | Env | Switch | Result |
|---|---|---|---|
| 2026-10-02 | staging | `readings` (`tools/kill_switch_drill.py --switch readings --hold 150`) | Config v2 live; `tools/worker_smoke.sh staging` → balance `canRead false`, hold `503 READINGS_DISABLED`; restored as v3. |
| 2026-10-02 | staging | `budget-hard` (`--switch budget-hard --hold 150`) | Config v4 live; hold `503 AI_BUDGET_EXHAUSTED (tier hard)`, no 402 paywall (RC47); restored as v5; the next smoke reading completed. |
