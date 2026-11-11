#!/bin/bash
# Installs nas-on-click for the current user, or refreshes an existing install.
#
#   install.sh                  first install or repair (interactive, uses ./config).
#                               Finished steps are detected and skipped.
#   install.sh --update CONFIG  non-interactive refresh used by the updater: replaces the
#                               app files, folder launchers and background jobs and keeps
#                               the config, password, WARP enrolment and share list.
#                               On failure the previous version is put back.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
MODE=install
ROLLBACK=1
if [ "${1:-}" = --update ]; then
  MODE=update; CFG="${2:-}"
  [ "${3:-}" = --no-rollback ] && ROLLBACK=0
else
  CFG="$HERE/config"
fi

. "$HERE/lib/config.sh"
if ! noc_load_config "$CFG"; then
  if [ $MODE = install ] && [ -x "${NOC_UI:-}" ]; then
    "$NOC_UI" ui --title "Setup" --message "This setup package contains an invalid config file." --style stop --button OK >/dev/null 2>&1
  fi
  exit 1
fi
noc_load_lang "$HERE" || exit 1
. "$HERE/lib/common.sh"
mkdir -p "$D" && chmod 700 "$D"
[ $MODE = install ] && exec >> "$D/install.log" 2>&1
echo "== $(date '+%F %T') $MODE $(cat "$HERE/VERSION" 2>/dev/null)"
UID_NUM="$(id -u)"
STAGE="$D/app.new"
SWAPPED=0
WARP_NOTE=""

say()    { printf '\n== %s\n' "$*"; }
stop_enroll() { [ -n "${ENROLL_PID:-}" ] && kill "$ENROLL_PID" 2>/dev/null; ENROLL_PID=""; }
fail()   { stop_enroll; printf '%s\n' "$1" > "$D/install-error"; echo "ERROR: $1"; exit 1; }
cancel() { stop_enroll; echo "$1"; exit 2; }

rollback() {
  [ $SWAPPED = 1 ] && [ $ROLLBACK = 1 ] && [ -d "$D/app.prev" ] || return 0
  echo "Restoring the previous version."
  rm -rf "$APP" && mv "$D/app.prev" "$APP" && /bin/bash "$APP/install.sh" --update "$CFG" --no-rollback
}

finish() {
  local rc=$? msg
  stop_enroll
  noc_status_done
  rm -rf "$STAGE"
  [ $rc -ne 0 ] && [ $MODE = update ] && rollback
  if [ $rc = 1 ] && [ $MODE = install ]; then
    msg="$(cat "$D/install-error" 2>/dev/null)"
    noc_alert "$L_FAILED_HEAD

${msg:-$L_UNEXPECTED}

$L_FAILED_TAIL" stop
  fi
  rm -f "$D/install-error"
}

# --- Welcome -----------------------------------------------------------------------
if [ $MODE = install ] && [ -z "${NOC_SKIP_INTRO:-}" ]; then
  intro="$L_INTRO_HEAD

$(if noc_has_remote; then echo "$L_INTRO_REMOTE"; else echo "$L_INTRO_OFFICE"; fi)

$L_INTRO_ASK
$L_INTRO_ITEM_NAS"
  noc_has_remote && intro="$intro
$L_INTRO_ITEM_MAC
$L_INTRO_ITEM_LOGIN"
  intro="$intro

$L_INTRO_TAIL"
  [ "$(noc_choose "$intro" "$L_BTN_START" "$L_BTN_CANCEL")" = "$L_BTN_START" ] || exit 0
fi

# --- Only one installer at a time ------------------------------------------------------
# One installer at a time: re-run this script under a kernel lock (see noc_locked).
if [ -z "${NOC_LOCKED:-}" ]; then
  [ -d "$D/install.lock" ] && rm -rf "$D/install.lock"   # lock folder of 1.0.x
  NOC_LOCKED=1 NOC_SKIP_INTRO=1 noc_locked "$D/install.lock" /bin/bash "$0" "$@"; rc=$?
  if [ $rc = 75 ]; then
    [ $MODE = install ] && { noc_alert "$L_ALREADY_RUNNING" note 20; exit 0; }
    exit 3   # update: report "not installed" so the updater does not claim success
  fi
  exit $rc
fi
unset NOC_LOCKED NOC_SKIP_INTRO
rm -f "$D/install-error"
trap finish EXIT

