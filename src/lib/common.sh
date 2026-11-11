# shellcheck shell=bash disable=SC2034
# Helpers shared by install.sh, agent.sh and uninstall.sh.
# Expects noc_load_config and noc_load_lang to have run.

WARP_CLI=/usr/local/bin/warp-cli
ME="$(id -un)"
D="$NOC_DIR"
APP="$D/app"
LOG="$D/agent.log"

noc_log() { echo "$(date '+%F %T') $*" >> "$LOG"; }

# --- Dialogs ------------------------------------------------------------------
# Text is passed through environment variables (read back with printenv) so that
# quotes and non-ASCII letters in messages can never break the AppleScript.

# noc_alert MESSAGE [stop|caution|note] [timeout-seconds]
noc_alert() {
  local giving=""
  [ -n "${3:-}" ] && giving="giving up after $3"
  NOC_MSG="$1" NOC_TITLE="$APP_NAME" NOC_B1="$L_BTN_OK" osascript \
    -e 'activate' \
    -e "display dialog (do shell script \"printenv NOC_MSG\") buttons {(do shell script \"printenv NOC_B1\")} default button 1 $giving with title (do shell script \"printenv NOC_TITLE\") with icon ${2:-caution}" \
    </dev/null >/dev/null 2>&1
}

# noc_choose MESSAGE BUTTON1 BUTTON2 [timeout] [icon]
# BUTTON2 is the default (Return). Prints the chosen button; prints nothing when the
# dialog timed out or was closed.
noc_choose() {
  local giving=""
  [ -n "${4:-}" ] && giving="giving up after $4"
  NOC_MSG="$1" NOC_TITLE="$APP_NAME" NOC_B1="$2" NOC_B2="$3" osascript \
    -e 'activate' \
    -e "set r to display dialog (do shell script \"printenv NOC_MSG\") buttons {(do shell script \"printenv NOC_B1\"), (do shell script \"printenv NOC_B2\")} default button 2 $giving with title (do shell script \"printenv NOC_TITLE\") with icon ${5:-note}" \
    -e 'set g to false' -e 'try' -e 'set g to gave up of r' -e 'end try' \
    -e 'if g then return ""' -e 'return button returned of r' \
    </dev/null 2>/dev/null
}

# noc_ask_text MESSAGE DEFAULT HIDDEN(yes|no) [timeout] [icon] [ok-label]
# Prints the text entered; returns 1 when cancelled or timed out.
noc_ask_text() {
  local hidden="" giving=""
  [ "$3" = yes ] && hidden="with hidden answer"
  [ -n "${4:-}" ] && giving="giving up after $4"
  NOC_MSG="$1" NOC_DEF="$2" NOC_TITLE="$APP_NAME" NOC_B1="$L_BTN_CANCEL" NOC_B2="${6:-$L_BTN_OK}" osascript \
    -e 'activate' \
    -e "set r to display dialog (do shell script \"printenv NOC_MSG\") default answer (do shell script \"printenv NOC_DEF\") $hidden buttons {(do shell script \"printenv NOC_B1\"), (do shell script \"printenv NOC_B2\")} default button 2 cancel button 1 $giving with title (do shell script \"printenv NOC_TITLE\") with icon ${5:-note}" \
    -e 'set g to false' -e 'try' -e 'set g to gave up of r' -e 'end try' \
    -e 'if g then error number -128' -e 'return text returned of r' \
    </dev/null 2>/dev/null
}

# noc_notify MESSAGE [TITLE]
noc_notify() {
  NOC_MSG="$1" NOC_TITLE="${2:-$APP_NAME}" osascript \
    -e 'display notification (do shell script "printenv NOC_MSG") with title (do shell script "printenv NOC_TITLE")' \
    </dev/null >/dev/null 2>&1
}

# --- Locks ------------------------------------------------------------------------
# noc_lock DIR NAME-IN-COMMAND: take a lock directory. A lock is only treated as stale
# when its owner is gone; a lock without a pid yet is stale only after 30 seconds
# (closes the gap between creating the directory and writing the pid).
noc_lock() {
  local dir="$1" pattern="$2" holder age
  mkdir "$dir" 2>/dev/null && { echo $$ > "$dir/pid"; return 0; }
  holder="$(cat "$dir/pid" 2>/dev/null)"
  if [ -n "$holder" ]; then
    ps -p "$holder" -o command= 2>/dev/null | grep -q "$pattern" && return 1
  else
    age=$(( $(date +%s) - $(stat -f %m "$dir" 2>/dev/null || echo 0) ))
    [ "$age" -lt 30 ] && return 1
  fi
  rm -rf "$dir"
  mkdir "$dir" 2>/dev/null && { echo $$ > "$dir/pid"; return 0; }
  return 1
}

