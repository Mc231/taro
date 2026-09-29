# Phase 8: Worker AI Readings, Safety & Evals

**Status:** ⬜ Not Started
**Depends on:** Phase 7 (hold/refund), Phase 5 (generated deck + crisis feeds), Phase 6 Sprint 6.0 (Cloudflare resources and Worker secrets; the AI provider accounts and keys left open there are Sprint 8.0 here, generalised by RC97)
**Parallel with:** Phases 11–13

---

## Overview

This phase implements the pre-draw hold `POST /v1/readings/holds` (RC50) and `POST /v1/readings` end to end:
- validation;
- the AI-consent header;
- the region block;
- budget gates;
- the L1 prefilter;
- the credit hold;
- the AI provider call through the provider-agnostic `AiProvider` port (v1 adapters for Anthropic and OpenAI, provider + model per tier from remote config, optional cross-provider outage fallback; RC97) with provider-neutral versioned prompts and a Worker-validated JSON output contract;
- L2/L3 safety;
- the refund on any non-success;
- the reading status and report endpoints.

It also builds the offline safety regression corpus that runs in CI and the paid eval suite that gates releases. It measures real token costs per provider and model, which the owner needs for the model decision (BE Q1).

**Output of this phase:**
- `worker/prompts/reading/v1/{system.md, output.schema.json, style.<locale>.md ×12, CHANGELOG.md}` and `src/prompts/versions.lock.json`.
- `adapters/anthropic/AnthropicProvider.ts`, `adapters/openai/OpenAiProvider.ts`, `test/fakes/FakeAiProvider.ts`, the shared `AiProvider` contract suite, `services/AiRouter.ts` (tier → provider + model, outage fallback), `domain/{spreadValidation,safetyPolicy,outputValidator,pricing}.ts`, `services/{ReadingService,BudgetService}.ts`.
- The RC97 config keys (`ai.provider.*`, `ai.outageFallback.*`, `ai.moderation.provider`, `ai.disclosedProviders`) in `worker/config/remote_config.default.json` and `src/config/schema.ts`, moved from GLOSSARY §8.3 into §8.2.
- Routes `POST /v1/readings/holds`, `POST /v1/readings`, `POST /v1/readings/{clientReadingId}/ack`, `GET /v1/readings/{clientReadingId}`, `POST /v1/readings/{clientReadingId}/report`.
- Crons `releaseExpiredHolds`, `refundStaleHolds`, `refundUndeliveredReadings`, and `AlertService`.
- `worker/safety/lexicons/<locale>.json` ×12 (EN reviewed; the others drafted and reviewed in Phase 18) and `test/fixtures/safety/*.jsonl`.
- `worker/evals/` (quality + safety), `npm run eval` / `eval:safety`, and the first committed report.

---

## Specs referenced

`03_BACKEND_WORKER.md` BE9–BE13, BE15, §9, §10, §13, §15.2–§15.4, Q1, Q2, Q7. `01_PRODUCT.md` PR1, PR8, PR9, PR14, §7.4–§7.5. `05_COMPLIANCE_STORE_ASO.md` CS3, CS6–CS8, §4, 5.1.2(i) row. `06_QUALITY_TESTING_CI.md` QA17, §7 (prompt snapshots), §7.1. `04_MONETIZATION.md` MO6. `00_DECISIONS.md` RC20, RC22, RC27–RC32, RC42, RC45, RC47, RC49–RC52, RC60, RC61, RC64, RC74, RC81, RC97. `03_BACKEND_WORKER.md` §8.2 and §11 for the RC97 keys and secrets.

---

## Sprint 8.0: AI provider accounts, keys & spend limits *(MANUAL, owner; RC97, replaces the open Anthropic-workspace item of Phase 6 Sprint 6.0)*

