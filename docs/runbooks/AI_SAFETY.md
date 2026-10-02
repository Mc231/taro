# AI safety runbook

Release gate per `06_QUALITY_TESTING_CI.md` QA17; the pass bar is defined in `05_COMPLIANCE_STORE_ASO.md` §4.3. Worker behaviour: `03_BACKEND_WORKER.md` §9 (readings, safety layers, reports), §10 (budget), §13 (retention), §14.1 (alerts). Decisions: RC22 (reports), RC27 (safety layers), RC39 (banned phrases), RC47 (never a paywall for a stop), RC64 (budget tiers), RC97 (provider-agnostic AI layer).

Rule of thumb: **an eval report comes before any change to the prompt, a model or a provider.** The only thing you may change without an eval is switching readings off.

## Kill switch

`readings.enabled` in server config is the only reading kill switch (RC8). Setting it to `false` makes every hold answer `503 READINGS_DISABLED`. The app shows S31 "readings are resting" with the Classic-reading offer, never a paywall (RC47). Nothing is charged, and in-flight holds are refunded by the stale-hold cron.

1. Edit `worker/config/remote_config.default.json` (or a copy): `"readings.enabled": false`, and bump `version`.
2. `cd worker && npm run config:push -- --env prod --file <file> --dry-run`, check the diff, then run it again without `--dry-run`.
3. Wait for the per-isolate config cache to expire (60 s, `CONFIG_CACHE_TTL_MS`), then run `npm run smoke -- --env prod` to confirm `READINGS_DISABLED`.
4. Post the reason in the incident channel (`docs/runbooks/INCIDENT.md`). To undo, push `true` with a higher `version`.

Use it for any unsafe output seen in production, a provider incident with harmful output, or a legal request. The budget tiers (below) stop readings on their own; they are not a kill switch.

## Weekly report triage (CS7, RC22)

Reports come from S33 (`POST /v1/readings/{clientReadingId}/report`). The Worker stores `{question?, reading, note?}` AES-256-GCM sealed with `REPORT_ENC_KEY` in `reading_reports`, plus `reason`, `locale`, `prompt_version` and `model` (`provider/model`). The nightly cron deletes rows 90 days after `created_at`. At most 10 reports per install per local day are accepted.

Every Monday:

1. Check the volume: `npm run metrics -- --env prod --query events` (look at `reading_reported`; the `code` column is the reason).
2. Export and decrypt last week's reports on the owner machine with the owner script (`worker/scripts/reports-export.ts` over `src/admin/reportsExport.ts`, 03 §9.7). Never paste decrypted text into tickets, chat or git. Delete the local export after triage. *(The export script is still open as of Sprint 8.5. Until it lands, decrypt with `openReport` from `src/crypto/reportPayload.ts`, which uses the AAD `install_id‖client_reading_id`.)*
3. Classify each report as one of:
   - **model error** (unsafe or banned content got through): add a lexicon entry (below) and a case to `worker/evals/safety/prompts.jsonl`; if the prompt needs a change, follow "Shipping a new prompt version";
   - **false positive / taste** (the reading was fine): no action, but note it in the log;
   - **crisis content**: check that the crisis flow triggered (L1 or model `self_harm`); if not, add an L1 pattern.
4. Record counts per reason and the actions taken in the "Eval report log" at the end of this runbook.

### Triage walk-through (Phase 19.3)

One Monday session, about 20 minutes. Run it on staging first (`--env staging`, database `taro-staging`) to rehearse; in prod use `taro-prod`.

1. **Volume and trend.** `cd worker && npm run metrics -- --env prod --query events` → the `reading_reported` row for the last 7 days, split by `code` (the reason). Compare with `reading_completed` for the same week: a report rate above **1 %** of completed readings, or any week with a jump of 3× or more, is a SEV2 per `INCIDENT.md` and gets its own note.
2. **Metadata first, no decryption.** List what came in without opening any payload:

   ```bash
   npx wrangler d1 execute taro-prod --env prod --remote --command \
     "SELECT reason, locale, prompt_version, model, COUNT(*) AS n FROM reading_reports
      WHERE created_at >= datetime('now','-7 days') GROUP BY 1,2,3,4 ORDER BY n DESC"
   ```

   Clusters tell you where to look: many reports for one `prompt_version` + `model` point to the prompt or model; many for one `locale` point to the translation or a lexicon gap in that language; `sexual` or `hateful` reasons are always opened.
