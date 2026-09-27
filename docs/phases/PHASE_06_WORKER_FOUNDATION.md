# Phase 6: Worker Foundation: Identity, Attestation, Config

**Status:** ⬜ Not Started
**Depends on:** Phase 3 (CI), Phase 1 (RC4, RC5, RC8). No dependency on Phase 10: the Cloudflare and Anthropic accounts are created here in Sprint 6.0 (RC83).
**Parallel with:** Phases 4, 5, 9, 10

---

## Overview

This phase stands up the `taro-api` Worker skeleton that every other backend feature plugs into:
- the Hono + zod-openapi app, the `Deps` composition root, and the ports with their fakes;
- the error envelope and middleware (request ID, auth, attestation, idempotency, rate limiting, app-version gate, logging);
- the D1 schema and migrations;
- remote config;
- install registration with App Attest and Play Integrity, install tokens, the timezone endpoint and data erasure.

It ends with automated staging deploys. Everything runs locally with fakes (`AI_PROVIDER=fake`, fake attestation) and inside the real workerd runtime in tests.

**Output of this phase:**
- Cloudflare zone, D1/KV/Rate-Limit/Analytics Engine per env, Anthropic workspaces and all Worker secrets (Sprint 6.0, moved from Phase 10.1 by RC83).
- `worker/migrations/0001_init.sql` (03 §4 as amended by the review pass: no `balances` table, `device_daily_usage`, reading hold columns, route-scoped idempotency; + `reading_reports` per RC22 + `purchases.is_test` per RC7).
- Routes: `GET /v1/health`, `GET /v1/config`, `POST /v1/attest/challenge`, `POST /v1/installs`, `POST /v1/installs/token`, `PUT /v1/installs/me/timezone`, `DELETE /v1/installs/me`, `GET /v1/balance` (reads only; spending logic comes in Phase 7).
- `worker/openapi/openapi.json` committed, plus contract fixtures in `worker/test/contract/fixtures/`.
- `.gitea/workflows/worker-deploy.yml` deploying staging on merge to `main`.

> **Tooling note (Phase 2, 2026-09-27):** `@cloudflare/vitest-pool-workers` 0.22 replaced `defineWorkersConfig`/`poolOptions` with the `cloudflareTest()` plugin and dropped `isolatedStorage`. Re-check the per-test D1/KV isolation approach in 06 §5.2/§7 before writing integration tests (see `docs/phase2_notes/WORKER_NOTES.md`).

---

## Specs referenced

`03_BACKEND_WORKER.md` BE1–BE4, BE7, BE13, BE16–BE20, §1, §2, §3 (incl. §3.7), §4, §5.1–§5.2, §8, §11, §12 (cron shell), §13, §14. `06_QUALITY_TESTING_CI.md` QA7, QA9, QA15, §7, §8 (`worker-deploy.yml`), §10.1. `02_ARCHITECTURE.md` §6.3–§6.4 (client expectations). `00_DECISIONS.md` RC4, RC5, RC8, RC9, RC11, RC22, RC37, RC38, RC49, RC53–RC55, RC61, RC65, RC67, RC78, RC83, RC86, RC87.

---

## Sprint 6.0: Cloudflare, Anthropic & Worker secrets *(MANUAL + scripted; moved from Phase 10.1, RC83)*

**Tasks:**
- [ ] Cloudflare:
  - DNS for `taro.vshyrochuk.com` (asa web hosting; follow the quiz_apps DNS note: gray cloud for Firebase Hosting A records if used), plus `api.taro.vshyrochuk.com` and `api-staging.taro.vshyrochuk.com` Worker custom domains (BE Q5, M11);
  - D1 `taro-staging` and `taro-prod`, KV namespaces ×3 per env, Rate Limiting bindings, and an Analytics Engine dataset;
  - fill in the binding IDs in `worker/wrangler.toml`.
- [ ] Cloudflare API token scoped to Workers, D1 and KV edit on this account only → the secrets bundle as `cloudflare_api_token` and `cloudflare_account_id` (03 §14.2).
- [ ] Anthropic Console: workspaces `taro-staging` (low monthly limit) and `taro-prod` (monthly spend limit above `31 × ai.budget.dailyHardUsd`, 03 §10.2), with API keys → `wrangler secret put ANTHROPIC_API_KEY --env staging|prod`.
- [ ] Generate and set the Worker secrets for staging and prod (03 §11): `TOKEN_SIGNING_KEYS` (Ed25519 JWKS via `worker/scripts/gen-keys.ts`), `CHALLENGE_KEY`, `IDEMPOTENCY_ENC_KEY`, `IP_HASH_KEY`, `PLAY_ACCOUNT_KEY`, `APPLE_ACCOUNT_NS`, `DEVICE_KEY_SECRET`, `TRANSFER_TOKEN_KEY`, `ALERT_WEBHOOK_URL`, and `DEBUG_ATTESTATION_TOKEN` (staging only). There is no admin bearer secret (RC84). Copies go into `.secrets/secrets.json.gpg` (06 QA10). Store-issued secrets (`APPLE_ASC_*`, `APPLE_DEVICECHECK_*`, `GOOGLE_*`) are added in Phase 10.
- [ ] `docs/runbooks/SECRET_ROTATION.md`, first version per secret (06 §13).

