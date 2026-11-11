#!/bin/bash
# Behaviour tests for the agent, installer and uninstaller logic.
# No NAS, no network and no changes to the machine: system tools are replaced by small
# shims in a temporary folder that replay fixtures and record how they were called.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ -x "$ROOT/dist/payload/bin/nas-on-click" ] || { echo "build first: tools/build.sh"; exit 1; }
WORK="$(mktemp -d)"
trap 'pkill -f "$WORK/" 2>/dev/null; rm -rf "$WORK"' EXIT
pass=0 failed=0
ok()     { pass=$((pass + 1)); echo "  ok   $1"; }
bad()    { failed=$((failed + 1)); echo "  FAIL $1"; }
check()  { local n="$1"; shift; if "$@"; then ok "$n"; else bad "$n"; fi; }
refute() { local n="$1"; shift; if "$@"; then bad "$n"; else ok "$n"; fi; }
has()    { grep -qF -- "$2" "$1" 2>/dev/null; }

export HOME="$WORK/home"; mkdir -p "$HOME"
SHIM="$WORK/shim"; mkdir -p "$SHIM"
export PATH="$SHIM:$PATH"
ME="$(id -un)"

# ---------------------------------------------------------------- shims
# Fixture values the shims read (changed per test).
export FX_GW=203.0.113.1 FX_IP=203.0.113.50 FX_MAC="" FX_NC=1 FX_TEAM="" FX_WARP=Disconnected
export FX_UNMOUNT=0 FX_UI_ANSWER="" FX_UI_RC=0 FX_MOUNT_RCS=""
export WORK ME
mk() { printf '#!/bin/bash\n%s\n' "$2" > "$SHIM/$1"; chmod +x "$SHIM/$1"; }
mk mount     'cat "$WORK/mounts" 2>/dev/null'
mk route     'echo "   gateway: $FX_GW"'
mk ifconfig  'echo "	inet $FX_IP netmask 0xffffff00"'
mk arp       'case "$FX_MAC" in "") ;; incomplete) echo "? ($2) at (incomplete) on en0" ;; *) echo "? ($2) at $FX_MAC on en0 ifscope [ethernet]" ;; esac'
mk nc        'exit $FX_NC'
mk open      'echo "$*" >> "$WORK/open.log"'
mk launchctl 'echo "$*" >> "$WORK/launchctl.log"'
mk codesign  'exit 0'
mk security  'case "$1" in
  find-generic-password) case " $* " in *" -w "*) echo stored-pw ;; *) echo "    \"acct\"<blob>=\"tester\"" ;; esac ;;
  delete-generic-password) echo "$*" >> "$WORK/security.log" ;;
esac'
mk diskutil  'echo "$*" >> "$WORK/diskutil.log"
[ "$FX_UNMOUNT" = 0 ] || exit 1
mp="${@: -1}"
until mkdir "$WORK/mounts.lock" 2>/dev/null; do sleep 0.05; done
grep -vF " on $mp (" "$WORK/mounts" > "$WORK/m.$$" 2>/dev/null; mv "$WORK/m.$$" "$WORK/mounts"
rmdir "$WORK/mounts.lock"'
mk warp-cli  'case "$*" in
  *"registration show"*) [ -n "$FX_TEAM" ] && echo "Organization: $FX_TEAM" ;;
  *status*) echo "Status update: $FX_WARP" ;;
esac'
export DISKUTIL="$SHIM/diskutil" WARP_CLI="$SHIM/warp-cli"

