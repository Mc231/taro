# Phase 3 notes: CI (Sprint 3.4)

This note covers the Gitea workflows under `.gitea/workflows/`, the device pins in `tools/ci/sim.env`, the secrets tooling in `tools/secrets-manager.sh` and `.secrets/README.md`, and the assumptions they make about the runner. The specs behind it are 06 QA10, QA11, QA14, §3, §4, §5, §8 and §9.

## Runner (as found on 2026-09-28)

These facts were read from the machine that runs quiz_apps CI:

| Fact | Value | Consequence for Taro |
|---|---|---|
| Gitea | 1.25.4 at `http://localhost:3001`, launchd `com.gitea.web` | reusable workflows (`uses: ./.gitea/workflows/…`), `schedule` and `workflow_dispatch` inputs all work, as in quiz_apps |
| act_runner | v0.5.0, launchd `com.gitea.act_runner`, config `~/gitea/act_runner/config.yaml` | — |
| Labels | `macos:host`, `ubuntu-latest:host` | every Taro job uses `runs-on: macos`, runs directly on the host with no containers |
| Capacity | **1** | jobs run one at a time. In `ci.yml`, `static` runs first and the test jobs `need` it, so a format or lint failure costs minutes rather than a whole run |
| Job timeout | 3 h (runner) | each job sets its own `timeout-minutes` (15 to 120) |
| Action cache | enabled (`~/.cache/actcache`) | `subosito/flutter-action` `cache: true` and `actions/setup-node` `cache: npm` work |
| Tool cache | `~/.cache/act/tool_cache` (flutter 3.47.x for quiz_apps, node 20, Zulu JDK 17) | Taro's Flutter 3.44.8 gets its own tool-cache entry on first run and does not collide with quiz_apps' `stable` |
| Default actions | fetched from github.com | `actions/checkout@v4`, `actions/setup-node@v4`, `actions/setup-java@v4` and `subosito/flutter-action@v2` are all proven by quiz_apps |
| Runner PATH | `/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin` | `~/.pub-cache/bin` is added through `$GITHUB_PATH` after `dart pub global activate melos` (quiz_apps pattern) |
| Preinstalled | python3.12 (`/usr/local/bin`), lcov, gitleaks, gpg, jq, sonar-scanner, node 25 (brew), Xcode 26.6, iOS 26.2/26.4/26.5 runtimes, Android SDK with `system-images;android-36;google_apis_playstore;arm64-v8a`, adb | used directly |
| Missing | `flutter` (only via the action), `yq`, `actionlint`, `shellcheck`, `melos` | the static job runs `brew install` for actionlint and shellcheck when they are absent; melos is activated per job |
| Shell | `/bin/bash` 3.2 (no Homebrew bash) | the workflow scripts avoid bash-4 features |

## Deviations from the phase doc, and why

