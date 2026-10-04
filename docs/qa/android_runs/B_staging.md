# Method B: real-staging integration tests on Android

- Date: 2026-10-04, emulator-5554 (Android 16, sdk_gphone64_arm64, Google Play services), flavor `staging` (`com.vshyrochuk.taro.stg`), Worker `https://api-staging.taro.vshyrochuk.com`, debug attestation token from the secrets bundle (never printed; a grep of every log for it found 0 hits).
- Test: `apps/taro/integration_test/qa/staging_e2e_test.dart`. It uses the real `ProductionEnvironment(Flavor.staging)` composition root, with `runApp` captured so the test can pump it, and drives the app through the UI. It is gated by `TARO_STAGING_SMOKE=true` plus the token.
- Runner: `apps/taro/integration_test/qa/run_staging_e2e.sh <label> '<name regex>' [fresh|unverified]`. It also runs a host watcher that acts on `QA_HOST:` lines in the test output:
  - airplane mode on/off
  - closes the native AdMob rewarded ad using `uiautomator`
  - presses BACK on the share sheet
- Logs: `docs/qa/android_runs/B_logs/ALL.log`, `ALL.host.log` (B1–B7 in one run), `B8.log`, `B1_fresh.log`.
- No app or Worker code was changed and nothing was committed.

## Results

| Case | Plan IDs | Result | Notes |
|---|---|---|---|
| B1 onboarding and registration | ONB-01, ONB-04, HOME-01 | **PASS**, but with an intermittent bug | Registration `trust: high`, UMP `notRequired`, ads initialised, chip shows "1 free reading". **BUG-1**: S04 got stuck in 3 of 6 fresh onboardings. |
| B2 paywall and rewarded ad | PAY-01, RW-01 | **PASS** (result: grant delayed) | S10 opens 120 ms after Begin, before any draw. It shows the real countdown "Next free reading in 14 h 10 min (at 9:00 PM)", the offer "Watch an ad for 1 reading · Optional · 3 left today", and "Prices unavailable — retry" (expected without Play billing). The Google test ad showed and the host closed it. 36 s after the tap, S12 showed "Your reading will appear shortly" (`grantDelayed`). The balance stayed at `bonus: 0`, as expected: the sample ad unit sends no SSV to staging. |
| B3 safety: rephrase and crisis | RD-11, RD-12 | **PASS in an earlier run**. **BLOCKED** in the final run (no reading available) | Earlier run (same code path, then inline in B1): see the rephrase and crisis rows under Timings. In both, the balance stayed the same and nothing was spent. |
| B4 single reading en and journal | RD-02 (single), RD-21 | **Reading PASS in an earlier run.** S09 footer and journal not verified. **BLOCKED** in the final run | Earlier run: reading completed **7.7 s** after "Draw for me", 1 card, and the Worker spent the free reading. `$(DisclaimerFooter).scrollTo()` then failed after 5 s. The test now scrolls with drags and records a missing footer as a bug, but this has not been re-run (no reading left). |
| B5 ar: three_ppf reading and report | language ar, RD-02, RD-27 | **BLOCKED** | `needs one reading available` (see Blockers) |
| B6 de: three_ppf reading | language de | **BLOCKED** | same |
| B7 offline, export, delete, import | offline banner, SET-08, SET-09, SET-12 | **PASS** | Details below the table. |
| B8 unverified: no attestation token | ONB-11 | **PASS** | Details below the table. |

**B7 details:**
- The offline banner appeared 1.1 s after airplane mode went on, and went away 2.3 s after it went off.
- Export returned `Ok`; the host closed the share sheet.
- Delete all through the S26 UI took 1.7 s. The journal emptied and the balance was the same before and after (`ledgerVersion` 1 → 2).
- Import with replace returned `Ok`.
- The journal was empty at export time, because B4–B6 were blocked, so the import round-trip had 0 entries. The 2-entry round-trip is covered by A `export_import_test`.

**B8 details:**
- `POST /v1/installs` returned 403 `ATTESTATION_FAILED`.
- S05 showed "Readings unavailable on this device · Taro couldn't verify this device. Your journal, daily card and Learn still work. · Try again".
- The Learn tab opened.

Final run (`ALL`, one invocation, fresh install): 3 passed (B1, B2, B7), 4 failed with `needs one reading available` (B3–B6), 93 s wall. B8: 1 passed, 29 s.

## Timings (staging, emulator, Wi-Fi)

| Step | ms |
|---|---|
| Hold: Begin tap → S08 | 115–121 |
| Refusal (lottery question) shown on S07, measured from "Draw for me" | 2,718 |
| Crisis S27 shown, measured from "Draw for me" | 1,109 |
| **Single reading complete** (from "Draw for me" until the reading is `complete` in the journal) | **7,712** |
| Paywall: Begin → S10 | 120 |
| Rewarded: offer tap → outcome on S12 (includes about 10 s of ad and the 25 s grant poll) | 35,972 |
| Delete all data (tap → done) | 1,747 |
| Offline banner shown / hidden after airplane on / off | 1,086 / 2,340 |