# The app binary: records mount/ui/keychain calls.
APPBIN='#!/bin/bash
cmd="$1"; shift
case "$cmd" in
  mount)
    pw="$(cat)"; echo "$pw" >> "$WORK/mount-stdin.log"; echo "$*" >> "$WORK/mount.log"
    n=$(($(cat "$WORK/mount-count" 2>/dev/null || echo 0) + 1)); echo $n > "$WORK/mount-count"
    rc=$(echo "$FX_MOUNT_RCS" | awk -v n=$n "{ print \$n }"); rc=${rc:-0}
    if [ "$rc" = 0 ]; then
      url="${2}"; host="${url#smb://}"; share="${host#*/}"; host="${host%%/*}"
      [ -n "${FX_SLEEP_DURING_MOUNT:-}" ] && echo $(( $(date +%s) + 5 )) > "$HOME/.nas-on-click/last-sleep"
      echo "//tester@$host/$share on /Volumes/$share (smbfs, nodev, nosuid, mounted by $ME)" >> "$WORK/mounts"
    fi
    exit "$rc" ;;
  ui) echo "$*" >> "$WORK/ui.log"; [ -n "$FX_UI_ANSWER" ] && echo "$FX_UI_ANSWER"; exit "$FX_UI_RC" ;;
  keychain-set) cat > "$WORK/keychain-set.log"; exit 0 ;;
  progress) exit 0 ;;
  hide-extension) exit 0 ;;
  verify-manifest) exec "'"$ROOT"'/dist/payload/bin/nas-on-click" verify-manifest "$@" ;;
esac
exit 64'

