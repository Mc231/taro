#!/usr/bin/env bash
# Swift coverage of the taro_attestation plugin (06 §5.2; RC40, unit taro_attestation_ios).
# Runs the plugin's XCTest in the example Runner with code coverage, exports
# xccov JSON and converts it to lcov for check_coverage.py:
#   packages/taro_attestation/coverage/ios/lcov.info
# Env: TARO_IOS_DESTINATION (xcodebuild -destination; default: first available
# iPhone simulator), PYTHON (default: tools/.venv/bin/python, then python3).
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
plugin="$repo_root/packages/taro_attestation"
example="$plugin/example"
out_dir="$plugin/coverage/ios"
result="$out_dir/RunnerTests.xcresult"

python="${PYTHON:-}"
if [[ -z "$python" ]]; then
  if [[ -x "$repo_root/tools/.venv/bin/python" ]]; then
    python="$repo_root/tools/.venv/bin/python"
  else
    python="python3"
  fi
fi

destination="${TARO_IOS_DESTINATION:-}"
if [[ -z "$destination" ]]; then
  udid="$(xcrun simctl list devices available --json | "$python" -c '
import json, sys
devices = json.load(sys.stdin)["devices"]
for runtime in sorted(devices, reverse=True):
    if "iOS" not in runtime:
        continue
    for d in devices[runtime]:
        if d.get("isAvailable") and d["name"].startswith("iPhone"):
            print(d["udid"]); sys.exit(0)
sys.exit("no available iPhone simulator")
')"
  destination="platform=iOS Simulator,id=$udid"
fi

echo "== native coverage (iOS): $destination"
rm -rf "$out_dir"
mkdir -p "$out_dir"

# Generated.xcconfig + Pods for the example Runner.
(cd "$example" && flutter build ios --config-only --simulator --debug)

xcodebuild test \
  -workspace "$example/ios/Runner.xcworkspace" \
  -scheme Runner \
  -configuration Debug \
  -destination "$destination" \
  -only-testing:RunnerTests \
  -enableCodeCoverage YES \
  -resultBundlePath "$result" \
  -quiet

xcrun xccov view --report --json "$result" > "$out_dir/xccov_report.json"
xcrun xccov view --archive --json "$result" > "$out_dir/xccov_archive.json"

"$python" "$repo_root/tools/xccov_to_lcov.py" \
  --report "$out_dir/xccov_report.json" \
  --archive "$out_dir/xccov_archive.json" \
  --repo-root "$repo_root" \
  --include 'packages/taro_attestation/ios/**' \
  -o "$out_dir/lcov.info"
