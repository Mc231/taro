# Phase 7: Worker Credits, Purchases & Rewarded Ads

**Status:** 🚧 Code complete (2026-09-29); store credentials + webhook registration in Phase 10
**Depends on:** Phase 6
**Parallel with:** Phases 4, 5, 11, 12

---

## Overview

This phase implements the money paths on the Worker, which is the single source of truth for credits (MO1, BE5):
- the append-only ledger with atomic hold and refund;
- free-daily allowance consumption;
- purchase verification for the App Store and Google Play;
- store webhooks and the voided-purchases backstop;
- the refund policy with a negative paid balance;
- rewarded ads through AdMob SSV;
- the owner-run credit-transfer script used for support recovery (no admin route, RC84).

Every path is idempotent and property-tested for ledger invariants.

**Output of this phase:**
- `services/{BalanceService.hold/refund/commit, PurchaseService, RefundService, RewardService}`, `worker/src/monetization/catalog.ts` (`PRODUCT_CATALOG`), `src/admin/{ledgerAdjust,creditsTransfer}.ts`.
- Routes `POST /v1/purchases/verify`, `POST /v1/rewards/intents`, `GET /v1/rewards/intents/{intentId}`, `POST /v1/rewards/intents/{intentId}/cancel`, `GET /v1/ads/admob/ssv`, `POST /v1/webhooks/appstore`, `POST /v1/webhooks/googleplay`.
- Cron jobs: voided purchases, Google ack retry, reward expiry, sandbox-volume alert.
- `worker/test/fixtures/product_ids.json`, exported for the Dart test (04 §15).

---

## Specs referenced

`03_BACKEND_WORKER.md` BE5, BE6, BE8, BE14, §2.4 (abuse), §4, §5.3, §6, §7, §12, §15.2. `04_MONETIZATION.md` MO1, MO2, MO5, MO6, MO8, MO10, MO14–MO17, §4, §5, §7, §9, §12 (edge cases 12.1–12.25), §13, §14 (Worker metrics), §15 (Worker tests). `00_DECISIONS.md` RC3, RC4, RC6, RC7, RC9, RC10, RC33, RC35, RC43, RC49, RC52, RC53, RC56, RC57, RC63, RC66, RC67, RC84, RC85.

---

## Sprint 7.1: Ledger & consumption (BE5, BE6, MO5, MO6)

