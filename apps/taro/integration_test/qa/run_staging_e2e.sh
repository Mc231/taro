#!/bin/bash
# Runs integration_test/qa/staging_e2e_test.dart on an Android emulator
# against the staging Worker, with a host watcher for the `QA_HOST:` steps
# (airplane mode, closing the native rewarded ad, closing the share sheet).
#
# usage: run_staging_e2e.sh <label> '<name regex>' [fresh|unverified]
#   run_staging_e2e.sh ALL '^B[1-7] ' fresh
#   run_staging_e2e.sh B8  '^B8 '     unverified
# Env: DEVICE (default emulator-5554), OUT (default /tmp/taro_qa),
# QA_GRANT=1 to let `QA_HOST: grant <supportId>` add 4 staging bonus credits
# to the run's install (worker ledger-adjust; RC53 allows one free reading
# per device and day, so B3-B6 need it after the first run of the day).
# The debug attestation token and the Cloudflare credentials are read inside
# the commands that use them and never printed.
set -u
LABEL=$1; NAME=$2; MODE=${3:-}
DEVICE=${DEVICE:-emulator-5554}; OUT=${OUT:-/tmp/taro_qa}; mkdir -p "$OUT"
A="adb -s $DEVICE"
ROOT=$(cd "$(dirname "$0")/../../../.." && pwd)
LOG=$OUT/$LABEL.out.log; HOSTLOG=$OUT/$LABEL.host.log

closead() {
  for i in $(seq 1 30); do
    sleep 5
    top=$($A shell dumpsys activity activities | grep -m1 topResumedActivity)
    case "$top" in *MainActivity*) echo "[host] ad gone"; return;; esac
    $A shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1
    b=$($A shell cat /sdcard/ui.xml | tr '>' '\n' \
      | grep -iE 'content-desc="(close|Close Ad|Skip)[^"]*"|text="(Close|Skip)"' \
      | grep -oE 'bounds="\[[0-9]+,[0-9]+\]\[[0-9]+,[0-9]+\]"' | head -1)
    if [ -n "$b" ]; then
      read -r x1 y1 x2 y2 <<<"$(echo "$b" | grep -oE '[0-9]+' | tr '\n' ' ')"
      echo "[host] tap close $b"
      $A shell input tap $(((x1 + x2) / 2)) $(((y1 + y2) / 2))
    elif [ "$i" -ge 12 ]; then echo "[host] BACK"; $A shell input keyevent BACK; fi
  done
}

grant() {
  local id
  id=$(echo "$1" | grep -oE '[0-9a-f]{8}' | head -1)
  if [ "${QA_GRANT:-0}" != 1 ]; then echo "[host] grant $id skipped (QA_GRANT!=1)"; return; fi
  echo "[host] grant 4 bonus to $id"
  (
    eval "$(grep -E '^export TARO_SECRETS=' ~/.zshrc)"
    cd "$ROOT/worker" || exit 2
    CLOUDFLARE_API_TOKEN=$(cd "$ROOT" && SECRETS_PASSPHRASE=$TARO_SECRETS tools/secrets-manager.sh get worker cloudflare_api_token 2>/dev/null) \
      CLOUDFLARE_ACCOUNT_ID=$(cd "$ROOT" && SECRETS_PASSPHRASE=$TARO_SECRETS tools/secrets-manager.sh get worker cloudflare_account_id 2>/dev/null) \
      npm run -s ledger-adjust -- --env staging --ticket "qa-e2e-$id" --support-id "$id" \
      --bucket bonus --delta 4 --note "QA e2e run_staging_e2e.sh"
  ) 2>&1 | grep -v -i token
}

watch_host() {
  tail -n0 -F "$LOG" | while read -r line; do
    case "$line" in
      *"QA_HOST: offline"*) echo "[host] airplane on"; $A shell cmd connectivity airplane-mode enable;;
      *"QA_HOST: online"*) echo "[host] airplane off"; $A shell cmd connectivity airplane-mode disable
        $A shell svc wifi enable; $A shell svc data enable;;
      *"QA_HOST: closead"*) closead &;;
      *"QA_HOST: grant "*) grant "${line##*QA_HOST: grant }" &;;
      *"QA_HOST: back"*) (sleep 5; echo "[host] BACK (share sheet)"; $A shell input keyevent BACK) &;;
    esac
  done
}

if [ "$MODE" = fresh ] || [ "$MODE" = unverified ]; then
  $A uninstall com.vshyrochuk.taro.stg >/dev/null 2>&1
fi
$A shell cmd connectivity airplane-mode disable; $A shell svc wifi enable; $A shell svc data enable
: >"$LOG"
watch_host >"$HOSTLOG" 2>&1 &
HP=$!

EXTRA=(); TOKEN=""
# QA_PACE_S: seconds between B9 questions (default 40 in the test; 0 repeats
# the round-2 R2-01 burst).
[ -n "${QA_PACE_S:-}" ] && EXTRA+=(--dart-define=QA_PACE_S="$QA_PACE_S")
if [ "$MODE" = unverified ]; then
  EXTRA=(--dart-define=TARO_QA_UNVERIFIED=true)
else
  eval "$(grep -E '^export TARO_SECRETS=' ~/.zshrc)"
  TOKEN=$(cd "$ROOT" && SECRETS_PASSPHRASE=$TARO_SECRETS tools/secrets-manager.sh get worker staging_debug_attestation_token 2>/dev/null)
fi
cd "$ROOT/apps/taro" || exit 2
START=$(date +%s)
flutter test integration_test/qa/staging_e2e_test.dart -d "$DEVICE" --flavor staging \
  --dart-define-from-file=config/staging.json --dart-define=TARO_STAGING_SMOKE=1 \
  --dart-define=TARO_DEBUG_ATTESTATION_TOKEN="$TOKEN" ${EXTRA[@]+"${EXTRA[@]}"} --name "$NAME" >"$LOG" 2>&1
RC=$?
echo "rc=$RC wall=$(($(date +%s) - START))s" >>"$LOG"
kill "$HP" 2>/dev/null; pkill -f "tail -n0 -F $LOG"
$A shell cmd connectivity airplane-mode disable
exit $RC
