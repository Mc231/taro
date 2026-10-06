#!/bin/bash
# Records the App Review demo video (review_video_test.dart) on an iOS
# simulator: boots it with a clean status bar, records the screen while the
# fake-backed test runs, trims to the test's REVIEW_VIDEO start/end marks,
# encodes H.264 MP4 sped up SPEED times (1.65: ~2 min) and shuts the
# simulator down.
# usage: SIM=<udid> [OUT=build/store/review] record.sh
set -u
SIM=${SIM:?simulator udid, an iPhone 6.9-inch}
ROOT=$(cd "$(dirname "$0")/../../../.." && pwd)
OUT=${OUT:-$ROOT/build/store/review}
mkdir -p "$OUT"
RAW=$OUT/taro_review_raw.mov; LOG=$OUT/review_video.log
MP4=$OUT/taro_review_demo.mp4

xcrun simctl boot "$SIM" 2>/dev/null; xcrun simctl bootstatus "$SIM" -b >/dev/null
xcrun simctl ui "$SIM" appearance light
xcrun simctl status_bar "$SIM" override --time 9:41 --dataNetwork wifi \
  --wifiMode active --wifiBars 3 --cellularMode active --cellularBars 4 \
  --batteryState charged --batteryLevel 100

xcrun simctl io "$SIM" recordVideo --codec h264 --force "$RAW" 2>"$OUT/record.err" &
REC=$!
sleep 2
T0=$(perl -MTime::HiRes=time -e 'printf "%.2f", time')
cd "$ROOT/apps/taro" || exit 2
# Each output line gets a wall-clock stamp so the marks map to video time.
flutter test integration_test/review_video/review_video_test.dart -d "$SIM" \
  --flavor dev --dart-define-from-file=config/dev.json \
  --dart-define=TARO_ENV=test --dart-define=REVIEW_VIDEO=1 2>&1 |
  perl -MTime::HiRes=time -ne '$|=1; printf "%.2f %s", time, $_' >"$LOG"
RC=${PIPESTATUS[0]}
kill -INT "$REC"; wait "$REC"
xcrun simctl status_bar "$SIM" clear
xcrun simctl shutdown "$SIM"

START=$(awk '/REVIEW_VIDEO: start/{print $1; exit}' "$LOG")
END=$(awk '/REVIEW_VIDEO: end/{print $1; exit}' "$LOG")
if [ -z "$START" ] || [ -z "$END" ]; then echo "marks missing (rc=$RC), see $LOG"; exit 1; fi
SS=$(python3 -c "print(max(0, $START - $T0 + 2 - 0.5))")
DUR=$(python3 -c "print($END - $START + 1.5)")
ffmpeg -y -loglevel error -ss "$SS" -i "$RAW" -t "$DUR" -an \
  -vf "setpts=PTS/${SPEED:-1.65},scale=-2:1920,fps=30" -c:v libx264 \
  -profile:v high -pix_fmt yuv420p \
  -crf 22 -movflags +faststart "$MP4"
echo "rc=$RC ss=$SS dur=$DUR"
ls -l "$MP4"
exit "$RC"
