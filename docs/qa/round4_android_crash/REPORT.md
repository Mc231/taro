# Round 4 — Android release crash hunt (2026-10-06)

Code: 1.0.0 RC (dedb6d3 + dd96993). Build under test: prod flavor, release, `--obfuscate --split-debug-info`, R8 full mode (AGP 9.0.1), same r8-map-id as the Play internal AAB.

## A4-01 — startup crash on every Play install (fixed)
- Signature: `Unable to get provider androidx.startup.InitializationProvider … Failed to create an instance of androidx.work.impl.WorkDatabase` (main thread, before the first frame). Retraced: `Room.getGeneratedImplementation` ← `WorkDatabase.create` ← `WorkManagerImpl.<init>` ← `WorkManagerInitializer` ← `InitializationProvider.onCreate`. Logs: `logs/A4-01_crash_obfuscated.txt`, `logs/A4-01_crash_retraced.txt`.
- Cause: `google_mobile_ads` → `play-services-ads:25.4.0` → `work-runtime:2.7.0` + `room-runtime:2.2.5`. Room's consumer rule keeps `WorkDatabase_Impl` but not its constructor under R8 full mode; Room instantiates it reflectively. Debug builds / fake-backed device tests never run R8.
- Fix: `apps/taro/android/app/proguard-rules.pro` (`-keep class * extends androidx.room.RoomDatabase { <init>(); }`) wired via `proguardFiles(...)` in the release build type.
- Guard: `tools/check_manifests.py` rule `r8-keep` (keep rule present, wired, and release `seeds.txt` keeps `WorkDatabase_Impl()`), tests in `tools/tests/test_check_manifests.py`.
- Verified: fixed APK and fixed AAB (bundletool, fastlane flags) launch; onboarding + ~16,000 monkey events (seeds 42, 99, 2024, 7), no FATAL / ANR / `E/flutter`.

## A4-02 — reminders fired in UTC on legacy zone names (fixed)
- Android 16 reports `Europe/Kiev`, `Asia/Calcutta`, `America/Buenos_Aires`; `timezone/data/latest.dart` lacks them → fallback to UTC (9:00 set → fired 12:00 in Kyiv).
- Fix: `local_reminder_scheduler.dart` imports `latest_all.dart`. Tests: three "legacy zone name … fires in local time" cases.

## Release scenario (fixed prod APK) — no crashes
Onboarding (AI allowed/declined), daily card, notifications (permission, reboot via boot receiver, fire + tap → daily card), offline cold start, prod reading + report sheet, paywall + Play billing sheet (cancelled), share sheet, file picker (invalid import), deep links (warm/cold/garbage/App Link), rotation, `am kill`/restore, "Don't keep activities", ar + font 2.0 + dark, uk per-app locale. 16 KB page alignment OK; no exact-alarm permission.

## Regression suites
- A: 22/22 (one harness glitch, passed alone).
- B: B1, B3–B7 pass; **B2 (rewarded on staging) fails** with 400 VALIDATION_FAILED because the launch config removed Google's sample units from `rewarded.allowedAdUnitIds` (staging uses sample units) — owner decision.

## Notes (not crashes)
- Debug-signed sideloads get "Readings unavailable" on prod (Play Integrity "unrecognized version") — by design; Play installs are recognized.
- Re-check on the next Play build: after moving the device clock a day ahead and back, "Watch an ad" said today's rewards were used while the screen said "3 left today".
- Cosmetic: with per-app locale Ukrainian, Language → "Use phone language" still says "English, from your phone settings".
