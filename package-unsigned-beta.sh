#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="Floating Browser"
APP_PATH="$SCRIPT_DIR/Build/$APP_NAME.app"
DIST_DIR="$SCRIPT_DIR/Dist"
TEMP_ROOT="$(mktemp -d /private/tmp/floating-browser-unsigned.XXXXXX)"
DMG_ROOT="$TEMP_ROOT/dmg"

cleanup() {
  rm -rf "$TEMP_ROOT" "$APP_PATH"
}
trap cleanup EXIT

SKIP_INSTALL=1 SIGNING_IDENTITY=- "$SCRIPT_DIR/build-local.sh"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")"
DMG_NAME="Floating-Browser-$VERSION-unsigned-beta-macOS.dmg"
FINAL_DMG="$DIST_DIR/$DMG_NAME"

mkdir -p "$DIST_DIR" "$DMG_ROOT"
ditto "$APP_PATH" "$DMG_ROOT/$APP_NAME.app"
xattr -cr "$DMG_ROOT/$APP_NAME.app"
codesign --verify --deep --strict --verbose=2 "$DMG_ROOT/$APP_NAME.app"
ln -s /Applications "$DMG_ROOT/Applications"
cp "$SCRIPT_DIR/UNSIGNED_BETA_INSTALL.md" "$DMG_ROOT/READ ME - UNSIGNED BETA.md"

rm -f "$FINAL_DMG" "$FINAL_DMG.sha256"
if diskutil image create from -h >/dev/null 2>&1; then
  diskutil image create from \
    --volumeName "$APP_NAME" \
    --format UDZO \
    "$DMG_ROOT" \
    "$FINAL_DMG"
else
  hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_ROOT" \
    -format UDZO \
    -ov \
    "$FINAL_DMG"
fi

(
  cd "$DIST_DIR"
  shasum -a 256 "$DMG_NAME" > "$DMG_NAME.sha256"
  shasum -a 256 -c "$DMG_NAME.sha256"
)

if spctl --assess --type execute "$APP_PATH" >/dev/null 2>&1; then
  echo "Warning: Gatekeeper unexpectedly accepted the unsigned beta." >&2
else
  echo "Gatekeeper rejection confirmed; users must follow the Open Anyway instructions."
fi

echo "Unsigned beta disk image: $FINAL_DMG"
echo "Checksum: $FINAL_DMG.sha256"