# --- Text helpers ---------------------------------------------------------------
noc_enc() { printf '%s' "$1" | perl -pe 's/([^A-Za-z0-9._~-])/sprintf("%%%02X",ord($1))/ge'; }
noc_nfc() { printf '%s' "$1" | perl -CS -MUnicode::Normalize -pe '$_ = NFC($_)'; }
noc_xml() { printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'; }

# User name as stored in the Keychain item (handles the hex form used for non-ASCII names).
noc_keychain_account() {
  security find-generic-password -s "$KEYCHAIN_SERVICE" 2>/dev/null | perl -ne '
    if (/"acct"<blob>=0x([0-9A-Fa-f]+)/) { print pack("H*", $1); exit }
    if (/"acct"<blob>="(.*)"\s*$/)      { print $1; exit }'
}

# --- Where are we? -----------------------------------------------------------------
noc_has_office() { [ -n "$OFFICE_HOST" ]; }
noc_has_remote() { [ -n "$REMOTE_HOST" ]; }

noc_on_office_subnet() {
  noc_has_office && ifconfig 2>/dev/null | grep -qF "inet $OFFICE_SUBNET_PREFIX"
}

# True only when the default gateway is the office router: same address, same MAC
# (from the ARP cache, so no packets are sent and no Local Network prompt appears).
noc_in_office() {
  local gw mac
  noc_has_office || return 1
  gw="$(route -n get default 2>/dev/null | awk '/gateway:/ { print $2; exit }')"
  [ "$gw" = "$OFFICE_GATEWAY" ] || return 1
  noc_on_office_subnet || return 1
  mac="$(arp -n "$OFFICE_GATEWAY" 2>/dev/null | awk '{ print $4; exit }')"
  [ -n "$mac" ] && [ "$(noc_norm_mac "$mac")" = "$OFFICE_GATEWAY_MAC" ]
}

noc_warp_org() {
  [ -x "$WARP_CLI" ] || return 1
  "$WARP_CLI" --accept-tos registration show 2>/dev/null | awk -F': *' '/^Organization:/ { gsub(/[[:space:]]+$/, "", $2); print $2; exit }'
}
noc_warp_enrolled()  { noc_has_remote && [ "$(noc_warp_org)" = "$WARP_TEAM" ]; }
noc_warp_connected() { noc_warp_enrolled && "$WARP_CLI" --accept-tos status 2>/dev/null | grep -q "Connected"; }
noc_remote_ok()      { noc_warp_connected && nc -z -G 4 "$REMOTE_HOST" 445 2>/dev/null; }

# Is the given NAS address usable from where the Mac is right now?
noc_reachable() {
  if [ "$1" = "$OFFICE_HOST" ]; then noc_in_office; else noc_remote_ok; fi
}

# --- Mounted shares ---------------------------------------------------------------
# This user's SMB mounts of the NAS, one per line: address<TAB>mount point<TAB>share name (NFC)
noc_mounts() {
  mount | grep -F "mounted by $ME)" | NOC_HOSTS="$OFFICE_HOST $REMOTE_HOST" perl -MUnicode::Normalize -ne '
    BEGIN { binmode STDOUT, ":utf8"; %h = map { $_ => 1 } split " ", $ENV{NOC_HOSTS} }
    next unless m{^//[^@ ]*@([0-9.]+)/(\S+) on (/.*) \(smbfs};
    next unless $h{$1};
    my ($a, $s, $m) = ($1, $2, $3);
    $s =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge;
    utf8::decode($s); utf8::decode($m);
    print "$a\t$m\t", NFC($s), "\n";'
}

# address<TAB>mount point of a share, or nothing when it is not mounted
noc_mount_of() {
  local want
  want="$(noc_nfc "$1")"
  noc_mounts | awk -F'\t' -v w="$want" '$3 == w { print $1 "\t" $2; exit }'
}
