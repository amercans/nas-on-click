#!/bin/bash
# Background job. launchd starts it at login, every minute and on network changes;
# the folder launchers start it when an icon is double-clicked.
#
#   agent.sh               mount and open the requested shares, then drop mounts whose
#                          route is gone (it never mounts anything on its own)
#   agent.sh sleep         unmount everything before the Mac goes to sleep
#   agent.sh update-check  look for a signed update (at most once a day)
#
# Sourcing this file only defines functions (the test suite does that).

set -u
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$APP_DIR/lib/config.sh"

# Dialogs close by themselves after two minutes, so a forgotten dialog never blocks
# the clean-up that runs in the background.
warn() { noc_alert "$1" caution 120; }

# --- Sleep: unmount everything in parallel, never forcibly -----------------------------
sleep_unmount() {
  date +%s > "$D/last-sleep"
  while IFS=$'\t' read -r _ mp _; do
    [ -n "$mp" ] || continue
    # One retry for a share that Finder is busy reading; about 20 s in total, inside
    # the time macOS waits before sleeping.
    ( { noc_timeout 8 "$DISKUTIL" unmount "$mp" >/dev/null 2>&1 \
          || { sleep 1; noc_timeout 11 "$DISKUTIL" unmount "$mp" >/dev/null 2>&1; }; } \
        && noc_log "sleep: unmounted $mp" || noc_log "sleep: could not unmount (open file or no reply) $mp" ) &
  done < <(noc_mounts)
  wait
}

# Unmount one share. A mount of the office address may be forced only when the Mac
# is certainly off the office network (it cannot come back); remote mounts never are.
close_mount() {
  local addr="$1" mp="$2" why="$3"
  # Off the office network an office mount is dead for good, and with no network at all
  # every mount is: force it at once, before macOS shows its "server connections
  # interrupted" dialog.
  if { [ "$addr" = "$OFFICE_HOST" ] && ! noc_on_office_subnet; } || noc_offline; then
    if noc_timeout 20 "$DISKUTIL" unmount force "$mp" >/dev/null 2>&1; then
      noc_log "$why: unmounted (off the office network) $mp"; return 0
    fi
    noc_log "$why: could not unmount (no reply) $mp"; return 1
  fi
  if noc_timeout 20 "$DISKUTIL" unmount "$mp" >/dev/null 2>&1; then noc_log "$why: unmounted $mp"; return 0; fi
  noc_log "$why: could not unmount (open file or no reply) $mp"; return 1
}

has_requests() { [ -n "$(ls -1 "$REQ" 2>/dev/null)" ]; }
# Wait N seconds, serving clicks that arrive in the meantime.
wait_serving() { local i; for ((i = 0; i < $1; i++)); do has_requests && handle_requests; sleep 1; done; }

# --- Clean-up: drop mounts whose route is gone (never mounts) ------------------------------
cleanup() {
  local a mp bad=0
  while IFS=$'\t' read -r a mp _; do noc_still_reachable "$a" || { bad=1; break; }; done < <(noc_mounts)
  [ $bad = 1 ] || return 0
  # No network at all, or office mounts with the Mac off the office network: these
  # cannot come back soon, so close them quickly (after 5 s, so a short blip does not
  # cut an open file) instead of waiting for macOS to complain.
  if noc_offline || { [ -n "$(noc_mounts | awk -F'\t' -v h="$OFFICE_HOST" '$1 == h')" ] && ! noc_on_office_subnet; }; then
    wait_serving 5
  fi
  if noc_offline; then
    while IFS=$'\t' read -r a mp _; do close_mount "$a" "$mp" "no network"; done < <(noc_mounts)
  fi
  while IFS=$'\t' read -r a mp _; do
    [ "$a" = "$OFFICE_HOST" ] && ! noc_on_office_subnet && close_mount "$a" "$mp" "left the office network"
  done < <(noc_mounts)
  [ -n "$(noc_mounts)" ] || return 0
  # The network may have just changed (WARP reconnects late after wake): look again in 15 s.
  wait_serving 15
  while IFS=$'\t' read -r a mp _; do
    noc_still_reachable "$a" && continue
    close_mount "$a" "$mp" "unreachable ($a)"
  done < <(noc_mounts)
}

# mount_with HOST SHARE (password on stdin). Exit: 0 mounted, 77 rejected, other failure.
mount_with() {
  # File names come back NFD from the file system; servers expect NFC.
  noc_timeout 60 "$APP/bin/nas-on-click" mount --url "smb://$1/$(noc_enc "$(noc_nfc "$2")")" --user "$U" >/dev/null 2>&1
}

# Mount SHARE on HOST. A password the NAS rejected is never sent again (that could
# trigger the NAS auto-block); the user is asked for the new one instead.
# Returns 0 mounted, 1 failed, 2 the user gave up (stop handling clicks).
mount_share() {
  local host="$1" s="$2" rc new fails
  if [ ! -f "$D/password-rejected" ]; then
    noc_password "$U" | mount_with "$host" "$s"; rc=${PIPESTATUS[1]}
    if [ "$rc" = 0 ]; then rm -f "$D/mount-failures"; return 0; fi
    # Treat the password as rejected on EAUTH, and also after two failures in a row
    # with the NAS reachable, whatever the error code: that bounds how often a stale
    # password can be sent even if a server reports rejection differently.
    fails=$(( $(cat "$D/mount-failures" 2>/dev/null || echo 0) + 1 ))
    echo "$fails" > "$D/mount-failures"
    if [ "$rc" != 77 ] && [ "$fails" -lt 2 ]; then return 1; fi
    : > "$D/password-rejected"; rm -f "$D/mount-failures"
    noc_log "stored password treated as rejected (code $rc)"
  fi
  new="$(noc_ask_text "$L_PW_CHANGED" "" secure 120 caution "$L_BTN_CONNECT")" || { noc_log "password prompt dismissed"; return 2; }
  [ -n "$new" ] || return 2
  printf '%s\n' "$new" | mount_with "$host" "$s"; rc=$?
  if [ "$rc" = 77 ]; then
    unset new; noc_log "new password rejected too"
    warn "$L_PW_REJECTED"; return 2
  fi
  # Only a password the NAS accepted is stored.
  if [ "$rc" = 0 ]; then
    printf '%s\n' "$new" | noc_save_password "$U" && rm -f "$D/password-rejected" && noc_log "new password saved"
  fi
  unset new
  [ "$rc" = 0 ]
}

