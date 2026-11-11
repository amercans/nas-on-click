# shellcheck shell=bash
# Signed self-update.
#
# A release publishes three files: the package (.tar.gz), manifest.json and
# manifest.sig (an Ed25519 signature over the exact bytes of manifest.json).
# The manifest names the product, version, package file, its SHA-256 and size.
# An update is installed only when:
#   - the signature verifies against a key in app/update-keys (shipped with the
#     installed version, so a signed release can also rotate keys),
#   - the product matches and the version is newer than the installed one,
#   - the downloaded package has exactly the size and SHA-256 from the manifest,
#   - and the user agreed.

NOC_PRODUCT="nas-on-click"
NOC_UPDATE_INTERVAL=86400
NOC_MANIFEST_MAX=65536
NOC_PACKAGE_MAX=52428800

noc_update_due() {
  local last
  [ -n "$UPDATE_URL" ] || return 1
  last="$(cat "$D/last-update-check" 2>/dev/null || echo 0)"
  case "$last" in ''|*[!0-9]*) last=0 ;; esac
  [ $(( $(date +%s) - last )) -ge $NOC_UPDATE_INTERVAL ]
}

# Run the check in its own session so launchd does not stop it with this job.
noc_update_spawn() {
  perl -MPOSIX -e 'POSIX::setsid(); exec @ARGV' /bin/bash "$APP/agent.sh" update-check </dev/null >/dev/null 2>&1 &
}

# noc_fetch URL OUTPUT MAX-BYTES  (https only, redirects included)
noc_fetch() {
  curl -fsSL --proto '=https' --proto-redir '=https' --max-time 120 --max-filesize "$3" -o "$2" "$1" 2>/dev/null \
    && [ "$(stat -f %z "$2" 2>/dev/null || echo 0)" -le "$3" ]
}

noc_update_check() {
  local tmp
  noc_update_due || return 0
  noc_lock "$D/update.lock" "agent.sh" || return 0
  date +%s > "$D/last-update-check"
  tmp="$(mktemp -d "$D/update.XXXXXX")" || { rm -rf "$D/update.lock"; return 0; }
  noc_update_run "$tmp"
  rm -rf "$tmp" "$D/update.lock"
}

noc_update_run() {
  local tmp="$1" info ver file sha size notes choice
  noc_fetch "$UPDATE_URL/manifest.json" "$tmp/manifest.json" $NOC_MANIFEST_MAX \
    && noc_fetch "$UPDATE_URL/manifest.sig" "$tmp/manifest.sig" 4096 \
    || { noc_log "update: could not download the manifest"; return 0; }

  info="$("$APP/bin/opener" --verify-manifest "$tmp/manifest.json" "$tmp/manifest.sig" \
            "$APP/update-keys" "$NOC_PRODUCT" "$(cat "$APP/VERSION")")"
  case $? in
    0) ;;
    3) noc_log "update: up to date"; return 0 ;;
    *) noc_log "update: manifest rejected (signature, product or format)"; return 0 ;;
  esac
  IFS=$'\t' read -r ver file sha size notes <<< "$info"

  # "Not now" is the default button, so pressing Return never installs.
  choice="$(noc_choose "$(printf "$L_UPDATE_AVAILABLE" "$ver" "$notes")" "$L_BTN_INSTALL" "$L_BTN_LATER" 600 note)"
  [ "$choice" = "$L_BTN_INSTALL" ] || { noc_log "update: $ver postponed"; return 0; }

  if ! noc_fetch "$UPDATE_URL/$file" "$tmp/$file" $NOC_PACKAGE_MAX \
     || [ "$(stat -f %z "$tmp/$file")" != "$size" ] \
     || [ "$(shasum -a 256 "$tmp/$file" | awk '{ print $1 }')" != "$sha" ]; then
    noc_log "update: package download failed or does not match the manifest"
    noc_notify "$L_UPDATE_FAILED"; return 0
  fi
  mkdir "$tmp/pkg" && tar -xzf "$tmp/$file" -C "$tmp/pkg" 2>/dev/null && [ -f "$tmp/pkg/install.sh" ] \
    || { noc_log "update: package could not be unpacked"; noc_notify "$L_UPDATE_FAILED"; return 0; }

  local before; before="$(cat "$APP/VERSION")"
  if /bin/bash "$tmp/pkg/install.sh" --update "$D/config" >> "$LOG" 2>&1 \
     && [ "$(cat "$APP/VERSION" 2>/dev/null)" = "$ver" ]; then
    noc_log "update: installed $ver"
    noc_notify "$(printf "$L_UPDATE_DONE" "$ver")"
  else
    if [ "$(cat "$APP/VERSION" 2>/dev/null)" = "$before" ] && [ -x "$APP/bin/opener" ]; then
      noc_log "update: install of $ver failed, still on $before"
    else
      noc_log "update: install of $ver failed and $before could not be confirmed - run setup again"
    fi
    noc_notify "$L_UPDATE_FAILED"
  fi
}
