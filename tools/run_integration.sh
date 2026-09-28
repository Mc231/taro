#!/usr/bin/env bash
# =============================================================================
# tools/run_integration.sh: `melos run test:integration` (06 §4, QA8).
#
# Runs the app's device tests on a booted simulator or emulator:
#   TARO_INTEGRATION_PLATFORM  ios | android (default: ios)
#   TARO_DEVICE_ID             simulator UDID / adb serial (default: the only
#                              booted device, chosen by flutter)
#   TARO_FLUTTER, TARO_PATROL  command overrides (tests stub them)
#
# From Phase 13 the flows are patrol tests in apps/taro/patrol_test/ and run
# with `patrol test`; until then the `integration_test/` spikes (RC91 FTS5)
# run with `flutter test integration_test`. Always the `dev` flavor with
# config/dev.json. .gitea/workflows/integration.yml sets both variables from
# tools/ci/sim.env.
# Exit codes: 0 pass (or nothing to run), 1 test failure, 2 bad input.
# =============================================================================

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/apps/taro"
FLUTTER="${TARO_FLUTTER:-flutter}"
PATROL="${TARO_PATROL:-patrol}"
PLATFORM="${TARO_INTEGRATION_PLATFORM:-ios}"
DEVICE="${TARO_DEVICE_ID:-}"

case "$PLATFORM" in
  ios | android) ;;
  *)
    echo "run_integration: TARO_INTEGRATION_PLATFORM must be ios or android, got '$PLATFORM'" >&2
    exit 2
    ;;
esac

device_args=()
[[ -n "$DEVICE" ]] && device_args=(-d "$DEVICE")
common=(--flavor dev --dart-define-from-file=config/dev.json)

cd "$APP"
shopt -s nullglob
patrol_tests=(patrol_test/*_test.dart patrol_test/**/*_test.dart)
spikes=(integration_test/*_test.dart)
shopt -u nullglob

echo "run_integration: platform=$PLATFORM device=${DEVICE:-<default>}"
if ((${#patrol_tests[@]})); then
  exec "$PATROL" test "${common[@]}" "${device_args[@]+"${device_args[@]}"}"
elif ((${#spikes[@]})); then
  exec "$FLUTTER" test integration_test "${common[@]}" "${device_args[@]+"${device_args[@]}"}"
else
  echo "run_integration: no integration tests yet (patrol flows land in Phase 13)"
fi
