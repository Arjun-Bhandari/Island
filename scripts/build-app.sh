#!/bin/bash
# Builds Island.app in release mode and zips it for distribution.
# Unsigned (ad-hoc signed) — friends right-click > Open the first time.
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="Island"
BUILD_DIR=".build/release"
DIST_DIR="dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"

echo "==> Building release binary..."
swift build -c release

echo "==> Assembling $APP_NAME.app..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
cp "Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

# SPM dependencies with their own resources (e.g. KeyboardShortcuts' UI
# strings) produce a .bundle next to the release binary. `swift build`
# doesn't package these into an .app for you — copy every one across, or
# the app crashes on launch on any machine that isn't this dev checkout.
# Contents/Resources is the standard, signature-covered location SPM's
# generated accessor checks (a loose copy at the bundle root makes
# codesign refuse to sign — "unsealed contents present in the bundle root").
shopt -s nullglob
for bundle in "$BUILD_DIR"/*.bundle; do
    name="$(basename "$bundle")"
    echo "==> Bundling resource: $name"
    cp -R "$bundle" "$APP_BUNDLE/Contents/Resources/$name"
done
shopt -u nullglob

echo "==> Ad-hoc signing (no Developer account needed)..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "==> Zipping for distribution..."
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP_BUNDLE/Contents/Info.plist")
ZIP_PATH="$DIST_DIR/$APP_NAME-$VERSION.zip"
rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$APP_BUNDLE" "$ZIP_PATH"
# Unversioned copy so the site can link to releases/latest/download/Island.zip forever.
LATEST_ZIP="$DIST_DIR/$APP_NAME.zip"
cp "$ZIP_PATH" "$LATEST_ZIP"

echo ""
echo "Done:"
echo "  App: $APP_BUNDLE"
echo "  Zip: $ZIP_PATH"
echo "  Zip: $LATEST_ZIP  (attach to every release — the site's download link uses it)"
echo ""
echo "First launch on another Mac: right-click the app > Open (unsigned build)."
