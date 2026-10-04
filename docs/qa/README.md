# QA suite (Android / iOS end-to-end)

The release QA suite on top of the CI gates in [../TESTING.md](../TESTING.md).
The plan with every case is [ANDROID_E2E_PLAN.md](ANDROID_E2E_PLAN.md); the
latest results and the bug list are in
[ANDROID_E2E_REPORT.md](ANDROID_E2E_REPORT.md); raw run notes, logs and
screenshots are under [android_runs/](android_runs/).

The test code lives in `apps/taro/integration_test/qa/` and is analyzer-clean
(`melos run analyze`). Both QA tests skip themselves without their defines,
so `melos run test:integration` (every file under `integration_test/`) does
not run them.

Use one device per run: `flutter test` installs and later uninstalls the app,
and two runs on the same emulator or the same `apps/taro/build/` folder
interfere. The debug APK is large, so on an emulator run
`adb shell pm trim-caches 4G` first.

## Method A: fake-backed flows

```bash
cd apps/taro
flutter test integration_test/flows/<flow>_test.dart --flavor dev \
  --dart-define-from-file=config/dev.json --dart-define=TARO_ENV=test -d emulator-5554
```

## Method B: real staging Worker (`qa/staging_e2e_test.dart`)

```bash
apps/taro/integration_test/qa/run_staging_e2e.sh ALL '^B[1-7] ' fresh
apps/taro/integration_test/qa/run_staging_e2e.sh B8  '^B8 '     unverified
```

- The script reads the staging debug attestation token from the secrets
  bundle inside the command that consumes it (`TARO_SECRETS` from
  `~/.zshrc`); it is never printed. Logs go to `$OUT` (default `/tmp/taro_qa`).
- It watches the test's `QA_HOST:` lines and does the host-side steps:
  airplane mode on/off, closing the native rewarded ad, closing the share
  sheet.
- The test is gated by `TARO_STAGING_SMOKE` (1/true/yes; any other non-empty
  value throws) and, except for B8, by `TARO_DEBUG_ATTESTATION_TOKEN`.
- Android counts the free AI reading per device and local day (RC53): a
  reinstall does not reset it. B3 spends nothing; B4 to B6 each need a
  reading (the day's free one, or staging bonus credits granted with
  `cd worker && npm run ledger-adjust -- --env staging --support-id <id> --bucket bonus --delta 4`).

## Method C: screenshot tour (`qa/screenshot_tour_test.dart`)

Visits S01 to S33 and key states on fakes and writes half-resolution PNGs to
the app's `code_cache/qa_shots/<mode>/`. Modes: `en_light`, `en_dark`, `ar`,
`de`, `ja`, `en_text200` (text scale 2.0). It only runs with `QA_MODE` set.

```bash
cd apps/taro
flutter test integration_test/qa/screenshot_tour_test.dart --flavor dev \
  --dart-define-from-file=config/dev.json --dart-define=TARO_ENV=test \
  --dart-define=QA_MODE=en_text200 -d emulator-5554 &
# while it runs (the test waits 20 s at the end so the pull can finish):
adb exec-out run-as com.vshyrochuk.taro.dev tar -cf - -C code_cache qa_shots | tar -xf -
```

Pull in a loop while the test runs, because `flutter test` uninstalls the app
when it ends. A shot named `<name>_FAILED.png` means the tour could not reach
that state; the log line `QA_SKIP:` says why. Look at every shot: the tour
checks reachability, not layout.

## Method M: manual

The manual checklist (system dialogs, Play sandbox purchases, TalkBack, deep
links, notifications) is in the report under "Manual checklist".
