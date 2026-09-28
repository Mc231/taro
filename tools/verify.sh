#!/usr/bin/env bash
# =============================================================================
# tools/verify.sh: reproduce the `ci` workflow locally (06 §6.4).
#
#   tools/verify.sh           everything `ci` runs except integration tests:
#                             format, analyze, every repo check, gitleaks,
#                             worker lint/typecheck/prettier, `test:coverage`
#                             (Dart unit + widget + golden, worker vitest,
#                             tools pytest, native; tools/ci/test_coverage.sh)
#                             and `coverage:check`.
#   tools/verify.sh --fast    the pre-push gate: format, analyze, every repo
#                             check, gitleaks, and `test:fast` (no goldens, no
#                             integration) in the packages changed against
#                             origin/main (all packages when there is no
#                             origin/main).
#
# Options:
#   --fast        the fast subset above
#   --fail-fast   stop at the first failing step (default: run every step and
#                 print a summary)
#   -h, --help    this text
#
# Repo checks are discovered by glob, so a new check is picked up without
# editing this file:
#   tools/check_*.py, tools/*/check_*.py        (python)
#   tools/check_*.dart, tools/dart_tools/bin/check_*.dart  (dart run)
# Scripts that need arguments get them from check_args() below;
# check_coverage.py runs as the coverage gate (full mode), not as a repo check.
#
# Every external command can be overridden through the environment (the
# pytest wrapper tools/tests/test_verify.py stubs them): TARO_VERIFY_ROOT,
# TARO_MELOS, TARO_PYTHON, TARO_DART, TARO_NPM, TARO_GIT, TARO_GITLEAKS.
#
# Exit codes: 0 all steps passed, 1 a step failed, 2 bad arguments.
# =============================================================================

set -uo pipefail

ROOT="${TARO_VERIFY_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
MELOS="${TARO_MELOS:-melos}"
DART="${TARO_DART:-dart}"
NPM="${TARO_NPM:-npm}"
GIT="${TARO_GIT:-git}"
GITLEAKS="${TARO_GITLEAKS:-gitleaks}"
if [[ -n "${TARO_PYTHON:-}" ]]; then
  PYTHON="$TARO_PYTHON"
elif [[ -x "$ROOT/tools/.venv/bin/python" ]]; then
  PYTHON="$ROOT/tools/.venv/bin/python"
else
  PYTHON="python3"
fi

FAST=0
FAIL_FAST=0
BASE_REF="origin/main"

usage() {
  sed -n '3,33p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fast) FAST=1 ;;
    --fail-fast) FAIL_FAST=1 ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "verify.sh: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

cd "$ROOT" || exit 2

PASSED=()
FAILED=()
SKIPPED=()

# step <name> <command...>: run one step and record the outcome.
step() {
  local name="$1"
  shift
  echo ""
  echo "==> $name"
  if "$@"; then
    PASSED+=("$name")
  else
    FAILED+=("$name")
    echo "!!! $name failed" >&2
    if ((FAIL_FAST)); then
      summary
      exit 1
    fi
  fi
}

skip() {
  echo ""
  echo "--- skip $1: $2"
  SKIPPED+=("$1 ($2)")
}

summary() {
  echo ""
  echo "==================== verify.sh summary ===================="
  local s
  for s in "${PASSED[@]+"${PASSED[@]}"}"; do echo "  ok    $s"; done
  for s in "${SKIPPED[@]+"${SKIPPED[@]}"}"; do echo "  skip  $s"; done
  for s in "${FAILED[@]+"${FAILED[@]}"}"; do echo "  FAIL  $s"; done
  echo "==========================================================="
}

has_base_ref() {
  "$GIT" rev-parse --verify --quiet "$BASE_REF" >/dev/null 2>&1
}

in_path_or_file() {
  [[ "$1" == */* ]] && [[ -x "$1" ]] && return 0
  command -v "$1" >/dev/null 2>&1
}

# check_args <script basename>: extra arguments for a repo check, one per
# line. Prints SKIP to leave the script out of the repo-check stage.
check_args() {
  case "$1" in
    check_coverage.py) echo SKIP ;; # the coverage gate step runs it
    check_commit_msg.py)
      if has_base_ref; then
        echo "--range"
        echo "$BASE_REF..HEAD"
      else
        echo SKIP
      fi
      ;;
    check_changelog.py)
      if has_base_ref; then
        echo "--range"
        echo "$BASE_REF..HEAD"
      fi
      ;;
    check_urls.py) echo "--offline" ;; # the network run is weekly (nightly)
    *) ;;
  esac
}

run_python_check() {
  local script="$1"
  shift
  "$PYTHON" "$script" "$@"
}

run_dart_check() {
  "$DART" run "$@"
}

discover_checks() {
  local f
  shopt -s nullglob
  for f in tools/check_*.py tools/*/check_*.py; do
    [[ "$f" == tools/tests/* || "$f" == tools/.venv/* ]] && continue
    echo "$f"
  done
  for f in tools/check_*.dart tools/dart_tools/bin/check_*.dart; do
    echo "$f"
  done
  shopt -u nullglob
}

repo_checks() {
  local script base arg
  local -a args
  while IFS= read -r script; do
    base="$(basename "$script")"
    args=()
    while IFS= read -r arg; do
      [[ -n "$arg" ]] && args+=("$arg")
    done < <(check_args "$base")
    if [[ "${args[0]:-}" == SKIP ]]; then
      skip "$base" "not a standalone check here"
      continue
    fi
    case "$script" in
      *.py) step "check: $base" run_python_check "$script" "${args[@]+"${args[@]}"}" ;;
      *.dart) step "check: $base" run_dart_check "$script" "${args[@]+"${args[@]}"}" ;;
    esac
  done < <(discover_checks)
}

secrets_scan() {
  if ! in_path_or_file "$GITLEAKS"; then
    skip "gitleaks" "gitleaks not installed (CI runs it)"
    return
  fi
  if [[ -f .gitleaks.toml ]]; then
    step "gitleaks" "$GITLEAKS" detect --no-banner --config .gitleaks.toml
  else
    step "gitleaks" "$GITLEAKS" detect --no-banner
  fi
}

fast_tests() {
  if has_base_ref; then
    "$MELOS" exec --diff="$BASE_REF" --dir-exists=test -c 1 --fail-fast -- \
      flutter test --no-pub --exclude-tags golden,integration
  else
    "$MELOS" run test:fast
  fi
}

worker_checks() {
  (cd worker && "$NPM" run lint && "$NPM" run typecheck && "$NPM" run format:check)
}

echo "verify.sh ($([[ $FAST == 1 ]] && echo fast || echo full)) in $ROOT"

step "format" "$MELOS" run format:check
step "analyze" "$MELOS" run analyze
repo_checks
secrets_scan

if ((FAST)); then
  step "test:fast" fast_tests
  skip "goldens, coverage, worker, native" "--fast"
else
  if [[ -d worker ]]; then
    step "worker: lint, typecheck, prettier" worker_checks
  else
    skip "worker" "no worker/ directory"
  fi
  # test:coverage (tools/ci/test_coverage.sh) runs every unit: Dart packages
  # and the app (goldens included), worker vitest, tools pytest, native.
  step "test:coverage" "$MELOS" run test:coverage
  # The gate reads every unit's report, so it runs last.
  step "coverage:check" "$MELOS" run coverage:check
fi
skip "integration" "not part of verify.sh (melos run test:integration)"

summary
((${#FAILED[@]} == 0))
