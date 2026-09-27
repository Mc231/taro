# Taro — Project Context (pre-planning)

> Everything we know before writing specs. Source of truth for the planning phase.
> Gathered 2026-09-26 from `../quiz_apps`, `../app-store-automation`, `../Blocks/docs/aso` and store-policy research.

---

## 1. Product

- Tarot reading app, iOS + Android, Flutter.
- **1 free reading per day**; additional readings cost money (IAP).
- **AdMob** ads.
- AI-generated interpretation of the drawn spread (proposed — see Open Questions).
- Hard requirement: **must pass App Store / Google Play review and not get banned.**

## 2. Locked decisions (from the user)

| # | Decision |
|---|---|
| D1 | Flutter |
| D2 | **No RevenueCat** — use the same IAP approach as `quiz_apps` (`in_app_purchase` + own `StoreIAPService`) |
| D3 | Same process as `quiz_apps`: **specs first, then implementation** (phase docs with sprints/checkboxes) |
| D4 | High-quality, scalable architecture |
| D5 | **≥ 90% test coverage of everything** (stricter than quiz_apps' 80% Sonar gate) |
| D6 | Full documentation (architecture, analytics events, runbooks, CHANGELOG) |
| D7 | Store setup / ASO via `asa` CLI (`../app-store-automation`) |
| D8 | AdMob for ads |
| D9 | `quiz_apps` is a **reference, not a template** — learn from its patterns, don't copy it 1:1; design taro's own clean architecture |
| D10 | **AI-generated readings** |
| D11 | Backend: **Cloudflare Worker** (holds LLM key, moderation, server-side limits/credits) |
| D12 | Monetization: **banner ads** + **Remove Ads** IAP (non-consumable) + **free readings per day (configurable, default 1)** + **IAP packs of extra readings** + **rewarded ad → extra reading (configurable on/off & amounts)** |
| D13 | **No accounts.** Anonymous install; user can **export/import their data** (backup file) |
| D14 | **All 12 locales** at launch (en, ar, de, es, fr, it, ja, ko, nl, pt, tr, uk); bundle **`com.vshyrochuk.taro`** |
| D15 | Deck art generated later (original art) |
| D16 | UI designed in **Claude Design** after specs are done, then implemented in Flutter |

---

## 3. Store-policy constraints (why apps like this get rejected)

### Apple
1. **Guideline 4.3(b) Spam — the #1 risk.** "Fortune telling" is explicitly named as a saturated category; rejected unless "unique, high-quality experience". Mitigation: original deck art, spread-level contextual readings, journal, learn mode, multiple spreads, widget, polish, localization. Ship **one** app, no reskins.
2. **3.1.1 IAP** — extra readings are digital goods → Apple IAP only. Consumable credit packs and/or subscription.
3. **3.1.2 Subscriptions** (if used) — clear price/period/trial, Restore, Terms + Privacy links on paywall.
4. **Claims** — frame as entertainment/self-reflection; no "accurate", "real psychic", "guaranteed". Disclaimer in onboarding, reading footer, store description.
5. **5.1.2(i) AI data sharing** — explicit in-app disclosure + consent before sending user's question to a third-party AI.
6. **AI output safety** — refuse health/pregnancy/death/legal/financial/gambling predictions; crisis resources for self-harm; moderation in + out. Reviewers test this.
7. **Privacy** — privacy policy, nutrition labels, ATT before ad tracking, in-app account deletion if accounts exist.
8. **Age rating** — ~13+; not targeted at kids (Taro: Apple 13+, Play 16–17 and 18+; RC93).
9. No dark patterns: free reading must be real, paywall before draw (not after revealing cards), no fake timers/fear upsells.

### Google Play
- Play Billing only; subscription policy; misleading-claims policy; Data Safety form (declare AI provider + AdMob); IARC rating (Teen); minimum-functionality / repetitive-content policy.

### AdMob-specific
- **UMP (GDPR/EEA/UK) consent is mandatory** for AdMob in those regions — *not implemented in quiz_apps* (gap).
- ATT on iOS (exists in quiz_apps), SKAdNetwork IDs in Info.plist.
- Ads must not be deceptive or interrupt a reading mid-flow; interstitial frequency caps.

---

## 4. quiz_apps — what we reuse

Repo: `/Users/volodymyrshyrochuk/pet/quiz_apps` (melos monorepo, 7 apps). Rules: `quiz_apps/CLAUDE.md`. Architecture: `docs/CORE_ARCHITECTURE_GUIDE.md`.

### 4.1 Process
- `app-planning-architect` agent → discovery Q&A → fills `docs/phases/{app}/` from `docs/phases/new_app_template/PHASE_01..16.md`.
- `phase-implementer` agent → plan → confirm → implement chunk → `melos run test/analyze/format`.
- Phase doc format: `# Phase N: Title`, `**Status:** ⬜/🚧/✅/⏸️`, Overview, Output, `## Sprint N.M` with `- [ ]` tasks (ticked with decision/evidence/test notes).
- Feature spec format (`docs/phases/push_notifications/README.md`): Why, Environment audit, **Locked decisions table (P1…, with Why)**, What lands where, Testing, Phases ("Done when"), Non-goals, Risks, Open questions.
- `tools/phase_state.py` tracks per-app phase state.
- Proposals in `docs/proposals/` → `docs/archive/` when shipped.
- Git: conventional commits, one commit per phase, authored by Volodymyr, **no AI references** in commits.

### 4.2 Architecture patterns
- Layers: app → UI engine package → core (business logic, sealed models, ports) → shared_services (infra adapters).
- **Custom BLoC** (StreamController-based, no flutter_bloc/riverpod/get_it/freezed).
- DI: InheritedWidget scope + `context.xService` extensions; home-made `ServiceLocator` for bootstrap.
- **Ports & adapters** everywhere, each with NoOp + Mock implementation.
- Storage: `sqflite` + `SharedPreferences`.
- Navigation: Navigator 1.0 + navigation abstraction; deep links via `app_links`.
- l10n: `flutter gen-l10n` ARB; store/landing 12 locales (en, ar, de, es, fr, it, ja, ko, nl, pt, tr, uk).
- Per-app `*_init_config.dart` (features, ads, IAP, resources, interstitial policy); `config/secrets.json` via `SecretsLoader`.
- Coding rules to inherit: all strings via ARB; sealed classes with factories; shared loading/empty/error widgets; no hardcoded animation values; Semantics + 48×48 targets; typed analytics events only; services via context DI; **fully-qualified IAP IDs `com.vshyrochuk.taro.{suffix}`**; **time-based logic needs resume hook + idempotent** (daily free reading!); Apple metadata never mentions Android/Google.

### 4.3 Reference code (study & re-implement where useful — not a 1:1 copy)
`shared_services` ↔ `quiz_engine_core` are mutually dependent and quiz-specific, so taro must **extract/copy** generic parts into its own package(s):

| Area | Source (`quiz_apps/packages/shared_services/lib/src/…`) | Notes |
|---|---|---|
| IAP | `iap/` (`StoreIAPService` ~1.3k LOC, analytics decorator, mock/no-op, consumable fulfillment w/ txn dedupe, pending/Ask-to-Buy, restore) | Subscriptions supported but never used in prod. No server receipt validation. |
| Ads | `ads/` (AdMob banner/interstitial/rewarded, preload, expiry, `InterstitialConfig` policy, remove-ads entitlement) | `google_mobile_ads ^9.0.0`. ATT present; **UMP missing**. |
| Daily allowance | `resources/` (`ResourceManager.checkAndResetDaily()`, midnight local, SQLite, resume) | `ResourceType` sealed = lives/fiftyFifty/skip → need `readingCredit`. |
| Analytics | `analytics/` (sealed typed events, Firebase/console/composite/no-op) | Doc pattern: `docs/ANALYTICS_EVENTS.md`. |
| Crash | `crash/` + `packages/crash_reporting_firebase` | |
| Notifications | `notifications/` (FCM topics + local reminders) | Daily-card reminder fits. |
| Misc | `settings/`, `logger/`, `rate_app/`, `config/` (SecretsLoader), `di/service_locator.dart`, base `Bloc` (`quiz_engine_core/lib/src/bloc/`) | |

### 4.4 Testing (baseline to exceed)
- mockito (+ some mocktail), hand-written fakes, platform-interface fakes.
- Unit + widget tests; integration tests only for screenshots/video (`packages/screenshot_tests`). No goldens.
- Coverage enforced only via SonarQube gate (80% new code). **Taro needs a local/CI gate ≥ 90%**.

### 4.5 CI/CD & tooling
- Self-hosted Gitea Actions (mirror of GitHub), reusable deploy workflows, shared fastlane (iOS beta/release, Android internal→production). Taro: origin `git@github.com:Mc231/taro.git` (owner Mc231); CI on a Gitea pull-mirror of it (`specs/00_DECISIONS.md` owner decisions).
- Secrets: GPG bundle `.secrets/secrets.json.gpg` + `~/pet/secure/{app}/`.
- Tools worth porting: `bump_version.sh`, `smoke_test.sh`, `check_fleet_consistency.py`, `phase_state.py`, screenshot pipeline, `upload_store_assets.sh`.
- Backend today: Firebase (Analytics, Crashlytics, FCM, Hosting) + Cloudflare (R2 CDN, DNS). **No app server.** Push spec precedent: Cloudflare Worker first, Cloud Functions second.

### 4.6 Versions
Flutter 3.44.8 stable, Dart ^3.7, melos ^6. iOS 16.0 min, Gradle 8.14, AGP 8.12.3. Key deps: firebase_core ^4.14, firebase_analytics ^12.5, firebase_messaging ^16.7, google_mobile_ads ^9.0, in_app_purchase ^3.2, sqflite ^2.4, shared_preferences ^2.5, flutter_local_notifications ^22.2, mockito ^5.6.4.

---

## 5. `asa` CLI (`../app-store-automation`)

- Click CLI (`src/app_automation/cli.py`), single YAML config per app (`store/aso.yaml`, schema `models/app_config.py`).
- Automates: bundle IDs, ASC app bootstrap, consumable/non-consumable IAPs (+localization, price, availability), metadata & localizations push, review info, age rating, screenshots, Firebase apps & configs, GitHub secrets, keystore/profiles, icons (OpenAI), landing/privacy pages, listing translation (~60 langs), Android listing/products/subscriptions/releases.
- ASO keyword work is **manual** — best template: `../Blocks/docs/aso/` (keywords.md, asc-listing.yaml, per-locale 30/30/100 char rules). Tracker: `quiz_apps/docs/ASO_TRACKER.md`. Post-launch metrics: `portfolio-audit` skill (add taro to `~/.blocks-secrets/portfolio.json`).

### Gaps for taro
| Gap | Impact |
|---|---|
| iOS auto-renewable subscriptions not supported (wrong endpoint; no subscriptionGroups create) | Create manually or extend `asa` |
| No `LIFESTYLE` category in `AppCategory` enum | Extend `asa` |
| Age-rating preset is `quiz-game` | Use `--preset custom` or add `tarot` preset |
| `setup` enables Game Center by default | Skip/flag |
| AdMob app/ad units not creatable | Manual (IDs stored in yaml) |
| Play Console app creation, first AAB, content rating, Data Safety | Manual |
| Some guide commands don't exist (`create-iaps`, `android push-localizations`) | Use real ones |

---

## 6. Remaining open questions / risks (for spec phase)

> **Resolved (2026-09-27).** These questions were answered by specs 01–06, and every cross-spec conflict and owner decision is recorded in [`specs/00_DECISIONS.md`](specs/00_DECISIONS.md) (RC1–RC93 and "Owner decisions"). The list below is kept as history; `00_DECISIONS.md` wins where they differ. All owner items are answered.

1. **Credit ownership without accounts** — where is the balance of purchased readings the source of truth: device (SQLite) or Worker ledger keyed by anonymous install ID? Apple consumables are not restorable, so a lost device = lost credits; export/import must **not** allow minting credits (sign exports or exclude balances).
2. **Receipt validation** — Worker verifies App Store (JWS / App Store Server API) and Play (Developer API) purchases before granting credits?
3. **Abuse** — free-daily limit enforced server-side per install ID (+ App Attest / Play Integrity?) so reinstall doesn't reset.
4. **Reset time** — local midnight vs. UTC day.
5. **LLM choice & cost per reading**, rate limits, caching, prompt/versioning, moderation provider.
6. **Remote config** for the configurable values (free/day, rewarded on/off, pack sizes) — Worker-served config vs. Firebase Remote Config.
7. **Ad placement** — banner on which screens (never over the reading text?), interstitials at all? UMP consent flow must be built.
8. **Export format** — JSON file via share sheet; what's included (journal, settings, not credits?).
9. **Coverage gate tooling** — local lcov ≥ 90% check + CI; Worker (TypeScript) coverage too.
10. **Repo tooling** — melos multi-package vs. single app with layered folders; CI (Gitea like quiz_apps?).
