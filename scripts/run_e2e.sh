#!/bin/bash
# Run the full e2e suite: emulators, seed, build, Playwright tests with video.
#
# Usage: ./scripts/run_e2e.sh
#
# Videos are saved to test-results/*/video.webm

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

# ── 1. Check / start Firebase emulators ──────────────────────────────────────
EMULATORS_RUNNING=false
if curl -s http://localhost:4400/emulators >/dev/null 2>&1; then
  EMULATORS_RUNNING=true
  echo "Emulators already running."
fi

if [ "$EMULATORS_RUNNING" = false ]; then
  echo "Starting Firebase emulators..."
  firebase emulators:start &
  EMULATOR_PID=$!

  # Wait for emulators to be ready (up to 30s)
  for i in $(seq 1 30); do
    if curl -s http://localhost:4400/emulators >/dev/null 2>&1; then
      break
    fi
    if [ "$i" -eq 30 ]; then
      echo "Error: Emulators failed to start within 30s"
      exit 1
    fi
    sleep 1
  done
  echo "Emulators ready."
fi

# ── 2. Seed data ─────────────────────────────────────────────────────────────
echo "Seeding emulator data..."
node scripts/seed_emulator.js

# ── 3. Build Flutter web ─────────────────────────────────────────────────────
echo "Building Flutter web..."
flutter build web --dart-define=USE_EMULATORS=true

# ── 4. Run Playwright tests ──────────────────────────────────────────────────
echo "Running Playwright e2e tests..."
npx playwright test e2e/ --reporter=list

echo ""
echo "Done! Videos saved to test-results/*/video.webm"
