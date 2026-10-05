#!/usr/bin/env bash
# =============================================================================
# tools/screenshots/take_screenshots.sh: the store screenshots (05 §9.4,
# Phase 20.2). Ported from quiz_apps tools/take_screenshots.sh.
#
# For each capture set, one device at a time: boots it, runs
# apps/taro/integration_test/screenshots/screenshots_test.dart on fakes
# (TARO_ENV=test) for every locale in one run (the test sets the app
# locale itself, so the device language never changes), pulls the raw
# frames from the app container while it runs, shuts the device down.
# Then composes the store images (screenshots.py compose), the Play
# feature graphic, verifies every size and removes the raw captures.
#
# usage: take_screenshots.sh [--captures iphone,ipad,phone,tablet]
#          [--locales en,ar,...] [--no-compose] [--keep-raw] [--dry-run]
#
# Devices (override by env): IPHONE_SIM="iPhone 17 Pro Max" (1320×2868),
# IPAD_SIM="iPad Pro 13-inch (M5)" (2064×2752), PHONE_AVD=Pixel_9a,
# TABLET_AVD=Pixel_Tablet (portrait; feeds both Play tablet sets).
# Command overrides for tests: TARO_FLUTTER, TARO_XCRUN, TARO_ADB,
# TARO_EMULATOR, TARO_PYTHON.
# Output: build/screenshots/{ios/iphone,ios/ipad,android/phone,android/tab7,
# android/tab10}/<locale>/NN_name.png and build/store/feature_graphic.png.
# Exit codes: 0 ok, 1 a capture or check failed, 2 bad input.
# =============================================================================

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP="$ROOT/apps/taro"
RAW="$ROOT/build/screenshots/raw"
FLUTTER="${TARO_FLUTTER:-flutter}"
XCRUN="${TARO_XCRUN:-xcrun}"
SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-${HOME:-}/Library/Android/sdk}}"
ADB="${TARO_ADB:-$SDK/platform-tools/adb}"
EMULATOR="${TARO_EMULATOR:-$SDK/emulator/emulator}"
PYTHON="${TARO_PYTHON:-$ROOT/tools/.venv/bin/python}"
IPHONE_SIM="${IPHONE_SIM:-iPhone 17 Pro Max}"
IPAD_SIM="${IPAD_SIM:-iPad Pro 13-inch (M5)}"
PHONE_AVD="${PHONE_AVD:-Pixel_9a}"
TABLET_AVD="${TABLET_AVD:-Pixel_Tablet}"
BUNDLE="com.vshyrochuk.taro.dev"
MIN_FREE_GB="${MIN_FREE_GB:-40}"

CAPTURES="iphone,ipad,phone,tablet"
LOCALES="en,ar,de,es,fr,it,ja,ko,nl,pt,tr,uk"
COMPOSE=1
KEEP_RAW=0
DRY=0

usage() { sed -n '2,27p' "$0" | sed 's/^# \{0,1\}//'; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --captures) CAPTURES="${2:-}"; shift 2 ;;
    --locales) LOCALES="${2:-}"; shift 2 ;;
    --no-compose) COMPOSE=0; shift ;;
    --keep-raw) KEEP_RAW=1; shift ;;
    --dry-run) DRY=1; shift ;;
    -h | --help) usage; exit 0 ;;
    *) echo "take_screenshots: unknown argument '$1'" >&2; usage >&2; exit 2 ;;
  esac
done

IFS=',' read -ra CAPTURE_LIST <<<"$CAPTURES"
for c in "${CAPTURE_LIST[@]}"; do
  case "$c" in
    iphone | ipad | phone | tablet) ;;
    *) echo "take_screenshots: unknown capture '$c' (iphone, ipad, phone, tablet)" >&2; exit 2 ;;
  esac
done

log() { echo "[shots] $*"; }

run() {
  if [[ $DRY -eq 1 ]]; then echo "+ $*"; else "$@"; fi
}

# Frees space before a build when the disk is short (flutter clean).
check_disk() {
  local free
  free=$(df -g "$ROOT" | awk 'NR==2 {print $4}')
  log "disk free: ${free} GB"
  if [[ "$free" -lt "$MIN_FREE_GB" ]]; then
    log "below ${MIN_FREE_GB} GB: flutter clean"
    (cd "$APP" && run "$FLUTTER" clean)
  fi
}

flutter_test() { # <capture> <device id>
  (cd "$APP" && run "$FLUTTER" test integration_test/screenshots/screenshots_test.dart \
    --flavor dev --dart-define-from-file=config/dev.json \
    --dart-define=TARO_ENV=test --dart-define=STORE_SHOTS="$1" \
    --dart-define=STORE_LOCALES="$LOCALES" -d "$2")
}

ios_pull() { # <udid> <capture>
  local data
  data=$("$XCRUN" simctl get_app_container "$1" "$BUNDLE" data 2>/dev/null) || return 0
  [[ -d "$data/tmp/store_shots/$2" ]] || return 0
  mkdir -p "$RAW/$2"
  rsync -a "$data/tmp/store_shots/$2/" "$RAW/$2/"
}

