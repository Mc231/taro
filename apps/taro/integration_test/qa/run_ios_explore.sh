#!/bin/bash
# Runs integration_test/qa/ios_explore_test.dart (QA round 2, iOS) on a
# simulator against the staging Worker, with a host watcher for the
# `QA_HOST:` steps: shot <name> (simctl screenshot), openurl <url>,
# grant <supportId> (QA_GRANT=1; 4 staging bonus credits), esc (Escape key
# to the Simulator, closes the share sheet).
# usage: SIM=<udid> OUT=<dir> run_ios_explore.sh
# The debug attestation token and the Cloudflare credentials are read inside
# the commands that use them and never printed.
set -u
SIM=${SIM:?simulator udid}; OUT=${OUT:-/tmp/taro_qa_ios}; mkdir -p "$OUT/shots"
ROOT=$(cd "$(dirname "$0")/../../../.." && pwd)
LOG=$OUT/explore.out.log; HOSTLOG=$OUT/explore.host.log

grant() {
  local id; id=$(echo "$1" | grep -oE '[0-9a-f]{8}' | head -1)
  if [ "${QA_GRANT:-0}" != 1 ]; then echo "[host] grant $id skipped"; return; fi
  echo "[host] grant 4 bonus to $id"
  (
    eval "$(grep -E '^export TARO_SECRETS=' ~/.zshrc)"
    cd "$ROOT/worker" || exit 2
    CLOUDFLARE_API_TOKEN=$(cd "$ROOT" && SECRETS_PASSPHRASE=$TARO_SECRETS tools/secrets-manager.sh get worker cloudflare_api_token 2>/dev/null) \
      CLOUDFLARE_ACCOUNT_ID=$(cd "$ROOT" && SECRETS_PASSPHRASE=$TARO_SECRETS tools/secrets-manager.sh get worker cloudflare_account_id 2>/dev/null) \
      npm run -s ledger-adjust -- --env staging --ticket "qa-ios-$id" --support-id "$id" \
      --bucket bonus --delta 4 --note "QA ios run_ios_explore.sh"
  ) 2>&1 | grep -v -i token
}

watch_host() {
  tail -n0 -F "$LOG" | while read -r line; do
    case "$line" in
      *"QA_HOST: shot "*) n=${line##*QA_HOST: shot }; n=${n//[^A-Za-z0-9_]/_}
        xcrun simctl io "$SIM" screenshot "$OUT/shots/$n.png" >/dev/null 2>&1 && echo "[host] shot $n";;
      *"QA_HOST: openurl "*) u=${line##*QA_HOST: openurl }; echo "[host] openurl $u"
        xcrun simctl openurl "$SIM" "$u";;
      *"QA_HOST: grant "*) grant "${line##*QA_HOST: grant }" &;;
      *"QA_HOST: esc"*) echo "[host] esc"
        osascript -e 'tell application "Simulator" to activate' -e 'delay 0.5' \
          -e 'tell application "System Events" to key code 53' 2>&1;;
    esac
  done
}

: >"$LOG"
watch_host >"$HOSTLOG" 2>&1 &
HP=$!
eval "$(grep -E '^export TARO_SECRETS=' ~/.zshrc)"
TOKEN=$(cd "$ROOT" && SECRETS_PASSPHRASE=$TARO_SECRETS tools/secrets-manager.sh get worker staging_debug_attestation_token 2>/dev/null)
cd "$ROOT/apps/taro" || exit 2
START=$(date +%s)
flutter test integration_test/qa/ios_explore_test.dart -d "$SIM" --flavor staging \
  --dart-define-from-file=config/staging.json --dart-define=TARO_STAGING_SMOKE=1 \
  --dart-define=TARO_DEBUG_ATTESTATION_TOKEN="$TOKEN" >"$LOG" 2>&1
RC=$?
echo "rc=$RC wall=$(($(date +%s) - START))s" >>"$LOG"
kill "$HP" 2>/dev/null; pkill -f "tail -n0 -F $LOG"
exit $RC