# Copy the package right away: the installer may be running from a USB stick or a
# temporary folder that disappears before setup ends.
rm -rf "$STAGE"; mkdir -p "$STAGE"
for f in agent.sh install.sh uninstall.sh lib lang bin update-keys VERSION; do
  cp -R "$HERE/$f" "$STAGE/" 2>/dev/null || break
done
[ -s "$STAGE/agent.sh" ] && [ -x "$STAGE/bin/nas-on-click" ] && [ -x "$STAGE/bin/sleepwatch" ] \
  && [ -s "$STAGE/lib/smb-shares.exp" ] && [ -s "$STAGE/update-keys" ] && [ -s "$STAGE/VERSION" ] \
  || fail "$L_COPY_FAILED"
if [ $MODE = install ]; then cp "$CFG" "$D/config.new" || fail "$L_COPY_FAILED"; fi

# --- NAS account -------------------------------------------------------------------------
# list_shares HOST USER (password on stdin): prints `smbutil view` output. The password
# is typed into smbutil's prompt through a pseudo-terminal by an expect script.
list_shares() { /usr/bin/expect -f "$STAGE/lib/smb-shares.exp" "$1" "$(noc_enc "$2")" 2>/dev/null; }

nas_account() {
  local host ok=0 list rc tries=0 user pass acct
  say "NAS account"
  noc_status "$L_STATUS_ACCOUNT"
  if ! host="$(noc_pick_host)"; then
    if noc_has_remote; then noc_alert "$L_NAS_UNREACHABLE_WARP" stop; else noc_alert "$L_NAS_UNREACHABLE_OFFICE" stop; fi
    cancel "$L_NAS_UNREACHABLE_OFFICE"
  fi
  echo "Checking against $host"
  # An earlier install may have left the Keychain item without the user file.
  if [ ! -f "$D/user" ]; then
    acct="$(noc_keychain_account)"
    [ -n "$acct" ] && printf '%s' "$acct" > "$D/user"
  fi
  if [ -f "$D/user" ] && noc_password "$(cat "$D/user")" >/dev/null; then
    list="$(noc_password "$(cat "$D/user")" | list_shares "$host" "$(cat "$D/user")")"; rc=$?
    if [ $rc = 0 ] && [ -n "$list" ]; then
      ok=1; printf '%s\n' "$list" | noc_parse_shares > "$D/shares"; rm -f "$D/password-rejected"
    else echo "The stored NAS password did not work (code $rc); asking again."; fi
  fi
  if [ $ok = 1 ]; then echo "NAS account already set up: $(cat "$D/user")"; return 0; fi

  noc_status "$L_ENTER_CREDS"
  user="$(id -F 2>/dev/null)"
  while [ $tries -lt 3 ]; do
    user="$(noc_ask_text "$L_ASK_USER" "$user" plain)" || cancel "$L_CANCELLED"
    if [ -z "$(printf '%s' "$user" | tr -d '[:space:]')" ]; then
      noc_alert "$L_USER_EMPTY"; user=""; continue
    fi
    user="$(noc_normalize_user "$user")"
    pass="$(noc_ask_text "$L_ASK_PASS" "" secure)" || cancel "$L_CANCELLED"
    noc_status "$L_STATUS_ACCOUNT"
    list="$(printf '%s\n' "$pass" | list_shares "$host" "$user")"; rc=$?
    if [ $rc = 0 ] && [ -n "$list" ]; then
      printf '%s\n' "$pass" | "$STAGE/bin/nas-on-click" keychain-set --service "$KEYCHAIN_SERVICE" --account "$user" --label "$APP_NAME" \
        || { unset pass; fail "$L_UNEXPECTED"; }
      printf '%s' "$user" > "$D/user"
      rm -f "$D/password-rejected"
      printf '%s\n' "$list" | noc_parse_shares > "$D/shares"
      echo "Account verified. Shares: $(tr '\n' ' ' < "$D/shares")"
      break
    fi
    echo "Share listing failed with code $rc."
    if [ $rc = 77 ]; then
      tries=$((tries + 1))
      if [ $tries -lt 3 ]; then noc_alert "$L_BAD_CREDS $(noc_fmt "$L_RETRY_N" "$tries")"
      else noc_alert "$L_BAD_CREDS $L_NO_MORE_TRIES"; unset pass; cancel "$L_CREDS_FAILED_3"; fi
    else
      [ "$(noc_choose "$(noc_fmt "$L_CONN_PROBLEM" "$rc")" "$L_BTN_RETRY" "$L_BTN_CANCEL" "" caution)" = "$L_BTN_RETRY" ] \
        || { unset pass; cancel "$L_CANCELLED"; }
    fi
  done
  unset pass
}

