#!/usr/bin/env bash
# Kotlin coverage of the taro_attestation plugin (06 §5.2; RC40, unit taro_attestation_android).
# Runs the plugin's JVM unit tests through the example's Gradle build with
# JaCoCo, then converts jacoco.xml to lcov for check_coverage.py:
#   packages/taro_attestation/coverage/android/lcov.info
# Env: PYTHON (default: tools/.venv/bin/python, then python3).
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
plugin="$repo_root/packages/taro_attestation"
example="$plugin/example"
out_dir="$plugin/coverage/android"
# The example's root build.gradle.kts moves every build dir to example/build/<project>.
report_dir="$example/build/taro_attestation/reports/coverage/test/debug"

python="${PYTHON:-}"
if [[ -z "$python" ]]; then
  if [[ -x "$repo_root/tools/.venv/bin/python" ]]; then
    python="$repo_root/tools/.venv/bin/python"
  else
    python="python3"
  fi
fi

echo "== native coverage (Android)"
rm -rf "$out_dir" "$report_dir"
mkdir -p "$out_dir"

# local.properties (flutter.sdk), the plugin registration and the Gradle
# wrapper (gradlew is gitignored by Flutter; `flutter pub get` alone writes
# local.properties but not the wrapper, so check both).
if [[ ! -f "$example/android/local.properties" || ! -x "$example/android/gradlew" ]]; then
  (cd "$example" && flutter build apk --config-only --debug)
fi

(cd "$example/android" && ./gradlew --no-daemon --quiet :taro_attestation:jacocoTestReport)

xml="$(find "$report_dir" -name '*.xml' -type f | head -n 1)"
if [[ -z "$xml" ]]; then
  echo "native_coverage_android: no JaCoCo XML under $report_dir" >&2
  exit 1
fi
cp "$xml" "$out_dir/jacoco.xml"

"$python" "$repo_root/tools/jacoco_to_lcov.py" "$out_dir/jacoco.xml" \
  --source-root packages/taro_attestation/android/src/main/kotlin \
  --source-root packages/taro_attestation/android/src/main/java \
  --repo-root "$repo_root" \
  -o "$out_dir/lcov.info"
