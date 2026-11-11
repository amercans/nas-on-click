#!/bin/bash
# Removes nas-on-click for the current user. Cloudflare WARP is left installed.
# Shares may be mounted inside the data folder, so everything is unmounted first;
# if anything stays mounted, nothing is deleted (deleting would reach the NAS).
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
CFG="$HERE/../config"; [ -f "$CFG" ] || CFG="$HERE/config"
. "$HERE/lib/config.sh"
noc_load_config "$CFG" || exit 1
noc_load_lang "$HERE" || exit 1
. "$HERE/lib/common.sh"

# Unmount first: if something stays mounted, the jobs keep running and nothing changes.
while IFS=$'\t' read -r _ mp _; do
  [ -n "$mp" ] && noc_timeout 20 "$DISKUTIL" unmount "$mp" >/dev/null 2>&1
done < <(noc_mounts)
if [ -n "$(noc_mounts)" ]; then
  echo "Some NAS folders could not be unmounted because files are open. Close them and run this again. Nothing was deleted."
  exit 1
fi
for l in "$NOC_AGENT_LABEL" "$NOC_SLEEP_LABEL" $LEGACY_LABELS; do
  launchctl bootout "gui/$(id -u)/$l" 2>/dev/null
done

for l in "$NOC_AGENT_LABEL" "$NOC_SLEEP_LABEL" $LEGACY_LABELS; do rm -f "$HOME/Library/LaunchAgents/$l.plist"; done
[ -f "$D/user" ] && security delete-generic-password -s "$KEYCHAIN_SERVICE" -a "$(cat "$D/user")" >/dev/null 2>&1

# Launchers and links in the NAS folder; anything else in it is kept.
FOLDER="$HOME/$FOLDER_NAME"
if [ -d "$FOLDER" ]; then
  while IFS= read -r l; do
    case "$(readlink "$l")" in /Volumes/*|"$D/mnt/"*) rm -f "$l" ;; esac
  done < <(find "$FOLDER" -mindepth 1 -maxdepth 1 -type l)
  while IFS= read -r app; do
    id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Contents/Info.plist" 2>/dev/null)"
    for p in $NOC_LAUNCHER_PREFIX $LEGACY_BUNDLE_PREFIXES; do
      case "$id" in "$p".*) rm -rfx "$app"; break ;; esac
    done
  done < <(find "$FOLDER" -mindepth 1 -maxdepth 1 -type d -name '*.app')
  rm -f "$FOLDER/.DS_Store"   # Finder's view settings would keep the folder from being empty
  rmdir "$FOLDER" 2>/dev/null
fi
[ -L "$HOME/Desktop/$FOLDER_NAME" ] && [ "$(readlink "$HOME/Desktop/$FOLDER_NAME")" = "$FOLDER" ] && rm -f "$HOME/Desktop/$FOLDER_NAME"

# Empty mount points only; -x keeps rm from ever crossing into another file system.
[ -d "$D/mnt" ] && find "$D/mnt" -mindepth 1 -maxdepth 1 -type d -exec rmdir {} \; 2>/dev/null
rm -rfx "$D" 2>/dev/null
echo "Removed. To remove Cloudflare WARP as well, run:"
echo "  sudo \"/Applications/Cloudflare WARP.app/Contents/Resources/uninstall.sh\""
echo "and delete \"/Library/Application Support/Cloudflare/mdm.xml\" if this setup created it."
