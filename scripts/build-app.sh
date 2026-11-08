#!/bin/bash
# Builds Island.app in release mode and packages it as a .dmg (for the site) and a .zip (for install.sh).
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

echo "==> Building disk image..."
# Styled drag-to-install window (background art, icon layout). dmgbuild writes
# Finder's .DS_Store directly, so it works headless on CI with no Finder scripting.
DMG_VENV=".build/dmgbuild-venv"
if [ ! -x "$DMG_VENV/bin/dmgbuild" ]; then
    python3 -m venv "$DMG_VENV"
    "$DMG_VENV/bin/pip" install --quiet "dmgbuild==1.6.7"
fi
DMG_PATH="$DIST_DIR/$APP_NAME-$VERSION.dmg"
rm -f "$DMG_PATH"
"$DMG_VENV/bin/dmgbuild" -s scripts/dmg-settings.py -D app="$APP_BUNDLE" "$APP_NAME" "$DMG_PATH"
LATEST_DMG="$DIST_DIR/$APP_NAME.dmg"
cp "$DMG_PATH" "$LATEST_DMG"

echo ""
echo "Done:"
echo "  App: $APP_BUNDLE"
echo "  Zip: $ZIP_PATH"
echo "  Dmg: $DMG_PATH"
echo "  Zip: $LATEST_ZIP  (install.sh downloads this)"
echo "  Dmg: $LATEST_DMG  (the site's download button links to this)"
echo ""
echo "First launch on another Mac: System Settings > Privacy & Security > Open Anyway (unsigned build)."
