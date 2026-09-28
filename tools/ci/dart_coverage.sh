#!/usr/bin/env bash
# Coverage for one Dart unit (06 §5.1, QA4). Usage: dart_coverage.sh <package_dir>
#  1. gen_coverage_all  -> test/coverage_all_test.dart (every non-excluded lib file)
#  2. flutter test --coverage --exclude-tags=integration -> coverage/lcov.info
#  3. lcov --remove (tools/coverage_exclusions.txt) -> coverage/lcov.filtered.info
# check_coverage.py re-applies the exact globs, so lcov's looser matching is safe.
set -euo pipefail
# The lcov patterns contain `*`; never let the shell expand them.
set -f

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
pkg="$(cd "${1:?usage: dart_coverage.sh <package_dir>}" && pwd)"
gen="$repo_root/tools/dart_tools/bin/gen_coverage_all.dart"

cd "$pkg"
echo "== coverage: ${pkg#"$repo_root"/}"
dart run "$gen" .
rm -f coverage/lcov.info coverage/lcov.filtered.info
flutter test --no-pub --coverage --coverage-path=coverage/lcov.info --exclude-tags=integration

patterns=()
while IFS= read -r p; do
  [[ -n "$p" ]] && patterns+=("$p")
done < <(dart run "$gen" --lcov-patterns .)

ignore=()
# lcov >= 2 errors on patterns that match nothing unless told otherwise;
# lcov 1.x does not know the `unused` category.
if ! lcov --version | grep -Eq 'version 1\.'; then
  ignore=(--ignore-errors unused)
fi

if [[ ${#patterns[@]} -gt 0 ]]; then
  lcov --quiet --remove coverage/lcov.info "${patterns[@]}" \
    -o coverage/lcov.filtered.info ${ignore[@]+"${ignore[@]}"}
else
  cp coverage/lcov.info coverage/lcov.filtered.info
fi
echo "   -> ${pkg#"$repo_root"/}/coverage/lcov.filtered.info"
