#!/bin/bash
# Run the full e2e suite: emulators, build, Playwright tests.
#
# Usage: ./scripts/run_e2e.sh [--skip-build] [extra playwright args]
#
# Seeding happens automatically in Playwright's globalSetup, which clears the
# emulators and reseeds before every run. Failure traces/videos land in
# test-results/.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

SKIP_BUILD=false
if [ "$1" = "--skip-build" ]; then
  SKIP_BUILD=true
  shift
fi

# ── 1. Check / start Firebase emulators ──────────────────────────────────────
EMULATOR_PID=""
if curl -s http://localhost:4400/emulators >/dev/null 2>&1; then
  echo "Emulators already running."
else
  echo "Starting Firebase emulators..."
  firebase emulators:start --only auth,firestore &
  EMULATOR_PID=$!
  # Only kill emulators we started ourselves.
  trap '[ -n "$EMULATOR_PID" ] && kill "$EMULATOR_PID" 2>/dev/null' EXIT

  for i in $(seq 1 60); do
    if curl -s http://localhost:9099/ >/dev/null 2>&1 \
      && curl -s http://localhost:8081/ >/dev/null 2>&1; then
      break
    fi
    if [ "$i" -eq 60 ]; then
      echo "Error: Emulators failed to start within 60s"
      exit 1
    fi
    sleep 1
  done
  echo "Emulators ready."
fi

# ── 2. Build Flutter web ─────────────────────────────────────────────────────
if [ "$SKIP_BUILD" = true ]; then
  echo "Skipping Flutter build (--skip-build)."
else
  echo "Building Flutter web..."
  flutter build web --dart-define=USE_EMULATORS=true --dart-define=ENABLE_SEMANTICS=true
fi

# ── 3. Run Playwright tests (globalSetup clears + seeds the emulators) ───────
echo "Running Playwright e2e tests..."
npx playwright test --project=e2e "$@"
