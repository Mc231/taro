#!/usr/bin/env bash
# =============================================================================
# tools/screenshots/upload_store_assets.sh: uploads the composed store
# screenshots and the Play feature graphic with asa (05 §9.4, Phase 20.2;
# docs/runbooks/STORE_SUBMISSION.md). Ported from quiz_apps
# tools/upload_store_assets.sh.
#
# usage: upload_store_assets.sh [--platform ios|android|all]
#          [--locales en,ar,...] [--source build/screenshots] [--dry-run]
#
# Reads build/screenshots/{ios/iphone,ios/ipad,android/phone,android/tab7,
# android/tab10}/<locale>/ and build/store/feature_graphic.png (from
# take_screenshots.sh). Store locales: App Store en-US, ar-SA, de-DE, es-ES,
# fr-FR, it, ja, ko, nl-NL, pt-BR, tr, uk; Play en-US, ar, de-DE, es-ES,
# fr-FR, it-IT, ja-JP, ko-KR, nl-NL, pt-BR, tr-TR, uk.
# ASA (default ~/pet/app-store-automation/.venv/bin/asa) can be overridden.
# --dry-run prints the asa commands without running them.
# Exit codes: 0 ok, 1 an upload failed or a set is missing, 2 bad input.
# =============================================================================

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ASA="${ASA:-${HOME:-}/pet/app-store-automation/.venv/bin/asa}"
BUNDLE="com.vshyrochuk.taro"
PLATFORM="all"
LOCALES="en,ar,de,es,fr,it,ja,ko,nl,pt,tr,uk"
SOURCE="$ROOT/build/screenshots"
FEATURE="$ROOT/build/store/feature_graphic.png"
DRY=0

usage() { sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --platform) PLATFORM="${2:-}"; shift 2 ;;
    --locales) LOCALES="${2:-}"; shift 2 ;;
    --source) SOURCE="${2:-}"; shift 2 ;;
    --dry-run) DRY=1; shift ;;
    -h | --help) usage; exit 0 ;;
    *) echo "upload_store_assets: unknown argument '$1'" >&2; usage >&2; exit 2 ;;
  esac
done
case "$PLATFORM" in
  ios | android | all) ;;
  *) echo "upload_store_assets: --platform must be ios, android or all" >&2; exit 2 ;;
esac

apple_locale() {
  case "$1" in
    en) echo en-US ;; ar) echo ar-SA ;; de) echo de-DE ;; es) echo es-ES ;;
    fr) echo fr-FR ;; nl) echo nl-NL ;; pt) echo pt-BR ;;
    it | ja | ko | tr | uk) echo "$1" ;;
    *) return 1 ;;
  esac
}

play_locale() {
  case "$1" in
    en) echo en-US ;; de) echo de-DE ;; es) echo es-ES ;; fr) echo fr-FR ;;
    it) echo it-IT ;; ja) echo ja-JP ;; ko) echo ko-KR ;; nl) echo nl-NL ;;
    pt) echo pt-BR ;; tr) echo tr-TR ;; ar | uk) echo "$1" ;;
    *) return 1 ;;
  esac
}

run() {
  if [[ $DRY -eq 1 ]]; then echo "+ $*"; else "$@"; fi
}

failed=0
upload_set() { # <dir> <asa args...>
  local dir="$1"
  shift
  if ! ls "$dir"/*.png >/dev/null 2>&1; then
    echo "upload_store_assets: no screenshots in $dir" >&2
    failed=1
    return
  fi
  run "$ASA" "$@" || failed=1
}

IFS=',' read -ra LOCALE_LIST <<<"$LOCALES"
for loc in "${LOCALE_LIST[@]}"; do
  apple=$(apple_locale "$loc") || { echo "upload_store_assets: unknown locale '$loc'" >&2; exit 2; }
  play=$(play_locale "$loc")
  if [[ "$PLATFORM" != android ]]; then
    upload_set "$SOURCE/ios/iphone/$loc" ios upload-screenshots -b "$BUNDLE" \
      -s "$SOURCE/ios/iphone/$loc" -d iphone-67 -l "$apple"
    upload_set "$SOURCE/ios/ipad/$loc" ios upload-screenshots -b "$BUNDLE" \
      -s "$SOURCE/ios/ipad/$loc" -d ipad-129 -l "$apple"
  fi
  if [[ "$PLATFORM" != ios ]]; then
    for pair in phone:phoneScreenshots tab7:sevenInchScreenshots tab10:tenInchScreenshots; do
      set_dir="$SOURCE/android/${pair%%:*}/$loc"
      upload_set "$set_dir" android upload-screenshots -p "$BUNDLE" \
        --screenshots-dir "$set_dir" --type "${pair#*:}" --language "$play"
    done
  fi
done
if [[ "$PLATFORM" != ios ]]; then
  if [[ -f "$FEATURE" ]]; then
    run "$ASA" android upload-feature-graphic -p "$BUNDLE" --image "$FEATURE" || failed=1
  else
    echo "upload_store_assets: $FEATURE missing" >&2
    failed=1
  fi
fi
exit $failed
