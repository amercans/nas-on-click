#!/bin/bash
# Publishes a signed release (maintainer only).
#
#   tools/release.sh VERSION "short release note"
#
# Builds the payload, packs it, writes manifest.json, signs it with the key in the
# login Keychain (see tools/signer.swift), tags the commit and creates the GitHub
# release with the package, manifest.json and manifest.sig.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
VER="${1:-}"; NOTES="${2:-}"
die() { echo "release: $*" >&2; exit 1; }

[[ $VER =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "usage: $0 MAJOR.MINOR.PATCH \"note\""
[ -n "$NOTES" ] || die "a short release note is required"
[ "$(git branch --show-current)" = main ] || die "release from main"
git diff --quiet && git diff --cached --quiet || die "commit your changes first"
git rev-parse -q --verify "refs/tags/v$VER" >/dev/null && die "tag v$VER already exists"
grep -q "^## \[$VER\]" CHANGELOG.md || die "add a '## [$VER]' section to CHANGELOG.md"
"$ROOT/tools/leak-scan.sh"

echo "$VER" > VERSION
"$ROOT/tools/build.sh"
PKG="nas-on-click-$VER.tar.gz"
COPYFILE_DISABLE=1 tar -czf "dist/$PKG" --uid 0 --gid 0 --uname root --gname wheel -C dist/payload .
SHA="$(shasum -a 256 "dist/$PKG" | awk '{ print $1 }')"
SIZE="$(stat -f %z "dist/$PKG")"
NOC_VER="$VER" NOC_PKG="$PKG" NOC_SHA="$SHA" NOC_SIZE="$SIZE" NOC_NOTES="$NOTES" python3 -I -c '
import json, os, datetime
m = {"product": "nas-on-click", "version": os.environ["NOC_VER"], "file": os.environ["NOC_PKG"],
     "sha256": os.environ["NOC_SHA"], "size": int(os.environ["NOC_SIZE"]),
     "published": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
     "notes": os.environ["NOC_NOTES"]}
open("dist/manifest.json", "w").write(json.dumps(m, ensure_ascii=False, indent=2) + "\n")'
swift "$ROOT/tools/signer.swift" sign dist/manifest.json > dist/manifest.sig
# Check the signature with the same code the installed copies use.
dist/payload/bin/opener --verify-manifest dist/manifest.json dist/manifest.sig keys/update-keys.txt nas-on-click 0.0.0 >/dev/null \
  || die "the manifest does not verify against keys/update-keys.txt"

if ! git diff --quiet VERSION; then git add VERSION; git commit -m "Release $VER"; fi
git tag -a "v$VER" -m "$VER"
git push origin main "v$VER"
# Upload as a draft first, then publish: with immutable releases, assets cannot be
# added once a release is published.
gh release create "v$VER" "dist/$PKG" dist/manifest.json dist/manifest.sig --draft --title "$VER" --notes "$NOTES"
gh release edit "v$VER" --draft=false
echo "Released $VER"
