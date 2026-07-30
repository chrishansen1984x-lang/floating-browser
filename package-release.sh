#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="Floating Browser"
APP_PATH="$SCRIPT_DIR/Build/$APP_NAME.app"
DIST_DIR="$SCRIPT_DIR/Dist"

: "${SIGNING_IDENTITY:?Set SIGNING_IDENTITY to a Developer ID Application certificate name.}"
: "${NOTARY_PROFILE:?Set NOTARY_PROFILE to an xcrun notarytool keychain profile.}"

BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$SCRIPT_DIR/Info.plist")"
if [[ "$BUNDLE_ID" == "com.local.FloatingBrowser" ]]; then
  echo "Replace the local-only CFBundleIdentifier before creating a public release." >&2
  exit 64
fi

SKIP_INSTALL=1 SIGNING_IDENTITY="$SIGNING_IDENTITY" "$SCRIPT_DIR/build-local.sh"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")"
DMG_NAME="Floating-Browser-$VERSION-macOS.dmg"
TEMP_ROOT="$(mktemp -d /private/tmp/floating-browser-notary.XXXXXX)"
SUBMISSION_ARCHIVE="$TEMP_ROOT/submission.zip"
DMG_ROOT="$TEMP_ROOT/dmg"
FINAL_DMG="$DIST_DIR/$DMG_NAME"

trap 'rm -rf "$TEMP_ROOT"' EXIT
mkdir -p "$DIST_DIR"

ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$SUBMISSION_ARCHIVE"
xcrun notarytool submit "$SUBMISSION_ARCHIVE" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"
codesign --verify --strict --verbose=2 "$APP_PATH"
spctl --assess --type execute --verbose=2 "$APP_PATH"

mkdir -p "$DMG_ROOT"
ditto "$APP_PATH" "$DMG_ROOT/$APP_NAME.app"
ln -s /Applications "$DMG_ROOT/Applications"

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
codesign --force --timestamp --sign "$SIGNING_IDENTITY" "$FINAL_DMG"
xcrun notarytool submit "$FINAL_DMG" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$FINAL_DMG"
xcrun stapler validate "$FINAL_DMG"
spctl --assess --type open --context context:primary-signature --verbose=2 "$FINAL_DMG"

(
  cd "$DIST_DIR"
  shasum -a 256 "$DMG_NAME" > "$DMG_NAME.sha256"
)

echo "Release disk image: $FINAL_DMG"
echo "Checksum: $FINAL_DMG.sha256"
