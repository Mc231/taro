#!/usr/bin/env bash
# =============================================================================
# tools/bump_version.sh: bump the app version (06 §10.1, QA13).
#
#   tools/bump_version.sh [patch|minor|major] [--version X.Y.Z+B] [--dry-run]
#
# * `apps/taro/pubspec.yaml` `version: X.Y.Z+B`: patch (default), minor or
#   major bump of X.Y.Z; the build number B always goes up by exactly 1 (it
#   is monotonic across both stores and never reused). `--version` pins an
#   exact value, whose B must still be greater than the current one.
# * `CHANGELOG.md`: `## [Unreleased]` becomes `## [X.Y.Z] - <today>` and a new
#   empty `## [Unreleased]` opens above it. Fails when Unreleased is empty.
# * `sonar-project.properties`: `sonar.projectVersion=X.Y.Z`, so the Sonar
#   new-code period rolls forward (06 §9).
#
# `--dry-run` validates and prints the plan without writing anything.
# Exit codes: 0 success, 1 validation failure, 2 bad arguments.
# =============================================================================

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/release_common.sh
source "$ROOT/tools/lib/release_common.sh"

PUBSPEC="$ROOT/apps/taro/pubspec.yaml"
CHANGELOG="$ROOT/CHANGELOG.md"
SONAR="$ROOT/sonar-project.properties"

BUMP="patch"
EXPLICIT=""
DRY_RUN=0

usage() {
  sed -n '3,19p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    patch | minor | major) BUMP="$1" ;;
    --version)
      EXPLICIT="${2:-}"
      if [[ -z "$EXPLICIT" ]]; then
        echo "error: --version needs X.Y.Z+B" >&2
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

split_full() {
  if [[ ! "$1" =~ ^([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)$ ]]; then
    echo "error: malformed version '$1' (expected X.Y.Z+B)" >&2
    return 1
  fi
  echo "${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"
}

[[ -f "$PUBSPEC" ]] || { echo "error: $PUBSPEC not found" >&2; exit 1; }
[[ -f "$CHANGELOG" ]] || { echo "error: $CHANGELOG not found" >&2; exit 1; }

current="$(grep -m1 '^version:' "$PUBSPEC" | sed -E 's/^version:[[:space:]]*//; s/["'\'']//g' || true)"
parts="$(split_full "$current")" || exit 1
read -r cur_semver cur_build <<<"$parts"

if [[ -n "$EXPLICIT" ]]; then
  parts="$(split_full "$EXPLICIT")" || exit 1
  read -r new_semver new_build <<<"$parts"
  if ((new_build <= cur_build)); then
    echo "error: build number must increase: $new_build <= current $cur_build" >&2
    exit 1
  fi
else
  new_semver="$(semver_next "$cur_semver" "$BUMP")" || exit 1
  new_build=$((cur_build + 1))
fi
next="$new_semver+$new_build"
date="$(today)"

if ! changelog_unreleased_has_entries "$CHANGELOG"; then
  echo "error: '## [Unreleased]' in CHANGELOG.md is empty or missing; add the release notes first" >&2
  exit 1
fi

echo "app: $current -> $next"
echo "CHANGELOG.md: ## [Unreleased] -> ## [$new_semver] - $date"
if [[ -f "$SONAR" ]]; then
  echo "sonar-project.properties: sonar.projectVersion=$new_semver"
else
  echo "warning: sonar-project.properties not found; skipping sonar.projectVersion" >&2
fi

if ((DRY_RUN)); then
  echo "(dry-run: no files written)"
  exit 0
fi

changelog_release "$CHANGELOG" "$new_semver" "$date"
sed -i.bak -E "s/^version:[[:space:]]*.*/version: $next/" "$PUBSPEC" && rm -f "$PUBSPEC.bak"
if [[ -f "$SONAR" ]]; then
  if grep -q '^sonar.projectVersion=' "$SONAR"; then
    sed -i.bak -E "s/^sonar\.projectVersion=.*/sonar.projectVersion=$new_semver/" "$SONAR" && rm -f "$SONAR.bak"
  else
    echo "sonar.projectVersion=$new_semver" >>"$SONAR"
  fi
fi
echo "bumped: $current -> $next"
