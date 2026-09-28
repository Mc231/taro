#!/usr/bin/env bash
# `melos run test:coverage`: produce every coverage report check_coverage.py
# reads (06 §5.1, §5.2; QA1, RC40, RC95). Runs every unit even when one
# fails, then exits non-zero if any did.
#   Dart units   -> <unit>/coverage/lcov.filtered.info   (tools/ci/dart_coverage.sh)
#   worker       -> worker/coverage/{lcov.info,coverage-summary.json}
#   tools        -> tools/coverage/coverage.json, tools/coverage.xml
#   native (RC40)-> packages/taro_attestation/coverage/{ios,android}/lcov.info
# Env: TARO_SKIP_NATIVE_COVERAGE=1 skips the two native units (their reports
# are then missing and check_coverage.py fails them, by design).
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root" || exit 1
failed=()

run() {
  local name="$1"
  shift
  if ! "$@"; then
    failed+=("$name")
  fi
}

# Dart units: every packages/* with lib/ and test/, the app, tools/dart_tools.
for dir in packages/*/ apps/taro/ tools/dart_tools/; do
  dir="${dir%/}"
  [[ -d "$dir/lib" && -d "$dir/test" && -f "$dir/pubspec.yaml" ]] || continue
  run "$dir" bash tools/ci/dart_coverage.sh "$dir"
done

run worker bash -c 'cd worker && npm run --silent test:coverage'

python="$repo_root/tools/.venv/bin/python"
if [[ ! -x "$python" ]]; then
  # Clean checkout (CI): build the tools venv so pytest has its deps (QA14: 3.12).
  base=$(command -v python3.12 || command -v python3)
  "$base" -m venv "$repo_root/tools/.venv"
  "$python" -m pip install --quiet --upgrade pip
  "$python" -m pip install --quiet -e "$repo_root/tools[dev]"
fi
run tools bash -c "cd tools && '$python' -m pytest -q --cov=. --cov-report=term \
  --cov-report=json:coverage/coverage.json --cov-report=xml:coverage.xml --cov-fail-under=90"

if [[ "${TARO_SKIP_NATIVE_COVERAGE:-0}" != "1" ]]; then
  if command -v xcodebuild >/dev/null 2>&1; then
    run taro_attestation_ios bash tools/ci/native_coverage_ios.sh
  else
    echo "test:coverage: xcodebuild not available; taro_attestation_ios skipped" >&2
    failed+=(taro_attestation_ios)
  fi
  run taro_attestation_android bash tools/ci/native_coverage_android.sh
fi

if [[ ${#failed[@]} -gt 0 ]]; then
  echo "test:coverage: failed: ${failed[*]}" >&2
  exit 1
fi
echo "test:coverage: all reports written; next: melos run coverage:check"