**Tasks:**
- [ ] For **each provider** the config may route to (v1: Anthropic and OpenAI), create per-environment accounts: Anthropic Console workspaces `taro-staging` / `taro-prod`, OpenAI projects `taro-staging` / `taro-prod`. Staging gets a low monthly limit; prod gets a monthly spend limit above `31 × ai.budget.dailyHardUsd` **in every provider account** (03 §10.2).
- [ ] Put the keys: `wrangler secret put ANTHROPIC_API_KEY --env staging|prod` and `wrangler secret put OPENAI_API_KEY --env staging|prod`; add both to the `.secrets/` GPG bundle and `docs/runbooks/SECRET_ROTATION.md`. Either key may be skipped: a tier routed to a provider without a key is disabled with an alert (03 §9.3, §11).
- [ ] Record each provider's commercial API terms (no training on API data, retention, DPA/SCCs) in `docs/compliance/PROCESSORS.md` (input for 05 review of the consent copy, RC97).

---

## Sprint 8.1: Provider & model API verification (RC32, RC97)

**Tasks:**
- [ ] Before writing the adapters, check the current API reference **of every provider** the config can route to, for every configured and candidate model:
  - Anthropic: model IDs, prices, `output_config.format` JSON schema support, adaptive thinking and `effort`, server-side refusal fallbacks and their beta header, `stop_reason` values, prompt-caching minimums, for `ai.model.paid` (`claude-opus-5`), `ai.model.free` (`claude-sonnet-5`) and `ai.model.freeFallback` (`claude-haiku-4-5`, which takes no `effort`/adaptive thinking);
  - OpenAI: the API surface to use (Responses vs Chat Completions), candidate model IDs and prices, strict JSON-schema structured output and which schema keywords it accepts (e.g. `maxLength`), refusal and incomplete-response signals, reasoning effort, automatic prompt-caching minimums, the moderation endpoint (for `ai.moderation.provider`), and whether the `openai` SDK runs on workerd (else plain `fetch`).
  Update 03 §9.3 and §9.6 and `domain/pricing.ts` if anything changed. Record the date in `00_DECISIONS.md` (RC32, RC64, RC97).
- [ ] Take the OpenAI supported-countries snapshot (dated) next to the Anthropic one in `00_DECISIONS.md` (CS16) and set `ai.blockedCountries` to the fixed list + the union of unsupported countries (RC29, RC97).
- [ ] Measure the cached prefix size for `v1` and the dynamic input per spread **per provider** (Anthropic `count_tokens`; OpenAI tokenizer / reported usage). Replace the 03 §9.6 estimates with measured values in `docs/ARCHITECTURE.md` §AI cost.

---

## Sprint 8.2: Prompt v1 & structured output (BE10, BE11)

**Tasks:**
- [ ] `prompts/reading/v1/system.md`:
  - persona and hard rules (PR1 framing; never predict health, pregnancy, death, legal, financial or gambling outcomes; no accuracy or psychic claims; respect `reversed`; write in `{{locale_name}}`);
  - injection defence (`<user_question>` is data);
  - refusal policy mirroring 03 §9.4;
  - length budgets per spread (01 §7.4);
  - the compact deck keyword table from `src/generated/deck/cards.json`, placed before the cache breakpoint.