1. **The Flutter pin is read without `flutter-version-file`.** QA14 and the phase doc suggest `subosito/flutter-action` with `flutter-version-file: pubspec.yaml`. That input shells out to `yq`, which the runner does not have. Each workflow therefore reads `environment.flutter` from the root `pubspec.yaml` in a step (`sed`), passes it as `flutter-version:` to the same action quiz_apps uses (`subosito/flutter-action@v2`, `channel: stable`, `cache: true`), and then asserts that `flutter --version` matches. The pin stays single-sourced in `pubspec.yaml`. Installing `yq` on the runner (`brew install yq`) would allow switching to `flutter-version-file`, but the current approach does not need it.
2. **Python 3.12 comes from the runner, not from `actions/setup-python`.** quiz_apps never used `setup-python` on this host. It uses the host `python3`, which is 3.14 here. The workflows call `/usr/local/bin/python3.12` directly, create `tools/.venv`, run `pip install -e './tools[dev]'`, and fail with a clear error if 3.12 is missing (QA14).
3. **Artifacts use `actions/upload-artifact@v3` and `download-artifact@v3`.** quiz_apps' only `upload-artifact@v4` step is marked `continue-on-error`, and Gitea's artifact store (`~/gitea/data/actions_artifacts`) has never held an artifact, so v4 is unproven here. v3 speaks the protocol Gitea has served since 1.19. GitHub's retirement of v3 applies only to github.com. actionlint's warning about v3 is suppressed explicitly in `reusable-static.yml`. If v4 is later confirmed to work (it needs `GITHUB_SERVER_URL` to pass `@actions/artifact`'s GHES check), switch all of them together.
4. **Reports travel as tarballs.** Each test job packs its reports with repo-relative paths into one `.tgz` (`coverage-flutter`, `coverage-native`, `coverage-worker`, `coverage-tools`). The `coverage-gate` job unpacks them at the workspace root, so `check_coverage.py` sees the same paths as a local run, whatever path-flattening the artifact action does.
5. **`golden.yml` uploads rather than commits.** The phase doc says the update run "commits `test(golden): update goldens`". The Gitea repo is a read-only pull-mirror (06 §3, §8), so the run uploads `goldens-<sha>` (a tarball) and the job summary gives the commit command to run in a GitHub clone.
6. **The integration schedule lives only in `nightly.yml`.** 06 §8 lists both an `integration.yml` schedule at 03:00 and an integration job in `nightly.yml`. On a capacity-1 runner that would run the suite twice every night. `integration.yml` is therefore `workflow_call` + `workflow_dispatch` only. `ci.yml` calls it on every push with `platforms: ios`, and `nightly.yml` calls it at 03:00 with `platforms: ios,android`.
7. **Native tests are their own reusable workflow.** 06 §8 puts the `taro_attestation` XCTest and JUnit runs inside `reusable-flutter-test.yml`. The phase doc lists a separate `reusable-native-test.yml` for RC40, and that is what `ci.yml` calls. The coverage gate needs both.
8. **Job summaries are not shown in the UI.** Gitea 1.25 does not render `$GITHUB_STEP_SUMMARY`. The workflows still write it, but also print the same text to the log and upload `coverage/summary.md` and `coverage/merged/lcov.info` as the `coverage-summary` artifact.
9. **`concurrency` may be ignored.** `ci.yml` declares `cancel-in-progress: true` per ref (06 §8), and Sonar, golden and nightly use `false`. If this Gitea version ignores `concurrency`, superseded runs simply queue behind the single runner slot. That is slower, but still correct.

## Contracts with the scripts other Sprint 3.x work owns

The workflows call these entry points exactly:

| Workflow step | Command | Assumption |
|---|---|---|
| static | `melos run format:check`, `melos run analyze` | defined in the root `pubspec.yaml` |
| static | `dart run tools/dart_tools/bin/check_architecture.dart` | exits non-zero on violations; run from the repo root |
| static | every `tools/check_*.py` and `tools/store_copy/check_*.py`, run with `tools/.venv/bin/python <script>` and no args | defaults to the repo root. `check_urls.py` gets `--offline`. `check_coverage.py`, `check_commit_msg.py` and `check_changelog.py` are skipped here and run in their own steps |
| static | `tools/check_commit_msg.py` | if `--help` mentions `--range`, it is called as `--range <base>..<head>`. Otherwise it is called hook-style, once per non-merge commit, with a message-file path |
| static | `tools/check_changelog.py --range <base>..<head>` | only if `--help` mentions `--range` (06 §10.2); otherwise a warning |
| static | `gitleaks detect --no-banner --redact --source .` | `.gitleaks.toml` at the repo root is picked up automatically |
| static | `shellcheck -x -s bash` over `git ls-files '*.sh' 'tools/ci/*.env'` | every tracked shell script must be shellcheck-clean |
| static (worker) | `npm ci`, `npm run typecheck`, `npm run lint`, `npm run format:check`, `npx wrangler deploy --dry-run --outdir dist --env staging`, `npm audit --omit=dev --audit-level=high` | bundle budget: 80% of `worker_bundle_limit_bytes` (default 3 MiB, the Workers Free plan's compressed limit; raise it to 10 MiB on Workers Paid) |
| flutter-test | `melos run test:coverage` | writes `*/coverage/lcov*.info` under `apps/`, `packages/` and `tools/dart_tools/`. Golden failures go to `*/test/golden/failures/**` |
| native-test | `tools/ci/native_coverage_ios.sh`, `tools/ci/native_coverage_android.sh` | Java 17 (Zulu), `GRADLE_USER_HOME=$HOME/.gradle-ci` and a `tools/.venv` are provided. Every new file whose path contains `coverage`, `jacoco` or `xccov` (or that ends in `.lcov`) is shipped to the gate |
| worker-test | `npm run test:coverage` | writes `worker/coverage/{lcov.info,coverage-summary.json}` |
| tools-test | `cd tools && .venv/bin/python -m pytest --cov --cov-report=json --cov-report=xml:coverage.xml --cov-fail-under=90` | JSON goes to `tools/coverage/coverage.json` (pyproject) and XML to `tools/coverage.xml` (Sonar) |
| coverage-gate | `tools/.venv/bin/python tools/check_coverage.py --verify-sonar` | writes `coverage/summary.md` and `coverage/merged/lcov.info`. No `--threshold` is ever passed |
| golden | `melos run test:golden` / `melos run golden:update` | `golden:update` must recognise this runner as the reference platform (macOS arm64, the pinned Flutter, `CI=true`) without `--force-local` |
| integration | `melos run test:integration` | the device is in `TARO_DEVICE_ID` (a simulator UDID or `emulator-5580`) and the platform in `TARO_INTEGRATION_PLATFORM` (`ios` or `android`). The simulator is erased before each run and the emulator boots with `-wipe-data` |

## Manual steps (owner)

These cannot be done from the repo. Tick them in the Phase 3 doc when done.

1. **Create the Gitea pull-mirror.** In Gitea (`http://localhost:3001`), choose **+ → New Migration → GitHub**. The URL is `https://github.com/Mc231/taro.git`. Tick **This repository will be a mirror**. The repo is private, so provide a GitHub token with read access to `Mc231/taro` (for example a fine-grained PAT with Contents: read). Set the mirror interval to 10m or less. Use the same Gitea owner as quiz_apps (`Volodya`) unless you prefer otherwise.
2. **Enable Actions on the repo.** Open **Settings → Repository → Advanced settings (Units)** and tick **Actions**. Then confirm that `.gitea/workflows/*.yml` shows up under the repo's **Actions** tab after the next mirror sync. Instance-wide `[actions] ENABLED=true` is already on, because quiz_apps runs.
3. **Confirm the runner can see the repo and has the right labels.** Under **Site Administration → Actions → Runners** (or user or org settings, depending on how the runner was registered), check that the runner is global or available to the Taro owner, and that its labels include `macos`. `~/gitea/act_runner/config.yaml` has `macos:host` and `ubuntu-latest:host` with `capacity: 1`. If the runner is scoped to the quiz_apps repo only, register it again at instance or user scope (`act_runner register --instance http://localhost:3001 --token <token> --labels macos:host` with the same config), then restart it with `launchctl kickstart -k gui/$(id -u)/com.gitea.act_runner`.
4. **Add `SECRETS_PASSPHRASE`.** _(Done 2026-09-28: bundle created with the `TARO_SECRETS` passphrase; Sonar token + URL stored as `shared.sonar_*`.)_ Follow `.secrets/README.md`: create the bundle with `tools/secrets-manager.sh init`, then `set …` and `encrypt`, and commit `.secrets/secrets.json.gpg` to GitHub. Then add the passphrase under **Repo → Settings → Actions → Secrets**. `ci` does not need it; deploy workflows will (Phase 6 and later).
5. **Set up the SonarQube project and token (advisory, RC88).** In SonarQube, create a project with key `taro` and display name Taro. Create the quality gate `Taro` (06 §9: coverage on new code ≥ 90%, overall coverage ≥ 90%, duplicated lines on new code ≤ 3%, 0 new bugs, 0 new vulnerabilities, 100% of hotspots reviewed, maintainability A) and assign it to the project. Generate a **project analysis token**. Add the Gitea repo secrets `SONAR_TOKEN` (the token) and `SONAR_HOST_URL` (the same URL quiz_apps uses). The sonar-flutter plugin is already installed for quiz_apps. Until the secrets exist, `sonarqube-main.yml` logs a warning and skips the scan.
6. **Optional runner hygiene:** `brew install actionlint shellcheck` makes the first static run faster, since the job otherwise installs them. `brew install yq` would allow `flutter-version-file` (deviation 1).
7. **Verify.** Push a branch to GitHub, wait for the mirror sync, and confirm that `CI` runs `static`, then tools, worker, flutter, native and integration (iOS), then `coverage-gate`, and ends green. Then run `Golden` and `Nightly` by hand once from the Actions tab (`workflow_dispatch`).

Manual re-run of any workflow through the API (for example Sonar after a dropped push event):

```bash
curl -X POST -H "Authorization: token $GITEA_TOKEN" -H 'Content-Type: application/json' \
  -d '{"ref":"main"}' \
  "http://localhost:3001/api/v1/repos/<owner>/taro/actions/workflows/<file>.yml/dispatches"
```

## Validation done locally

- `actionlint` v1.7.12 (built into the session scratchpad) reports no findings with the same two `-ignore`s the static job uses. actionlint also shellchecks every inline `run:` script.
- `shellcheck` reports no findings on `tools/secrets-manager.sh` and `tools/ci/sim.env`.
- `tools/secrets-manager.sh` passed a smoke test against a throwaway `SECRETS_DIR` with a dummy passphrase: `init`, `set`, `set-file`, `encrypt`, `get`, `list`, `validate`, `clean`, and the `/tmp` refusal of `decrypt-to`. No real secret or `.gpg` file was created in the repo.
- The workflows have not run on the Gitea runner yet. That needs manual steps 1 to 3.