Rephrase run details: S07 kept the question and showed "Try asking it another way", "Tarot can't predict gambling results or numbers…", two example rewordings and "Reflect on the cards without a question". The chip still said "1 free reading today". The crisis run went to S27 with no reading footer and no upsell.

## Bugs and findings

**BUG-1 (P0, onboarding): S04 is sometimes left on screen after "Allow AI readings".**
- **Seen:** 3 of 6 fresh onboardings, real staging build.
- **State when stuck:** router location `/consent/ai`, `onboardingStep=done`, `ai=granted`, UMP `notRequired`, ads initialised. The app does not leave S04 by itself (waited 20 s, then 60 s).
- **Likely cause** (from reading the code, not confirmed):
  - `AiConsentScreen` calls `context.go(home)` as soon as the controller state becomes `granted`.
  - `OnboardingCompletion.run` only persists `onboardingStep=ump` after that.
  - The guard then still sees `aiConsent` and redirects back to `/consent/ai`.
  - Once the step becomes `ump`/`done`, `onboardingGuard` does not move `/consent/ai` to Home (only launch, welcome and disclaimer are redirected).
  - The fake flows pass because the fake consent store writes synchronously.
- **Workaround in the test:** `router.go(home)`. The bug is recorded and fails the case at the end.
- **Repro:** run B1 on a fresh install a few times. Confirm by hand (plan ONB-04, M) on a release build.

**FINDING-2 (test infra): the staging smoke gate never turns on with `=1`.**
- `integration_test/staging/smoke_test.dart` and the plan document `--dart-define=TARO_STAGING_SMOKE=1`.
- `bool.fromEnvironment` treats only `true` as true, so with `=1` every test is skipped silently.
- The fix is to use `=true` in the docs (or `String.fromEnvironment(...) == '1'`).

**FINDING-3 (plan correction): reinstalling does not give a new free reading on Android.**
- By design (RC53, `device_daily_usage`), the free and rewarded counters are per device key and local day, shared by every install ID on the device.
- `pm clear` or uninstall gives a new install ID (`free.used: 0`) but `free.remaining: 0`.
- `flutter test` also uninstalls the app after each invocation, so a bonus grant cannot carry over between runs.
- The plan's Reset row and step 2 ("Use `pm clear` between tests that need a fresh free reading") need correcting: only one AI reading per emulator per local day is possible without purchases or SSV.

**FINDING-4 (expected, recorded): no rewarded grant on staging.**
- The Google sample rewarded unit sends no SSV to staging.
- The outcome is `grantDelayed` and `bonus` stays 0, so rewarded readings cannot feed further tests on the emulator.

**FINDING-5 (to verify): S09 disclaimer footer not found.**
- In the one completed single-card reading, `$(DisclaimerFooter).scrollTo()` (the same call the A flows use) did not find the footer within 5 s.
- This may be a test-scroll issue rather than a missing footer. Re-run B4 when a reading is available (the new drag-scroll records it either way), or check C screenshots of S09.

## Blockers and how to unblock B3–B6

- B3–B6 each need one available AI reading. The emulator's device-day free reading was spent at 06:3x UTC (the B4 single reading), and the rewarded flow cannot grant.
- Granting staging credits with `npm run ledger-adjust` needs Cloudflare credentials. The run was not allowed to use them, so the owner has to decide.
- Options:
  1. Re-run after the device's local midnight (21:00 UTC). Note that the free reading is 1 per day, so one of B3/B4/B5/B6 per day: B3 does not spend it, so B3 plus one of B4/B5/B6.
  2. The owner grants bonus credits to the run's install. The Support ID is in Settings, and the command is `npm run ledger-adjust -- --env staging --support-id <id> --bucket bonus --delta 4 …`, run while the `ALL` run waits.
  3. A staging-only config or allowance change. That is a Worker/config change, so it is outside this task.
- The full command once readings exist: `apps/taro/integration_test/qa/run_staging_e2e.sh ALL '^B[1-7] ' fresh`.

## Coverage of the plan's B cases

| Plan ID | Status |
|---|---|
| ONB-01, ONB-04, HOME-01 | Run: B1 PASS (with BUG-1) |
| ONB-11 | Run: B8 PASS |
| PAY-01 | Run: B2 PASS |
| RW-01 | Run: B2 PASS (`grantDelayed`, as the plan expects) |
| RD-11, RD-12 | Run: PASS in an earlier run, blocked in the final run |
| RD-02 `single` | Run: PASS in an earlier run (7.7 s) |
| RD-21 | Not verified (FINDING-5) |
| RD-02 `three_ppf` (ar/de), RD-27 report, language ar/de with a reading | Blocked |
| SET-08, SET-09, SET-12, offline banner | Run: B7 PASS |
| UMP-01 | Not automated (EEA debug geography not wired) |
| UMP-04 | Covered by B1's log: `notRequired`, ads init |
| BAN-02, DAY-05, PAY-03, DL-01 | Not automated here |
