#!/bin/bash
# Run e2e tests with screen recording to produce a walkthrough video.
#
# Prerequisites:
#   - Firebase emulators running (firebase emulators:start)
#   - Seed data loaded (node scripts/seed_emulator.js)
#   - ffmpeg installed (brew install ffmpeg)
#
# Usage: ./scripts/run_e2e_video.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
RAW_VIDEO="$PROJECT_DIR/e2e_raw.mp4"
FINAL_VIDEO="$PROJECT_DIR/e2e_walkthrough.mp4"

cd "$PROJECT_DIR"

# Clean up
rm -f "$RAW_VIDEO" "$FINAL_VIDEO"
pkill -f "chrome.*remote-debugging" 2>/dev/null || true
pkill chromedriver 2>/dev/null || true
sleep 1

# chromedriver is required by flutter drive -d chrome
chromedriver --port=4444 &
CHROMEDRIVER_PID=$!
sleep 2

echo "Launching e2e tests (backgrounded)..."
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/e2e_test.dart \
  --dart-define=USE_EMULATORS=true \
  --dart-define=RECORD_VIDEO=true \
  -d chrome --no-headless 2>&1 | tee /tmp/e2e_output.log &
FLUTTER_PID=$!

# Wait for Chrome to appear (up to 60s)
echo "Waiting for Chrome to launch..."
for i in $(seq 1 60); do
  if pgrep -f "chrome.*remote-debugging" >/dev/null 2>&1; then
    sleep 3  # Give Chrome a moment to render
    break
  fi
  sleep 1
done

# Bring Chrome to the foreground
echo "Bringing Chrome to front..."
osascript -e 'tell application "Google Chrome" to activate' 2>/dev/null || true
sleep 1

# Start recording
echo "Starting screen recording..."
ffmpeg -y -f avfoundation -framerate 10 -i "1" \
  -c:v libx264 -preset ultrafast -pix_fmt yuv420p \
  "$RAW_VIDEO" </dev/null 2>/dev/null &
FFMPEG_PID=$!

# Wait for flutter drive to finish
wait $FLUTTER_PID || true

echo "Stopping screen recording..."
kill -INT $FFMPEG_PID 2>/dev/null || true
sleep 5
wait $FFMPEG_PID 2>/dev/null || true

# Clean up Chrome and chromedriver
pkill -f "chrome.*remote-debugging" 2>/dev/null || true
kill $CHROMEDRIVER_PID 2>/dev/null || true

# Compress the video
if [ -f "$RAW_VIDEO" ]; then
  echo "Compressing video..."
  ffmpeg -y -i "$RAW_VIDEO" \
    -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p \
    -vf "scale=1280:-2" \
    "$FINAL_VIDEO" </dev/null 2>/dev/null
  rm -f "$RAW_VIDEO"
  echo ""
  echo "Video saved: $FINAL_VIDEO"
  echo "Size: $(du -h "$FINAL_VIDEO" | cut -f1)"
else
  echo "Warning: Video file not created"
fi

echo ""
grep -E "passed|failed|All tests" /tmp/e2e_output.log 2>/dev/null || true
