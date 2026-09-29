# Taro — Specification Set

**App:** Taro, a reflective tarot journal with AI readings (Flutter, iOS + Android), bundle `com.vshyrochuk.taro`
**Status:** v1.1 reconciled (2026-09-27). RC1–RC95 are applied; see [00_DECISIONS.md](00_DECISIONS.md) (decision log) and [GLOSSARY.md](GLOSSARY.md) (canonical names).
**Source facts:** `../CONTEXT.md` (locked decisions D1–D16, store-policy constraints)

---

## 1. Index

| File | Prefix | Purpose |
|---|---|---|
| [01_PRODUCT.md](01_PRODUCT.md) | PR | What Taro is: positioning, v1 feature set, screens S01–S33 and every state, flows F1–F8, content model, accessibility, RTL, the design-token contract for Claude Design, and the analytics catalogue. |
| [02_ARCHITECTURE.md](02_ARCHITECTURE.md) | AR | How the Flutter client is built: 3 packages + app with folder layering (RC95), Riverpod DI/state, ports with Prod/NoOp/Fake, drift (journal + device databases), Worker API client, bootstrap, flavors, consent sequencing, backup codec. |
| [03_BACKEND_WORKER.md](03_BACKEND_WORKER.md) | BE | The Cloudflare Worker, source of truth for credits: identity and attestation, the D1 ledger, pre-draw holds, purchases, rewarded SSV, AI readings with safety layers, budget tiers, remote config, retention, observability. |
| [04_MONETIZATION.md](04_MONETIZATION.md) | MO | What is sold and how: product catalogue and prices, credit buckets, IAP client state machines, banner allow-list, rewarded ads, UMP/ATT order, paywall UX rules, edge cases, monetization config and KPIs. |
| [05_COMPLIANCE_STORE_ASO.md](05_COMPLIANCE_STORE_ASO.md) | CS | Passing review on both stores: guideline matrices, disclaimers, AI safety requirements and the safety-eval pass bar, privacy labels and policy, age rating, App Review notes, `aso.yaml`, `asa` gaps, ASO. |
| [06_QUALITY_TESTING_CI.md](06_QUALITY_TESTING_CI.md) | QA | Making quality mechanical: ≥ 90 % coverage per unit, the exclusion list, test pyramid, goldens, repo checks, Worker testing, CI on Gitea, release checklist, Definition of Done. |
| [backup_schema_v1.json](backup_schema_v1.json) | — | The frozen JSON Schema of the user backup file (RC70). The app's copy must be byte-identical. |
| [00_DECISIONS.md](00_DECISIONS.md) | RC | Produced by Phase 1 (2026-09-27): the decision log (RC1–RC93, RC94, RC95) and the owner decisions. |
| [GLOSSARY.md](GLOSSARY.md) | — | Produced by Phase 1 (2026-09-27): the canonical names (IDs, endpoints, tables, config keys, ports, events). The only source of spelling. |

Ownership when specs disagree: product behaviour and screen states → 01; wire format, config key names, retention and money logic → 03; prices, packs and ad rules → 04; store and legal copy, the safety pass bar → 05; test and coverage rules → 06. An RC row in `00_DECISIONS.md` overrides all of them; `GLOSSARY.md` is the only source of spelling.

## 2. Reading order

1. `../CONTEXT.md`: why the project exists and what is locked (D1–D16).
2. **01 Product**: what the user sees. Read §3 (locked decisions), §7.3 (draw ritual), §8 (screens and states) and §9 (flows) first.
3. **04 Monetization**: how free, rewarded and paid readings work from the user's side.
4. **03 Backend Worker**: how the Worker enforces it. Read §2.3 (idempotency), §5 (balance and holds), §9.0–§9.1 (hold and reading pipeline) and §10 (budget).
5. **02 Architecture**: how the client is structured to match.
6. **05 Compliance**: what reviewers check and what the store listing says.
7. **06 Quality**: how all of the above is tested and gated.
8. `00_DECISIONS.md` (decision log) and `GLOSSARY.md` (canonical names), then `../phases/README.md` (the implementation plan).

## 3. Glossary of core terms