reset() {
  rm -f "$WORK"/*.log "$WORK/mounts" "$WORK/mount-count"
  rm -rf "$HOME/.nas-on-click"
  mkdir -p "$APP/bin" "$D/requests"
  printf '%s\n' "$APPBIN" > "$APP/bin/nas-on-click"; chmod +x "$APP/bin/nas-on-click"
  echo tester > "$D/user"; printf 'Projects\nDİAS\nShared Files\n' > "$D/shares"
  export FX_GW=203.0.113.1 FX_IP=203.0.113.50 FX_MAC="" FX_NC=1 FX_TEAM="" FX_WARP=Disconnected
  export FX_UNMOUNT=0 FX_UI_ANSWER="" FX_UI_RC=0 FX_MOUNT_RCS="" FX_SLEEP_DURING_MOUNT=""
  OPENED=0
}
remote_up()  { export FX_TEAM=example-team FX_WARP=Connected FX_NC=0; }
in_office()  { export FX_GW=192.0.2.1 FX_IP=192.0.2.50 FX_MAC=0:0:5e:0:53:1; }
request()    { : > "$D/requests/$1"; }

# ---------------------------------------------------------------- load the code
. "$ROOT/src/lib/config.sh"
noc_load_config "$ROOT/config.example" >/dev/null
LANGUAGE=en
noc_load_lang "$ROOT/src"
. "$ROOT/src/lib/common.sh"
. "$ROOT/src/lib/update.sh"
. "$ROOT/src/agent.sh"
REQ="$D/requests"
wait_serving() { :; }   # the real one waits 15 s for the network to settle

echo "parsing"
reset
cat > "$WORK/mounts" <<EOF
//tester@198.51.100.20/D%C4%B0AS on /Volumes/DİAS (smbfs, nodev, nosuid, mounted by $ME)
//tester@198.51.100.20/Shared%20Files on /Volumes/Shared Files (smbfs, nodev, nosuid, mounted by $ME)
//tester@198.51.100.20/Projects on /Volumes/Projects (smbfs, nodev, nosuid, mounted by someone-else)
//tester@203.0.113.9/Projects on /Volumes/Projects-1 (smbfs, nodev, nosuid, mounted by $ME)
/dev/disk3s1 on / (apfs, local, journaled)
EOF
out="$(noc_mounts)"
check "only this user's NAS mounts are listed" [ "$(printf '%s\n' "$out" | wc -l | tr -d ' ')" = 2 ]
check "percent-encoded non-ASCII share decoded" [ "$(noc_mount_of "DİAS")" = "198.51.100.20	/Volumes/DİAS" ]
check "NFD request matches NFC share"           [ -n "$(noc_mount_of "$(printf 'DI\xcc\x87AS')")" ]
check "share name with a space"                  [ "$(noc_mount_of "Shared Files" | cut -f2)" = "/Volumes/Shared Files" ]
shares="$(printf '%s\n' "Share  Type  Comments" "-------" "Projects   Disk" "IPC\$  Pipe  IPC Service" \
  "Shared Files     Disk   team" "docker  Disk" "../x  Disk" "Printer  Printer" | noc_parse_shares)"
check "share list filtered (IPC\$, printers, excluded, path-like)" [ "$shares" = "$(printf 'Projects\nShared Files')" ]
USERNAME_UPPERCASE=yes
check "user name: trimmed, upper case, dotless i kept" [ "$(noc_normalize_user '  ayşe ılgaz ')" = "AYŞE ıLGAZ" ]
USERNAME_UPPERCASE=no
check "XML escaping for Info.plist values" [ "$(noc_xml 'R&D <x>')" = "R&amp;D &lt;x&gt;" ]
check "placeholders filled without printf"  [ "$(noc_fmt 'a %s b %s' '100%' 'x&y')" = "a 100% b x&y" ]

echo "routing"
reset; remote_up; in_office
check "WARP is preferred even in the office"   [ "$(noc_pick_host)" = "$REMOTE_HOST" ]
reset; in_office
check "office route without WARP"              [ "$(noc_pick_host)" = "$OFFICE_HOST" ]
reset; in_office; export FX_MAC=0:0:5e:0:53:99
check "a different router MAC is not the office" [ "$(noc_office_state)" = no ]
reset; in_office; export FX_MAC=""
check "expired ARP entry: office state unknown" [ "$(noc_office_state)" = unknown ]
check "an office mount survives an expired ARP entry" noc_still_reachable "$OFFICE_HOST"
reset; in_office; export FX_MAC=incomplete
check "router not answering ARP: not the office"  [ "$(noc_office_state)" = no ]

echo "clicks"
reset; remote_up; request Projects
handle_requests
check "click mounts through WARP and opens"  has "$WORK/open.log" "/Volumes/Projects"
check "password reached the helper via stdin" [ "$(cat "$WORK/mount-stdin.log")" = stored-pw ]

reset; remote_up; request "$(printf 'DI\xcc\x87AS')"
handle_requests
check "NFD file name is sent to the server as NFC" has "$WORK/mount.log" "smb://198.51.100.20/D%C4%B0AS"

reset; remote_up; request Projects; touch -t 202001010000 "$D/requests/Projects"
handle_requests
check "click older than three minutes is dropped" [ ! -f "$WORK/mount.log" ] && [ ! -e "$D/requests/Projects" ]

reset; remote_up; request "a..b"; request "Unknown"
handle_requests
check "invalid and unknown requests are removed" [ -z "$(ls -A "$D/requests")" ] && [ ! -f "$WORK/mount.log" ]

reset; remote_up; request Projects; export FX_MOUNT_RCS="77 0" FX_UI_ANSWER=new-pw
handle_requests
check "rejected password: user asked, new one used" [ "$(tr '\n' ' ' < "$WORK/mount-stdin.log")" = "stored-pw new-pw " ]
check "new password stored via stdin"             [ "$(cat "$WORK/keychain-set.log")" = new-pw ]
check "flag cleared after success"                [ ! -f "$D/password-rejected" ]

reset; remote_up; export FX_MOUNT_RCS="1 1" FX_UI_RC=1
request Projects; handle_requests; request Projects; handle_requests
check "two failures in a row with any code: treated as rejected" [ -f "$D/password-rejected" ] && [ "$(grep -c stored-pw "$WORK/mount-stdin.log")" = 2 ]

reset; remote_up; request Projects; export FX_MOUNT_RCS="77 1" FX_UI_ANSWER=new-pw
handle_requests
check "a new password that did not mount is not stored" [ ! -f "$WORK/keychain-set.log" ]

reset; remote_up; request Projects; : > "$D/password-rejected"; export FX_UI_ANSWER=new-pw
handle_requests
refute "a known-rejected password is never sent again" has "$WORK/mount-stdin.log" stored-pw

reset; remote_up; request Projects; request DİAS; export FX_MOUNT_RCS="77" FX_UI_RC=1
handle_requests
check "dismissed prompt stops all pending clicks" [ "$(wc -l < "$WORK/mount.log" | tr -d ' ')" = 1 ] && [ -z "$(ls -A "$D/requests")" ]

reset; remote_up; request Projects; export FX_SLEEP_DURING_MOUNT=1
handle_requests
check "slept while mounting: unmounted, not opened" has "$WORK/diskutil.log" "unmount /Volumes/Projects" && [ ! -f "$WORK/open.log" ]

reset; request Projects
handle_requests
check "unreachable NAS: no mount, user told" [ ! -f "$WORK/mount.log" ] && has "$WORK/ui.log" "--style caution"

echo "clean-up"
reset; in_office
echo "//tester@192.0.2.10/Projects on /Volumes/Projects (smbfs, nodev, nosuid, mounted by $ME)" > "$WORK/mounts"
cleanup
check "reachable office mount is kept" [ ! -f "$WORK/diskutil.log" ]
export FX_GW=203.0.113.1 FX_IP=203.0.113.50 FX_UNMOUNT=1
cleanup
check "office mount off the office network: force allowed" has "$WORK/diskutil.log" "unmount force /Volumes/Projects"
reset
echo "//tester@198.51.100.20/Projects on /Volumes/Projects (smbfs, nodev, nosuid, mounted by $ME)" > "$WORK/mounts"
export FX_UNMOUNT=1
cleanup
refute "remote mount is never forced" has "$WORK/diskutil.log" "force"

echo "locks"
reset
noc_locked "$D/agent.lock" sleep 3 & holder=$!
sleep 0.5
noc_locked "$D/agent.lock" true; rc=$?
check "a held lock makes a second run back off (75)" [ $rc = 75 ]
wait "$holder"
noc_locked "$D/agent.lock" true; rc=$?
check "the lock is free again after the holder ends"  [ $rc = 0 ]

echo "sleep"
reset
printf '%s\n' "//tester@198.51.100.20/Projects on /Volumes/Projects (smbfs, nodev, nosuid, mounted by $ME)" \
  "//tester@192.0.2.10/DİAS on /Volumes/DİAS (smbfs, nodev, nosuid, mounted by $ME)" > "$WORK/mounts"
sleep_unmount
check "sleep unmounts every share"       [ -z "$(noc_mounts)" ]
refute "sleep never forces" has "$WORK/diskutil.log" force

echo "installer and uninstaller"
reset
# A previous version is installed; the update fails after the swap (no shares) and
# must put the previous version back.
cp -R "$ROOT/dist/payload/." "$APP/"; echo 0.9.0 > "$APP/VERSION"
cp "$ROOT/config.example" "$D/config"; : > "$D/shares"
/bin/bash "$ROOT/dist/payload/install.sh" --update "$D/config" >/dev/null 2>&1; rc=$?
check "failed update reports failure"     [ $rc != 0 ]
check "failed update restores the previous version" [ "$(cat "$APP/VERSION" 2>/dev/null)" = 0.9.0 ]

reset
cp -R "$ROOT/dist/payload/." "$APP/"; cp "$ROOT/config.example" "$D/config"
printf 'Projects\n' > "$D/shares"
/bin/bash "$ROOT/dist/payload/install.sh" --update "$D/config" >/dev/null 2>&1; rc=$?
check "update succeeds and creates the launcher" [ $rc = 0 ] && [ -f "$HOME/NAS Drive/Projects.app/Contents/Info.plist" ]
check "launcher records the share and role" \
  /usr/libexec/PlistBuddy -c 'Print :NOCShare' "$HOME/NAS Drive/Projects.app/Contents/Info.plist"
check "helper app created"                [ -x "$APP/Helper.app/Contents/MacOS/nas-on-click" ]

echo "//tester@198.51.100.20/Projects on /Volumes/Projects (smbfs, nodev, nosuid, mounted by $ME)" > "$WORK/mounts"
export FX_UNMOUNT=1
/bin/bash "$APP/uninstall.sh" >/dev/null 2>&1; rc=$?
check "uninstall refuses while a share stays mounted" [ $rc = 1 ] && [ -d "$D" ] && [ -d "$HOME/NAS Drive/Projects.app" ]
export FX_UNMOUNT=0
/bin/bash "$APP/uninstall.sh" > "$WORK/uninstall.out" 2>&1; rc=$?
[ -n "${DEBUG:-}" ] && { cat "$WORK/uninstall.out"; ls -la "$D" "$HOME/NAS Drive" 2>&1; }
check "uninstall removes everything once unmounted" [ $rc = 0 ] && [ ! -d "$D" ] && [ ! -e "$HOME/NAS Drive" ]

echo
echo "$pass passed, $failed failed"
[ $failed = 0 ]
