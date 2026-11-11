#!/bin/bash
# Builds the setup app for one deployment.
#
#   tools/make-package.sh --config FILE [--icon FILE.icns] [--readme FILE] [--out DIR]
#
# Produces DIR/<INSTALLER_NAME>/<INSTALLER_NAME>.app (payload + your config) and a zip
# of that folder, ready to hand out. The config stays out of the repository.
# --icon sets the setup app's icon; without it macOS shows its generic app icon.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="" ICON="" README="" OUT="$ROOT/dist/package"
while [ $# -gt 0 ]; do
  case "$1" in
    --config) CONFIG="$2"; shift 2 ;;
    --icon)   ICON="$2"; shift 2 ;;
    --readme) README="$2"; shift 2 ;;
    --out)    OUT="$2"; shift 2 ;;
    *) echo "unknown option $1" >&2; exit 1 ;;
  esac
done
[ -f "$CONFIG" ] || { echo "usage: $0 --config FILE [--icon FILE.icns] [--readme FILE] [--out DIR]" >&2; exit 1; }

. "$ROOT/src/lib/config.sh"
noc_load_config "$CONFIG"
xml() { printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'; }

"$ROOT/tools/build.sh"
VERSION="$(cat "$ROOT/VERSION")"
DIR="$OUT/$INSTALLER_NAME"
APPB="$DIR/$INSTALLER_NAME.app"
rm -rf "$DIR"; mkdir -p "$APPB/Contents/MacOS" "$APPB/Contents/Resources"
cp "$ROOT/dist/payload/bin/nas-on-click" "$APPB/Contents/MacOS/nas-on-click"
cp -R "$ROOT/dist/payload/." "$APPB/Contents/Resources/"
cp "$CONFIG" "$APPB/Contents/Resources/config"
ICON_KEY=""
if [ -n "$ICON" ]; then
  cp "$ICON" "$APPB/Contents/Resources/app.icns"
  ICON_KEY="<key>CFBundleIconFile</key><string>app</string>"
fi
cat > "$APPB/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>$BUNDLE_ID.setup</string>
  <key>CFBundleName</key><string>$(xml "$INSTALLER_NAME")</string>
  <key>CFBundleExecutable</key><string>nas-on-click</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>LSMinimumSystemVersion</key><string>12.0</string>
  <key>LSUIElement</key><true/>
  <key>NOCRole</key><string>installer</string>
  $ICON_KEY
</dict></plist>
PLIST
codesign --force --deep -s - "$APPB"
[ -n "$README" ] && cp "$README" "$DIR/"
ZIP="$OUT/$INSTALLER_NAME-$VERSION.zip"
rm -f "$ZIP"
ditto -c -k --keepParent "$DIR" "$ZIP"
echo "Setup app: $APPB"
echo "Zip:       $ZIP"
