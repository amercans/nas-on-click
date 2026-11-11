#!/bin/bash
# Builds an installer for one deployment.
#
#   tools/make-package.sh --config FILE [--readme FILE] [--out DIR]
#
# Produces DIR/<INSTALLER_NAME>.app (payload + your config) and a zip of it, ready to
# hand out. The config stays out of the repository; keep it with your own records.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="" README="" OUT="$ROOT/dist/package"
while [ $# -gt 0 ]; do
  case "$1" in
    --config) CONFIG="$2"; shift 2 ;;
    --readme) README="$2"; shift 2 ;;
    --out)    OUT="$2"; shift 2 ;;
    *) echo "unknown option $1" >&2; exit 1 ;;
  esac
done
[ -f "$CONFIG" ] || { echo "usage: $0 --config FILE [--readme FILE] [--out DIR]" >&2; exit 1; }

. "$ROOT/src/lib/config.sh"
noc_load_config "$CONFIG"

"$ROOT/tools/build.sh"
VERSION="$(cat "$ROOT/VERSION")"
DIR="$OUT/$INSTALLER_NAME"
APPB="$DIR/$INSTALLER_NAME.app"
rm -rf "$DIR"; mkdir -p "$DIR"
osacompile -o "$APPB" "$ROOT/src/installer.applescript"
cp -R "$ROOT/dist/payload/." "$APPB/Contents/Resources/"
cp "$CONFIG" "$APPB/Contents/Resources/config"
codesign --force --deep -s - "$APPB"
[ -n "$README" ] && cp "$README" "$DIR/"
ZIP="$OUT/$INSTALLER_NAME-$VERSION.zip"
rm -f "$ZIP"
ditto -c -k --keepParent "$DIR" "$ZIP"
echo "Installer: $APPB"
echo "Zip:       $ZIP"