3. **Open only what you need.** Decrypt the reports in the clusters from step 2 plus every `sexual`, `hateful` and `harmful_advice` report, on the owner machine only (the export script or `openReport`, see step 2 above). Work in a temporary folder and delete it at the end. Never copy decrypted text into tickets, chat, commits or eval files.
4. **Classify each opened report** (model error, false positive / taste, crisis content, as above). For a **model error**, also decide the urgency:
   - certainty or banned claims, medical / legal / financial advice that should have been declined: add the lexicon entry and the eval case this week, ship with the next prompt or lexicon change;
   - sexual content involving minors, instructions for self-harm or harm to others, or anything a store reviewer would reject outright: SEV1. Set `readings.enabled = false` (above) first, then fix, eval, and re-enable.
5. **Write the eval case in neutral form.** Paraphrase the triggering question (no names, places, dates or other identifying details from the report) and add it to `worker/evals/safety/prompts.jsonl` with the expected category. The decrypted text itself never enters the repository.
6. **Check the loop closed.** For every lexicon or prompt change from last week, re-run `npm run eval:offline` over the recorded outputs and check that the reported pattern is now caught, with no new over-refusals in the benign controls.
7. **Log it.** Add one row to "Eval report log" below with kind `triage`: the week, counts per reason, actions (lexicon entries, eval cases, prompt changes, incidents). An empty week gets a row too (`0 reports`).

The report rows expire 90 days after `created_at` (nightly cron); nothing needs deleting by hand. A user asking for their report to be deleted is handled by the in-app "Delete all data" erasure (`DELETE /v1/installs/me`, 03 §3.6, RC37), which removes their `reading_reports` rows.

## Adding lexicon entries (L1 prefilter, L3 forbidden claims)

- Store-copy and L3 banned claims: add the phrase to `tools/store_copy/banned_phrases.yaml` (the one canonical list, RC39). Under the 05 §9.5 rules it also applies to the store copy and the ARB files.
- L1 prefilter patterns and locale-specific L3 rules: edit `worker/safety/lexicons/<locale>.json`. Patterns are regexes over `foldText()` output (lower case, Latin diacritics folded). A rule fires when all of its `patterns` match and none of its `unless` entries do. Only `high` rules of `self_harm`, `harm_to_others` and `sexual_minors` short-circuit; `hint` rules become `<prefilter_hint>`.
- Then recompile the lexicons into `src/generated/safety_lexicons.json` with the step named in the lexicon file's `$comment` (`npm run safety:lexicons`, Sprint 8.4), then run `npm test`. The offline graders use the same phrases, so run `npm run eval:offline` over the last recorded outputs to see the effect on true positives (and new false positives) before you ship.
- Add the triggering text, in a neutral form, to the safety suite so the next eval covers it.

## Running the safety eval

- Offline (no keys, CI-safe): `cd worker && npm run eval:offline -- --cases evals/safety/prompts.jsonl --outputs <recorded outputs> --out <dir>`. It grades schema, classification, crisis, language, certainty, banned phrases, card echo, length, contacts and leakage per tier. Rendered prompts come from `npm run prompt:render`.
- Live (Sprint 8.6, needs the Sprint 8.0 keys of the target environment): one full run **per routable provider + model**, meaning the three tiers `ai.provider.paid/free/freeFallback` with their `ai.model.*` plus the outage fallback when it is set (RC97). Commit the report as `worker/evals/reports/<date>-<promptVersion>-<provider>-<model>.md`.
- The 05 §4.3 pass bar must hold for every one of them before it is routed in prod.

## Shipping a new prompt version (eval first)

1. Copy `worker/prompts/reading/v<N>/` to `v<N+1>/`. After the first commit a version is never edited in place.
2. Make the change and add a `CHANGELOG.md` entry in the new directory.
3. Register the version in `src/prompts/templates.ts`, update `src/prompts/versions.lock.json` (the test prints the new hash) and the snapshots (`npx vitest run test/unit/prompts -u`), then review the snapshot diff.
4. Run the offline eval, then the live eval for every routed provider + model. Commit the reports.
5. Only then switch the server config to the new version and push it to staging, then `smoke`, then prod. Keep the old version routable until the new one has run clean in prod for a week.

## Moving a tier to another provider or model (config only)

The tiers are `ai.provider.paid` / `.free` / `.freeFallback` plus `ai.model.*` (server-only config, RC64, RC97). No release is needed, but an eval report is.