# --- Clicks: mount the requested shares and open them in Finder -------------------------
OPENED=0
handle_requests() {
  local list s now started found addr mp f host where k
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

  if ! host="$(noc_pick_host)"; then
    if noc_warp_enrolled && ! noc_warp_connected; then
      "$WARP_CLI" --accept-tos connect >/dev/null 2>&1
      for _ in 1 2 3 4 5 6 7 8 9 10; do noc_warp_connected && break; sleep 2; done
    fi
    if ! host="$(noc_pick_host)"; then
      rm -f "$REQ"/* 2>/dev/null
      noc_log "request: NAS unreachable (not in the office, WARP not connected)"
      if ! noc_has_remote; then warn "$L_UNREACHABLE_OFFICE"
      elif noc_warp_enrolled; then warn "$L_UNREACHABLE_WARP"
      else warn "$L_UNREACHABLE_NOWARP"; fi
      return 0
    fi
  fi
  if [ "$host" = "$OFFICE_HOST" ]; then where=office; else where=remote; fi

  U="$(cat "$D/user")"
  if ! noc_password "$U" >/dev/null; then
    rm -f "$REQ"/* 2>/dev/null; noc_log "password missing from the Keychain"; warn "$L_NO_PASSWORD"; return 0
  fi

  while IFS= read -r s; do
    rm -f "$REQ/$s"
    case "$s" in ""|*/*|*..*|.*) noc_log "request: invalid name ignored"; continue ;; esac
    grep -qxF -- "$(noc_nfc "$s")" <(while IFS= read -r k; do noc_nfc "$k"; echo; done < "$D/shares") \
      || { noc_log "request: not an allowed share: $s"; continue; }
    found="$(noc_mount_of "$s")"; addr="${found%%$'\t'*}"; mp="${found#*$'\t'}"; [ -n "$found" ] || mp=""
    # A mount left over from a route that is gone is replaced.
    if [ -n "$mp" ] && ! noc_still_reachable "$addr"; then
      close_mount "$addr" "$mp" "click, stale mount ($addr)" \
        || { warn "$(noc_fmt "$L_OLD_MOUNT_BUSY" "$(noc_nfc "$s")")"; continue; }
      mp=""
    fi
    if [ -z "$mp" ]; then
      started=$(date +%s)
      mount_share "$host" "$s"
      case $? in
        2) rm -f "$REQ"/* 2>/dev/null; break ;;
      esac
      found="$(noc_mount_of "$s")"; [ -n "$found" ] && mp="${found#*$'\t'}" || mp=""
      # The lid was closed while mounting: do not leave the mount open or pop a window.
      if [ -n "$mp" ] && [ "$(cat "$D/last-sleep" 2>/dev/null || echo 0)" -ge "$started" ]; then
        close_mount "$host" "$mp" "slept while mounting"; continue
      fi
      if [ -n "$mp" ]; then noc_log "mounted: $(noc_nfc "$s") ($where)"; else noc_log "mount failed: $(noc_nfc "$s") ($where)"; fi
    fi
    if [ -n "$mp" ]; then open "$mp"; OPENED=1
    else warn "$(noc_fmt "$L_OPEN_FAILED" "$(noc_nfc "$s")")"; fi
  done <<< "$list"
}

main() {
  noc_load_config "$APP_DIR/../config" || exit 1
  noc_load_lang "$APP_DIR" || exit 1
  . "$APP_DIR/lib/common.sh"
  . "$APP_DIR/lib/update.sh"
  REQ="$D/requests"

  [ "${1:-}" = sleep ] && { sleep_unmount; exit 0; }

  # One run at a time (one update check at a time), under a kernel lock.
  if [ -z "${NOC_LOCKED:-}" ]; then
    local lock="$D/agent.lock" rc
    [ "${1:-}" = update-check ] && lock="$D/update.lock"
    NOC_LOCKED=1 noc_locked "$lock" /bin/bash "$APP_DIR/agent.sh" "$@"; rc=$?
    [ $rc = 75 ] && exit 0
    # launchd ignores a kickstart while a run is going, so a click that landed after
    # that run's last check would wait for the next timer run: serve it now.
    if [ -z "${1:-}" ] && has_requests; then exec /bin/bash "$APP_DIR/agent.sh"; fi
    exit $rc
  fi
  unset NOC_LOCKED   # children (update check, installer) take their own locks
  [ "${1:-}" = update-check ] && { noc_update_check; exit 0; }

  [ -f "$LOG" ] && [ "$(wc -l < "$LOG")" -gt 4000 ] && tail -n 2000 "$LOG" > "$LOG.tmp" && mv -f "$LOG.tmp" "$LOG"

  handle_requests
  cleanup
  # Serve clicks that arrived while this run was busy.
  for _ in 1 2 3; do has_requests || break; handle_requests; done
  # After a share was opened, look for an update in a separate session (at most daily).
  [ $OPENED = 1 ] && noc_update_due && noc_update_spawn
  exit 0
}

[ "${BASH_SOURCE[0]}" = "$0" ] && main "$@"
