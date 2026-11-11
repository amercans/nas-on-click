#!/bin/bash
# Background job. Started by launchd (on login, every minute, on network changes)
# and by the folder launchers when an icon is double-clicked.
#
#   agent.sh               mount and open requested shares, then drop mounts that
#                          became unreachable (it never mounts anything on its own)
#   agent.sh sleep         unmount everything before the Mac goes to sleep
#   agent.sh update-check  look for a signed update (at most once a day)
set -u
APP_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$APP_DIR/lib/config.sh"
noc_load_config "$APP_DIR/../config" || exit 1
noc_load_lang "$APP_DIR" || exit 1
. "$APP_DIR/lib/common.sh"
. "$APP_DIR/lib/update.sh"

REQ="$D/requests"
[ -f "$LOG" ] && [ "$(wc -l < "$LOG")" -gt 4000 ] && tail -n 2000 "$LOG" > "$LOG.tmp" && mv -f "$LOG.tmp" "$LOG"

# Dialogs close by themselves after two minutes, so a forgotten dialog never
# blocks the cleanup that runs in the background.
warn() { noc_alert "$1" caution 120; }

unmount_quiet() { perl -e "alarm $1; exec @ARGV" /usr/sbin/diskutil unmount "$2" >/dev/null 2>&1; }

# --- Sleep: unmount everything in parallel, never forcibly -------------------------
if [ "${1:-}" = sleep ]; then
  date +%s > "$D/last-sleep"
  while IFS=$'\t' read -r _ mp _; do
    [ -n "$mp" ] || continue
    # One retry for a share that Finder is busy reading; ~20 s in total, inside the
    # time macOS waits before sleeping.
    ( { unmount_quiet 8 "$mp" || { sleep 1; unmount_quiet 11 "$mp"; }; } \
        && noc_log "sleep: unmounted $mp" || noc_log "sleep: could not unmount (open file or no reply) $mp" ) &
  done < <(noc_mounts)
  wait
  exit 0
fi

if [ "${1:-}" = update-check ]; then
  noc_update_check
  exit 0
fi

# --- One run at a time. A request left behind is picked up by the running copy. -----
noc_lock "$D/agent.lock" "agent.sh" || exit 0
# launchd ignores a kickstart while this run is still going, so a click that lands
# after the last check would wait for the next timer run: start a fresh run for it.
release_lock() {
  rm -rf "$D/agent.lock"
  if [ -n "$(ls -1 "$REQ" 2>/dev/null)" ]; then
    perl -MPOSIX -e 'POSIX::setsid(); exec @ARGV' /bin/bash "$APP/agent.sh" </dev/null >/dev/null 2>&1 &
  fi
}
trap release_lock EXIT

# Unmount one share. A mount of the office address may be forced only when the Mac is
# certainly off the office network (it can never come back); remote mounts never are.
close_mount() {
  local addr="$1" mp="$2" why="$3"
  if unmount_quiet 20 "$mp"; then noc_log "$why: unmounted $mp"; return 0; fi
  if [ "$addr" = "$OFFICE_HOST" ] && ! noc_on_office_subnet \
     && perl -e 'alarm 20; exec @ARGV' /usr/sbin/diskutil unmount force "$mp" >/dev/null 2>&1; then
    noc_log "$why: unmounted (off the office network) $mp"; return 0
  fi
  noc_log "$why: could not unmount (open file or no reply) $mp"; return 1
}

has_requests() { [ -n "$(ls -1 "$REQ" 2>/dev/null)" ]; }
# Wait N seconds, serving clicks that arrive in the meantime.
wait_serving() { local i; for ((i = 0; i < $1; i++)); do has_requests && handle_requests; sleep 1; done; }

# --- Cleanup: drop mounts whose address is no longer reachable (never mounts) --------
cleanup() {
  local a mp bad=0
  while IFS=$'\t' read -r a mp _; do noc_reachable "$a" || { bad=1; break; }; done < <(noc_mounts)
  [ $bad = 1 ] || return 0
  # The network may have just changed (WARP reconnects late after wake): look again in 15 s.
  wait_serving 15
  while IFS=$'\t' read -r a mp _; do
    noc_reachable "$a" && continue
    close_mount "$a" "$mp" "unreachable ($a)"
  done < <(noc_mounts)
}

# --- Password check. A password the NAS rejected is never sent again (that could
# trigger the NAS auto-block); the user is asked for the new one instead.
check_password() {
  local new
  if [ ! -f "$D/password-rejected" ]; then
    smbutil view -N "//$(noc_enc "$U"):$(noc_enc "$P")@$IP" >/dev/null 2>&1 </dev/null
    [ $? = 77 ] || return 0
    : > "$D/password-rejected"; noc_log "NAS rejected the stored password"
  fi
  new="$(noc_ask_text "$L_PW_CHANGED" "" yes 120 caution "$L_BTN_CONNECT")" || { noc_log "password prompt dismissed"; return 1; }
  [ -n "$new" ] || return 1
  smbutil view -N "//$(noc_enc "$U"):$(noc_enc "$new")@$IP" >/dev/null 2>&1 </dev/null
  if [ $? = 77 ]; then
    unset new; noc_log "new password rejected too"
    warn "$L_PW_REJECTED"; return 1
  fi
  security add-generic-password -U -s "$KEYCHAIN_SERVICE" -a "$U" -w "$new" -l "$APP_NAME"
  P="$new"; unset new; rm -f "$D/password-rejected"
  noc_log "new password saved"
}