android_pull() { # <serial> <capture>
  local tmp
  tmp=$(mktemp -d)
  # Directory.systemTemp is the app's code_cache (cache on older images).
  "$ADB" -s "$1" exec-out run-as "$BUNDLE" sh -c \
    'if [ -d code_cache/store_shots ]; then cd code_cache; else cd cache; fi; tar -cf - store_shots' 2>/dev/null |
    tar -xf - -C "$tmp" 2>/dev/null
  if [[ -d "$tmp/store_shots/$2" ]]; then
    mkdir -p "$RAW/$2"
    rsync -a "$tmp/store_shots/$2/" "$RAW/$2/"
  fi
  rm -rf "$tmp"
}

# Runs the test with a background pull loop (the app is removed at the end).
capture_with_pull() { # <pull fn> <device id> <capture>
  local pull="$1" id="$2" capture="$3" loop status
  if [[ $DRY -eq 1 ]]; then flutter_test "$capture" "$id"; return 0; fi
  ( while :; do "$pull" "$id" "$capture"; sleep 3; done ) &
  loop=$!
  flutter_test "$capture" "$id"
  status=$?
  kill "$loop" 2>/dev/null
  wait "$loop" 2>/dev/null
  "$pull" "$id" "$capture"
  return $status
}

capture_ios() { # <capture> <simulator name>
  local udid
  udid=$("$XCRUN" simctl list devices available | grep -F "$2 (" | head -1 |
    grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}')
  if [[ -z "$udid" ]]; then
    echo "take_screenshots: simulator '$2' not found" >&2
    return 1
  fi
  log "$1: $2 ($udid)"
  run "$XCRUN" simctl boot "$udid" 2>/dev/null
  capture_with_pull ios_pull "$udid" "$1"
  local status=$?
  run "$XCRUN" simctl shutdown "$udid" 2>/dev/null
  return $status
}

# True once the display is taller than wide (dumpsys `cur=WxH`).
is_portrait() { # <serial>
  local size
  size=$("$ADB" -s "$1" shell dumpsys window displays 2>/dev/null |
    grep -m1 -oE ' cur=[0-9]+x[0-9]+' | cut -d= -f2)
  [[ -n "$size" ]] && ((${size%x*} < ${size#*x}))
}

capture_android() { # <capture> <avd>
  log "$1: $2"
  if [[ $DRY -eq 1 ]]; then
    run "$EMULATOR" -avd "$2" -no-snapshot-save -no-boot-anim
    flutter_test "$1" emulator-5554
    return 0
  fi
  "$EMULATOR" -avd "$2" -no-snapshot-save -no-boot-anim >/dev/null 2>&1 &
  "$ADB" wait-for-device
  until [[ "$("$ADB" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == "1" ]]; do
    sleep 2
  done
  local serial
  serial=$("$ADB" devices | awk '/^emulator-/ {print $1; exit}')
  if [[ "$1" == "tablet" ]]; then
    # Portrait: the Pixel Tablet's natural orientation is landscape; the
    # lock only holds once the launcher is up, so retry until it applies.
    local tries=0
    until is_portrait "$serial"; do
      tries=$((tries + 1))
      [[ $tries -gt 20 ]] && { echo "take_screenshots: tablet stays landscape" >&2; break; }
      "$ADB" -s "$serial" shell settings put system accelerometer_rotation 0
      "$ADB" -s "$serial" shell settings put system user_rotation 1
      "$ADB" -s "$serial" shell wm user-rotation lock 1 >/dev/null
      sleep 3
    done
  fi
  capture_with_pull android_pull "$serial" "$1"
  local status=$?
  "$ADB" -s "$serial" emu kill >/dev/null 2>&1
  sleep 5
  return $status
}

failed=0
for c in "${CAPTURE_LIST[@]}"; do
  check_disk
  case "$c" in
    iphone) capture_ios iphone "$IPHONE_SIM" || failed=1 ;;
    ipad) capture_ios ipad "$IPAD_SIM" || failed=1 ;;
    phone) capture_android phone "$PHONE_AVD" || failed=1 ;;
    tablet) capture_android tablet "$TABLET_AVD" || failed=1 ;;
  esac
done
[[ $failed -eq 0 ]] || { echo "take_screenshots: a capture failed" >&2; exit 1; }

if [[ $COMPOSE -eq 1 ]]; then
  targets=""
  for c in "${CAPTURE_LIST[@]}"; do
    case "$c" in
      tablet) targets="$targets,tab7,tab10" ;;
      *) targets="$targets,$c" ;;
    esac
  done
  targets="${targets#,}"
  run "$PYTHON" "$ROOT/tools/screenshots/screenshots.py" compose --locales "$LOCALES" --targets "$targets" || exit 1
  run "$PYTHON" "$ROOT/tools/screenshots/screenshots.py" feature-graphic || exit 1
  run "$PYTHON" "$ROOT/tools/screenshots/screenshots.py" verify --locales "$LOCALES" --targets "$targets" || exit 1
fi
if [[ $KEEP_RAW -eq 0 && $DRY -eq 0 ]]; then
  rm -rf "$RAW"
fi
log "done"