| Term | Meaning |
|---|---|
| **Install ID** | Random UUID v4 created on first launch and kept in secure storage (iOS Keychain survives reinstall; Android does not). It owns the install's credits on the Worker. There are no user accounts. |
| **Install secret** | 256-bit random value stored next to the install ID and sent only at registration. Re-registering a known install ID requires it (RC54). |
| **Device key** | Android: a hash derived from `ANDROID_ID`, which survives reinstall. iOS: DeviceCheck bits. It keys the free allowance and rewarded cap per device, so a reinstall cannot mint free readings (RC53). |
| **Install token** | Short-lived (7-day) Ed25519 JWT the Worker issues after attested registration; sent as `Authorization: Bearer`. |
| **Trust level** | `high` (App Attest / Play Integrity passed) or `low` (attestation unavailable; tighter free-reading caps and proof-of-work at registration). |
| **Credit buckets** | `free` (daily allowance, resets at the install's local midnight), `bonus` (rewarded ads; shown to users as "earned readings"), `paid` (verified IAP packs). Consumed in that order. One reading costs exactly one credit. |
| **Ledger** | Append-only D1 table of every credit movement. Balances are sums over it; there is no cache table. |
| **Pre-draw hold** | `POST /v1/readings/holds`, called on **Begin** before the shuffle. It reserves one credit, so the paywall can only appear before any card is drawn. It is refunded if unused, failed, declined or undelivered (RC50). |
| **`clientReadingId` / attempt** | The client's UUID for one draw. It is also the idempotency key for the hold and the reading. A retry with the same ID runs a new attempt; stored errors are never replayed (RC49). |
| **Delivery ack** | `POST /v1/readings/{clientReadingId}/ack` after the device has stored the reading. Unacknowledged readings are refunded after 7 days (RC51). |
| **`BalanceDto` / `CreditBalance`** | The balance on the wire (03 §5.1) and in the client domain (02 §4): buckets, `canRead` + `canReadReason`, `nextSource`, `paidBlocked`, `purchasesAllowed`, rewarded state, `ledgerVersion`. |
| **`ledgerVersion`** | `installs.state_version`, bumped on every per-install mutation; the client never lets an older response overwrite a newer one (RC67). |
| **`purchasesAllowed`** | `false` for blocked installs or installs in refund debt; the client hides pack buttons. Verified purchases are still always granted (RC66). |
| **`purchaseBinding`** | Values the Worker returns at registration for StoreKit `appAccountToken` and Play `obfuscatedAccountId`; the install ID itself is never given to a store. |
| **Reward intent** | Worker-issued opaque ID for one rewarded ad, passed to AdMob as SSV `userId` and `customData`. The grant happens only through the AdMob **SSV** callback to the Worker. |
| **Classic reading** | A reading without AI (authored card meanings per position), offered when AI consent is declined, the region is unsupported, or readings are paused. Free, offline, screen S32 (RC71). |
| **Budget tiers** | Soft (free readings switch to a cheaper model), free stop (free allowance paused; paid and earned readings still work), hard (all AI readings paused). Never shown as a paywall (RC64). |
| **Refusal / decline** | A question in a restricted category (health, pregnancy, death, legal, financial, gambling, self-harm, …) is declined at no cost; self-harm shows crisis resources. |
| **Remove Banner Ads** | The one non-consumable IAP. It removes banners only; optional rewarded ads stay (RC80). |
| **Support ID / transfer code** | Support ID: first 8 hex chars of `SHA-256(installId)`. Transfer code: a single-use token the Worker issues when a new install re-submits a purchase already claimed by an old install; it lets the owner move unspent credits (RC84). |
| **Flavors / `prodStaging`** | `dev`, `staging`, `prod`, plus the `prodStaging` build (prod bundle ID, staging Worker, sandbox IAP) for internal testers (RC78). |
| **S-IDs, F-IDs** | Screen IDs S01–S33 and flow IDs F1–F8 in 01 §8–§9. |
| **RC** | A reconciliation decision in `00_DECISIONS.md`. RC1–RC48 fix naming conflicts between specs; RC49–RC93 are review-pass fixes; RC94 records the glossary-defined names; RC95 folds five client packages into the app (3 packages + app). All are applied to the specs. |
| **Packages / app layers** | Three packages — `taro_core` (pure Dart domain, ports, use cases; port fakes in its `test/fakes/`), `taro_ui` (design system, tokens), `taro_attestation` (native plugin) — and the app `apps/taro`, whose layers are folders: `lib/data/`, `lib/services/`, `lib/l10n/`, `lib/features/`, `assets/deck/`, `test/helpers/`. Layering is enforced by the `tools/check_architecture.dart` import-graph check (02 §2.1, RC95). |

## 4. Owner decisions

**Answered 2026-09-27:** #1 deferred (decide after beta cost data; model stays remote-configurable). #3 confirmed, stays configurable (1–5). #14: devices changed to **universal** (iPhone + iPad, Android phone + tablet, see PR16/RC24); v1.1 scope cuts stay. All other defaults are confirmed.

### Original list

Only product or business decisions are listed. Each has a default that the specs and phases already assume; confirm it or override it in Phase 1 Sprint 1.3. An override is recorded in `00_DECISIONS.md` and the affected specs and phases are edited in the same commit.

| # | Decision | Default in the specs | Where |
|---|---|---|---|
| 1 | **AI model and budget for free readings.** Quality vs cost of the free daily reading (≈ $0.017 per three-card reading on Sonnet 5, ≈ $0.009 on Haiku 4.5, ≈ $0.04 on Opus 5). | Free: `claude-sonnet-5`, falling back to `claude-haiku-4-5` in the soft budget tier. Paid: `claude-opus-5`. These are the Anthropic defaults; each tier's provider is server config (`ai.provider.*`, Anthropic or OpenAI, RC97). Budget sized at $0.03 per daily active install; hard stop $300/day. Revisit after the beta. | 03 BE10, §10.2, Q1; RC64 |
| 2 | **Pack sizes and prices.** | 3 / 10 / 30 readings at $1.99 / $4.99 / $9.99; Remove Banner Ads $3.99. Enrol in the App Store Small Business Program and the Play 15 % tier. | 04 §4, §4.1, Q6 |
| 3 | **Free AI readings per day.** | 1 (config range 1–5; never 0, because the store copy promises it). | 04 MO14, 03 §8.2 |
| 4 | **Rewarded ads.** | On; +1 reading per ad; 3 per day; 5-minute cooldown; offered only when the free reading is used up. | 04 §9, Q7; RC57 |
| 5 | **Play target audience.** Including 13–15-year-olds widens reach but needs age-dependent ad consent in the EEA. | Play 16–17 and 18+; Apple rating 13+; AI processing based on contract; the policy says "not directed at children under 16". | 05 CS4, Q5; RC93 |
| 6 | **Territories excluded at launch.** | China mainland, Russia, Saudi Arabia, UAE, Qatar, Kuwait, Bahrain, Oman, plus countries where the API of any routable AI provider (v1 Anthropic, OpenAI) is not offered. | 05 CS16, Q2; RC97 |
| 7 | **Family Sharing for Remove Banner Ads** (irreversible in App Store Connect). | On. | 04 MO17, Q8 |
| 8 | **Recovering paid credits after an Android reinstall or a new iPhone without Keychain migration.** | Manual support transfer, run by the owner, only with a transfer code proving the same store account. No automatic cross-device credits. | 03 §6.6, 04 §12.9; RC84 |
| 9 | **Send Apple consumption information on refund requests** (can reduce refund abuse; needs a privacy-policy update). | Off in v1. | 03 Q4, 04 Q3 |
| 10 | **Deck art pipeline (D15)**: who produces 78 cards + card back, with which tool, by when. | Placeholder typographic cards until the art lands; art is required before store screenshots (Phase 18). | 01 §11, Phase 1 Sprint 1.3 |
| 11 | **Who verifies crisis-line numbers** for the 12 locales' main countries. | The owner, from official sources, before launch and every 6 months; entries older than 200 days fail the release build. | 03 §9.5, Q3; 05 §4.2 |
| 12 | **Domain and API hosts.** | `taro.vshyrochuk.com` (landing, privacy, terms, support), `api.taro.vshyrochuk.com`, `api-staging.taro.vshyrochuk.com`. | 03 Q5, 05 CS10 |
| 13 | **Store name and category.** | "Taro: Tarot Card Reading"; Lifestyle (Apple secondary: Entertainment); "AI" kept out of the name. | 05 CS1, CS2, Q6 |
| 14 | **Form factors and v1 scope cuts.** | **Universal (confirmed)**; home-screen widget, share images and extra spreads in v1.1; no subscriptions, no interstitials in v1. | 01 PR11, PR16; 04 MO3, MO9, Q1, Q2 |