---

## Sprint 6.1: App skeleton, deps, middleware

**Tasks:**
- [ ] `src/env.ts` (bindings type, including the env-bound vars `ENVIRONMENT`, `ALLOW_DEBUG_ATTESTATION`, `AI_PROVIDER`). `src/deps.ts`: the `Deps` interface with every port from 03 §1 (`AiProvider`, `AppAttestVerifier`, `PlayIntegrityVerifier`, `AppStoreServerApi`, `PlayDeveloperApi`, `AdmobKeyProvider`, `GoogleOidcVerifier`, `DeviceCheckApi`, `TokenSigner`, `Clock`, `IdGenerator`, `Crypto`, `ConfigStore`, `Metrics`, `Logger`, `Alerter`) + `makeProdDeps(env)`, which throws if `ENVIRONMENT == 'prod'` and any test-only var is set (BE20, RC86). Unit test `test/unit/deps.prodConfig.test.ts`. `src/app.ts` `buildApp(deps)`.
- [ ] `test/fakes/`: `FixedClock`, `SeqIdGenerator`, `InMemoryMetrics`, `CapturingLogger` (with `expectNoSensitive()`, BE13), `FakeAppAttestVerifier`, `FakePlayIntegrityVerifier`, and a `FakeConfigStore`.
- [ ] `src/http/errors.ts`: the error envelope and the code table (03 §2.2 + RC5 additions `AI_CONSENT_REQUIRED` 412, `AI_UNAVAILABLE_REGION` 403). `src/http/middleware/`:
  - `requestId.ts`;
  - `clientHeaders.ts` (`X-Taro-Platform`, `-App-Version`, `-Locale`);
  - `appVersionGate.ts` (426 `UPGRADE_REQUIRED` below `app.minVersion.{platform}`);
  - `noCors.ts` (browser `Origin` → 403);
  - `logging.ts` (03 §14.1 fields, `inst8` only).
- [ ] `src/http/middleware/idempotency.ts` per 03 §2.3 (RC49): scope `(install_id, route, key)`, request hash, `in_progress`/`done`, **only terminal outcomes stored** (2xx, 400, 422) and the row deleted for every other status, replay with `Idempotent-Replayed: true`, 409 `REQUEST_IN_PROGRESS`, 422 `IDEMPOTENCY_KEY_REUSED`, takeover after **120 s**, AES-256-GCM body encryption (`IDEMPOTENCY_ENC_KEY` keyring, AAD `install_id‖route‖key`), TTL 7 days, `deleteBody(installId, route, key)` for the reading ack.
- [ ] `src/http/middleware/rateLimit.ts`: the `RL_BURST` and `RL_READINGS` bindings, IP-prefix HMAC keys (`IP_HASH_KEY`, IPv4 /24 and **IPv6 /64**), the CGNAT ASN list, the KV soft counters and the per-(platform, version) alert buckets (03 §2.4, RC65).
- [ ] Tests: `test/unit/http/*.test.ts` and `test/integration/middleware/*.test.ts` (replay byte-for-byte for 200/422, **no replay for 402/409/412/429/503** (the handler runs again), key reuse, crashed takeover after 120 s, same key on two routes, 426, CORS 403, `expectNoSensitive` incl. the install secret).

---

## Sprint 6.2: D1 schema, repos, config

**Tasks:**
- [ ] `migrations/0001_init.sql`: every table and trigger from 03 §4, plus:
  - `reading_reports(id, install_id, client_reading_id, reason, note_enc, question_enc, reading_enc, created_at, expires_at)` (RC22);
  - `purchases.is_test` (RC7).
  - `check_migrations.py` is green.