**Tasks:**
- [x] Spike (first task): confirm how a D1 `batch` can make later statements conditional on an earlier statement's `changes()` (03 §5.3 step 1). Record the chosen pattern in `docs/ARCHITECTURE.md` §Ledger. *Evidence:* `worker/test/integration/db/batchConditional.test.ts`, `worker/src/repos/batchGuard.ts`, docs/ARCHITECTURE.md §Ledger (one batch, CAS gate + `(SELECT changes()) = 1` chain).
- [x] `domain/ledgerRules.ts`, `domain/consumptionOrder.ts` (free → bonus → paid; free skipped while the free-stop tier is active or the device used today's allowance; `paidBlocked = paid < 0`; `purchasesAllowed = status != blocked && paid >= 0 && store.enabled`), `domain/allowance.ts` (snapshot `free_limit`, raised to `MAX(free_limit, current)` inside the upsert; low-trust caps; `device_reused`). *Evidence:* `worker/src/domain/{ledgerRules,consumptionOrder,allowance}.ts`; `test/unit/domain/{ledgerRules,consumptionOrder,allowance}.test.ts`.
- [x] `services/BalanceService.hold(install, reading)`: the 03 §5.3 algorithm without a cache table (conditional `INSERT … SELECT … WHERE SUM ≥ 1`), CAS on `readings.hold_state`, `hold_local_date`, `device_daily_usage` on Android, `state_version + 1`. Returns `{chargeSource}` or `402 INSUFFICIENT_CREDITS` with `details.freeResetsAt` and `details.reason`. *Evidence:* `worker/src/services/BalanceService.ts` (`hold`, `insufficientCreditsError`); the SUM ≥ 1 condition sits in the `readings` CAS gate and the ledger `-1` is chained on it; `test/integration/services/BalanceService.hold.test.ts`.
- [x] `BalanceService.refund(reading, reason)`: CAS `held → refunded`; free → decrement the row of `hold_local_date` (never today) on both usage tables; bonus or paid → a `reading_refund` / `reading_undelivered` ledger entry with `ref_id = {readingId}#{attempt}`. `BalanceService.commit`: CAS `held → consumed`, re-hold if the cron refunded first (03 §5.3 step 4). *Evidence:* `BalanceService.refund` / `commit` (a re-hold is attempt + 1, see ARCHITECTURE §Ledger); `BalanceService.hold.test.ts` › refund / commit suites.
- [x] Low-trust caps: KV counters `lt:ip:*` (with CGNAT ASN overrides) and the alert-only `lt:bucket:*` (03 §2.4, RC65). *Evidence:* `BalanceService.hold` via `SoftLimits` (`lt:ip` peek + consume, `lt:bucket`); `BalanceService.hold.test.ts` › low-trust caps.
- [x] Property tests (fast-check, `test/unit/domain/ledger.property.test.ts`): for any interleaving of hold, refund, commit, grant, revoke, stale-hold cron and idempotency takeover, `SUM(bonus) ≥ 0`, `0 ≤ free_used ≤ free_limit` on both usage tables, **no double free refund**, at most one hold and one refund per `(reading, attempt)`, and `state_version` strictly increasing (03 §5.3, RC52, RC67). *Evidence:* `worker/test/unit/domain/ledger.property.test.ts` (250 runs × ≤ 40 steps against real D1, incl. parallel races; mutation-checked).
- [x] Integration: two parallel holds on the last credit → exactly one `402` (04 §15). 10 parallel holds on the same `clientReadingId` → one hold. A free hold at 23:59 local refunded at 00:01 decrements the previous day's row. `readings.freeDaily` raised mid-day → the second free hold succeeds. Android: a second install with the same device key gets no second free hold today (RC53). *Evidence:* `BalanceService.hold.test.ts` (two parallel holds → one 402; 10 parallel holds same `clientReadingId`; 23:59 → 00:01 refund; `freeDaily` raised mid-day; Android device key).

---

## Sprint 7.2: Purchase verification (BE8, MO2, MO8)

**Tasks:**
- [x] `src/monetization/catalog.ts`: `PRODUCT_CATALOG` for `readings_3`, `readings_10`, `readings_30` and `remove_ads` (RC3). Retired catalog entries (`PRODUCT_CATALOG` status `retired`, 03 §6.2) are still verifiable. The public config builder injects `store.packs[].credits` from the catalog. Test: config and catalog agree. Export `test/fixtures/product_ids.json`. *Evidence:* `worker/src/monetization/catalog.ts` (`consumableProduct` accepts retired entries, `productIdsFixture`); `test/unit/monetization/catalog.test.ts` (retired still verifies, config ↔ catalog agreement, file snapshot `worker/test/fixtures/product_ids.json`).

- [x] `adapters/apple/AppStoreServerApi.ts`:
  - ES256 JWT from the `APPLE_ASC_*` secrets;
  - `GET /inApps/v1/transactions/{id}` against production, then sandbox on `4040010` (05 §1 2.1, 03 §6.2);
  - JWS verification with x5c → pinned Apple Root CA G3 and cert OIDs. *Evidence:* `worker/src/adapters/apple/{AppStoreServerApi,AppleJwsVerifier,appleRootG3}.ts`; `test/unit/adapters/{appStoreServerApi,appleJws}.test.ts` (JWT claims verified with the generated key, 4040010 → sandbox, pinned-root fingerprint + self-signature).

- [x] `adapters/google/PlayDeveloperApi.ts`: `purchases.products.get`, `:acknowledge`, `voidedpurchases.list`. *Evidence:* `worker/src/adapters/google/PlayDeveloperApi.ts`, `worker/src/storeDeps.ts`; `test/unit/adapters/playDeveloperApi.test.ts`.

- [x] `services/PurchaseService.verify({platform, …})` behind `POST /v1/purchases/verify` **[idem]**, a single route per RC4:
  - **iOS:** bundle ∈ `purchases.allowedBundleIds`, `Consumable`, product in the catalog, no `revocationDate`, env rules (sandbox accepted in prod, tagged `environment='sandbox'`), and the binding rule: `appAccountToken` mapped to a **different active install** → 409 `PURCHASE_ALREADY_CLAIMED` with `transferEligible` + `transferToken` (RC85); missing/unknown → first claim wins.
  - **Android:** `purchaseState` 0 → grant; 2 → `202 {status: pending}`; 1 → 422. Test purchases are tagged `is_test`. Binding mismatch logged, not blocking (RC9).
  - **Sandbox/test caps (RC63):** `purchases.sandboxMaxCreditsPerInstallPerDay` (30) and `purchases.sandboxGlobalCreditsPerDay` (1,000) → beyond either, 422 `PURCHASE_INVALID` `reason=sandbox_cap`; `sandbox_volume` alert at 50 % of the global cap.
  - **Grant:** one batch of `purchases` + ledger `purchase` + `state_version`. Same install → return the stored grant (`already_granted`). Another install → 409 `PURCHASE_ALREADY_CLAIMED` (+ `transferToken` when the caller re-submitted from the same store account). A **blocked or indebted** install is granted like any other; verify never returns 403 for a valid transaction (RC66), and such grants emit `blocked_purchase`.
  - **Google acknowledgement:** server-side after the grant (RC10). A failed acknowledgement is logged as `pendingAck` and retried by cron.
  - **Response** (03 §6.2 step 5): `200 {status: granted|already_granted, purchaseId, productId, creditsGranted, isFirstPurchase, balance}`; `202 {status: pending}` (Android pending). `isFirstPurchase` = first `purchases` row for the install. Rejections are errors, not a status: `422 PURCHASE_INVALID` (`details.reason`) / `PRODUCT_UNKNOWN`, `409 PURCHASE_ALREADY_CLAIMED`. *Evidence:* `worker/src/services/PurchaseService.ts`, `worker/src/routes/purchases.ts`, `PurchaseRepo.grantBatch` (sandbox caps inside the insert gate), `src/monetization/transferToken.ts`, `src/repos/PendingAckRepo.ts` (`ack:pending:{purchaseId}`). Bound-to-another-active-install transactions are granted to that install (the §6.4 safety net) and the caller gets 409; `transferToken` only with proof of the store account (iOS client `signedTransaction`, Android token).

- [x] Tests: a test root CA + leaf chain (`test/helpers/apple_jws.ts`) with valid, bad-signature, wrong-root, wrong-bundle, unknown-product, revoked, sandbox-in-prod tagging, **sandbox cap per install and global → 422 `sandbox_cap`**, **prod config without sandbox caps rejected by the schema**, iOS token bound to another active install → 409 + `transferToken`, blocked install → granted. `FakePlayDeveloperApi` states 0, 1 and 2, consumed-and-known, test purchase capped, obfuscated-ID mismatch. 10 parallel verifies with the same transaction produce one ledger row (06 §7). *Evidence:* `worker/test/helpers/apple_jws.ts`, `test/fakes/{FakeAppStoreServerApi,FakePlayDeveloperApi}.ts`; `test/integration/services/PurchaseService.test.ts` (30 cases incl. 10 parallel verifies → one ledger row on iOS and Android); `test/integration/routes/purchases.test.ts` (route, idempotency, real adapter over a generated chain: valid + bad signature); `test/unit/config/schema.test.ts` › sandbox caps.


---

## Sprint 7.3: Webhooks, refunds, backstops (MO16, 03 §6.4–§6.5)

**Tasks:**
- [x] `POST /v1/webhooks/appstore`: verify `signedPayload` and the inner JWS, dedupe on `notificationUUID` (`webhook_events`). Handle `REFUND` → revoke, `REFUND_REVERSED` → re-grant, `ONE_TIME_CHARGE` → grant when `appAccountToken` resolves (the crash safety net), `CONSUMPTION_REQUEST` → gated by `purchases.apple.sendConsumptionInfo` (default false, BE Q4), `TEST` → log. Respond 200 after verification and 400 only on a bad signature. *Evidence:* `worker/src/routes/webhooks.ts`, `WebhookService.handleAppStore` (outer + inner JWS via `AppStoreServerApi.verifyNotification` / `verifySignedTransaction`; outcome-based dedupe, `failed` → 500 and retried), `PurchaseService.grantAppleNotification`, `AppleAppStoreServerApi.sendConsumptionInfo`; `test/integration/routes/webhooks.test.ts` › POST /v1/webhooks/appstore (incl. end to end over a generated chain), `test/unit/adapters/appStoreNotifications.test.ts`. `REVOKE` and other types → `ignored`.
- [x] `POST /v1/webhooks/googleplay`: Pub/Sub OIDC JWT verification (`GoogleOidcVerifier`, JWKS cached in `CACHE_KV`, audience and SA email), dedupe on `messageId`. Handle `voidedPurchaseNotification` → revoke, `ONE_TIME_PRODUCT_PURCHASED` → verify, grant and acknowledge, `testNotification` → log. Respond 204. *Evidence:* `worker/src/adapters/google/GoogleOidcVerifier.ts` (`google:jwks`, 6 h, throttled refetch on unknown `kid`), `WebhookService.authorizePlayPush` / `handlePlay` (auth before body validation, `401` otherwise), `PurchaseService.grantPlayNotification`; `test/unit/adapters/googleOidc.test.ts` (RS256 key generated in the test, stubbed JWKS), `webhooks.test.ts` › POST /v1/webhooks/googleplay.
- [x] `services/RefundService.revoke`: purchase `revoked`, ledger `refund_revoke` (paid may go negative), `refund_count++`, `state_version + 1`. At `abuse.refundBlockThreshold` (3) the install is `blocked`: purchases disabled (`purchasesAllowed = false`, `blocked`), free, bonus and positive paid credits keep working (03 §6.5, RC66). *Evidence:* `worker/src/services/RefundService.ts` (one batch gated on the `purchases` CAS; `InstallRepo.recordRefundAfterStmt`; `LedgerRepo.purchaseMovementAfterStmt` with `{purchaseId}#n` cycle refs; `regrant` for `REFUND_REVERSED`); `test/integration/services/RefundService.test.ts`; the property test's revoke step now runs `RefundService.revoke`.
- [x] Crons: daily voided-purchases backstop (last 2 days), hourly Google ack retry. (No reconcile cron: there is no balance cache, BE5.) *Evidence:* `voidedPurchasesBackstop` (`30 3 * * *`, `WebhookService.voidedBackstop`, paged, ≤ `maxBatches` pages) and `retryPendingAcks` (`7 * * * *`, `PurchaseService.retryPendingAcks`) in `worker/src/scheduled.ts`; `test/integration/cron/storeCrons.test.ts`.
- [x] Tests: every notification type, duplicate delivery, negative balance → `paidBlocked` **and `purchasesAllowed = false` (`refundDebt`)** (04 §12.21), the refund-block threshold → `purchasesAllowed = false` (`blocked`) while free readings still work, and a purchase that still arrives for a blocked install is granted. *Evidence:* `webhooks.test.ts` (every Apple type incl. `REVOKE`/other, every RTDN kind, duplicates by UUID/messageId, REFUND → `GET /v1/balance` `paidBlocked` + `refundDebt`); `RefundService.test.ts` › blocks at `abuse.refundBlockThreshold` (free → bonus → positive paid holds still succeed, late purchase granted with `blocked_purchase`).

---

## Sprint 7.4: Rewarded ads via SSV (BE14, MO10, RC33, RC35)

**Tasks:**
- [x] `POST /v1/rewards/intents` **[idem] [attest]** (03 §7.1, RC57): *Evidence:* `worker/src/routes/rewards.ts`, `RewardService.createIntent` (cap + cooldown re-checked in the issuing `INSERT … SELECT`), `test/integration/routes/rewards.test.ts` › POST /v1/rewards/intents; races in `test/integration/services/RewardService.test.ts`.
  - checks `rewarded.enabled`, `adUnitId`, the cap (`granted_today + 1 ≤ dailyCap`, per install and per device key), the cooldown from the **last grant** (RC35), `device_reused` and the low-trust caps;
  - cancels any other open intent of the install (at most one open intent);
  - creates `ad_rewards` with `issued`, `amount` snapshot and `expires_at = now + rewarded.intentTtlSec`;
  - returns `{intentId, customData, userId, amount, expiresAt}` where `customData == userId == intentId` (RC56), so the raw install ID never goes to Google;
  - errors: 403 `REWARDED_DISABLED`, 409 `REWARDED_DAILY_CAP` (`reason: cap|cooldown`, `availableAt`).
- [x] `POST /v1/rewards/intents/{intentId}/cancel` (auth): `issued → cancelled`, idempotent. *Evidence:* `RewardService.cancel` (grace deadline kept in `expires_at`, docs/ARCHITECTURE.md §Rewarded ads); `rewards.test.ts` › cancel and GET.
- [x] `adapters/admob/AdmobKeyProvider.ts`: gstatic verifier keys, cached in KV for 24 h, refetched on an unknown `key_id`. *Evidence:* `GstaticAdmobKeyProvider` (refetch throttled to once per 60 s), `adapters/admob/SsvVerifier.ts`; `test/unit/adapters/admob/admob.test.ts` (stubbed fetch).
- [x] `GET /v1/ads/admob/ssv` (path per RC4): *Evidence:* `worker/src/routes/admobSsv.ts`, `RewardService.handleSsv`; `rewards.test.ts` › GET /v1/ads/admob/ssv.
  - ECDSA-SHA256 verification over the query prefix; `ad_unit ∈ rewarded.allowedAdUnitIds`; dedupe on `transaction_id`;
  - intent lookup via `custom_data`, `user_id == custom_data`; **no cap or cooldown re-check**: any valid, unexpired, unused intent is granted (a `cancelled` one within a 2-minute grace too) (RC57);
  - grant in one batch using the snapshot amount (never `reward_amount`), incrementing `daily_usage` and `device_daily_usage`;
  - invalid signature → 403; any other rejection → 200 with no grant, logged as `ssv_rejected{reason}`.
- [x] `GET /v1/rewards/intents/{intentId}` → `{status: issued|granted|cancelled|expired|rejected, amount, balance?}`. *Evidence:* `RewardService.status` (an `issued` row past its TTL reads `expired`); `rewards.test.ts` › reports the grant with the balance.
- [x] Cron: expire `ad_rewards` whose TTL has passed. *Evidence:* `expireRewardIntents` in `worker/src/scheduled.ts` (`*/15`), `RewardRepo.expireDue` (+ `state_version`); `rewards.test.ts` › expireRewardIntents cron.
- [x] Tests (generated P-256 keys and a fake key provider): valid, tampered query, unknown `key_id`, wrong ad unit, expired or used intent, **an intent issued under the cap is honoured after a cap reduction**, a cancelled intent inside/outside the grace window, duplicate `transaction_id`, three cancelled intents leave the install eligible, the cooldown measured from the last grant, and a second install on the same device key sharing the cap. *Evidence:* `test/helpers/admobSsv.ts`, `test/fakes/FakeAdmobKeyProvider.ts`, `test/unit/domain/rewardRules.test.ts`, `test/integration/routes/rewards.test.ts` (valid; tampered → 403; unknown `key_id` → 403; wrong ad unit; expired and used; cap reduction honoured; cancelled inside/outside grace; duplicate and parallel `transaction_id`; three cancelled intents; cooldown from the last grant; Android device key sharing the cap).

---

## Sprint 7.5: Support tooling & metrics (04 §12.9, RC43, RC84)

**Tasks:**
- [x] `src/admin/creditsTransfer.ts`: a pure batch builder. Input `{ticketId, transferToken}`. It verifies the token (`TRANSFER_TOKEN_KEY`, TTL, single use), resolves the old and new installs from it, and moves `min(unspent paid of the old install, credits of the proven transactions)` with paired `admin_adjust` entries (`ref_id = ticketId`, idempotent per ticket). `worker/scripts/credits-transfer.ts` is the thin CLI that applies the batch via `wrangler d1 execute --remote` (or the D1 HTTP API) and logs ticket, install prefixes and amount. There is **no admin HTTP route and no admin bearer secret**. Evidence: `src/admin/creditsTransfer.ts`, `src/admin/d1.ts`, `scripts/credits-transfer.ts`; `test/integration/admin/creditsTransfer.test.ts` (end to end from a real 409 transfer code, idempotent per ticket, single use per code, dry run, resume after a partial write, balance race, refusals). Legs use `ref_id = {ticket}#out` / `{ticket}#in` (the ledger unique key has no install column; docs/ARCHITECTURE.md §Support tooling).
- [x] `src/admin/ledgerAdjust.ts` + `scripts/ledger-adjust.ts` (manual adjustments, `--block`, settle a refund debt), and `scripts/metrics.ts` (Analytics Engine SQL). All are covered by the gate (RC61): logic in `src/admin`, CLIs tested through `main([...])`. Evidence: `src/admin/ledgerAdjust.ts`, `scripts/ledger-adjust.ts`, `src/admin/metrics.ts`, `scripts/metrics.ts`; `test/integration/admin/ledgerAdjust.test.ts`, `test/unit/scripts/metrics.test.ts`; `npm run credits-transfer | ledger-adjust | metrics`.
- [x] Metrics: `purchase_granted`, `purchase_revoked`, `reward_issued`, `reward_granted`, `reward_rejected`, `ssv_grant_lag_ms`, verify error rate, `sandbox_grant`, `blocked_purchase`. Alerts: verify error rate > 2% over 10 min, `ssv_rejected` spike, sandbox volume (03 §14.1, 04 §12.3, §14). Evidence: new `purchase_verify` event and `blocked_purchase` alert in `PurchaseService` (`test/integration/services/PurchaseService.metrics.test.ts`); `purchase_revoked` in `RefundService`; `ssv_grant_lag_ms` = `reward_granted.latencyMs` quantiles; alert rules `verify_error_rate`, `ssv_rejected_spike`, `sandbox_volume`, `blocked_purchase` in `src/admin/metrics.ts` (`metrics --query alerts`, exit 3). Cron evaluation is Phase 8 `AlertService`.
- [x] `docs/runbooks/SUPPORT_CREDITS.md`: how to handle a "lost credits after reinstall" email, step by step: the user taps "Move readings from another device" on the new install, sends the transfer code, the owner runs the script (04 §12.9, 03 §6.6, BE-R3). Evidence: `docs/runbooks/SUPPORT_CREDITS.md` (transfer, manual adjustment, refund debt, block, refusal table).
- [x] Contract fixtures for every new route (`purchases.verify.*`, `rewards.intent.*`, `errors.*`), synced to Dart. Evidence: `test/contract/fixtures.test.ts` → `purchases.verify.{ios,android}.request`, `purchases.verify.{granted,already_granted,pending}.response`, `rewards.intent.{request,response,status_issued.response,status_granted.response}`, `errors.{purchase_already_claimed,purchase_invalid,product_unknown,rewarded_daily_cap,rewarded_disabled}`; `melos run contract:sync`, `tools/check_contract_fixtures.py` OK (39 fixtures).

---

## Done when

- [x] The Worker coverage thresholds pass (90/90/90/85), including `scripts/**` and `src/admin/**`. All integration flows in 03 §15.2 pass: register → balance → free reading hold → 402 → rewarded → SSV → bonus → purchase → paid → refund webhook → `paidBlocked` + `purchasesAllowed=false`. Readings are still simulated through `BalanceService` until Phase 8. *Evidence:* `npm run test:coverage` → 81 files, 897 tests, statements 99.67 %, branches 96.21 %, functions 99.87 %, lines 99.66 % (`scripts/**`, `src/admin/**` included); `worker/test/integration/flows/moneyFlow.test.ts` (the full flow over `buildApp`, ending `paid = -3`, `paidBlocked`, `purchasesAllowed = false`, `refundDebt`); the other 03 §15.2 Phase 7 regressions in `BalanceService.hold.test.ts`, `PurchaseService.test.ts`, `rewards.test.ts`, `webhooks.test.ts`.
- [x] `check_iap_ids.py` is green against `catalog.ts`. *Evidence:* `tools/check_iap_ids.py` OK; also green: `check_migrations`, `check_glossary`, `check_remote_config`, `check_worker_env`, `check_forbidden_apis`, `check_changelog`, `check_retention`, `check_contract_fixtures` (39), `openapi:check`, `config:schema:check`, `wrangler deploy --dry-run --env staging`.
- [ ] Deployed to staging. Webhook URLs registered in App Store Connect (sandbox) and the Play RTDN topic *(MANUAL, Phase 10 Sprints 10.3–10.4)*. Staging deploys run from `.gitea/workflows/worker-deploy.yml` on push to `main`.
- [x] Docs: `docs/ARCHITECTURE.md` (purchase and rewarded sequence diagrams), the support runbook and `worker/CHANGELOG.md`. *Evidence:* `docs/ARCHITECTURE.md` §Ledger (incl. "End-to-end money flow"), §Purchases, §Store webhooks and refunds, §Rewarded ads, §Support tooling and metrics (mermaid sequence diagrams); `docs/runbooks/SUPPORT_CREDITS.md`; `worker/CHANGELOG.md` and root `CHANGELOG.md` `[Unreleased]`.
- [ ] One commit: `feat(worker): Phase 7 — Credits, purchases & rewarded ads`.

## Next phase

Phase 8: Worker AI Readings & Safety.
