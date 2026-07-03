#!/usr/bin/env bash
#
# One-command build for Trio + EquilKit + LinxCGMKit (community fork).
# Run from the repository root:
#   ./scripts/build.sh
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SCHEME="Trio"
WORKSPACE="Trio.xcworkspace"
CONFIGURATION="${CONFIGURATION:-Debug}"
DERIVED_DATA="${DERIVED_DATA:-$ROOT/DerivedData}"
BUILD_FOR="${BUILD_FOR:-device}"   # device | simulator
TEAM_ID="${TEAM_ID:-}"
DEVICE_ID="${DEVICE_ID:-}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}==>${NC} $*"; }
warn()  { echo -e "${YELLOW}!!${NC} $*"; }
fail()  { echo -e "${RED}ERROR:${NC} $*" >&2; exit 1; }

usage() {
  cat <<'EOF'
Usage: ./scripts/build.sh [options]

Build Trio with pre-wired EquilKit and LinxCGMKit.

Options:
  --simulator       Build for iOS Simulator (no Apple Developer team required)
  --device          Build for a connected iPhone (default)
  --team TEAM_ID    Apple Developer Team ID (10 characters)
  --device-id UUID  Specific iPhone UDID (optional; auto-detected if omitted)
  --release         Use Release configuration (default: Debug)
  -h, --help        Show this help

Environment variables (optional):
  TEAM_ID, DEVICE_ID, CONFIGURATION, DERIVED_DATA, BUILD_FOR

Examples:
  ./scripts/build.sh --simulator
  ./scripts/build.sh --team ABCDE12345
  ./scripts/install.sh
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --simulator)  BUILD_FOR="simulator"; shift ;;
    --device)     BUILD_FOR="device"; shift ;;
    --team)       TEAM_ID="$2"; shift 2 ;;
    --device-id)  DEVICE_ID="$2"; shift 2 ;;
    --release)    CONFIGURATION="Release"; shift ;;
    -h|--help)    usage; exit 0 ;;
    *)            fail "Unknown option: $1 (try --help)" ;;
  esac
done

# --- Prerequisites -----------------------------------------------------------

info "Checking prerequisites"

if ! command -v xcodebuild >/dev/null 2>&1; then
  fail "Xcode command-line tools not found. Install Xcode from the Mac App Store, then run: xcode-select --install"
fi

if ! xcodebuild -version >/dev/null 2>&1; then
  fail "xcodebuild failed. Open Xcode once and accept the license agreement."
fi

if [[ ! -d "$ROOT/$WORKSPACE" ]]; then
  fail "Run this script from the Trio-Equil-Linx-Build repo root (missing $WORKSPACE)."
fi

# --- Submodules --------------------------------------------------------------

if [[ -f "$ROOT/.gitmodules" ]]; then
  info "Updating git submodules"
  git submodule update --init --recursive
fi

# --- Signing / team ID -------------------------------------------------------

ensure_team_id() {
  if [[ -n "$TEAM_ID" ]]; then
    return
  fi
  if [[ -f "$ROOT/ConfigOverride.xcconfig" ]]; then
    TEAM_ID="$(grep -E '^DEVELOPER_TEAM\s*=' "$ROOT/ConfigOverride.xcconfig" | head -1 | sed 's/.*=\s*//;s/ //g')"
  fi
  if [[ -z "$TEAM_ID" || "$TEAM_ID" == "##TEAM_ID##" ]]; then
    echo ""
    warn "Apple Developer Team ID is required to install on a physical iPhone."
    echo "Find it at https://developer.apple.com/account — Membership details (10-character ID)."
    echo ""
    read -r -p "Enter your Team ID (or press Enter to skip and build for simulator only): " TEAM_ID
    if [[ -z "$TEAM_ID" ]]; then
      warn "No Team ID — switching to simulator build."
      BUILD_FOR="simulator"
      return
    fi
    echo "DEVELOPER_TEAM = $TEAM_ID" > "$ROOT/ConfigOverride.xcconfig"
    info "Wrote ConfigOverride.xcconfig"
  fi
}

# --- Destination -------------------------------------------------------------

if [[ "$BUILD_FOR" == "simulator" ]]; then
  DESTINATION='platform=iOS Simulator,name=iPhone 16,OS=latest'
  info "Building for iOS Simulator"
else
  ensure_team_id
  if [[ "$BUILD_FOR" != "simulator" ]]; then
    if [[ -z "$DEVICE_ID" ]]; then
      DEVICE_ID="$(xcrun devicectl list devices 2>/dev/null | awk '/iPhone/ && /connected/ {print $NF; exit}')"
      if [[ -z "$DEVICE_ID" ]]; then
        DEVICE_ID="$(xcrun devicectl list devices 2>/dev/null | awk '/iPhone/ {print $NF; exit}')"
      fi
    fi
    if [[ -z "$DEVICE_ID" ]]; then
      warn "No iPhone detected. Connect via USB or Wi-Fi, or use --simulator."
      fail "Device build requires a connected iPhone or --device-id UUID."
    fi
    DESTINATION="id=$DEVICE_ID"
    info "Building for device $DEVICE_ID"
  fi
fi

# --- Build -------------------------------------------------------------------

info "Building $SCHEME ($CONFIGURATION)"
info "Derived data: $DERIVED_DATA"

XCBUILD_ARGS=(
  -workspace "$WORKSPACE"
  -scheme "$SCHEME"
  -configuration "$CONFIGURATION"
  -destination "$DESTINATION"
  -derivedDataPath "$DERIVED_DATA"
  -allowProvisioningUpdates
)

if [[ "$BUILD_FOR" == "device" && -n "${TEAM_ID:-}" ]]; then
  XCBUILD_ARGS+=(DEVELOPMENT_TEAM="$TEAM_ID" CODE_SIGN_STYLE=Automatic)
fi

set +e
xcodebuild "${XCBUILD_ARGS[@]}" build 2>&1 | tee "$ROOT/build.log"
BUILD_STATUS=${PIPESTATUS[0]}
set -e

if [[ "$BUILD_STATUS" -ne 0 ]]; then
  fail "Build failed (see build.log). Common fixes: open Xcode once, sign in with Apple ID, check Team ID."
fi

# --- Result ------------------------------------------------------------------

if [[ "$BUILD_FOR" == "simulator" ]]; then
  APP_PATH="$DERIVED_DATA/Build/Products/${CONFIGURATION}-iphonesimulator/Trio.app"
else
  APP_PATH="$DERIVED_DATA/Build/Products/${CONFIGURATION}-iphoneos/Trio.app"
fi

if [[ -d "$APP_PATH" ]]; then
  info "Build succeeded: $APP_PATH"
  echo "$APP_PATH" > "$ROOT/.last-build-app-path"
  if [[ "$BUILD_FOR" == "device" ]]; then
    echo ""
    info "Install on your iPhone with: ./scripts/install.sh"
  fi
else
  warn "Build finished but app bundle not found at expected path."
  warn "Search DerivedData for Trio.app or open Trio.xcworkspace in Xcode."
fi