- [ ] `src/repos/`: `InstallRepo`, `LedgerRepo` (balances via `SUM`, no cache table, BE5), `DailyUsageRepo`, `DeviceUsageRepo`, `PurchaseRepo`, `RewardRepo`, `ReadingRepo`, `IdempotencyRepo`, `WebhookEventRepo`, `SpendRepo`, `ReportRepo`. Test setup: `test/setup/apply_migrations.ts` (`applyD1Migrations`, `isolatedStorage: true`).
- [ ] Integration tests that the ledger triggers reject UPDATE and DELETE.
- [ ] `src/config/schema.ts` (zod, the RC8 key set with 04 §13 ranges, `readings.freeDaily` 1–5 per MO14, plus the review-pass keys in 03 §8.2: `ai.model.freeFallback`, `ai.budget.*`, `ai.deadlineMs`, `readings.holdTtlSec`, `attest.allowedAppIds`, `purchases.allowedBundleIds`, `purchases.sandbox*`, `abuse.lowTrust.*`, `alerts.*`, `rewarded.{cooldownSec,intentTtlSec,loadTimeoutSec,grantPollTimeoutSec}`), `src/config/defaults.ts`, `worker/config/remote_config.default.json`, and `remote_config.schema.json` exported for `check_remote_config.py`.
- [ ] `services/ConfigService.ts`: `config:public` / `config:server` in `CONFIG_KV`, validated on read, fallback to compiled defaults with a `config_invalid` log, 60 s isolate cache.
- [ ] Routes: `GET /v1/config` (ETag `"v{version}"`, `Cache-Control: public, max-age=300`, 304 on match).
- [ ] `src/admin/configPush.ts` (validation + payload builder) and the thin CLI `scripts/config-push.ts` (`main(argv)`: validate → `wrangler kv put`, with `--env` and `--dry-run`). Both are **inside** the coverage gate (RC61); the CLI is tested through `main([...])` with a stubbed command runner.

---

## Sprint 6.3: Identity & attestation (BE3, BE4)

**Tasks:**
- [ ] `domain/challenge.ts`: a stateless HMAC challenge with a 5-min TTL, and replay detection via `used_challenges`. Route `POST /v1/attest/challenge`.
- [ ] `adapters/apple/AppAttestVerifier.ts` (03 §3.3):
  - CBOR decode (`cbor-x`), then an x5c chain check against the pinned Apple App Attestation Root CA (`@peculiar/x509`);
  - nonce extension check, `rpIdHash` check, `counter == 0`, `aaguid` rules per env;
  - assertion verification (signature, counter strictly increasing).
  - Tests use a test CA and keys **generated in the test** (06 §7) plus one real-format decode fixture.
- [ ] `adapters/google/PlayIntegrityVerifier.ts`:
  - `decodeIntegrityToken` via the service-account OAuth token, cached in `CACHE_KV` for 50 min;
  - checks on nonce and requestHash, package, `PLAY_RECOGNIZED`, `MEETS_DEVICE_INTEGRITY`, and a 120 s age;
  - **Standard API only** (RC87): registration checks `requestDetails.requestHash == base64url(SHA256(challenge ‖ installId ‖ deviceKey))`, per-call checks bind the request hash (03 §3.4); `requestPackageName ∈ attest.allowedAppIds` (RC78).
  - Tests use stubbed `fetch` and sanitised recorded fixtures.
- [ ] `adapters/apple/DeviceCheckApi.ts` (query/update the two bits with an ES256 JWT from `APPLE_DEVICECHECK_*`), with a fake for route tests (03 §3.7, RC53).
- [ ] `services/InstallService.ts`:
  - register: store `install_secret_hash`, `device_key_hash` (Android) and `device_reused` (iOS DeviceCheck `bit0`, then set it) (RC53, RC54);
  - re-register only with the matching `installSecret` (or an iOS assertion by the stored key), else 403; keep the balance, bump `token_generation`, 5 re-registrations per day; reactivate a `deleted` row the same way (03 §3.3);
  - `type: none` requires proof-of-work (`powBits` from the challenge) and the per-prefix registration cap (RC65);
  - trust `high`/`low` per 03 §3.3; hard failures return 403 `ATTESTATION_FAILED`;
  - compute `apple_account_token = UUIDv5(APPLE_ACCOUNT_NS, id)` and `play_account_hash = HMAC(PLAY_ACCOUNT_KEY, id)` and return them as `purchaseBinding` (RC9).
- [ ] `adapters/cf/Ed25519TokenSigner.ts`: EdDSA JWT via `jose`, `kid` rotation from the `TOKEN_SIGNING_KEYS` JWKS, 7-day TTL. `http/middleware/auth.ts` checks the signature, expiry, `status` and `gen == token_generation`.
- [ ] `http/middleware/attestation.ts`: parses the `[attest]` header (`aa1.` / `pi1.` / `none`), computes `clientDataHash = SHA256(method‖path‖SHA256(body)‖Idempotency-Key)`, applies `attest.requiredOnReadings`, and downgrades low-trust requests. It is applied to exactly the RC11 routes.
- [ ] Routes: `POST /v1/installs` **[idem]** (the client sends a fresh key per attempt, RC55), `POST /v1/installs/token` **[attest]**.
- [ ] A dev/staging-only debug attestation bypass (`X-Taro-Debug-Attestation` with `DEBUG_ATTESTATION_TOKEN`; 02 §5 `DebugAttestationService`), honoured **only** when the deploy env var `ALLOW_DEBUG_ATTESTATION` is set (RC86). Tests: header ignored when the var is absent; prod config has no such var.
- [ ] Integration tests: re-registration without the secret → 403; with it → 200 and old tokens revoked; iOS reinstall within 7 days with a fresh idempotency key → 200; `deleted` row reactivated; Android second `installId` with the same `deviceKey` shares today's `device_daily_usage`; `type: none` without valid PoW → 403.

