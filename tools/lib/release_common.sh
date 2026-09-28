#!/usr/bin/env bash
# Shared helpers for tools/bump_version.sh and tools/bump_worker_version.sh
# (06 §10.1, §10.2). Sourced, never executed.
#
# Environment: TARO_TODAY overrides today's date (YYYY-MM-DD) for tests.

# semver_parse <X.Y.Z>: echoes "X Y Z" or fails.
semver_parse() {
  if [[ ! "$1" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    echo "error: malformed version '$1' (expected X.Y.Z)" >&2
    return 1
  fi
  echo "${BASH_REMATCH[1]} ${BASH_REMATCH[2]} ${BASH_REMATCH[3]}"
}

# semver_next <X.Y.Z> <patch|minor|major>
semver_next() {
  local maj min pat parts
  parts="$(semver_parse "$1")" || return 1
  read -r maj min pat <<<"$parts"
  case "$2" in
    patch) echo "$maj.$min.$((pat + 1))" ;;
    minor) echo "$maj.$((min + 1)).0" ;;
    major) echo "$((maj + 1)).0.0" ;;
    *)
      echo "error: unknown bump '$2' (patch|minor|major)" >&2
      return 1
      ;;
  esac
}

today() {
  echo "${TARO_TODAY:-$(date +%F)}"
}

# changelog_unreleased_has_entries <file>: true when `## [Unreleased]` holds
# at least one line that is not blank and not a `###` section heading.
changelog_unreleased_has_entries() {
  awk '
    /^## \[Unreleased\]/ { inside = 1; found = 1; next }
    inside && /^## / { exit }
    inside && NF && !/^### / { entries = 1; exit }
    END { exit !(found && entries) }
  ' "$1"
}

# changelog_release <file> <X.Y.Z> <date>: renames `## [Unreleased]` to
# `## [X.Y.Z] - <date>` and opens a new empty `## [Unreleased]` above it.
changelog_release() {
  local file="$1" version="$2" date="$3" tmp
  if ! grep -q '^## \[Unreleased\]' "$file"; then
    echo "error: $file has no '## [Unreleased]' section" >&2
    return 1
  fi
  if grep -q "^## \[$version\]" "$file"; then
    echo "error: $file already has a '## [$version]' section" >&2
    return 1
  fi
  if ! changelog_unreleased_has_entries "$file"; then
    echo "error: '## [Unreleased]' in $file is empty; add the release notes first" >&2
    return 1
  fi
  tmp="$(mktemp)"
  awk -v v="$version" -v d="$date" '
    !done && /^## \[Unreleased\]/ {
      print "## [Unreleased]"
      print ""
      print "## [" v "] - " d
      done = 1
      next
    }
    { print }
  ' "$file" >"$tmp" && mv "$tmp" "$file"
}
