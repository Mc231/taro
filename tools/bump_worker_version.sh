#!/usr/bin/env bash
# =============================================================================
# tools/bump_worker_version.sh: bump the Worker version (06 §10.1, QA13).
#
#   tools/bump_worker_version.sh [patch|minor|major] [--version X.Y.Z] [--dry-run]
#
# * `worker/package.json` `version` (and the two root entries of
#   `worker/package-lock.json`): patch (default), minor or major bump, or an
#   exact `--version` that must be greater than the current one. The value is
#   served at `GET /v1/health` as `workerVersion`.
# * `worker/CHANGELOG.md`: `## [Unreleased]` becomes `## [X.Y.Z] - <today>`
#   and a new empty `## [Unreleased]` opens above it. Fails when Unreleased
#   is empty.
#
# The API major lives in the path (`/v1`); this script never changes it.
# `--dry-run` validates and prints the plan without writing anything.
# Exit codes: 0 success, 1 validation failure, 2 bad arguments.
# =============================================================================

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/release_common.sh
source "$ROOT/tools/lib/release_common.sh"

PACKAGE="$ROOT/worker/package.json"
LOCK="$ROOT/worker/package-lock.json"
CHANGELOG="$ROOT/worker/CHANGELOG.md"

BUMP="patch"
EXPLICIT=""
DRY_RUN=0

usage() {
  sed -n '3,18p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    patch | minor | major) BUMP="$1" ;;
    --version)
      EXPLICIT="${2:-}"
      if [[ -z "$EXPLICIT" ]]; then
        echo "error: --version needs X.Y.Z" >&2
        exit 2
      fi
      shift
      ;;
    --dry-run) DRY_RUN=1 ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

# is_greater <a> <b>: true when semver a > b.
is_greater() {
  local a b
  a="$(semver_parse "$1")" || return 2
  b="$(semver_parse "$2")" || return 2
  read -r a1 a2 a3 <<<"$a"
  read -r b1 b2 b3 <<<"$b"
  ((a1 != b1)) && { ((a1 > b1)); return; }
  ((a2 != b2)) && { ((a2 > b2)); return; }
  ((a3 > b3))
}

[[ -f "$PACKAGE" ]] || { echo "error: $PACKAGE not found" >&2; exit 1; }
[[ -f "$CHANGELOG" ]] || { echo "error: $CHANGELOG not found" >&2; exit 1; }

current="$(grep -m1 -E '^[[:space:]]*"version":' "$PACKAGE" | sed -E 's/.*"version":[[:space:]]*"([^"]*)".*/\1/' || true)"
semver_parse "$current" >/dev/null || exit 1

if [[ -n "$EXPLICIT" ]]; then
  semver_parse "$EXPLICIT" >/dev/null || exit 1
  if ! is_greater "$EXPLICIT" "$current"; then
    echo "error: version must increase: $EXPLICIT <= current $current" >&2
    exit 1
  fi
  next="$EXPLICIT"
else
  next="$(semver_next "$current" "$BUMP")" || exit 1
fi
date="$(today)"

if ! changelog_unreleased_has_entries "$CHANGELOG"; then
  echo "error: '## [Unreleased]' in worker/CHANGELOG.md is empty or missing; add the release notes first" >&2
  exit 1
fi

echo "worker: $current -> $next"
echo "worker/CHANGELOG.md: ## [Unreleased] -> ## [$next] - $date"

if ((DRY_RUN)); then
  echo "(dry-run: no files written)"
  exit 0
fi

changelog_release "$CHANGELOG" "$next" "$date"

# replace_first <file> <count>: rewrite the first <count> `"version": "<current>"`.
replace_first() {
  local file="$1" count="$2" tmp
  tmp="$(mktemp)"
  awk -v old="\"version\": \"$current\"" -v new="\"version\": \"$next\"" -v n="$count" '
    seen < n && (i = index($0, old)) {
      $0 = substr($0, 1, i - 1) new substr($0, i + length(old))
      seen++
    }
    { print }
  ' "$file" >"$tmp" && cat "$tmp" >"$file" && rm -f "$tmp"
}

replace_first "$PACKAGE" 1
# package-lock.json repeats the root version at the top and under packages."".
[[ -f "$LOCK" ]] && replace_first "$LOCK" 2
echo "bumped: worker $current -> $next"
