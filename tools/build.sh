#!/bin/bash
# Builds the release payload into dist/payload: scripts, language files, update keys
# and universal (arm64 + x86_64) helper binaries, ad-hoc signed.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/dist/payload"
BUILD="$ROOT/dist/build"
rm -rf "$OUT" "$BUILD"
mkdir -p "$OUT/bin" "$BUILD"
# nas-on-click: launchers, setup app, dialogs, mounting, Keychain, update checks.
# sleepwatch: the sleep watcher (kept separate: it runs all the time).
for arch in arm64 x86_64; do
  swiftc -O -target "$arch-apple-macos12.0" -o "$BUILD/nas-on-click-$arch" "$ROOT"/src/app/*.swift
  swiftc -O -target "$arch-apple-macos12.0" -o "$BUILD/sleepwatch-$arch" "$ROOT/src/helpers/sleepwatch.swift"
done
for helper in nas-on-click sleepwatch; do
  lipo -create -output "$OUT/bin/$helper" "$BUILD/$helper-arm64" "$BUILD/$helper-x86_64"
  codesign --force -s - "$OUT/bin/$helper"
done
cp "$ROOT/src/install.sh" "$ROOT/src/agent.sh" "$ROOT/src/uninstall.sh" "$OUT/"
cp -R "$ROOT/src/lib" "$ROOT/src/lang" "$OUT/"
cp "$ROOT/keys/update-keys.txt" "$OUT/update-keys"
cp "$ROOT/VERSION" "$OUT/VERSION"
chmod 755 "$OUT/install.sh" "$OUT/agent.sh" "$OUT/uninstall.sh"
rm -rf "$BUILD"
echo "Payload built in $OUT ($(cat "$OUT/VERSION"))"