# --- Cloudflare WARP: install and enrol in the team --------------------------------------
# The leaf certificate of the WARP installer must be exactly Cloudflare's Developer ID.
CLOUDFLARE_SIGNER_RE='^[[:space:]]*1\. Developer ID Installer: Cloudflare Inc\. \(68WVV388M8\)$'
warp_pkg_trusted() {
  local sig
  sig="$(/usr/sbin/pkgutil --check-signature "$1" 2>/dev/null)" || return 1
  printf '%s\n' "$sig" | grep -q "Status: signed by a developer certificate issued by Apple for distribution" \
    && printf '%s\n' "$sig" | grep -Eq "$CLOUDFLARE_SIGNER_RE"
}
MDM="/Library/Application Support/Cloudflare/mdm.xml"

warp_setup() {
  local pkg sig cmd rc old
  say "Cloudflare WARP"
  # Never take over a WARP install that another organisation manages.
  if [ -f "$MDM" ] && ! grep -q "<string>$WARP_TEAM</string>" "$MDM" 2>/dev/null; then fail "$L_WARP_FOREIGN"; fi
  if [ -d "/Applications/Cloudflare WARP.app" ]; then echo "WARP is already installed."
  else
    pkg="$D/Cloudflare_WARP.pkg"
    noc_status "$L_WARP_DOWNLOADING"
    curl -fsSL --proto '=https' --proto-redir '=https' --max-time 900 -o "$pkg" "https://downloads.cloudflareclient.com/v1/download/macos/ga" || fail "$L_WARP_DL_FAIL"
    warp_pkg_trusted "$pkg" || { rm -f "$pkg"; fail "$L_WARP_SIG_FAIL"; }
    echo "Signature verified. Installing (one Mac password prompt)."
    # Runs as root. The package is copied into a root-owned folder and its signature is
    # checked again there, so it cannot be swapped after the check above. The team name
    # is written for WARP only when no MDM file exists yet. WARP_TEAM is limited to
    # [a-z0-9-] by the config check.
    read -r -d '' cmd <<ROOT
set -e
T=\$(mktemp -d /private/tmp/noc.XXXXXX)
trap 'rm -rf "\$T"' EXIT
cp $(printf '%q' "$pkg") "\$T/w.pkg"
S=\$(/usr/sbin/pkgutil --check-signature "\$T/w.pkg")
printf '%s\\n' "\$S" | grep -q 'issued by Apple for distribution'
printf '%s\\n' "\$S" | grep -Eq '$CLOUDFLARE_SIGNER_RE'
M='/Library/Application Support/Cloudflare'
if [ ! -e "\$M/mdm.xml" ]; then
  mkdir -p "\$M"
  printf '%s\\n' '<dict>' '  <key>organization</key>' '  <string>$WARP_TEAM</string>' '  <key>onboarding</key>' '  <false/>' '</dict>' > "\$M/mdm.xml"
fi
/usr/sbin/installer -pkg "\$T/w.pkg" -target /
ROOT
    NOC_CMD="$cmd" NOC_PROMPT="$L_WARP_ADMIN_PROMPT" osascript -e 'activate' \
      -e 'do shell script (do shell script "printenv NOC_CMD") with prompt (do shell script "printenv NOC_PROMPT") with administrator privileges' \
      >/dev/null 2>"$D/warp-error.txt"; rc=$?
    if [ $rc != 0 ]; then
      rm -f "$pkg"
      if grep -q -- "-128" "$D/warp-error.txt"; then rm -f "$D/warp-error.txt"; cancel "$L_WARP_CANCELLED"; fi
      rm -f "$D/warp-error.txt"; fail "$L_WARP_INSTALL_FAIL"
    fi
    rm -f "$D/warp-error.txt"
    for _ in $(seq 1 24); do [ -x "$WARP_CLI" ] && break; sleep 5; done
    [ -x "$WARP_CLI" ] || fail "$L_WARP_INCOMPLETE"
    rm -f "$pkg"; echo "WARP installed."
  fi

  say "WARP enrolment ($WARP_TEAM)"
  if noc_warp_enrolled; then echo "Already enrolled."
  else
    noc_status "$L_LOGIN_NOTIFY"
    ( noc_alert "$L_LOGIN_DIALOG" note 60 & )
    old="$(noc_warp_org)"
    if "$WARP_CLI" --accept-tos registration show >/dev/null 2>&1; then
      [ "$(noc_choose "$(noc_fmt "$L_WARP_SWITCH" "${old:-$L_WARP_PERSONAL}")" "$L_BTN_CANCEL" "$L_BTN_CONFIRM" "" caution)" = "$L_BTN_CONFIRM" ] \
        || cancel "$L_WARP_SWITCH_DECLINED"
      "$WARP_CLI" --accept-tos registration delete >/dev/null 2>&1
    fi
    # A WARP installed by this script already knows the team (mdm.xml) and may start the
    # sign-in itself; give it 45 s before opening one, so no second browser tab appears.
    if grep -q "<string>$WARP_TEAM</string>" "$MDM" 2>/dev/null; then
      for _ in $(seq 1 9); do noc_warp_enrolled && break; sleep 5; done
    fi
    if ! noc_warp_enrolled; then
      "$WARP_CLI" --accept-tos registration new "$WARP_TEAM" >/dev/null 2>&1 &
      ENROLL_PID=$!
    fi
    for i in $(seq 1 120); do
      noc_warp_enrolled && break
      [ $((i % 12)) = 0 ] && noc_status "$(noc_fmt "$L_LOGIN_PROGRESS" "$((i / 12))")"
      sleep 5
    done
    noc_warp_enrolled || fail "$L_LOGIN_TIMEOUT"
    ENROLL_PID=""
    echo "Enrolled."
  fi
  noc_status "$L_STATUS_WARP"
  "$WARP_CLI" --accept-tos connect >/dev/null 2>&1
  for _ in $(seq 1 24); do noc_warp_connected && break; sleep 5; done
  noc_warp_connected || { echo "WARNING: WARP did not connect (VPN permission?)"; WARP_NOTE="$L_WARP_NOT_CONNECTED"; }
}

