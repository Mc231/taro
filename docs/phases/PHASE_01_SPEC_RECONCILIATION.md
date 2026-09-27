# Phase 1: Spec Reconciliation & Owner Decisions

**Status:** ✅ Complete (2026-09-27). All owner items answered (Play account: personal; support email: owner Gmail).
**Depends on:** none
**Parallel with:** Phase 9 (asa gaps) can start once Sprint 1.2 is done.

---

## Overview

The six specs in `docs/specs/` were written in parallel, and several of them were written before the others existed. They agree on the shared contract but **contradict each other on concrete names**: card IDs, spread IDs, product IDs, endpoint paths, error codes, config keys, table names, state-management library, golden tooling, banner placements, ATT pre-prompt, age rating, iPad support, and the behaviour when AI consent is declined.

Code cannot be written against two names for the same thing. This phase resolves every conflict in writing **before Phase 2 starts**. The result is one decision log and edited specs, so that every later phase references a single name.

The table in Sprint 1.1 lists every conflict found while this plan was written (RC1–RC48), followed by the **review-pass decisions RC49–RC93** (2026-09-26). The review pass has **already been applied** to specs 01–06 (status "Draft v1.0.1"); Sprint 1.1 only confirms those rows or records overrides. Where an RC49+ row changes an earlier row, the earlier row says so. Each row has a **default resolution**, which later phases already assume. The owner may override any default. An override is recorded in the decision log, and the phases that use that name are edited in the same commit.

**Output of this phase:**
- `docs/specs/00_DECISIONS.md`, the reconciliation log. It has one row per RC-ID with the chosen resolution, the spec sections edited, and the date.
- Specs 01–06 edited so they no longer contradict each other. Each spec's status moves from "Draft v1" to "v1.1 reconciled".
- Owner answers recorded for every open question that has a cost or legal impact (Sprint 1.3).
- `docs/specs/GLOSSARY.md`, the canonical names: IDs, endpoints, tables, config keys and ports.

---

## Specs referenced

All six: `01_PRODUCT.md`, `02_ARCHITECTURE.md`, `03_BACKEND_WORKER.md`, `04_MONETIZATION.md`, `05_COMPLIANCE_STORE_ASO.md`, `06_QUALITY_TESTING_CI.md`, plus `../CONTEXT.md` (D1–D16).

---

## Sprint 1.1: Resolve cross-spec conflicts

**Tasks:**
- [x] Create `docs/specs/00_DECISIONS.md` with columns `RC-ID | Topic | Conflict (spec §) | Resolution | Specs edited | Date`.
- [x] For each row below, confirm the default or record an override, then edit every affected spec section in the same change.
- [x] Add a "Reconciled by 00_DECISIONS.md RCx" note next to each edited decision row (PR/AR/BE/MO/CS/QA) so the history stays traceable.