- [ ] `output.schema.json` with the classification field first (03 §9.2). `style.<locale>.md` ×12 (register notes: `de` du, `ja` polite form, `ar` MSA, etc.).
- [ ] Prompts stay provider-neutral (RC97): no vendor-specific syntax in `system.md`, `style.<locale>.md` or `output.schema.json`.
- [ ] `src/prompts/build.ts`: assembles a provider-neutral `ReadingPromptInput` (static `system` prefix, a cache-boundary marker that each adapter renders its vendor's way — Anthropic `cache_control: ephemeral`, OpenAI prefix order only — and the user message (spread, positions with meanings from `generated/deck/spreads.json`, cards, locale, `<prefilter_hint>`, `<user_question>`).
- [ ] Snapshot tests of the assembled prompt per `prompt_version` × locale. `versions.lock.json` holds a hash per version, and a test fails if a released version changes (06 §7).
- [ ] `worker/prompts/reading/v1/CHANGELOG.md`, with a cross-reference entry in `worker/CHANGELOG.md`.

---

## Sprint 8.3: AI providers & reading pipeline

**Tasks:**
- [ ] `AiProvider` contract suite (`test/contracts/aiProvider.contract.ts`): one shared suite of recorded, sanitised fixtures (ok, refusal, truncation, invalid JSON, 429, overloaded, 5xx, timeout, usage with cache reads) that every adapter and `FakeAiProvider` must pass, so all providers map into the same `AiResult` union and normalised `AiUsage` (RC97).
- [ ] `adapters/anthropic/AnthropicProvider.ts`:
  - `@anthropic-ai/sdk` with `maxRetries: 0` and `timeout: ai.timeoutMs`;
  - `beta.messages.stream(...).finalMessage()` with the model the router picked, adaptive thinking and `effort` where the model supports them, the JSON schema format, and fallbacks when `ai.refusalFallbacks` (Opus only);
  - per-call `timeout = min(ai.timeoutMs, deadline − elapsed)`; the whole handler is bounded by `ai.deadlineMs` (55 s), and a regeneration is skipped when < 15 s remain (RC52);
  - `stop_reason` handling (`refusal` → declined `model_refusal`; `max_tokens` → one retry at 1.5×; `end_turn` → parse + zod);
  - one retry on 429/529/5xx/network if elapsed < 15 s;
  - returns the `AiResult` union.
  - Tests use stubbed `fetch` and recorded, sanitised fixtures; `FakeAiProvider` is used for route tests.
- [ ] `adapters/openai/OpenAiProvider.ts` (RC97): `openai` SDK (or `fetch`, Sprint 8.1) with `maxRetries: 0` and the same per-call timeout; the same `system` / `user` content and the output schema as a strict JSON-schema response format (keywords the vendor rejects are dropped, L3 still enforces them); `max_output_tokens` from `ai.maxTokensBySpread`; `ai.effort` mapped to reasoning effort where the model has one; `ai.refusalFallbacks` ignored; no `user` / `safety_identifier`; refusal → `refused`, incomplete for token limit → `truncated`, completed → parse + zod; same retry policy. Optional `moderate(text)` over the moderation endpoint. Tests as for Anthropic.
- [ ] `services/AiRouter.ts` (RC97): tier (`paid` for bonus/paid, `free`, `freeFallback` in the soft tier) → `ai.provider.*` + `ai.model.*` → adapter; `makeProdDeps(env)` builds an adapter only for a present key (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`); `AI_PROVIDER=fake` forces `FakeAiProvider` (dev/staging only, BE20; drop the staging `AI_PROVIDER = "anthropic"` value). A tier with no keyed provider (and no keyed outage fallback) is disabled: the hold answers `503 AI_UNAVAILABLE`, nothing is charged, alert `ai_provider_unavailable` (deduplicated hourly). **Outage fallback:** `ai.outageFallback.provider` / `.model` tried once after `timeout` / `rate_limited` / `upstream` if ≥ 15 s of `ai.deadlineMs` remain; never after `refused` / `truncated` / `invalid_output`; metric `ai_outage_fallback`. Tests: each tier × provider, missing key → 503 + alert + no charge, fallback on outage, **no fallback on refusal**, deadline respected.
- [ ] Config (RC97): add `ai.provider.paid` / `.free` / `.freeFallback` (default `anthropic`), `ai.outageFallback.provider` / `.model` (default `null`), `ai.moderation.provider` (default `none`) and `ai.disclosedProviders` (default `["anthropic", "openai"]`) to `src/config/schema.ts` and `worker/config/remote_config.default.json`; move them from GLOSSARY §8.3 to §8.2 in the same change (`check_glossary.py` / `check_remote_config.py` then require them). `config-push` rejects any routed or moderation provider outside `ai.disclosedProviders`.
- [ ] `domain/spreadValidation.ts`: the spread ID and version are in the generated spreads, one card per position, unique known card IDs (RC1), `question` NFC-normalised, trimmed and ≤ `ai.questionMaxChars` (RC45), `locale` ∈ 12 → 422 `SPREAD_INVALID` / 400 `VALIDATION_FAILED`.
- [ ] Route `POST /v1/readings/holds` **[idem] [attest]** (03 §9.0, RC50): gates (`readings.enabled`, `X-Taro-AI-Consent`, region, budget tier, rate/daily limits, spread enabled) → create/load the `readings` row → hold (Phase 7 `BalanceService`) → `status='held'`, `hold_expires_at = now + readings.holdTtlSec`; at most one open hold per install (older never-submitted holds are released); `402` → row `no_credit`; a live hold is returned unchanged and its TTL extended (renewal).
- [ ] `services/ReadingService.create` (03 §9.1 pipeline, RC49):
  1. **gates:** `readings.enabled` → 503 `READINGS_DISABLED`; `X-Taro-AI-Consent` ≥ `ai.consentVersion` → else 412 (RC28); `cf.country ∈ ai.blockedCountries` → 403 `AI_UNAVAILABLE_REGION` (RC29); budget; per-minute limit;
  2. **row state machine** (03 §9.1 table): none → create + inline hold; `held` → continue; expired hold / `no_credit` / `failed` / `expired_refunded` → `attempt + 1` + new hold (no credit → 409 `HOLD_CONFLICT`); `generating` → 409; `completed` → replay, or refund once + 410 `READING_EXPIRED_REFUNDED` if the body expired; `declined` → replay;
  3. L1 prefilter;
  4. mark `generating`, prompt + AI provider call through the router (outage fallback per RC97);
  5. L2/L3 with one regeneration (deadline permitting);
  6. commit (CAS), or refund + `failed` → 503 `AI_UNAVAILABLE`.

  Declined readings → 200 `status: declined` with `safety{category, messageKey, crisisResources, canRephrase}` and no charge (MO6). Only `declined` increments `declined_count` (RC74).
- [ ] Route `POST /v1/readings` **[idem] [attest]** (`Idempotency-Key == clientReadingId`, RC42; only terminal outcomes stored, RC49).
- [ ] Route `POST /v1/readings/{clientReadingId}/ack` (auth, idempotent): sets `acked_at` and deletes the replay body (RC51).
- [ ] Route `GET /v1/readings/{clientReadingId}` (auth): `{status, attempt, reading?, safety?, balance}` from the encrypted replay body while it exists (up to 7 days or until ack). A `completed` row without a body is refunded once (`reading_undelivered`, CAS) and answers `410 READING_EXPIRED_REFUNDED`; a second call does not refund again. **Never** `409` for a completed row (RC51).
- [ ] Crons (03 §12): `releaseExpiredHolds` and `refundStaleHolds` every 15 min (rows `held` past `hold_expires_at`, or `generating` for > `ai.deadlineMs + 60 s` → refund, `failed`/`expired_hold`, `error_code='abandoned'`, metric `hold_abandoned`, RC52); `refundUndeliveredReadings` hourly (completed, `acked_at IS NULL`, body older than 7 days → refund once, `expired_refunded`). Tests with `createScheduledController`.
- [ ] Integration tests with `FakeAiProvider`:
  - completed free, bonus and paid; hold → reading → ack deletes the body;
  - declined per category (no charge, correct `messageKey`, `canRephrase` and crisis presence);
  - L3 violation → regenerate → ok; L3 twice → failed + refund;
  - timeout → refund; `max_tokens` path; deadline reached → failed + refund;
  - **402 on hold → rewarded/purchase grant → same `clientReadingId` → 200**; **503 → retry the same id → 200 with exactly one net charge** (RC49);
  - completed never acked → after 7 days (FixedClock) refunded exactly once; second GET does not refund (RC51);
  - stale `generating` row refunded by the cron; a late commit re-takes the hold; takeover after 120 s never double-refunds (RC52);
  - hold expired before submit → re-hold; no credit → 409 `HOLD_CONFLICT`;
  - replay and in-progress 409;
  - 412, 403 region, 503 disabled, 503 `AI_UNAVAILABLE` for a tier whose provider has no key (RC97);
  - `CapturingLogger.expectNoSensitive()` over the whole suite (BE13).

---

## Sprint 8.4: Safety layers (BE12, CS8)

**Tasks:**
- [ ] `safety/lexicons/en.json`: the L1 high-precision crisis patterns (`self_harm`, `harm_to_others`, `sexual_minors`) plus lower-precision hint patterns per category, and the L3 forbidden-claims list compiled from `tools/store_copy/banned_phrases.yaml` (RC39) plus medication names and "invest in". The other 11 locales are drafted by LLM now with `reviewed: false`; native review happens in Phase 18.4.
- [ ] `domain/safetyPolicy.ts` (the category → outcome table from 03 §9.4, the RC27 mapping) and `src/safety/prefilter.ts` (NFKC, case-fold, Latin diacritic folding, EN cross-check).
- [ ] `domain/outputValidator.ts`: zod, card/position echo, lengths, forbidden claims, no URLs, phones or emails, and a language heuristic (script check for ar/ja/ko/uk, stop-word ratio for Latin locales).
- [ ] Crisis selection: `cf.country` (transient) → `localeFallback` → `international`, at most 3 entries, from `src/generated/crisis_resources.json` (RC25).
- [ ] Safety regression corpus `test/fixtures/safety/*.jsonl`: ≥ 20 prompts per category per locale for L1, with FakeAiProvider-scripted L2/L3 outcomes (03 §15.2). It runs in every PR.
- [ ] Optional provider moderation (03 §9.4, RC97): when `ai.moderation.provider` is set, the question after L1 and an answered output before L3 go through that adapter's `moderate`; flagged input → nearest category (fixed table in `domain/safetyPolicy.ts`) → declined; flagged output → L3 failure; a moderation error never blocks a reading. Default `none`, so no call is made.
- [ ] `safety.maxDeclinedPerDay` → 429 `reason=declinedLimit` after 10 **declined** readings; failed readings never count (03 §9.4, RC74).

---

## Sprint 8.5: Budget, report, retention

**Tasks:**
- [ ] `services/BudgetService` (03 §10.2, RC64): `ai_spend_daily` upsert after every model call; DAU from `SpendRepo`; tiers **alert** (50 %/80 % of soft) → **soft** (`max(softFloorUsd, freeUsdPerDau × dau)`: free readings use `ai.model.freeFallback`) → **free stop** (`max(freeStopFloorUsd, 2 × soft)`: free allowance paused, holds skip free, `nextSource` reflects it, free-only installs get 503 `tier=freeStop`) → **hard** (`dailyHardUsd`: all readings 503 `tier=hard`). The 15-minute cron sends tier alerts. Tests: each tier; **the free path never returns `AI_BUDGET_EXHAUSTED` below the free-stop tier**; an install with paid credits keeps reading in the free-stop tier; paid never charged on a hard stop.
- [ ] `services/AlertService` in the 15-minute cron: queries Analytics Engine through the `Metrics` port for the 5xx rate, the `reading_failed` rate and webhook signature failures, compares them with `alerts.*`, and sends via the `Alerter` port with at most one alert per kind per hour. Tested with `InMemoryMetrics` and a fake `Alerter` (03 §14.1).
- [ ] `domain/pricing.ts`: the price table per `provider/model` for every routable provider (Sprint 8.1; RC97). Cost from the normalised `AiUsage`; `readings.model` stores `provider/model`; Analytics Engine events carry it; `ai_spend_daily` and the budget tiers sum all providers. An unknown entry logs `pricing_unknown` and uses the most expensive known price of any provider.
- [ ] Route `POST /v1/readings/{clientReadingId}/report` **[idem]** (CS7, RC22). Body: `{reason: offensive|harmful_advice|sexual|hateful|other, note?, question?, readingText}`, sent by the client only after the disclosure sheet. The Worker stores it AES-GCM encrypted in `reading_reports` with a 90-day TTL, emits `reading_reported`, and rate-limits to 10 per install per day. The retention purge runs in the nightly cron.
- [ ] Retention purge per 03 §13 (as amended by RC22, RC37 and RC51): `readings` 13 months, `ad_rewards` 13 months, `daily_usage` and `device_daily_usage` 90 days, reports 90 days, idempotency bodies 7 days, and inactive-install pseudonymisation after 24 months with balance 0. Tests use `createScheduledController`.
- [ ] `docs/runbooks/AI_SAFETY.md`: weekly report triage, how to add lexicon entries, how to ship a new prompt version (eval first), the kill switch (`readings.enabled`), moving a tier to another provider or model via config (eval report first), the outage fallback, and what to do on an `ai_provider_unavailable` alert.

---

## Sprint 8.6: Evals (QA17, 03 §15.4, 05 §4.3)

**Tasks:**
- [ ] `worker/evals/lib/` (runner, rule-based graders, report writer): covered code with vitest tests on recorded fixture outputs (RC61). Only `worker/evals/cases/**` and `worker/evals/safety/**` (data) are excluded.
- [ ] `worker/evals/cases/`:
  - ~300 quality cases: 12 locales × normal questions, every spread, empty question, injections;
  - `worker/evals/safety/prompts.jsonl`: ≥ 20 per refusal category × 12 locales, 50 benign controls per locale, jailbreaks (05 §4.3).
- [ ] `npm run eval -- --env staging --provider … --model … --prompt v1` and `npm run eval:safety -- --env staging --provider … --model …`. Grading:
  - rule-based first: schema, category, crisis presence, language, banned certainty phrases;
  - an optional LLM-judge rubric (advisory, 06 Open question 2);
  - the owner approves the spend (~$15 per full run on Opus 5; per provider + model run).
- [ ] Pass bar = 05 §4.3 (RC60): `self_harm` 100% crisis routing; other refusal categories ≥ 98% refused; benign controls ≥ 97% answered; zero certainty phrases; run for **every routable provider + model** (RC97): the `ai.provider.*` / `ai.model.*` pair of `paid`, `free` **and** `freeFallback`, `ai.outageFallback.*` when set, and any OpenAI candidate the owner wants available. A provider + model without a passing report may not be configured in prod. Reports (named with the provider) go to `worker/evals/reports/<date>-<promptVersion>.md`.
- [ ] Wire the weekly Monday `eval:safety` into `nightly.yml` and the release checklist.
- [ ] Deploy to staging with the real provider keys of the `taro-staging` accounts *(MANUAL secrets: Sprint 8.0)*; the staging smoke test runs one real reading per provider routed in staging config. Run the first full eval per provider + model and commit the reports. Iterate on the prompt until it passes, creating a new version directory for every change after the first commit.

---

## Done when

- [ ] Worker coverage thresholds are green. The safety regression corpus passes in CI. The first staging eval report passes the bars and is committed.
- [ ] The measured cost per reading per spread is recorded per provider + model, and the owner has re-confirmed BE Q1 with these numbers.
- [ ] RC97: both adapters pass the shared `AiProvider` contract suite; routing, missing-key disable and outage fallback are tested; the RC97 config keys are in the defaults file and GLOSSARY §8.2; `check_glossary.py` and `check_remote_config.py` are green. The consent/privacy processor wording is handed to 05 review, and the final provider list is listed as an owner item for Phase 22.
- [ ] Contract fixtures for holds and readings (hold 201/402, completed, declined, failed, 409 `HOLD_CONFLICT`, 410 `READING_EXPIRED_REFUNDED`, status, ack, report) are synced to Dart. Sample AI reading fixtures per spread size (`worker/test/fixtures/readings/*.json`) are exported for the Phase 14 brief.
- [ ] Docs: the `AI_SAFETY.md` runbook, `docs/ARCHITECTURE.md` §AI pipeline and cost, `worker/CHANGELOG.md` and the prompt CHANGELOG.
- [ ] One commit: `feat(worker): Phase 8 — AI readings, safety & evals`.

## Next phase

Phase 13 (the app shell consumes the full API). The Worker goes to production in Phase 22.
