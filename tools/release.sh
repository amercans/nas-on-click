#!/bin/bash
# Publishes a signed release (maintainer only).
#
#   tools/release.sh VERSION NOTES [--resume]
#
# NOTES is either a short English note, or a file with one line per language:
#   en: Fixes ...
#   tr: ... düzeltildi
#   de: ...   (also fr, es, ru)
# Installed copies show the note in their own language and fall back to English.
#
# --resume continues after an interruption, once the tag is already on GitHub.
#
# 1. Sets VERSION, commits and pushes a tag.
# 2. GitHub Actions (.github/workflows/release.yml) builds the package from that tag,
#    attests its build provenance and attaches it to a draft release.
# 3. This script downloads that package, verifies the attestation, writes manifest.json
#    for exactly that file, signs it with the key in the login Keychain (macOS asks for
#    confirmation) and publishes the release.
# The signing key never leaves this Mac; the package never comes from this Mac.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
VER="${1:-}"; NOTES="${2:-}"; RESUME="${3:-}"
REPO="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"
die() { echo "release: $*" >&2; exit 1; }

[[ $VER =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "usage: $0 MAJOR.MINOR.PATCH \"note\""
[ -n "$NOTES" ] || die "a release note (text or file) is required"
if [ -f "$NOTES" ]; then
  grep -q '^en: ' "$NOTES" || die "the notes file needs an 'en: ' line"
fi
[ "$(git branch --show-current)" = main ] || die "release from main"
git diff --quiet && git diff --cached --quiet || die "commit your changes first"
grep -q "^## \[$VER\]" CHANGELOG.md || die "add a '## [$VER]' section to CHANGELOG.md"

if [ "$RESUME" = --resume ]; then
  git rev-parse -q --verify "refs/tags/v$VER" >/dev/null || die "no tag v$VER to resume"
  [ "$(cat VERSION)" = "$VER" ] || die "VERSION is not $VER"
  "$ROOT/tools/build.sh" >/dev/null
else
  git rev-parse -q --verify "refs/tags/v$VER" >/dev/null && die "tag v$VER already exists (use --resume)"
  "$ROOT/tools/leak-scan.sh"
  # A local build supplies the verifier used below (the same code installed copies run).
  echo "$VER" > VERSION
  "$ROOT/tools/build.sh" >/dev/null
  if ! git diff --quiet VERSION; then git add VERSION; git commit -m "Release $VER"; fi
  git tag -a "v$VER" -m "$VER"
  git push origin main "v$VER"
fi
COMMIT="$(git rev-parse "v$VER^{commit}")"
[ "$(git ls-remote origin "refs/tags/v$VER^{}" | awk '{ print $1 }')" = "$COMMIT" ] || die "the tag on GitHub does not point at $COMMIT"

echo "Waiting for the release build on GitHub..."
sleep 10
RUN="$(gh run list --repo "$REPO" --workflow release.yml --branch "v$VER" --limit 1 --json databaseId --jq '.[0].databaseId')"
[ -n "$RUN" ] || die "release build not found"
while :; do
  STATE="$(gh run view "$RUN" --repo "$REPO" --json status,conclusion --jq '.status + " " + (.conclusion // "")')"
  case "$STATE" in
    "completed success") break ;;
    completed*) die "release build failed: gh run view $RUN --repo $REPO --log-failed" ;;
  esac
  sleep 10
done

OUT="$ROOT/dist/release"
rm -rf "$OUT"; mkdir -p "$OUT"
PKG="nas-on-click-$VER.tar.gz"
gh release download "v$VER" --repo "$REPO" --pattern "$PKG" --dir "$OUT"
# Only accept a package built by release.yml, from this tag, at this exact commit,
# on a GitHub-hosted runner.
gh attestation verify "$OUT/$PKG" --repo "$REPO" \
  --signer-workflow "$REPO/.github/workflows/release.yml" \
  --source-ref "refs/tags/v$VER" --source-digest "$COMMIT" \
  --deny-self-hosted-runners >/dev/null || die "build provenance did not verify"
echo "Provenance verified."

SHA="$(shasum -a 256 "$OUT/$PKG" | awk '{ print $1 }')"
SIZE="$(stat -f %z "$OUT/$PKG")"
NOC_VER="$VER" NOC_PKG="$PKG" NOC_SHA="$SHA" NOC_SIZE="$SIZE" NOC_NOTES="$NOTES" NOC_OUT="$OUT" python3 -I -c '
import json, os, datetime
notes, i18n = os.environ["NOC_NOTES"], {}
if os.path.isfile(notes):
    for line in open(notes, encoding="utf-8"):
        code, sep, text = line.partition(":")
        if sep and code.strip() in ("en", "tr", "de", "fr", "es", "ru") and text.strip():
            i18n[code.strip()] = text.strip()
    notes = i18n["en"]
m = {"product": "nas-on-click", "version": os.environ["NOC_VER"], "file": os.environ["NOC_PKG"],
     "sha256": os.environ["NOC_SHA"], "size": int(os.environ["NOC_SIZE"]),
     "published": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
     "notes": notes}
if i18n:
    m["notes_i18n"] = i18n
open(os.path.join(os.environ["NOC_OUT"], "manifest.json"), "w").write(json.dumps(m, ensure_ascii=False, indent=2) + "\n")'
swift "$ROOT/tools/signer.swift" sign "$OUT/manifest.json" > "$OUT/manifest.sig"
dist/payload/bin/nas-on-click verify-manifest "$OUT/manifest.json" "$OUT/manifest.sig" keys/update-keys.txt nas-on-click 0.0.0 >/dev/null \
  || die "the manifest does not verify against keys/update-keys.txt"

# The release is still a draft, so re-uploading is allowed; then check what GitHub holds
# is byte-for-byte what was signed before publishing (after which it is immutable).
gh release upload "v$VER" --repo "$REPO" --clobber "$OUT/manifest.json" "$OUT/manifest.sig" || true
CHECK="$OUT/check"; rm -rf "$CHECK"; mkdir -p "$CHECK"
gh release download "v$VER" --repo "$REPO" --pattern "manifest.*" --dir "$CHECK"
cmp -s "$CHECK/manifest.json" "$OUT/manifest.json" && cmp -s "$CHECK/manifest.sig" "$OUT/manifest.sig" \
  || die "the uploaded manifest does not match the signed one"
gh release edit "v$VER" --repo "$REPO" --draft=false
echo "Released $VER"