| RC | Topic | Conflict | Default resolution (assumed by later phases) |
|---|---|---|---|
| RC1 | Card IDs | 01 §10.1 `major_00`, `cups_03`, 01–14 numbering. 02 §4 `major_00_fool`, `cups_01_ace`. 03 cross-spec `major_00_fool`, `pentacles_king` | **01 wins**: `major_00`…`major_21`, `{wands,cups,swords,pentacles}_01`…`_14`. Edit 02 §4 and 03 §9.1 examples and the §Cross-spec contract. |
| RC2 | Spread IDs | 01 §10.3 has six spreads. 02 has `daily_single`, `three_past_present_future`. 03 has `single`, `three_card`, `celtic_cross` | **01 wins**: `single`, `three_ppf`, `three_sao`, `relationship`, `two_paths`, `celtic_cross`. The daily card is not a spread. Edit 03 `ai.maxTokensBySpread` keys and 02 `Spread` examples. |
| RC3 | Pack product IDs and sizes | 03 §6.1 `readings_5/15/40`. 04 §4 `readings_3/10/30` at $1.99/$4.99/$9.99. 05 CS12 `readings_pack_s/m/l` | **04 wins (it owns economics)**: `com.vshyrochuk.taro.readings_3`, `.readings_10`, `.readings_30`, `.remove_ads`. Credits live in `worker/src/monetization/catalog.ts` (MO2), not in config. A size change means a new product ID. Analytics aliases stay `pack_s/m/l` (01 §15). Edit 03 §6.1, 05 CS12 and `aso.yaml` §8.1, and 06 `check_iap_ids.py` paths. |
| RC4 | Endpoint paths | 02 §6.3, 03 §2–§9 and 04 §7 differ on balance, purchases, rewarded, SSV, webhooks, timezone, challenge and token | **Canonical set:** `POST /v1/attest/challenge`, `POST /v1/installs`, `POST /v1/installs/token`, `PUT /v1/installs/me/timezone`, `DELETE /v1/installs/me`, `GET /v1/config`, `GET /v1/balance`, `POST /v1/readings`, `GET /v1/readings/{clientReadingId}` (**new in 03**, for resume per 02 §6.3), `POST /v1/readings/{clientReadingId}/report` (**new in 03**, CS7), `POST /v1/purchases/verify` (single route with a `platform` discriminator; 03's Apple and Google handlers become internal services), `POST /v1/rewards/intents`, `GET /v1/rewards/intents/{intentId}`, `POST /v1/rewards/intents/{intentId}/cancel` (RC57), `POST /v1/readings/holds` (RC50), `POST /v1/readings/{clientReadingId}/ack` (RC51), `GET /v1/ads/admob/ssv`, `POST /v1/webhooks/appstore`, `POST /v1/webhooks/googleplay`, `GET /v1/health`. **No admin route** (RC84 replaces the former `POST /v1/admin/credits/transfer` with an owner-run script). |
| RC5 | Error envelope and codes | 02 §3 uses lower-case codes and `422 content_refused`. 03 §2.2 uses UPPER_SNAKE and declined readings return `200 status: declined`. 04 has `402 no_credits` and `429 timezone_change_throttled` | **03 wins.** Also add `412 AI_CONSENT_REQUIRED` (RC28) and `403 AI_UNAVAILABLE_REGION` (RC29). Edit the 02 §3 `Failure` mapping table and 04 §5.4/§7. |
| RC6 | Balance DTO | 02 `CreditBalance`, 03 `BalanceDto`, 04 `CreditState` | **Wire: 03 `BalanceDto`** plus `ledgerVersion` (defined by RC67 as `installs.state_version`), `rewarded.cooldownEndsAt`, `canReadReason` (RC74), `purchasesAllowed` / `purchasesBlockedReason` (RC66) and `free.paused` (RC64). The client domain type is `CreditBalance` in `taro_core`. The bucket is named `bonus` on the wire and "earned readings" in the UI. |
| RC7 | Ledger schema | 03 §4 has `ledger`, `ad_rewards`, `reading_hold/refund`. 04 §5.2 has `ledger_entries`, `reward_intents`, `reward_grants`, reserve/commit/release | **03 DDL wins.** 04's logical kinds map onto it: reserve→`reading_hold`, release→`reading_refund`, commit→`readings.status='completed'`. Add `purchases.is_test`. Edit 04 §5.2, §7 and §18. |
| RC8 | Remote config keys | Names differ across 01 §20, 02 §9.4, 03 §8.2, 04 §13, 05 and 06 | **03 owns the names (01 says so).** 04's knobs move into 03's namespaces: `readings.freeDaily` (range 1–5, MO14), `readings.enabled` (the only reading kill switch; replaces `ai.enabled` and `ai.readings_enabled`), `readings.tzCooldownHours` (24, range 12–168), `rewarded.{enabled,amount,dailyCap,cooldownSec,intentTtlSec,grantPollTimeoutSec,loadTimeoutSec,allowedAdUnitIds}`, `ads.{enabled,bannerEnabled,bannerScreens,bannerMinCompletedReadings,attPrepromptEnabled}`, `store.{enabled,packs[],verifyRetryWindowHours,pendingHoldMinutes}` (packs have enabled, sortOrder and Worker-injected credits), `spreads.enabled` (no per-spread cost key, RC62), `ai.consentVersion`, `ai.questionMaxChars`, `ai.blockedCountries`, `app.minVersion.{ios,android}`, `app.recommendedVersion.*`, `balance.staleAfterSec`, `review.promptAfterPositiveReadings`. There is one schema (`worker/src/config/schema.ts`) and one defaults file (`worker/config/remote_config.default.json`). |
| RC9 | Purchase-to-install binding | 03 §6.1 uses UUIDv5 for `appAccountToken` and HMAC for `playAccountId`, returned at registration. 04 MO15 uses the raw installId and sha256 | **03 wins.** On Android the binding never blocks a claim (first valid claim wins); on iOS it does, per RC85. 04 MO15 and §7 are already edited. |
| RC10 | Google acknowledgement | 03 BE8: the Worker acknowledges. 04 MO8: the client consumes and the Worker does not acknowledge | **03 wins.** The Worker acknowledges right after the grant, and the client still consumes after a `granted` response. |
| RC11 | Which calls need attestation | 02 includes purchases, 03 excludes them, 04 includes them | **03 wins**: `[attest]` on `POST /v1/installs/token`, `POST /v1/readings/holds` (RC50), `POST /v1/readings`, `POST /v1/rewards/intents` only. |
| RC12 | Play Integrity API | 02 uses Standard only. 03 uses Classic at registration and Standard per call | **Superseded by RC87: Standard API only.** |
| RC13 | Client state and test tooling | 02 uses Riverpod + freezed + alchemist + patrol. 04 has "bloc". 06 says no freezed and uses `matchesGoldenFile` | **Riverpod 3 + freezed (02)**, with `*.freezed.dart` added to the 06 exclusions. **Goldens use 06 QA8** (built-in `matchesGoldenFile` + `TaroGoldenComparator`); alchemist is dropped from 02. **Integration uses patrol** (built on `integration_test`) because native ATT/UMP/StoreKit dialogs are required. 04's `StoreBloc` and `OutOfReadingsBloc` become the `StoreController` and `OutOfReadingsController` Notifiers. |
| RC14 | Local storage | 02 uses drift only. 04 uses sqflite `unverified_purchases` and secure storage for Remove Ads | **drift (02).** 04's queue is drift `purchase_outbox`, and the Remove Ads cache is drift `entitlements`. |
| RC15 | Package layout | 04 assumes `taro_monetization`. 06 names `taro_test_support`. Token file paths differ between 01 §14 and 02 §14 | **02's package list.** No `taro_monetization`: its ports and logic go to `taro_core`, adapters to `taro_services`, repositories to `taro_data`, and UI to `apps/taro/lib/features/paywall`. The test package is `taro_testing`. The design drop goes to `docs/design/taro.tokens.json` (01), the generator is `tools/tokens/` (02), and output goes to `packages/taro_ui/lib/src/tokens/generated/`. **Token names follow 01 §14** (product owns the design contract); edit 02 §14.2. |
| RC16 | Coverage exclusions and pragmas | 02 excludes `main_*.dart` and allows listed pragmas. 06 bans pragmas and does not exclude main | **06 wins on pragmas (banned).** Add to the exclusion list: `*.freezed.dart`, `firebase_options_*.dart`, `**/lib/src/generated/**` (gen-l10n per 02 §11), and `apps/taro/lib/main_*.dart` (a three-line entrypoint; the logic is in `bootstrap()`, which is covered). Edit 06 §5.3 and `sonar.coverage.exclusions`. |
| RC17 | Tabs, routes, journal and backup model | 01 §8.1 has 4 tabs and `/home`, `/reading/*`. 02 §8.1 has 5 tabs and `/today`, `/spreads`, `/history`, `/shop`. 01 puts notes on readings; 02 has a separate `JournalEntry` with mood and tags. The backup formats differ | **01 wins on tabs, routes and data model**: notes live on `Reading` and `DailyCard`; free-form entries, mood and tags are v1.2. **Backup**: 01 §7.11 structure (`format: "taro.backup"`) plus 02's `checksum` field. Edit 02 §4, §6.1, §8.1 and §12. |
| RC18 | Banner placements | 01 PR13 allows S05, S14 and S16 only. 04 §8 also allows spread picker, reading, journal entry and card detail. 05 forbids banners on the reading screen | **Strictest wins (01 PR13)**: `kBannerAllowList = {home, journal_list, learn_library}`. Edit 04 §8. |
| RC19 | ATT pre-prompt; skipping ATT | 01 PR10 has no pre-prompt. 04 Q4 and 05 CS14 use a neutral pre-prompt | **Neutral pre-prompt (04/05)**, toggled by `ads.attPrepromptEnabled` (default true), with UMP's IDFA explainer disabled. ATT is skipped when UMP gives `canRequestAds == false`. Edit 01 PR10 and §7.12. |
| RC20 | AI consent declined | 01 PR12: daily card, Learn and Journal only. 05 CS6: a "Classic reading" (cards + static meanings) | **Adopt the Classic reading (05)**: free, no Worker call, saved to the Journal as `status: classic`. It is also the fallback for `AI_UNAVAILABLE_REGION` and `READINGS_DISABLED`. Add a state and a flow to 01 §7.4, §8.3 and §9.8. |
| RC21 | When AI consent is asked | 01 asks in onboarding step 3. 02 and 05 ask before the first reading | **Both**: onboarding step 3 (with "Not now"), plus the gate re-prompt before a reading if consent is missing or `ai.consentVersion` has increased. |
| RC22 | Report reading vs "never store text" | 05 CS7 stores reported text for 90 days. 01 PR14 and 03 BE13 say text is never stored | **Adopt CS7 as an explicit, user-initiated exception.** The report sheet discloses that the question and reading are sent. The Worker stores them AES-GCM encrypted in a new `reading_reports` table with a 90-day TTL. Edit PR14, BE13 and 03 §13. |
| RC23 | Age rating | 01 says 12+/Teen. 05 CS4 says 13+. 06's checklist says 12+ | **Apple 13+ (05 CS4); Play target audience 16+ per RC93.** 01 Q3 and the 06 §12 checklist are already edited. |
| RC24 | iPad | 01 PR16 was iPhone-only. 05 Q3 defaults to universal | **Universal (owner decision 2026-09-27; PR16 updated).** Keep the iPad screenshot set in 05 §9.4; add tablet-width goldens (iPad 13", Android tablet) for ★ screens in 06 §3. |
| RC25 | Crisis resources source | 01 bundles them keyed by device region. 03 serves them from the Worker by `cf.country`. 05 bundles `assets/compliance/crisis_resources.json` | **One source, `packages/taro_content/source/crisis/crisis_resources.yaml`**, compiled by `tools/content build` into the app asset and `worker/src/generated/crisis_resources.json`. The Worker selects by `cf.country`; S27 from Help uses the device region. Both carry `verifiedAt` and a 200-day staleness test. |
| RC26 | Deck content location | 01 `taro_content/source/**` YAML. 02 `assets/deck/v1/*.json`. 03 `worker/deck/*.json` + `tools/sync_deck`. 06 `content/deck/<locale>` | **01 §11 pipeline.** `tools/content build` is the only generator. It emits `packages/taro_content/assets/deck/{deck_meta.json,{locale}.json}`, `assets/spreads/spreads.json`, `worker/src/generated/deck/{cards,spreads}.json` and `worker/src/generated/deck_prompt.{locale}.json`. `tools/sync_deck` becomes a parity check. |
| RC27 | Refusal taxonomy | 01: rephrase/refused/crisis. 02: `RefusalCategory`. 03 §9.4 has 10 categories + `canRephrase`. 05: `moderationBlocked` | **03's category list is canonical.** 01's `rephrase` = declined with `canRephrase: true`. 01's `crisis` = `self_harm` or `harm_to_others`. 05's `moderationBlocked` = `sexual_minors` or `hate_or_harassment`. |
| RC28 | AI consent enforcement | 01 wants an endpoint. 02 sends `aiConsentVersion` in the body. 05 wants a header and 412 | **Header `X-Taro-AI-Consent: <version>`** on `POST /v1/readings`, and `412 AI_CONSENT_REQUIRED` if it is below `ai.consentVersion`. No separate endpoint. |
| RC29 | AI region availability | 05 CS16 excludes territories and wants `ai_unavailable_region` | CS16 exclusions are applied in both stores. The Worker also returns `403 AI_UNAVAILABLE_REGION` when `cf.country ∈ ai.blockedCountries`; the client offers a Classic reading (RC20). |
| RC30 | Reading content schema | 01 PR9 `summary/positions/synthesis/reflectionPrompts`. 03 `title/overview/cards[]/synthesis/reflectionPrompts`. 02 `Interpretation.disclaimer` from the Worker | **The wire format is 03's.** The client domain type is `ReadingContent{title, summary (= overview), positions[{positionId, text}], synthesis, reflectionPrompts}`. No disclaimer comes from the Worker (PR9); remove it from 02. |
| RC31 | Reading timeout | 01 PR8: 45 s. 02: 45 s + polling. 03: ≥ 60 s | Client HTTP timeout **60 s**. Show "taking longer than usual" at 20 s. On timeout, poll `GET /v1/readings/{clientReadingId}` per 02 §6.3. Edit 01 PR8 and §9.7. |
| RC32 | Model ID and prices | 03 BE10 `claude-opus-5` with estimated prices | Confirm current model IDs, pricing and structured-output and fallback parameters against the Claude API reference at the start of Phase 8 (Sprint 8.1). |
| RC33 | Rewarded grant polling | 01: 20 s. 02: 30 s. 03: 10 s. 04: config | `rewarded.grantPollTimeoutSec` = 20, polling every 1.5 s, then fall back to the next sync. |
| RC34 | Rewarded entry points | 01: S10 and the Home chip. 04: S10 and the Store screen | S10 (reached from the gate or the Home chip) and S11. Offered only when `free.remaining == 0` (04 Q7). |
| RC35 | Rewarded cooldown | 04 has `cooldown_seconds`; 03 has none | Adopt `rewarded.cooldownSec` = 300 in the Worker (03 §7.1), anchored on the last grant (RC57). |
| RC36 | Firebase project IDs | 02: `taro-dev` / `taro-prod`. 05: `taro-vsh` | `taro-dev` (dev + staging) and `taro-prod`. Edit 05 §8.1 `firebase:`. |
| RC37 | "Delete all data" semantics | 01 §7.10 keeps the install ID, ledger and Remove Ads. 03 §3.6 marks the install `deleted`, and the client wipes secure storage | **01 wins.** `DELETE /v1/installs/me` erases `readings`, `ad_rewards`, `reading_reports`, `idempotency_keys` and past `daily_usage` rows (today's row is kept). It keeps `installs` (status stays `active`, locale nulled), `ledger` and `purchases`. The client keeps the install ID, session token and entitlements. Edit 03 §3.6. |
| RC38 | Worker composition names | 03: `buildApp(deps)`, `AiProvider`, zod + OpenAPI. 06: `createApp`, `LlmClient`, `worker/schemas/*.json`. 02: `worker/contracts/v1/` | **03 wins.** Contract fixtures live in `worker/test/contract/fixtures/`, are copied to `packages/taro_data/test/contract/fixtures/` by `melos run contract:sync`, and are checked by `tools/check_contract_fixtures.py`. Edit 02 §2 and 06 §7. |
| RC39 | Banned-phrases file | 05: `tools/store_copy/banned_phrases.yaml`. 06: `tools/banned_phrases.yaml` | **`tools/store_copy/banned_phrases.yaml` (05)**, also compiled into the Worker L3 lexicon. |
| RC40 | Native code coverage | 06 says there is no native code in v1. 02 AR9 has its own Swift/Kotlin attestation plugin | Gate the `taro_attestation` native code at ≥ 90% lines: Xcode `xccov` for Swift and JaCoCo for Kotlin, run by `check_coverage.py` as units `taro_attestation_ios` and `taro_attestation_android`. Amend 06 non-goals. |
| RC41 | Missing ports | 06 needs `IdGenerator` and `Logger` ports; 02 lacks them | Add `IdGenerator` (`SecureIdGenerator` over `uuid`) and `Logger` (over `package:logging`) to 02 §5. |
| RC42 | Idempotency key for readings | 02 uses `Idempotency-Key = readingId`. 03 has a separate key and `clientReadingId` | Send both headers with the same UUID for readings and holds (`Idempotency-Key == clientReadingId`; the idempotency scope includes the route). Only terminal outcomes are replayed (RC49). For other routes, generate one per user action and reuse it on retry; registration uses a fresh key per attempt (RC55). |
| RC43 | Support code | 01: first 8 hex chars of `SHA-256(installId)`. 04: "first 8 chars + checksum" | **01 format**, labelled "Support ID" in About (04 §12.9). The admin transfer tool resolves the install by store order ID and checks the support code against the hash prefix. |
| RC44 | Gate order | 01 PR5 checks registration first; 02 `ReadingGate` has no registration or region check | `ReadingGate` checks, in this order: registration/trust → AI consent → online → `readings.enabled` / region → spread enabled → balance. It returns `GateDecision.{deviceUnverified, needsAiConsent, offline, readingsPaused, aiUnavailableRegion, spreadDisabled, needsCredits, needsSync, allowed}`. |
| RC45 | Question length | 01: 300. 02: 280. 03: 300 | 300 grapheme clusters, from `ai.questionMaxChars`. |
| RC46 | Resume sync path | 06 §2.5 names `/v1/credits/sync` | `GET /v1/balance` (RC4). Edit 06. |
| RC47 | Budget stop vs paywall | 03 §10.2: never a paywall. 01 S31 is "maintenance" | Map `AI_BUDGET_EXHAUSTED` and `READINGS_DISABLED` to S31 `readingsPaused` with the Classic-reading offer. Never map them to S10. |
| RC48 | 402 race after the draw | 02 §9.3 deletes the pending reading on 402. 01 PR6 and 04 §12.1 keep the drawn cards | **Keep the cards (01/04).** With the pre-draw hold (RC50) this only happens when a hold is lost: the pending reading stays face-down, S10 opens, and after a grant the same draw is resubmitted with the same `clientReadingId`, which RC49 makes work. 02 §9.3, 01 §7.3/§8.3 and 04 §12.1 are already edited. |

**Review-pass decisions (applied to the specs on 2026-09-26):**

| RC | Topic | Finding | Resolution (applied) |
|---|---|---|---|
| RC49 | Reading retry & idempotency | Stored 402/503 were replayed for 24 h, so a retry with the same `clientReadingId` after a purchase or an outage stayed stuck; the ledger UNIQUE blocked a second hold | 03 §2.3: only terminal outcomes (2xx, 400, 422) are stored; every other outcome deletes the idempotency row. `readings` state machine `held → generating → completed \| declined \| failed \| no_credit \| expired_hold \| expired_refunded` (03 §9.1), `readings.attempt`, ledger `ref_id = {readingId}#{attempt}`. Tests: 402 → grant → same id → 200; 503 → retry → 200 with one net charge. |
| RC50 | Paywall before the draw under races | 01 §7.3/PR8 revealed cards in parallel with the request, so a 402 could arrive after the reveal | **Pre-draw hold** `POST /v1/readings/holds` on Begin, before the shuffle (03 §9.0). The reveal runs only while the hold has ≥ 120 s left; a renewal 402 keeps the cards face-down. Edited 01 PR5/PR8/§7.3/§8.3, 02 AR12/§9.3, 04 MO6/§5.5/§12.1. |
| RC51 | Undelivered readings | A lost 200 plus the 24 h body TTL meant charged-but-never-delivered readings and a 409 loop | `POST /v1/readings/{clientReadingId}/ack`; replay TTL 7 days, body deleted on ack; hourly `refundUndeliveredReadings` (reason `reading_undelivered`); `410 READING_EXPIRED_REFUNDED`; never 409 for a completed row. The client retries with the same cards. |
| RC52 | Orphaned holds, double refunds | No cron refunded holds cut by eviction/deploys; the 90 s takeover could double-hold/refund the free bucket | `readings.hold_state` CAS for hold/refund/commit, free refunds keyed by `hold_local_date`, `free_limit` raised in the upsert, 55 s hard server deadline, 120 s takeover, 15-minute `refundStaleHolds` + `releaseExpiredHolds`, metric `hold_abandoned`. |
| RC53 | Android reinstall farming | New UUID per reinstall = new free reading and rewarded cap | Android `deviceKey` from `ANDROID_ID` → `installs.device_key_hash` and `device_daily_usage`; iOS DeviceCheck `bit0` → `device_reused`. Declared in 05 §5.2. 04 §16 and Q5 corrected. |
| RC54 | Install takeover by ID | Re-registration accepted any known `installId` | 256-bit `installSecret` in secure storage, sent only to `POST /v1/installs`, stored as `install_secret_hash`; re-registration requires it (or, on iOS, an assertion by the stored key); otherwise 403. `deleted` rows are reactivated only this way. |
| RC55 | Registration idempotency key | `Idempotency-Key = installId` collided after an iOS reinstall within 7 days (422) | Fresh UUID per registration attempt (and per delete action), reused only for a network retry. |
| RC56 | SSV `userId` | 04 §9.2 sent `userId = installId` to Google | `userId = customData = intentId`; the Worker checks `user_id == custom_data`. |
| RC57 | Rewarded cap semantics | Cap re-checked at SSV could deny an earned reward; dismissed ads used slots; cooldown anchor undefined | Cap counts granted rewards; at most one open intent (new cancels old); cooldown from the last grant; SSV grants any valid unexpired unused intent; `POST /v1/rewards/intents/{intentId}/cancel`; `rewarded.loadTimeoutSec` = 10. |
| RC58 | Auto-continue after purchase | 04 §11 auto-continued the draw; 01 F3 requires tapping Begin | Return to S07 with Begin enabled; nothing auto-starts. |
| RC59 | Banner gap | 04: 8 dp; 05: 16 dp | `space.adGap` ≥ 16 dp everywhere (01 §14.3, 04 §8, Phases 14, 15, 17.2). |
| RC60 | Safety eval pass bar | 05 §4.3 and 06 §7.1 differed | 05 §4.3 owns it: `self_harm` 100 %, other categories ≥ 98 %, benign ≥ 97 %, 12 locales × ≥ 20 prompts per category, for every routable model. 06 references it. |
| RC61 | Worker coverage exclusions | `scripts/**` and `evals/**` were excluded although hand-written | Script logic moves to `src/admin/*`; scripts are thin covered CLIs; eval graders live in `evals/lib/` (covered); only eval case data is excluded. |
| RC62 | Per-spread cost | `spreads.costOverrides` / `Spread.creditCost` contradicted MO4 and "10 Readings" | Removed; cost is the constant 1. |
| RC63 | Sandbox grants in prod | Unlimited free prod credits for TestFlight/license testers | `purchases.sandboxMaxCreditsPerInstallPerDay` 30, `sandboxGlobalCreditsPerDay` 1,000, `sandbox_volume` alert; no public TestFlight links; internal testing on `prodStaging` (RC78). |
| RC64 | Budget tiers and free model | Opus for free readings + a $50 soft stop broke "a free reading every day" | `ai.model.free = claude-sonnet-5`, `ai.model.freeFallback = claude-haiku-4-5`; tiers soft (model downgrade) → free stop (free paused, paid/bonus still work) → hard; sized by `ai.budget.freeUsdPerDau`; store copy separates the free daily card from "1 free AI reading a day". |
| RC65 | Low-trust caps | A global cap could be drained by one attacker; /24 CGNAT blocked honest users | Proof-of-work for `type: none`, 5 such registrations per prefix per day, IPv6 /64, higher cap for CGNAT ASNs, global counter replaced by per-(platform, version) alert buckets. BE-R5 no longer relies on low trust. |
| RC66 | Blocked installs and refund debt | Blocked installs could pay and get nothing; indebted buyers repaid debt | `BalanceDto.purchasesAllowed` / `purchasesBlockedReason (blocked \| refundDebt \| storeDisabled)`; purchase buttons hidden (S11 `purchasesBlocked`); verified purchases always granted, never 403; `paidBlocked = paid < 0`. |
| RC67 | `ledgerVersion` | Undefined in 03; did not change on free consumption | `installs.state_version`, bumped on every per-install mutation; client accepts `≥`, replaces on `>` or newer `serverTime`. |
| RC68 | Analytics before consent | Onboarding events were logged before UMP | Manifest consent defaults denied; `setConsent(allDenied)` at bootstrap; `ConsentAwareAnalytics` buffers ≤ 50 events until `whenResolved`, then flushes or drops. |
| RC69 | Privacy disclosures | Copy said "not stored"; logs 30 vs 7 days; "not linked" promise | Consent copy and policy state: question never stored, reading text until delivered (≤ 7 days), reports 90 days, logs 7 days; 03 §13 is the single source; `tools/check_retention.py`; PR14 "not linked" promise removed. |
| RC70 | Backup schema v1 | Missing `updatedAt`/`drawnAt`/`classic`; checksum canonicalisation undefined | `docs/specs/backup_schema_v1.json` (JSON Schema, frozen) with `data` wrapper, `classic`, `ratingReason`, limits; checksum = SHA-256 over RFC 8785 JCS of `data`; golden fixture. |
| RC71 | Classic reading | No S-ID, route, flow or events | S32 `/reading/:id?mode=classic`, flow F8, `classic_reading_started/completed`; no banner/rate-app credit; exported as `classic`. |
| RC72 | Report sheet | No S-ID or states | S33 with `editing`, `submitting`, `submitted`, `failed`, `offline`, `rateLimited`, `alreadyReported`; `reading_reported{reason}`; local `reported` flag. |
| RC73 | `app.recommendedVersion` | Key without UI | S05 `updateAvailable` dismissible notice, once per version. |
| RC74 | Server limits without client states | `maxPerInstallPerDay` looked like "out of readings"; low-trust caps had no state; failures counted as declines | `canReadReason` and `details.reason`; S07 `dailyLimitReached` (no paywall) and `lowTrustLimited`; only `declined` counts toward `safety.maxDeclinedPerDay`. |
| RC75 | OS backup/restore | drift DB with outbox/caches/consent was backed up | Two drift files: `taro_journal.db` (may be backed up) and `taro_device.db` (excluded on iOS and Android); restore-simulation test. |
| RC76 | Testable bootstrap | `bootstrap()` was not injectable | `TaroEnvironment` interface; `ProductionEnvironment` is pure delegation; `test/bootstrap/bootstrap_test.dart`. |
| RC77 | `taro_testing` and Riverpod | `pumpTaro` in `taro_testing` would break the layering gate | `taro_testing` is Riverpod-free (`pumpTaroWidget`); `apps/taro/test/helpers/pump_app.dart` holds `TaroFakes` → overrides and `pumpTaro`. |
| RC78 | Flavors vs attestation/IAP | `.stg` bundle fails attestation and has no IAP products | `prodStaging` build configuration (prod bundle, staging Worker, sandbox IAP) for internal testing; Worker `attest.allowedAppIds` / `purchases.allowedBundleIds` per env (staging accepts prod + `.stg`). |
| RC79 | App Review notes | Steps did not match the real flow | Notes follow 01 flows and quote ARB labels exactly; `check_store_copy.py` rule `review_notes_labels_exist`. |
| RC80 | "Remove Ads" naming | Rewarded ads remain after purchase | Display name "Remove Banner Ads" in 12 locales and in-app; description "Optional reward videos stay available". Product ID unchanged. |
| RC81 | `CrisisResource` fields | 02, 03 and 05 differed | Canonical schema 03 §9.5 `{name, phone?, sms?, url?, hours?, languages[], verifiedAt}`; 02 §4 and 05 §4.2 edited. |
| RC82 | Config signing, negative-balance key | 04 §13 claimed signing defined in 03; `monetization.refund.negative_balance_enabled` duplicated locked MO16 | Config is not signed (TLS only); the key is deleted. |
| RC83 | Phase dependency cycle | Phase 6.5 needed Phase 10.1 while Phase 10 depended on 6 | Cloudflare/Anthropic/secret setup moved to Phase 6 Sprint 6.0; Phase 10 depends on 1, 9 and 6.5; Phase 12.6 is a separately tracked exit criterion. |
| RC84 | Support credit transfer | Public admin route with a static token; order ID as proof | Owner-run `worker/scripts/credits-transfer.ts` over `src/admin/creditsTransfer.ts`; proof is a `transferToken` issued by `POST /v1/purchases/verify` when the same store account re-submits a transaction claimed by another install; `ADMIN_TOKEN` removed. |
| RC85 | iOS purchase binding | iOS never checked the buyer's install | iOS: `appAccountToken` bound to another active install → `409 PURCHASE_ALREADY_CLAIMED` (+ transfer hint); first-claim-wins only for Android and unbound transactions. Amends RC9. |
| RC86 | Test-only switches | Debug attestation / fake AI selectable by header | `ALLOW_DEBUG_ATTESTATION`, `AI_PROVIDER`, `DEBUG_ATTESTATION_TOKEN` only as `[env.dev]` / `[env.staging]` vars; `check_worker_env.py` + deploy-time check; startup throws in prod. |
| RC87 | Play Integrity API | Classic + Standard doubled native surface | Standard API only; registration binds `SHA256(challenge ‖ installId ‖ deviceKey)` as `requestHash`. Supersedes RC12. |
| RC88 | SonarQube | Sonar gate blocked deploys despite flakiness | Advisory only; the release gate is `check_coverage.py` + `ci`. |
| RC89 | Widget bridge in v1 | Dead `DailyCardWidgetBridge` port and `home_widget` dep | Removed from v1; added in Phase 23.1. |
| RC90 | Raw visual value lint scope | Banned non-UI durations (timeouts, backoff) | Scope limited to `taro_ui` (minus tokens/motion), `features/**/view/**` and `common/**`; non-UI durations via named constants. |
| RC91 | Journal search engine | FTS5 availability unverified | Phase 2.2 spike verifies FTS5 on iOS, Android and CI; fallback LIKE over an indexed lowercase column. |
| RC92 | `.well-known` hosting | ASA-7 could not serve AASA/assetlinks | New ASA-10 (serve `web/.well-known/` with `application/json`); fallback Worker route. |
| RC93 | Teen users and legal basis | EEA 13–15-year-olds treated as adults for ads; AI legal basis was consent | Play target audience 16–17 and 18+; Apple rating stays 13+; AI processing based on contract (Art. 6(1)(b)), consent sheet kept as permission UX; policy says "not directed at children under 16". Amends RC23. |

- [x] Update `docs/CONTEXT.md` §6 open questions with a pointer to `00_DECISIONS.md`.

---

## Sprint 1.2: Canonical glossary

**Tasks:**
- [x] Write `docs/specs/GLOSSARY.md`. Every later phase cites it, so it must list:
  - card IDs (78 generated rows), spread IDs + position IDs (01 §10.3), product IDs (RC3), analytics aliases;
  - endpoints (RC4) with auth, `[idem]` and `[attest]` flags;
  - error codes (RC5) mapped to their `Failure` subtypes (02 §3) and ARB keys;
  - D1 tables (03 §4 + `reading_reports`) and drift tables (02 §6.1 as edited by RC14/RC17);
  - remote-config keys (RC8) with type, default, range and enforcer;
  - ports: Dart (02 §5 + RC41) and Worker (03 §1);
  - screen IDs S01–S33 mapped to route, analytics `screen` enum and banner screen ID (RC18);
  - secure-storage keys (02 §6.2) and secret names (03 §11).
- [x] Add a `tools/check_glossary.py` task to Phase 3's check list (Phase 3 Sprint 3.2; 06 §6.2) (it verifies that the IDs in the glossary match `GLOSSARY.md` tables used by generators).

---

## Sprint 1.3: Owner decisions with cost or legal impact

**Tasks** (record each answer in `00_DECISIONS.md` under "Owner decisions"):
- [x] **BE Q1, model for free readings.** _Deferred to Phase 21 (owner 2026-09-27); not open._ _Owner 2026-09-27: deferred — decide after Phase 21 cost data; keep default until then; model stays remote-configurable._ Default (RC64): `claude-sonnet-5` for free readings, `claude-haiku-4-5` as the soft-tier fallback, `claude-opus-5` for paid; `ai.budget.freeUsdPerDau` = $0.03, soft floor $50, free-stop floor $100, hard $300/day. Revisit after Phase 21 closed-testing cost data.
- [x] **CS4 / RC93, Play target audience.** _Owner 2026-09-27: default confirmed._ Default: 16–17 and 18+ (Apple rating 13+); AI legal basis = contract.
- [x] **BE Q5, API host.** _Owner 2026-09-27: default confirmed._ Default: `api.taro.vshyrochuk.com` (prod), `api-staging.taro.vshyrochuk.com` (staging), local `wrangler dev` (dev). Landing, privacy and terms go on `taro.vshyrochuk.com` (CS10).
- [x] **MO §4.1 prices.** _Owner 2026-09-27: default confirmed._ Default: $1.99 / $4.99 / $9.99 packs and $3.99 Remove Ads. Enrol in the App Store Small Business Program and the Play 15% tier (manual, Phase 10).
- [x] **CS16 territories.** _Owner 2026-09-27: default confirmed._ Default: exclude CHN, RUS, SAU, ARE, QAT, KWT, BHR, OMN, plus countries where the Anthropic API is not offered (list snapshot dated in `00_DECISIONS.md`).
- [x] **BE Q3 / CS §4.2 crisis numbers.** _Owner 2026-09-27: default confirmed._ The owner verifies them (Phase 18 Sprint 18.4). Record who verifies and the source list.
- [x] **BE Q4 / MO Q3 Apple consumption info.** _Owner 2026-09-27: default confirmed._ Default: off.
- [x] **D15 art.** _Owner 2026-09-27: default confirmed._ Decide the art pipeline owner and tool, and a target date for 78 cards + card back (feeds Phase 18). Default: placeholder typographic cards until then (01 §11).
- [x] **Play developer account type.** _Owner 2026-09-27: personal → ≥ 12 testers × 14 days closed test in Phase 21._ Check whether the account falls under the new personal-account rule (≥ 12 testers for 14 days, CS M5). It decides the length of Phase 21. _Still open (owner); tracked in `00_DECISIONS.md` "Still open", answer at Phase 10._
- [x] **CI host.** _Owner 2026-09-27: GitHub origin `git@github.com:Mc231/taro.git` (owner `Mc231`), CI on a self-hosted Gitea pull-mirror of it, as in `quiz_apps`._ Recorded in 05 §8.1 `github:` and 06 QA10.

---

## Sprint 1.4: Spec sign-off

**Tasks:**
- [x] Re-read all six specs end to end after the edits. Grep (`grep -rnF`, plain string) `docs/specs`, `docs/phases` and `docs/CONTEXT.md` for each superseded name and confirm zero matches outside `00_DECISIONS.md` and this phase doc: `readings_5`, `three_card`, `major_00_fool`, `/v1/credits`, `ledger_entries`, `taro_monetization`, `taro_test_support`, `alchemist`, `sqflite`, `12+`, `userId=installId`, `SSV time`, `costOverrides`, `cost_overrides`, `creditCost`, `adGap ≥ 8`, `ads/rewarded/sessions`, `admin/credits/transfer`, `ADMIN_TOKEN`, `reconcileBalances`, `globalFreePerDay`, `requestClassicToken`, `readings_pack_`, `daily_single`, `three_past_present_future`, `cups_01_ace`, `pentacles_king`, `ai.enabled`, `ai.readings_enabled`, `vshyrochuk/taro`, `iPhone-only`, `StoreBloc`, `OutOfReadingsBloc`, `taro-vsh`, `createApp`, `LlmClient`, `content_refused`, `no_credits`, `timezone_change_throttled`, `CreditState`, `unverified_purchases`, `tools/banned_phrases.yaml`, `balance_pill`, `ReadingFlowController`, `PaywallController`, `ReportSheetController`, `RewardedFlowController`, `AdBanner`, `banner_impression_screen`, `ump_consent_result`, `iap.retiredPacks`, `timezone_change_cooldown_hours`, `LocaleProvider`, `features/today`, `grantedAt`, `packages/taro_data`, `packages/taro_services`, `packages/taro_content`, `packages/taro_l10n`, `packages/taro_testing` (added by RC95, 2026-09-27; `apps/taro/lib/l10n` left the list because RC95 made it the l10n folder). (`CONTEXT.md` §4 describes quiz_apps, so its `sqflite` hit is a fact about that repo, not a Taro name.) The same list is in `00_DECISIONS.md` "Override procedure" step 4, so later RCs re-run it.
- [x] Set each spec's Status to `v1.1 reconciled (YYYY-MM-DD)`. (2026-09-27, also `00_DECISIONS.md` and `GLOSSARY.md`.)
- [x] Update `docs/phases/README.md` if an override changes a phase dependency. (No override; Phase 1 row and the Repo / CI path updated.)

---

## Done when

- [x] `docs/specs/00_DECISIONS.md` has a resolution for RC1–RC93 (plus RC94) and all Sprint 1.3 owner decisions.
- [x] `docs/specs/GLOSSARY.md` exists and is referenced from every spec's header.
- [x] Grep check (Sprint 1.4) is clean.
- [x] No code is written in this phase, so the coverage gate is n/a. Docs updated: specs 01–06, `CONTEXT.md`, and this README if overrides changed dependencies.
- [x] One commit: `docs(taro): Phase 1 — Spec reconciliation & owner decisions`.

## Next phase

Phase 2: Repository Bootstrap & Toolchain. Phase 9 (asa gaps) can start in parallel.
