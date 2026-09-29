# Changelog

All notable changes to the Taro Worker (`taro-api`) are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Phase 6.5 contract: `openapi/openapi.json` (OpenAPI 3.1, generated from the zod routes by `npm run openapi`; `npm run openapi:check`, a test and the static CI job fail on drift). Every operation carries `security`, `x-taro-auth` and `x-taro-flags` from one `routeGuards()` helper that also builds its middleware; a wiring test checks them against the GLOSSARY §4 table (RC11).
- Contract fixtures `test/contract/fixtures/{installs,balance,config,timezone,errors}.*.json`, exported by `test/contract/fixtures.test.ts` as file snapshots (`npm run contract:update`) and validated against the route schemas; copied to the app by `melos run contract:sync`.
- `scheduled()` with the three 03 §12 cron triggers (`wrangler.toml` `[env.*.triggers]`, `src/scheduled.ts`); the hourly trigger purges expired `idempotency_keys` and `used_challenges` in bounded `LIMIT 500` batches. The other jobs arrive in Phases 7 and 8.
- `WebhookAlerter` sends each alert kind at most once per hour (last-sent instant in `CACHE_KV` `alert:last:{bucket}`; `Alert.dedupeKey` separates budget tiers); fails open when KV is unavailable.
- Owner CLIs `npm run gen-keys -- --env <env>` (Ed25519 JWKS and the random Worker secrets as JSON on stdout; `--rotate` prepends keyring keys; never `DEBUG_ATTESTATION_TOKEN` for prod) and `npm run smoke -- --env <env>` / `tools/worker_smoke.sh <env>` (health, config, and on staging a debug-attested registration plus a balance read).
- `.gitea/workflows/worker-deploy.yml`: staging on `main`, production canary (10%) on tag `worker-v*`, promotion to 100% by a manual dispatch with an approval input; skips with a warning while `CLOUDFLARE_API_TOKEN` is absent or `wrangler.toml` holds placeholder IDs.