# --- Folder launchers and background jobs ------------------------------------------------
stop_job() {
  launchctl bootout "gui/$UID_NUM/$1" 2>/dev/null
  for _ in $(seq 1 20); do launchctl print "gui/$UID_NUM/$1" >/dev/null 2>&1 || return 0; sleep 0.5; done
}
load_job() {
  for _ in 1 2 3; do launchctl bootstrap "gui/$UID_NUM" "$1" 2>/dev/null && return 0; sleep 2; done
  echo "WARNING: could not load $1"; return 1
}

# Is this .app one of our launchers (current or legacy bundle-id prefix)?
our_launcher() {
  local id p
  id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$1/Contents/Info.plist" 2>/dev/null)" || return 1
  for p in $NOC_LAUNCHER_PREFIX $LEGACY_BUNDLE_PREFIXES; do
    case "$id" in "$p".*) return 0 ;; esac
  done
  return 1
}

FOLDER="$HOME/$FOLDER_NAME"
# The system's network-share icon, copied from this Mac at install time (never shipped).
share_icon() {
  local base=/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources
  if [ -f "$base/GenericSharepoint.icns" ]; then echo "$base/GenericSharepoint.icns"; else echo "$base/GenericFolderIcon.icns"; fi
}

# The helper app shows dialogs and the progress window with the app's name and icon.
make_helper() {
  local h="$APP/Helper.app"
  rm -rf "$h"
  mkdir -p "$h/Contents/MacOS" "$h/Contents/Resources"
  cp "$APP/bin/nas-on-click" "$h/Contents/MacOS/nas-on-click"
  cp "$(share_icon)" "$h/Contents/Resources/app.icns" 2>/dev/null
  cat > "$h/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>$BUNDLE_ID.helper</string>
  <key>CFBundleName</key><string>$(noc_xml "$APP_NAME")</string>
  <key>CFBundleDisplayName</key><string>$(noc_xml "$APP_NAME")</string>
  <key>CFBundleExecutable</key><string>nas-on-click</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleIconFile</key><string>app</string>
  <key>CFBundleShortVersionString</key><string>$(cat "$APP/VERSION")</string>
  <key>LSMinimumSystemVersion</key><string>12.0</string>
  <key>LSUIElement</key><true/>
  <key>NOCRole</key><string>helper</string>
</dict></plist>
PLIST
  codesign --force -s - "$h" >/dev/null 2>&1
}

