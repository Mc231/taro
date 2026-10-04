# Method A: fake-backed integration flows on Android

- Date: 2026-10-04, emulator-5554 (Android 16, sdk_gphone64_arm64, 7.7 GB /data, about 0.6 GB free)
- Command, one file at a time, from `apps/taro`: `flutter test integration_test/flows/<flow>.dart --flavor dev --dart-define-from-file=config/dev.json --dart-define=TARO_ENV=test -d emulator-5554`. The patrol CLI is not installed and there is no `patrol_test/` folder, so `tools/run_integration.sh` would also use `flutter test`.
- Caveat: during the run, the working tree held another agent's uncommitted edits (`lib/data/install/install_repository_impl.dart`, `lib/di/providers.dart`, `lib/features/reading/controller/question_controller.dart`, `lib/services/attestation/platform_attestation_service.dart`). The same agent also used the same emulator and build dir at the same time.
- Logs: `docs/qa/android_runs/logs/A_<flow>.log` (first run), `A_<flow>_rerun*.log` (re-runs)

## Result: 16 of 17 pass; 1 fails every time

| # | Flow | Run 1 | Re-run | Verdict |
|---|---|---|---|---|
| 1 | classic_reading_test | PASS (82 s) | n/a | PASS |
| 2 | consent_denied_test | PASS | n/a | PASS |
| 3 | daily_reset_resume_test | PASS | n/a | PASS |
| 4 | export_import_test | PASS | n/a | PASS |
| 5 | first_launch_free_reading_test | FAIL | FAIL (same assertion) | **REAL FAILURE** |
| 6 | hold_lost_test | FAIL (infra: install) | PASS | PASS (infra flake) |
| 7 | kill_switch_test | FAIL (infra: install) | PASS | PASS (infra flake) |
| 8 | os_restore_test | PASS | n/a | PASS |
| 9 | out_of_credits_purchase_test | PASS (289 s) | n/a | PASS |
| 10 | reading_failure_refund_test | PASS | n/a | PASS |
| 11 | reinstall_same_install_id_test | PASS | n/a | PASS |
| 12 | remove_ads_restore_test | PASS | n/a | PASS |
| 13 | report_reading_test | PASS | n/a | PASS |
| 14 | review_guidelines_test | PASS | n/a | PASS |
| 15 | rewarded_ad_test | PASS | n/a | PASS |
| 16 | rtl_locale_test | PASS | n/a | PASS |
| 17 | timezone_change_test | FAIL (hung 890 s, killed) | FAIL (VmServiceDisappeared), FAIL (Gradle clash), PASS on 4th run with the emulator idle | PASS (infra flake) |

## Failure details

### first_launch_free_reading_test: real, fails both times
The flow runs onboarding, the free reading (hold taken, `three_ppf`), shuffle, draw and Reveal all, and reaches **S09 Reading result**. It then fails at `integration_test/flows/first_launch_free_reading_test.dart:55`, on `await app.$(DisclaimerFooter).scrollTo();`:
```
WaitUntilVisibleTimeoutException: TimeoutException after 0:00:05.000000:
Finder "Found 0 widgets with type "DisclaimerFooter" (considering only hit-testable
widgets with a RenderBox): []" did not find any visible (i.e. hit-testable) widgets
  #0 PatrolTester.dragUntilVisible (patrol_tester.dart:800)
  #2 PatrolTester.scrollUntilVisible (patrol_tester.dart:943)
```
In the content state, `ReadingResultScreen._content` puts the footer at the end of a lazy `ListView`. The scroll did not reach it within patrol's 5 s `scrollTo` timeout on this phone viewport. Not verified: whether the cause is the test (scroll step or timeout too small for a long reading on a phone) or the app (footer missing or not hit-testable in that state). It fails the same way every time, so it needs a look. On S09, `timezone_change_test` and `classic_reading_test` pass because they do not assert the footer.

### hold_lost_test, kill_switch_test: infra
`adb: failed to install ... app-dev-debug.apk: Failure [INSTALL_FAILED_INSUFFICIENT_STORAGE]`, then `DELETE_FAILED_INTERNAL_ERROR`. The APK is 218 MB and the emulator had about 600 MB free. Both pass after `pm trim-caches`.

### timezone_change_test: infra
- Run 1 hung after the install for about 15 min while another agent launched `com.vshyrochuk.taro.stg` on the same emulator. The process was killed.
- Re-run 1: `VmServiceDisappearedException` while loading.
- Re-run 2: Gradle `Unable to delete directory .../intermediates/assets/devDebug/mergeDevDebugAssets`, caused by a build running at the same time in the shared `build/` dir.
- Re-run 3: PASS (9 s test body) once the emulator and build dir were free.

## Recommendations
- Look at `first_launch_free_reading_test` S09 footer scroll; it is the only reproducible failure.
- Emulator hygiene for the next methods: free storage (wipe data or a bigger `/data`), and serialise device runs across agents (the emulator and `apps/taro/build/` are shared).