1. Check that the provider is in `ai.disclosedProviders`. If it is not, stop: adding a provider needs a copy change, an `ai.consentVersion` bump and an app release (RC97 (9)). `config-push` rejects undisclosed routing.
2. Check that the provider's key is set in the target environment (`ANTHROPIC_API_KEY` / `OPENAI_API_KEY`). A tier routed to a provider without a key is disabled (`503 AI_UNAVAILABLE` plus the `ai_provider_unavailable` alert).
3. Check that `src/domain/pricing.ts` has the `provider/model` price. An unknown model logs `pricing_unknown` and is priced at the highest known price, which trips the budget tiers early.
4. Commit a passing eval report for exactly that provider + model + prompt version.
5. Push the config to staging, run `smoke` (one real reading per routed provider), then push to prod and watch `reading_failed` and `reading_declined` for an hour.

## Outage fallback

`ai.outageFallback.provider` / `.model` (default `null`, off). When set, a reading whose primary call ends in `timeout`, `rate_limited` or `upstream` after its own retry, with at least 15 s of `ai.deadlineMs` left, is tried once on the fallback. It is never used after `refused`, `truncated` or `invalid_output`. Metric: `ai_outage_fallback`.

- Turn it on only with a passing eval report for the fallback provider + model, and a key in that environment.
- During a long primary outage, consider moving the affected tier itself to the fallback provider (previous section) instead of paying the extra latency on every reading.

## `ai_provider_unavailable` alert

Meaning: a tier is routed to a provider that has no adapter in this environment (missing or empty key) and no keyed outage fallback. Its holds answer `503 AI_UNAVAILABLE` and nothing is charged. The alert is deduplicated hourly per tier.

1. Look at the alert fields (tier, provider) and at the current server config (`ai.provider.*`).
2. If the key was lost or rotated, set it again: `wrangler secret put <ANTHROPIC_API_KEY|OPENAI_API_KEY> --env <env>` (`docs/runbooks/SECRET_ROTATION.md`), then `smoke`.
3. If the routing was a mistake, push config that routes the tier back to a keyed provider (with an eval report, per the previous sections).
4. If neither is quick, and the free tier is the one affected, users with bonus or paid credits may still read on the paid tier. Say so in the incident note.

## Budget alerts (03 §10.2, RC64)

The 15-minute cron sends `budget_tier` alerts, deduplicated per level per hour: `budget_alert` at 50 % and 80 % of soft; `budget_soft_hit` (free readings move to `ai.model.freeFallback`); `budget_free_stop` (free allowance paused, bonus and paid still work, free-only installs get `503 AI_BUDGET_EXHAUSTED tier=freeStop`); `budget_hard_hit` (all readings `503 tier=hard`, in-flight readings refunded). Spend is `ai_spend_daily`, summed over all providers, per UTC day.

- A soft or free-stop hit on a normal traffic day means cost per reading has drifted. Check `reading_completed` cost per model (`npm run metrics -- --query events`) and the `pricing_unknown` log lines.
- Raising the limits (`ai.budget.*`) is a config push. Keep each provider account's monthly spend limit above `31 × ai.budget.dailyHardUsd`.
- Never "fix" a budget stop by showing a paywall (RC47).

## Metric alerts (03 §14.1)

`AlertService` (15-minute cron) reads Analytics Engine through the SQL API (`ANALYTICS_ACCOUNT_ID`, `ANALYTICS_API_TOKEN`; without them the rules are skipped and `alert_check_skipped` is logged). It alerts on:

- `error_rate`: 5xx share of `http_response` above `alerts.error5xxRatePct`;
- `reading_failed_rate`: failed readings over completed + declined + failed above `alerts.readingFailedRatePct`;
- `webhook_sig_failures`: more than `alerts.webhookSigFailuresPer15m` in 15 minutes.

A rate alert needs at least 3 events in the window. For a `reading_failed_rate` alert, check the `code` split (`timeout`, `rate_limited`, `upstream`, `invalid_output`) with `npm run metrics`. Provider errors point to the outage fallback or a tier move. `invalid_output` points to the prompt or the model: roll back to the last good prompt version by config.

## Crisis resources verification

Crisis resources are authored in `apps/taro/content/source/crisis/crisis_resources.yaml` and compiled by `tools/content build` (RC25). They are chosen by `cf.country`. Before each release, and quarterly: check every number and URL for the launch countries. Update the YAML and rebuild, then run a crisis case from the safety suite per locale and check that the crisis card shows the right country's resources.

## Live eval commands (`eval`, `eval:safety`)

