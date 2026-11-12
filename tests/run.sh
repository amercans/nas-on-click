#!/bin/bash
# Test suite: config parsing, manifest verification and the update flow.
# Needs a built payload (tools/build.sh). Uses a throw-away signing key and a
# temporary HOME; nothing on the machine is changed and nothing is downloaded.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OPENER="$ROOT/dist/payload/bin/nas-on-click"
[ -x "$OPENER" ] || { echo "build first: tools/build.sh"; exit 1; }
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
pass=0 failed=0
ok()   { pass=$((pass + 1)); echo "  ok   $1"; }
bad()  { failed=$((failed + 1)); echo "  FAIL $1"; }
check() { local name="$1"; shift; if "$@"; then ok "$name"; else bad "$name"; fi; }
refuse() { local name="$1"; shift; if "$@" 2>/dev/null; then bad "$name"; else ok "$name"; fi; }

# ---------------------------------------------------------------- config
echo "config"
. "$ROOT/src/lib/config.sh"
check "example config loads" noc_load_config "$ROOT/config.example"
check "derived data dir" [ "$NOC_DIR" = "$HOME/.nas-on-click" ]
check "MAC is normalised" [ "$(noc_norm_mac 00:00:5E:00:53:0A)" = "0:0:5e:0:53:a" ]
mk() { cp "$ROOT/config.example" "$WORK/c"; printf '%s\n' "$@" >> "$WORK/c"; echo "$WORK/c"; }
refuse "unknown key rejected"        noc_load_config "$(mk 'PATH=/tmp')"
refuse "dollar sign rejected"        noc_load_config "$(mk 'APP_NAME=$(id)')"
refuse "backtick rejected"           noc_load_config "$(mk 'ORG_NAME=`id`')"
refuse "bad office address rejected" noc_load_config "$(mk 'OFFICE_HOST=nas.local')"
refuse "http update URL rejected"    noc_load_config "$(mk 'UPDATE_URL=http://example.com/x')"
refuse "path as folder rejected"     noc_load_config "$(mk 'FOLDER_NAME=../x')"
refuse "same office and remote host rejected" noc_load_config "$(mk 'REMOTE_HOST=192.0.2.10')"
check "office-only config loads"     noc_load_config "$(mk 'REMOTE_HOST=' 'WARP_TEAM=')"
for l in auto en tr de fr es ru; do check "language $l accepted" noc_load_config "$(mk "LANGUAGE=$l")"; done
refuse "unknown language rejected" noc_load_config "$(mk 'LANGUAGE=xx')"
same_keys=1
for f in "$ROOT"/src/lang/*.sh; do
  diff -q <(grep -o '^L_[A-Z_0-9]*' "$ROOT/src/lang/en.sh" | sort) <(grep -o '^L_[A-Z_0-9]*' "$f" | sort) >/dev/null || { echo "    keys differ: $f"; same_keys=0; }
done
check "every language defines exactly the same strings" [ $same_keys = 1 ]
refuse "no host at all rejected"     noc_load_config "$(mk 'REMOTE_HOST=' 'WARP_TEAM=' 'OFFICE_HOST=' 'OFFICE_GATEWAY=' 'OFFICE_GATEWAY_MAC=' 'OFFICE_SUBNET_PREFIX=')"

# ---------------------------------------------------------------- manifest
echo "manifest"
SIGNER=(swift "$ROOT/tools/signer.swift" --key-file "$WORK/key")
"${SIGNER[@]}" keygen > "$WORK/keys" || { echo "signer failed"; exit 1; }
swift "$ROOT/tools/signer.swift" --key-file "$WORK/other" keygen > "$WORK/otherkeys"
SHA0="$(printf 'x%.0s' {1..64} | tr x a)"
manifest() { # product version file sha size
  printf '{"product":"%s","version":"%s","file":"%s","sha256":"%s","size":%s,"notes":"line one\\nline\\ttwo"}' "$@" > "$WORK/m.json"
  "${SIGNER[@]}" sign "$WORK/m.json" > "$WORK/m.sig"
}
verify() { "$OPENER" verify-manifest "$WORK/m.json" "$WORK/m.sig" "$WORK/keys" nas-on-click "$1" >"$WORK/out" 2>/dev/null; echo $?; }

manifest nas-on-click 1.2.0 nas-on-click-1.2.0.tar.gz "$SHA0" 1000
check "newer version accepted"         [ "$(verify 1.1.9)" = 0 ]
check "output fields"                  [ "$(cut -f1,2,4 "$WORK/out")" = "1.2.0	nas-on-click-1.2.0.tar.gz	1000" ]
check "notes flattened to one line"    [ "$(wc -l < "$WORK/out" | tr -d ' ')" = 1 ]
check "same version is not newer"      [ "$(verify 1.2.0)" = 3 ]
check "older version is not newer"     [ "$(verify 1.10.0)" = 3 ]
printf ' ' >> "$WORK/m.json"
check "tampered manifest rejected"     [ "$(verify 1.0.0)" = 1 ]
manifest nas-on-click 1.2.0 nas-on-click-1.2.0.tar.gz "$SHA0" 1000
cp "$WORK/otherkeys" "$WORK/keys.bak"; cp "$WORK/keys" "$WORK/keys.good"; cp "$WORK/otherkeys" "$WORK/keys"
check "unknown key rejected"           [ "$(verify 1.0.0)" = 1 ]
{ cat "$WORK/otherkeys"; cat "$WORK/keys.good"; } > "$WORK/keys"
check "any listed key accepted"        [ "$(verify 1.0.0)" = 0 ]
cp "$WORK/keys.good" "$WORK/keys"
manifest other-product 1.2.0 nas-on-click-1.2.0.tar.gz "$SHA0" 1000
check "other product rejected"         [ "$(verify 1.0.0)" = 1 ]
manifest nas-on-click 1.2.0 ../evil.tar.gz "$SHA0" 1000
check "path in file name rejected"     [ "$(verify 1.0.0)" = 1 ]
manifest nas-on-click 1.2.0 nas-on-click-1.2.0.tar.gz ABC 1000
check "bad sha256 rejected"            [ "$(verify 1.0.0)" = 1 ]
manifest nas-on-click 1.2 nas-on-click-1.2.tar.gz "$SHA0" 1000
check "non-semver version rejected"    [ "$(verify 1.0.0)" = 1 ]
printf '{"product":"nas-on-click","version":"1.2.0","file":"nas-on-click-1.2.0.tar.gz","sha256":"%s","size":1000,"notes":"English note","notes_i18n":{"tr":"Türkçe not"}}' "$SHA0" > "$WORK/m.json"
"${SIGNER[@]}" sign "$WORK/m.json" > "$WORK/m.sig"
"$OPENER" verify-manifest "$WORK/m.json" "$WORK/m.sig" "$WORK/keys" nas-on-click 1.0.0 tr > "$WORK/out"
check "release note shown in the user's language" [ "$(cut -f5 "$WORK/out")" = "Türkçe not" ]
"$OPENER" verify-manifest "$WORK/m.json" "$WORK/m.sig" "$WORK/keys" nas-on-click 1.0.0 de > "$WORK/out"
check "missing translation falls back to English" [ "$(cut -f5 "$WORK/out")" = "English note" ]
echo "bm90IGEgc2lnbmF0dXJl" > "$WORK/m.sig"
check "garbage signature rejected"     [ "$(verify 1.0.0)" = 1 ]

# ---------------------------------------------------------------- update flow
echo "update flow"
export HOME="$WORK/home"; mkdir -p "$HOME"
noc_load_config "$ROOT/config.example"
LANGUAGE=en
noc_load_lang "$ROOT/src"
. "$ROOT/src/lib/common.sh"
. "$ROOT/src/lib/update.sh"
mkdir -p "$APP/bin"; cp "$OPENER" "$APP/bin/nas-on-click"; cp "$WORK/keys" "$APP/update-keys"; echo 1.0.0 > "$APP/VERSION"
: > "$D/config"
SERVER="$WORK/server"
# A fake package whose installer only leaves a marker.
mkdir -p "$WORK/pkgsrc"; printf '#!/bin/bash\ntouch "%s/installed"\n' "$WORK" > "$WORK/pkgsrc/install.sh"
publish() { # version
  mkdir -p "$SERVER"; rm -f "$SERVER"/*
  tar -czf "$SERVER/nas-on-click-$1.tar.gz" -C "$WORK/pkgsrc" .
  manifest nas-on-click "$1" "nas-on-click-$1.tar.gz" "$(shasum -a 256 "$SERVER/nas-on-click-$1.tar.gz" | awk '{print $1}')" "$(stat -f %z "$SERVER/nas-on-click-$1.tar.gz")"
  cp "$WORK/m.json" "$SERVER/manifest.json"; cp "$WORK/m.sig" "$SERVER/manifest.sig"
}
# Stubs: local files instead of the network, scripted answers instead of dialogs.
noc_fetch() { cp "$SERVER/${1##*/}" "$2" 2>/dev/null; }
ANSWER=""; noc_choose() { printf '%s' "$ANSWER"; }
noc_alert() { :; }
run_update() { rm -f "$WORK/installed" "$D/last-update-check"; noc_update_check; }

publish 1.1.0
ANSWER="$L_BTN_INSTALL"; run_update
check "signed update installed after consent" [ -f "$WORK/installed" ]
ANSWER="$L_BTN_LATER"; run_update
check "postponed update not installed"        [ ! -f "$WORK/installed" ]
ANSWER="$L_BTN_INSTALL"; rm -f "$WORK/installed"; date +%s > "$D/last-update-check"; noc_update_check
check "no second check within a day"          [ ! -f "$WORK/installed" ]
publish 1.1.0; echo junk >> "$SERVER/nas-on-click-1.1.0.tar.gz"; run_update
check "package not matching manifest refused" [ ! -f "$WORK/installed" ]
publish 1.1.0; cp "$WORK/otherkeys" "$APP/update-keys"; run_update; cp "$WORK/keys" "$APP/update-keys"
check "release signed by unknown key refused" [ ! -f "$WORK/installed" ]
publish 0.9.0; run_update
check "older release refused"                 [ ! -f "$WORK/installed" ]
UPDATE_URL=""; publish 1.1.0; run_update
check "updates off when UPDATE_URL is empty"  [ ! -f "$WORK/installed" ]

echo
echo "$pass passed, $failed failed"
[ $failed = 0 ]