---

## Sprint 6.4: Timezone, balance read, erasure

**Tasks:**
- [ ] `domain/dayBoundary.ts`: `localDate(nowUtc, tz)` and `nextResetUtc(nowUtc, tz)` (03 §5.2). Unit tests over the 03 §15.2 zones plus the 06 `kBoundaryZones` matrix. Property test (fast-check): `nextResetUtc > now` and `localDate(next) == localDate(now)+1`.
- [ ] Route `PUT /v1/installs/me/timezone` **[idem]**: IANA validation, a no-op when unchanged, 409 `TIMEZONE_CHANGE_TOO_SOON` inside `readings.tzCooldownHours` (24 h, RC8).
- [ ] `services/BalanceService.read` + `GET /v1/balance`, returning `BalanceDto` per 03 §5.1 (`free{…,paused}`, `bonus`, `paid` as ledger SUMs, `canRead`, `canReadReason`, `nextSource`, `rewarded{…,cooldownEndsAt}`, `paidBlocked`, `purchasesAllowed`, `purchasesBlockedReason`, `serverTime`, `ledgerVersion = installs.state_version`; RC6, RC66, RC67, RC74). It lazily snapshots the `daily_usage` row per 03 §5.2 and updates `last_seen_at` at most hourly. The route is read-only; holds come in Phase 7.
- [ ] Route `DELETE /v1/installs/me` **[idem]** with the RC37 semantics. Test: every per-install row is erased or anonymised, the ledger and purchases are kept, and the install stays active with today's allowance intact.
- [ ] The `Date` header on every response (02 §6.3), tested.

---

## Sprint 6.5: Contract, observability, deploy

**Tasks:**
- [ ] OpenAPI generation → `worker/openapi/openapi.json`, with a CI diff check (03 §14.2).
- [ ] Contract fixtures `worker/test/contract/fixtures/{installs,balance,config,timezone,errors}.*.json`, exported by the tests. `melos run contract:sync` copies them to `apps/taro/test/contract/fixtures/` (RC38).
- [ ] `adapters/cf/AnalyticsEngineMetrics.ts` (`taro_api_events`), the structured logger and the `Alerter` port with a webhook adapter and per-kind hourly dedupe (03 §14.1). `scheduled()` handler shell with the three crons from 03 §12. Jobs are registered in Phase 7 and Phase 8; the idempotency and challenge purge runs now.
- [ ] `.gitea/workflows/worker-deploy.yml` (06 §8, BE18):
  - tests → `check_migrations` → `check_worker_env.py` (no debug/test vars in `[env.prod]`, RC86) → `wrangler d1 migrations apply --remote` → `wrangler versions upload` → `versions deploy` (100% on staging; 10% → smoke → 100% on prod with a manual approval input) → `tools/worker_smoke.sh <env>`.
  - Prod deploys are triggered only by the tag `worker-v*`.
- [ ] `worker/scripts/smoke.ts` (thin CLI over `src/admin/smoke.ts`, covered) / `tools/worker_smoke.sh`: health, config, and registration with the debug attestation token on staging only (enabled by the staging env var, never by a header alone).
- [ ] Apply migrations and deploy to the staging resources created in Sprint 6.0.
- [ ] `docs/runbooks/WORKER_ROLLBACK.md` first version (`wrangler rollback`, `versions deploy <old>@100%`, D1 Time Travel).

---

## Done when

- [ ] `npm run test:coverage` in `worker/` passes lines, statements and functions ≥ 90% and branches ≥ 85%. `check_coverage.py --unit worker` is green.
- [ ] Staging responds on the chosen host (BE Q5) to `/v1/health` and `/v1/config`. Registration with the debug bypass succeeds from `tools/worker_smoke.sh staging`.
- [ ] Contract fixtures are synced and `check_contract_fixtures.py` is green.
- [ ] Docs updated: `docs/ARCHITECTURE.md` §Worker, `worker/COVERAGE.md` (exclusions mirror of 06 §5.3: generated code and eval case data only, RC61), `worker/CHANGELOG.md` and the runbook.
- [ ] One commit: `feat(worker): Phase 6 — Worker foundation: identity, attestation, config`.

## Next phase

Phase 7: Worker Credits, Purchases & Rewarded Ads.