mount_share() {
  local s mp
  s="$(noc_nfc "$1")"
  if printf '%s' "$U" | LC_ALL=C grep -q '[^ -~]'; then
    # Finder's "mount volume" mangles non-ASCII user names, so use mount_smbfs into
    # our own folder. Output is discarded: error text could contain the password.
    mp="$D/mnt/$s"; mkdir -p "$mp"
    perl -e 'alarm 60; exec @ARGV' mount_smbfs -N "//$(noc_enc "$U"):$(noc_enc "$P")@$IP/$(noc_enc "$s")" "$mp" </dev/null >/dev/null 2>&1
  else
    NOC_U="$U" NOC_P="$P" NOC_URL="smb://$IP/$(noc_enc "$s")" perl -e 'alarm 60; exec @ARGV' osascript \
      -e 'mount volume (do shell script "printenv NOC_URL") as user name (do shell script "printenv NOC_U") with password (do shell script "printenv NOC_P")' \
      </dev/null >/dev/null 2>&1
  fi
}

# --- Handle clicks: mount the requested shares and open them in Finder -------------
OPENED=0
handle_requests() {
  local list s now started found addr mp f where pw_checked=0
  now=$(date +%s)
  # Drop clicks older than three minutes so nothing opens "by itself" much later
  # (a click may wait behind a dialog that stays open for up to two minutes).
  for f in "$REQ"/*; do
    [ -e "$f" ] || continue
    [ $(( now - $(stat -f %m "$f" 2>/dev/null || echo 0) )) -gt 180 ] && rm -f "$f"
  done
  list="$(ls -1 "$REQ" 2>/dev/null)"
  [ -n "$list" ] || return 0
  if [ ! -f "$D/user" ] || [ ! -f "$D/shares" ]; then
    rm -f "$REQ"/* 2>/dev/null; warn "$L_SETUP_INCOMPLETE"; return 0
  fi

  # WARP first: the office check rests on values that are not secret (gateway IP and
  # MAC), so the direct route is only used when the tunnel is not available.
  if noc_remote_ok; then IP="$REMOTE_HOST"; where=remote
  elif noc_in_office; then IP="$OFFICE_HOST"; where=office
  else
    if noc_warp_enrolled && ! noc_warp_connected; then
      "$WARP_CLI" --accept-tos connect >/dev/null 2>&1
      for _ in 1 2 3 4 5 6 7 8 9 10; do noc_warp_connected && break; sleep 2; done
    fi
    if noc_remote_ok; then IP="$REMOTE_HOST"; where=remote
    else
      rm -f "$REQ"/* 2>/dev/null
      noc_log "request: NAS unreachable (not in the office, WARP not connected)"
      if ! noc_has_remote; then warn "$L_UNREACHABLE_OFFICE"
      elif noc_warp_enrolled; then warn "$L_UNREACHABLE_WARP"
      else warn "$L_UNREACHABLE_NOWARP"; fi
      return 0
    fi
  fi

  U="$(cat "$D/user")"
  P="$(security find-generic-password -s "$KEYCHAIN_SERVICE" -a "$U" -w 2>/dev/null)" || {
    rm -f "$REQ"/* 2>/dev/null; noc_log "password missing from the Keychain"; warn "$L_NO_PASSWORD"; return 0; }

  while IFS= read -r s; do
    case "$s" in ""|*/*|*..*|.*) continue ;; esac
    rm -f "$REQ/$s"
    grep -qxF -- "$(noc_nfc "$s")" <(while IFS= read -r k; do noc_nfc "$k"; echo; done < "$D/shares") \
      || { noc_log "request: not an allowed share: $s"; continue; }
    found="$(noc_mount_of "$s")"; addr="${found%%$'\t'*}"; mp="${found#*$'\t'}"; [ -n "$found" ] || mp=""
    # A mount left over from an address that is no longer reachable is replaced.
    if [ -n "$mp" ] && ! noc_reachable "$addr"; then
      close_mount "$addr" "$mp" "click, stale mount ($addr)" || { warn "$(printf "$L_OLD_MOUNT_BUSY" "$(noc_nfc "$s")")"; continue; }
      mp=""
    fi
    if [ -z "$mp" ]; then
      if [ $pw_checked = 0 ]; then
        check_password || { rm -f "$REQ"/* 2>/dev/null; break; }
        pw_checked=1
      fi
      started=$(date +%s)
      mount_share "$s"
      found="$(noc_mount_of "$s")"; [ -n "$found" ] && mp="${found#*$'\t'}" || mp=""
      # The lid was closed while mounting: do not leave the mount open or pop a window.
      if [ -n "$mp" ] && [ "$(cat "$D/last-sleep" 2>/dev/null || echo 0)" -ge "$started" ]; then
        close_mount "$IP" "$mp" "slept while mounting"; continue
      fi
      [ -n "$mp" ] && noc_log "mounted: $(noc_nfc "$s") ($where)" || noc_log "mount failed: $(noc_nfc "$s") ($where)"
    fi
    if [ -n "$mp" ]; then open "$mp"; OPENED=1
    else warn "$(printf "$L_OPEN_FAILED" "$(noc_nfc "$s")")"; fi
  done <<< "$list"
  unset P
}

handle_requests
cleanup
# Serve clicks that arrived while this run was busy.
for _ in 1 2 3; do has_requests || break; handle_requests; done
# After a share was opened, look for an update in a separate session (at most daily).
[ $OPENED = 1 ] && noc_update_due && noc_update_spawn
exit 0
