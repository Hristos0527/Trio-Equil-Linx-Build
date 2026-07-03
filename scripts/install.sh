#!/usr/bin/env bash
#
# Install the last Trio build onto a connected iPhone.
# Run after ./scripts/build.sh (device build).
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CONFIGURATION="${CONFIGURATION:-Debug}"
DERIVED_DATA="${DERIVED_DATA:-$ROOT/DerivedData}"
DEVICE_ID="${DEVICE_ID:-}"
APP_PATH="${APP_PATH:-}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}==>${NC} $*"; }
warn()  { echo -e "${YELLOW}!!${NC} $*"; }
fail()  { echo -e "${RED}ERROR:${NC} $*" >&2; exit 1; }

usage() {
  cat <<'EOF'
Usage: ./scripts/install.sh [options]

Install Trio.app onto a connected iPhone.

Options:
  --app PATH        Path to Trio.app (default: last build or DerivedData)
  --device-id UUID  Specific iPhone UDID (auto-detected if omitted)
  -h, --help        Show this help

Prerequisites:
  - Build first: ./scripts/build.sh --team YOUR_TEAM_ID
  - iPhone connected via USB or Wi-Fi
  - iPhone unlocked and trusted on this Mac
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app)        APP_PATH="$2"; shift 2 ;;
    --device-id)  DEVICE_ID="$2"; shift 2 ;;
    -h|--help)    usage; exit 0 ;;
    *)            fail "Unknown option: $1 (try --help)" ;;
  esac
done

if [[ -z "$APP_PATH" && -f "$ROOT/.last-build-app-path" ]]; then
  APP_PATH="$(cat "$ROOT/.last-build-app-path")"
fi

if [[ -z "$APP_PATH" ]]; then
  APP_PATH="$DERIVED_DATA/Build/Products/${CONFIGURATION}-iphoneos/Trio.app"
fi

if [[ ! -d "$APP_PATH" ]]; then
  fail "Trio.app not found at: $APP_PATH\nRun ./scripts/build.sh first."
fi

if [[ -z "$DEVICE_ID" ]]; then
  DEVICE_ID="$(xcrun devicectl list devices 2>/dev/null | awk '/iPhone/ && /connected/ {print $NF; exit}')"
  if [[ -z "$DEVICE_ID" ]]; then
    DEVICE_ID="$(xcrun devicectl list devices 2>/dev/null | awk '/iPhone/ {print $NF; exit}')"
  fi
fi

if [[ -z "$DEVICE_ID" ]]; then
  fail "No iPhone found. Connect your phone via USB, unlock it, and trust this Mac."
fi

info "Installing $APP_PATH"
info "Target device: $DEVICE_ID"

xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH"

info "Installed. Open Trio on your iPhone."
info "First launch: Settings → General → VPN & Device Management → trust the developer certificate."