Both commands call the real provider API through the Worker's own adapters (`AnthropicProvider`, `OpenAiProvider`). They use the same prompt builder, L1 prefilter and default `ai.*` config (`maxTokensBySpread`, `effort`, `timeoutMs`, `maxRetries`, `refusalFallbacks`, `deadlineMs`) as production, then grade the answers with the offline rule graders. There is no L3 regeneration and no moderation call. The owner approves the budget before every run.

```bash
cd worker
# Key of the target environment (staging), from the secrets bundle; never echo it.
# Default routing is OpenAI only (00_DECISIONS, 2026-10-01); use worker.anthropic_api_key / --provider anthropic only to re-qualify Anthropic.
export OPENAI_API_KEY=$(SECRETS_PASSPHRASE=$TARO_SECRETS ../tools/secrets-manager.sh get worker openai_api_key)
# Quick check (~50 cases, all locales/spreads/categories):
npm run eval:safety -- --env staging --provider openai --model gpt-6.1-sol --sample smoke --max-usd 5
# Full safety suite (the 05 §4.3 bar), one run per routable provider + model:
npm run eval:safety -- --env staging --provider openai --model gpt-6.1-sol --max-usd 60
# Quality cases (tone, schema, length, card echo), optional advisory LLM judge:
npm run eval -- --env staging --provider openai --model gpt-6-luna --max-usd 5 --judge-model gpt-6.1-sol
unset OPENAI_API_KEY
```

- **Budget.** `--max-usd` is required. Before the first call the run prints a projected (typical) spend and refuses to start if it is over the budget; use `--limit N` or `--sample smoke`, or get a larger budget approved. During the run, no call starts when the money spent plus that call's worst case (the prompt twice uncached, plus `max_tokens` and the 1.5x truncation retry, doubled for Opus refusal fallbacks) would pass the budget. Each case prints its cost and the running total. Exit code 4 means the budget stopped the run. The report is still written and is marked incomplete.
- **Options.** `--cases <jsonl>` (repeatable) replaces the suite file. `--limit N` keeps the first N cases after sampling. `--concurrency N` sets parallel calls (default 4, max 16). `--skip-l1` sends L1 hard blocks to the model too, to measure the model alone. `--tier <label>` sets the report's tier label. `--out <dir>` sets the report folder (default `evals/reports`). `--judge` / `--judge-model <id>` turns on the advisory LLM judge. `--allow-incomplete` returns 0 for an incomplete run.
- **Reports.** `evals/reports/<date>-<promptVersion>-<provider>-<model>.md` for `eval:safety`, with `-quality` added for `eval` and `-smoke` added for smoke runs. Each report comes with `.summary.json`, `.results.jsonl` (the grade per case) and `.outputs.jsonl` (the answers in the `eval:offline` format, so a grader change can re-grade them without new spend). The `## Live run` section gives the outcome split (L1 block, answered, declined, provider refusal, truncated, invalid, outages), the token totals and the measured cost per reading per spread. Use those cost numbers for BE Q1.
- **Exit codes.** 0 = pass. 1 = input error or missing key. 2 = usage error. 3 = the 05 §4.3 bar failed, or the run is incomplete (outages leave cases ungraded; re-run them). 4 = budget.
- **LLM judge.** It scores answered readings from 1 to 5 on tone, spread coherence and card fidelity, using the same provider. It is advisory only: it never changes the verdict (06 Open question 2), and its cost counts against `--max-usd`.
- **Weekly CI.** `nightly.yml` runs `eval:safety --sample smoke` every Monday (or when started by hand with `weekly: true`). It covers every provider + model that `config/remote_config.default.json` routes (paid, free, freeFallback, and the outage fallback when set). It uses the staging keys from the secrets bundle (`worker.staging_<provider>_api_key`, else `worker.<provider>_api_key`); a provider without a key is skipped with a warning. The Gitea repository variables `EVAL_SAFETY_SAMPLE` (`smoke`|`all`) and `EVAL_SAFETY_MAX_USD` (default `10` per provider + model) change the sample and the budget. Reports are uploaded as the `eval-safety-reports` artifact and never committed. A failing bar fails the job: triage it like a release blocker, and do not route that provider + model in prod until a full run passes.
- **Before a release** (checklist in `docs/runbooks/RELEASE.md`): a committed full `eval:safety` report that passes, for every routed provider + model with the production prompt version.

## Eval report log

| Date | Prompt | Provider / model | Kind | Result | Report |
|---|---|---|---|---|---|
| 2026-09-30 | v1 | simulated | offline | see report | `worker/evals/reports/2026-09-30-v1-offline-simulated.md` |
