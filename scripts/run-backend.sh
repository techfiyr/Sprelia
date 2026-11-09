#!/usr/bin/env bash
# Runs the Sprelia API locally on port 8080.
#
#   scripts/run-backend.sh            Local mode (default): Firebase Auth + Firestore emulators for
#                                     demo-sprelia, API pinned to them. No production access.
#   scripts/run-backend.sh live       Live mode: API against the real `sprelia` Firebase project via
#                                     `npm run dev:sprelia` (backend/.env.sprelia.local + root .env).
#                                     Requires Application Default Credentials; never a key file.
#
# Pair the app with env/development.json (local) or env/development-firebase.local.json (live).
# Ctrl+C stops everything this script started. No secrets are printed.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-local}"
PORT=8080
cd "$ROOT/backend"

port_busy() { lsof -iTCP:"$1" -sTCP:LISTEN -P >/dev/null 2>&1; }

if port_busy "$PORT"; then
  echo "Port $PORT is already in use. Stop the running backend first." >&2
  exit 1
fi

case "$MODE" in
  local)
    for p in 9099 8180; do
      if port_busy "$p"; then
        echo "Port $p is in use (an emulator may already be running). Stop it first." >&2
        exit 1
      fi
    done
    LOG_DIR="$(mktemp -d)"
    cd "$ROOT"
    GOOGLE_CLOUD_PROJECT=demo-sprelia firebase emulators:start --only auth,firestore \
      --project demo-sprelia >"$LOG_DIR/emulators.log" 2>&1 &
    EMU_PID=$!
    trap 'kill "$EMU_PID" 2>/dev/null || true' EXIT INT TERM
    echo "Starting emulators (log: $LOG_DIR/emulators.log)..."
    for _ in $(seq 1 60); do
      port_busy 9099 && port_busy 8180 && break
      kill -0 "$EMU_PID" 2>/dev/null || { echo "Emulators failed to start; see $LOG_DIR/emulators.log" >&2; exit 1; }
      sleep 1
    done
    port_busy 9099 && port_busy 8180 || { echo "Emulators did not become ready." >&2; exit 1; }
    echo "Emulators ready: auth :9099, firestore :8180, UI http://127.0.0.1:4000"
    echo "API on :$PORT (demo-sprelia, emulators only). Ctrl+C to stop."
    cd "$ROOT/backend"
    # Cleared environment: no inherited credentials can reach a real project.
    env -i PATH="$PATH" HOME="$HOME" \
      APP_ENV=development PORT="$PORT" \
      FIREBASE_PROJECT_ID=demo-sprelia GOOGLE_CLOUD_PROJECT=demo-sprelia \
      FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 FIRESTORE_EMULATOR_HOST=127.0.0.1:8180 \
      npx tsx src/main.ts
    ;;
  live)
    ADC="${GOOGLE_APPLICATION_CREDENTIALS:-$HOME/.config/gcloud/application_default_credentials.json}"
    if [ ! -f "$ADC" ]; then
      echo "Application Default Credentials not found." >&2
      echo "Install the Google Cloud CLI and run: gcloud auth application-default login" >&2
      exit 1
    fi
    echo "Live mode: API on :$PORT against Firebase project from backend/.env.sprelia.local."
    echo "Use test accounts only. Ctrl+C to stop."
    npm run dev:sprelia
    ;;
  *)
    echo "Usage: scripts/run-backend.sh [local|live]" >&2
    exit 2
    ;;
esac