make_launchers() {
  local icon n=0 s app id
  mkdir -p "$FOLDER"
  # Remove links to old mount points and our own launchers; nothing else is touched.
  while IFS= read -r l; do
    case "$(readlink "$l")" in /Volumes/*|"$D/mnt/"*) rm -f "$l" ;; esac
  done < <(find "$FOLDER" -mindepth 1 -maxdepth 1 -type l)
  while IFS= read -r app; do
    our_launcher "$app" && rm -rfx "$app"
  done < <(find "$FOLDER" -mindepth 1 -maxdepth 1 -type d -name '*.app')

  icon="$(share_icon)"
  while IFS= read -r s; do
    [ -n "$s" ] || continue
    case "$s" in */*|*..*|.*) continue ;; esac
    app="$FOLDER/$s.app"
    if [ -e "$app" ]; then echo "WARNING: \"$s.app\" already exists and is not ours; skipped."; continue; fi
    n=$((n + 1))
    id="$NOC_LAUNCHER_PREFIX.k$(printf '%s' "$s" | md5 | cut -c1-12)"
    mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
    cp "$APP/bin/nas-on-click" "$app/Contents/MacOS/nas-on-click"
    cp "$icon" "$app/Contents/Resources/folder.icns" 2>/dev/null
    cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>$id</string>
  <key>CFBundleName</key><string>$(noc_xml "$APP_NAME")</string>
  <key>CFBundleExecutable</key><string>nas-on-click</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleIconFile</key><string>folder</string>
  <key>CFBundleShortVersionString</key><string>$(cat "$APP/VERSION")</string>
  <key>LSMinimumSystemVersion</key><string>12.0</string>
  <key>LSUIElement</key><true/>
  <key>NOCRole</key><string>launcher</string>
  <key>NOCShare</key><string>$(noc_xml "$s")</string>
  <key>NOCRequestDir</key><string>$(noc_xml "$D/requests")</string>
  <key>NOCAgentLabel</key><string>$NOC_AGENT_LABEL</string>
  <key>NOCTitle</key><string>$(noc_xml "$APP_NAME")</string>
  <key>NOCOK</key><string>$(noc_xml "$L_BTN_OK")</string>
  <key>NOCAgentError</key><string>$(noc_xml "$L_AGENT_NOT_RUNNING")</string>
</dict></plist>
PLIST
    codesign --force -s - "$app" >/dev/null 2>&1
    "$APP/bin/nas-on-click" hide-extension "$app"
    touch "$app"
  done < "$D/shares"
  echo "$n folder launchers created."
  [ $n -gt 0 ]
}

write_plists() {
  mkdir -p "$HOME/Library/LaunchAgents"
  # Agent: started by the launchers; also on network changes and every minute, when it
  # only closes mounts that became unreachable.
  cat > "$1/agent.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$NOC_AGENT_LABEL</string>
  <key>ProgramArguments</key><array><string>/bin/bash</string><string>$(noc_xml "$APP/agent.sh")</string></array>
  <key>RunAtLoad</key><true/>
  <key>StartInterval</key><integer>60</integer>
  <key>WatchPaths</key><array><string>/Library/Preferences/SystemConfiguration</string></array>
  <key>ThrottleInterval</key><integer>5</integer>
  <key>AbandonProcessGroup</key><true/>
</dict></plist>
PLIST
  cat > "$1/sleep.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$NOC_SLEEP_LABEL</string>
  <key>ProgramArguments</key><array><string>$(noc_xml "$APP/bin/sleepwatch")</string><string>$(noc_xml "$APP/agent.sh")</string><string>$NOC_AGENT_LABEL</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
</dict></plist>
PLIST
}

