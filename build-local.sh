#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="Floating Browser"
PRODUCT_NAME="FloatingBrowser"
BUILD_DIR="$SCRIPT_DIR/Build"
APP_PATH="$BUILD_DIR/$APP_NAME.app"
TEMP_ROOT="$(mktemp -d /private/tmp/floating-browser-build.XXXXXX)"
trap 'rm -rf "$TEMP_ROOT"' EXIT

DEFAULT_INSTALL_DIR="/Applications"
if [[ ! -w "$DEFAULT_INSTALL_DIR" ]]; then
  DEFAULT_INSTALL_DIR="$HOME/Applications"
fi
INSTALL_PATH="${INSTALL_PATH:-$DEFAULT_INSTALL_DIR/$APP_NAME.app}"
SIGNING_IDENTITY="${SIGNING_IDENTITY:--}"

case "$INSTALL_PATH" in
  "/Applications/$APP_NAME.app"|"$HOME/Applications/$APP_NAME.app")
    ;;
  *)
    echo "Refusing unsafe install path: $INSTALL_PATH" >&2
    echo "Use /Applications/$APP_NAME.app or $HOME/Applications/$APP_NAME.app." >&2
    exit 64
    ;;
esac

ARM_BUILD="$TEMP_ROOT/arm64"
INTEL_BUILD="$TEMP_ROOT/x86_64"
STAGED_APP="$TEMP_ROOT/$APP_NAME.app"

swift build --package-path "$SCRIPT_DIR" --build-path "$ARM_BUILD" -c release --arch arm64
swift build --package-path "$SCRIPT_DIR" --build-path "$INTEL_BUILD" -c release --arch x86_64

ARM_BIN_DIR="$(swift build --package-path "$SCRIPT_DIR" --build-path "$ARM_BUILD" -c release --arch arm64 --show-bin-path)"
INTEL_BIN_DIR="$(swift build --package-path "$SCRIPT_DIR" --build-path "$INTEL_BUILD" -c release --arch x86_64 --show-bin-path)"

mkdir -p "$STAGED_APP/Contents/MacOS" "$STAGED_APP/Contents/Resources"
lipo -create \
  "$ARM_BIN_DIR/$PRODUCT_NAME" \
  "$INTEL_BIN_DIR/$PRODUCT_NAME" \
  -output "$STAGED_APP/Contents/MacOS/$PRODUCT_NAME"
cp "$SCRIPT_DIR/Info.plist" "$STAGED_APP/Contents/Info.plist"
if [[ -d "$SCRIPT_DIR/Resources" ]]; then
  ditto "$SCRIPT_DIR/Resources" "$STAGED_APP/Contents/Resources"
fi

sign_app() {
  local target="$1"
  xattr -cr "$target"
  if [[ "$SIGNING_IDENTITY" == "-" ]]; then
    codesign --force --options runtime --timestamp=none --sign - "$target"
  else
    codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$target"
  fi
  codesign --verify --strict --verbose=2 "$target"
}

mkdir -p "$BUILD_DIR" "$(dirname "$INSTALL_PATH")"
rm -rf "$APP_PATH"
ditto "$STAGED_APP" "$APP_PATH"
sign_app "$APP_PATH"

if [[ "${SKIP_INSTALL:-0}" == "1" ]]; then
  file "$APP_PATH/Contents/MacOS/$PRODUCT_NAME"
  echo "Built: $APP_PATH"
  exit 0
fi

pkill -x "$PRODUCT_NAME" 2>/dev/null || true

rm -rf "$INSTALL_PATH"
ditto "$APP_PATH" "$INSTALL_PATH"
sign_app "$INSTALL_PATH"

LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister"
"$LSREGISTER" -f -R -trusted "$INSTALL_PATH"

file "$INSTALL_PATH/Contents/MacOS/$PRODUCT_NAME"
rm -rf "$APP_PATH"
echo "Installed: $INSTALL_PATH"