- Phase 6.3 identity and attestation: `POST /v1/attest/challenge` (stateless HMAC challenge, 5-minute TTL, replay detection in `used_challenges` via `UsedChallengeRepo`, `powBits`), `POST /v1/installs` **[idem]** (App Attest / Play Integrity Standard / `type: none` with proof-of-work; `installSecret` ownership proof or an iOS assertion by the stored key for re-registration, 5 per day, `token_generation` bump, `deleted` rows reactivated; per-prefix registration caps; Android `device_key_hash`, iOS DeviceCheck `device_reused`; `purchaseBinding` with UUIDv5 `appleAccountToken` / HMAC `playAccountId`; the response embeds `BalanceDto` and `PublicConfigDto`) and `POST /v1/installs/token` **[attest]** (accepts an expired token).
- Adapters: `AppleAppAttestVerifier` (CBOR via `cbor-x`, x5c chain to the pinned Apple App Attestation Root CA via `@peculiar/x509`, nonce extension, rpIdHash, counter, per-env aaguid, assertions), `GooglePlayIntegrityVerifier` (Standard API `decodeIntegrityToken`, service-account OAuth token cached 50 min in `CACHE_KV`, request hash, package, recognition, device integrity, 120 s age), `AppleDeviceCheckApi` (ES256 JWT, two bits), `Ed25519TokenSigner` (EdDSA install tokens, `TOKEN_SIGNING_KEYS` JWKS `kid` rotation, 7-day TTL).
- Middleware: `auth` (signature, expiry → `TOKEN_EXPIRED`, `status`, `gen == token_generation`) and `attestation` (`aa1.` / `pi1.` / `none`, per-call `clientDataHash`, `attest.requiredOnReadings`, low-trust downgrade on outages). Debug attestation (`X-Taro-Debug-Attestation`) is honoured only when the deploy env sets `ALLOW_DEBUG_ATTESTATION` (RC86).
- Phase 6.1 app skeleton: `Env` with every GLOSSARY §6.1/§13 binding, var and secret; `Deps` with all 03 §1 ports (`src/ports/`) and `makeProdDeps(env)` (prod test-var guard, lazily parsed secrets, WebCrypto/UUID/JSON-logger/Analytics Engine/webhook-alerter adapters; later-phase adapters reject until implemented).
- Error envelope and the full 03 §2.2 code table incl. `412 AI_CONSENT_REQUIRED` and `403 AI_UNAVAILABLE_REGION` (`src/http/errors.ts`); 404 and zod validation failures use the envelope.
- Middleware: `X-Request-Id`, `X-Taro-*` client headers, `426 UPGRADE_REQUIRED` app-version gate, no-CORS `403`, structured request log (`inst8` only), `[idem]` idempotency (RC49 terminal-only replay, 120 s takeover, AES-256-GCM keyring, 7-day TTL, `deleteIdempotentBody`), and rate limiting (`RL_BURST`/`RL_READINGS`, IP-prefix HMAC keys with IPv6 /64, CGNAT ASN cap, KV soft counters, low-trust bucket alerts).
- Phase 6.2 D1 schema: `migrations/0001_init.sql` holds every 03 §4 table, index and trigger (append-only `ledger` triggers, `device_daily_usage`, reading hold columns, route-scoped `idempotency_keys`, `reading_reports` per RC22, `purchases.is_test` per RC7; no balances table); tests apply migrations per file and prove the ledger rejects UPDATE and DELETE.
- Repos in `src/repos/`: `InstallRepo`, `LedgerRepo` (balances as `SUM(delta)`, guarded hold insert), `DailyUsageRepo`, `DeviceUsageRepo`, `PurchaseRepo`, `RewardRepo`, `ReadingRepo` (hold/refund/commit compare-and-set), `IdempotencyRepo`, `WebhookEventRepo`, `SpendRepo`, `ReportRepo`, with batch statement builders and RC37 erasure statements.
- Remote config: the one zod schema `src/config/schema.ts` (every GLOSSARY §8 key with 03 §8.2 / 04 §13 ranges), `config/remote_config.default.json` loaded by `src/config/defaults.ts`, and `config/remote_config.schema.json` exported by `npm run config:schema` (a test fails when it is stale).
- `ConfigService` over `CONFIG_KV` (`config:public`, `config:server`): validated on read, falls back to the defaults with a `config_invalid` log, keeps the last valid document on KV errors, 60 s isolate cache.
- `GET /v1/config`: `PublicConfigDto` with pack credits injected from `PRODUCT_CATALOG` (`src/monetization/catalog.ts`), `ETag: "v{version}"`, `Cache-Control: public, max-age=300`, `304` on `If-None-Match`.
- Owner CLI `npm run config:push -- --env <env> [--file] [--dry-run] [--local] [--force]` (`scripts/config-push.ts` over `src/admin/configPush.ts`): validates, refuses a non-increasing `version`, writes both KV documents with `wrangler kv key put`. Scripts run through `scripts/run.mjs` (esbuild bundle, `main(argv, deps)`).
- Phase 6.4 day boundary: `src/domain/dayBoundary.ts` (`localDate`, `nextResetUtc` by bisection on the local date, IANA validation), tested over the 03 §15.2 zones and the 06 `kBoundaryZones` matrix plus fast-check properties.
- `GET /v1/balance` (`BalanceService.read`, pure `domain/allowance.ts`): `BalanceDto` per 03 §5.1 with ledger-SUM balances and `ledgerVersion = state_version` from one D1 batch, lazy `daily_usage` snapshot, `free.paused` and `readingsPaused` from the budget tiers (`domain/budget.ts`, `BudgetService`), low-trust and device caps, rewarded cap/cooldown, `purchasesAllowed`/`purchasesBlockedReason`; `last_seen_at` at most hourly.
- `PUT /v1/installs/me/timezone` [idem]: IANA validation, no-op on the same zone, `409 TIMEZONE_CHANGE_TOO_SOON` with `details.allowedAfter` inside `readings.tzCooldownHours`, compare-and-set update with a `state_version` bump; returns the new `BalanceDto`.
- `DELETE /v1/installs/me` [idem] per RC37: erases reports, settled readings, reward intents, other idempotency rows and past usage rows; keeps the install (locale nulled), ledger, purchases, today's usage and still-held readings; `204`.
- `Date` header on every response from the server `Clock`.
- Test fakes in `test/fakes/` (`FixedClock`, `SeqIdGenerator`, `InMemoryMetrics`, `CapturingLogger.expectNoSensitive`, `FakeAppAttestVerifier`, `FakePlayIntegrityVerifier`, `FakeConfigStore`, `CapturingAlerter`, `FakeRateLimiter`, `createHarness`).
- Generated deck feeds from `tools/content build` in `src/generated/` (`deck/cards.json`, `deck/spreads.json`, `deck_prompt.en.json`, `crisis_resources.json`; Prettier-ignored) and the parity test stub `test/unit/content/deck_parity.test.ts`.
- Worker skeleton: Hono + `@hono/zod-openapi` app with `buildApp(deps)` and `makeProdDeps(env)`.
- `GET /v1/health` returning `{ status, workerVersion, environment }`.
- `wrangler.toml` with `dev`, `staging` and `prod` environments and placeholder bindings.
- Vitest in workerd (`@cloudflare/vitest-pool-workers`) with istanbul coverage gates, ESLint and Prettier.

### Changed

- `PUT /v1/installs/me/timezone` and `DELETE /v1/installs/me` logic moved into `InstallService` (`changeTimezone`, `erase`); no behaviour change.

### Fixed

- The challenge-tampering registration test flipped the last base64url characters, which only change padding bits in about 1 of 256 runs; it now changes a character inside the MAC.