deploy() {
  local la="$HOME/Library/LaunchAgents" pa pu tmpd changed=0 l
  pa="$la/$NOC_AGENT_LABEL.plist"; pu="$la/$NOC_SLEEP_LABEL.plist"
  say "Folder launchers and background jobs"
  for l in $LEGACY_LABELS; do stop_job "$l"; rm -f "$la/$l.plist"; done
  tmpd="$(mktemp -d "$D/plist.XXXXXX")"
  write_plists "$tmpd"
  cmp -s "$tmpd/agent.plist" "$pa" && cmp -s "$tmpd/sleep.plist" "$pu" || changed=1
  if [ $MODE = install ] || [ $changed = 1 ]; then stop_job "$NOC_AGENT_LABEL"; stop_job "$NOC_SLEEP_LABEL"; fi

  rm -rf "$D/app.prev"
  if [ -d "$APP" ]; then mv "$APP" "$D/app.prev" || fail "$L_COPY_FAILED"; fi
  mv "$STAGE" "$APP" || fail "$L_COPY_FAILED"
  SWAPPED=1
  xattr -cr "$APP" 2>/dev/null
  chmod 700 "$APP/agent.sh" "$APP/install.sh" "$APP/uninstall.sh"
  [ $MODE = install ] && { mv -f "$D/config.new" "$D/config"; chmod 600 "$D/config"; }
  mkdir -p "$D/requests"; rm -f "$D/requests/"* 2>/dev/null
  # 1.0.x used lock folders; lockf needs plain files (never delete a held lock file).
  for l in "$D/agent.lock" "$D/update.lock"; do [ -d "$l" ] && rm -rf "$l"; done

  make_helper
  noc_status "$L_STATUS_LAUNCHERS"
  make_launchers || { rm -rf "$tmpd"; fail "$L_NO_SHARES"; }

  if [ $MODE = install ] || [ $changed = 1 ]; then
    mv -f "$tmpd/agent.plist" "$pa"; mv -f "$tmpd/sleep.plist" "$pu"
    load_job "$pa" || { rm -rf "$tmpd"; fail "$L_UNEXPECTED"; }
    load_job "$pu" || { rm -rf "$tmpd"; fail "$L_UNEXPECTED"; }
  else
    # Same job definitions: the agent script is re-read on every run; restart the sleep watcher.
    launchctl kickstart -k "gui/$UID_NUM/$NOC_SLEEP_LABEL" >/dev/null 2>&1
  fi
  rm -rf "$tmpd"
}

# --- Run -----------------------------------------------------------------------------------
if [ $MODE = update ]; then
  [ -f "$D/user" ] && [ -f "$D/shares" ] || fail "not installed"
  deploy
  echo "Update to $(cat "$APP/VERSION") complete."
  exit 0
fi

noc_status "$L_STARTED"
# In the office the account is checked first (no WARP needed); elsewhere WARP comes first.
if noc_in_office || ! noc_has_remote; then
  nas_account
  if noc_has_remote; then
    # Without WARP the NAS still works in the office: carry on and mention it at the end.
    ( trap - EXIT; warp_setup ); rc=$?
    if [ $rc = 2 ]; then WARP_NOTE="$L_WARP_SKIPPED_OFFICE"
    elif [ $rc != 0 ]; then WARP_NOTE="$L_WARP_FAILED_OFFICE"
    elif ! noc_warp_connected; then WARP_NOTE="$L_WARP_NOT_CONNECTED"
    fi
    rm -f "$D/install-error"
  fi
else
  warp_setup
  for _ in $(seq 1 12); do nc -z -G 4 "$REMOTE_HOST" 445 2>/dev/null && break; sleep 5; done
  nas_account
fi

deploy

# Desktop link (an old broken link is replaced; a real folder is never touched)
link="$HOME/Desktop/$FOLDER_NAME"
if [ -L "$link" ] || [ ! -e "$link" ]; then ln -sfn "$FOLDER" "$link" 2>/dev/null || echo "WARNING: could not create the Desktop link."; fi
if [ "$(readlink "$link" 2>/dev/null)" = "$FOLDER" ]; then where="$L_LOC_DESKTOP"; else where="$L_LOC_HOME"; fi

echo
echo "Setup complete."
open "$FOLDER" 2>/dev/null
body=""
[ -n "$WARP_NOTE" ] && body="$WARP_NOTE

"
body="$body$L_FINAL_DONE

$where $L_FINAL_HOWTO

$L_FINAL_WHERE

$L_FINAL_SIDEBAR"
noc_has_remote && body="$body

$L_FINAL_WARP"
noc_status_done
noc_ui --headline "$L_FINAL_TITLE" --message "$body" --style stop --button "$L_BTN_GOTIT" >/dev/null
exit 0
