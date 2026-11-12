# shellcheck shell=bash disable=SC2034
# Helpers shared by install.sh, agent.sh and uninstall.sh.
# Expects noc_load_config and noc_load_lang to have run.
#
# The NAS password never appears in a process's arguments or environment: it travels
# through pipes only (Keychain -> `security ... -g` -> stdin of the helper or of the
# expect script; `security -i` on stdin when it is saved).

# Tools are referenced through variables so the test suite can substitute them.
: "${WARP_CLI:=/usr/local/bin/warp-cli}"
: "${DISKUTIL:=/usr/sbin/diskutil}"
: "${SMBUTIL_EXP:=}"
ME="$(id -un)"
D="$NOC_DIR"
APP="$D/app"
LOG="$D/agent.log"

noc_log() { echo "$(date '+%F %T') $*" >> "$LOG"; }

# noc_timeout SECONDS COMMAND...: run COMMAND, killing it after SECONDS.
noc_timeout() { local s="$1"; shift; perl -e 'alarm shift; exec @ARGV' "$s" "$@"; }

# noc_fmt TEMPLATE VALUE...: replace each %s in TEMPLATE with the next VALUE.
# Used instead of printf so that text from the config can never act as a format.
noc_fmt() {
  local rest="$1" out="" v; shift
  for v in "$@"; do
    case "$rest" in *%s*) out="$out${rest%%\%s*}$v"; rest="${rest#*%s}" ;; esac
  done
  printf '%s' "$out$rest"
}

# --- Locks -----------------------------------------------------------------------------
# noc_locked LOCKFILE COMMAND...: run COMMAND holding an flock on LOCKFILE (lockf(1)).
# The kernel drops the lock when the process ends, so a crash never leaves a stale
# lock. Returns 75 at once when another process holds it.
noc_locked() { local f="$1"; shift; /usr/bin/lockf -s -t 0 "$f" "$@"; }

# --- Native dialogs ------------------------------------------------------------------
# The helper app shows the windows with the app's name and icon. The installer passes
# its own binary in NOC_UI before the helper exists.
noc_ui_bin() {
  if [ -x "$APP/Helper.app/Contents/MacOS/nas-on-click" ]; then echo "$APP/Helper.app/Contents/MacOS/nas-on-click"
  elif [ -n "${NOC_UI:-}" ] && [ -x "$NOC_UI" ]; then echo "$NOC_UI"
  else echo "$APP/bin/nas-on-click"; fi
}
noc_ui() { "$(noc_ui_bin)" ui --title "$APP_NAME" "$@" </dev/null 2>/dev/null; }

# noc_alert MESSAGE [note|caution|stop] [timeout]
noc_alert() { noc_ui --message "$1" --style "${2:-caution}" --button "$L_BTN_OK" ${3:+--timeout "$3"} >/dev/null; }

# noc_choose MESSAGE DEFAULT-BUTTON OTHER-BUTTON [timeout] [style]
# Prints the chosen button; nothing when the dialog timed out.
noc_choose() { noc_ui --message "$1" --style "${5:-note}" --button "$2" --button "$3" ${4:+--timeout "$4"}; }

# noc_ask_text MESSAGE DEFAULT secure|plain [timeout] [style] [ok-label]
# Prints the text; returns 1 when cancelled or timed out.
noc_ask_text() {
  local mode=--input
  [ "$3" = secure ] && mode=--secure
  noc_ui --message "$1" --style "${5:-note}" "$mode" --default "$2" \
    --button "${6:-$L_BTN_OK}" --button "$L_BTN_CANCEL" ${4:+--timeout "$4"}
}

# Progress window (installer): noc_status TEXT starts or updates it, noc_status_done closes it.
noc_status() {
  printf '%s\n' "$1" > "$D/status.tmp" && mv -f "$D/status.tmp" "$D/status"
  if [ -z "${NOC_PROGRESS_STARTED:-}" ]; then
    NOC_PROGRESS_STARTED=1
    "$(noc_ui_bin)" progress --title "$APP_NAME" --status-file "$D/status" </dev/null >/dev/null 2>&1 &
  fi
}
noc_status_done() { rm -f "$D/status"; }

# --- Text helpers -----------------------------------------------------------------------
noc_enc() { printf '%s' "$1" | perl -pe 's/([^A-Za-z0-9._~-])/sprintf("%%%02X",ord($1))/ge'; }
noc_nfc() { printf '%s' "$1" | perl -CS -MUnicode::Normalize -pe '$_ = NFC($_)'; }
noc_xml() { printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'; }

# User name as stored in the Keychain item (handles the hex form used for non-ASCII names).
noc_keychain_account() {
  security find-generic-password -s "$KEYCHAIN_SERVICE" 2>/dev/null | perl -ne '
    if (/"acct"<blob>=0x([0-9A-Fa-f]+)/) { print pack("H*", $1); exit }
    if (/"acct"<blob>="(.*)"\s*$/)      { print $1; exit }'
}
# Writes the stored password to stdout (for a pipe), or fails.
# `security -w` prints passwords that contain non-ASCII letters as hex, which cannot be
# told apart from a password that is itself hex. `-g` is unambiguous: it prints
#   password: "text"             for plain passwords, or
#   password: 0x<HEX>  "..."     for everything else (decoded here).
noc_password() {
  security find-generic-password -s "$KEYCHAIN_SERVICE" -a "$1" -g 2>&1 >/dev/null | perl -ne '
    if (/^password: 0x([0-9A-Fa-f]+)/) { print pack("H*", $1), "\n"; $ok = 1; last }
    if (/^password: "(.*)"$/)          { print "$1\n"; $ok = 1; last }
    END { exit($ok ? 0 : 1) }'
}
# noc_save_password ACCOUNT: reads a password from stdin and stores it.
# The item is created by /usr/bin/security itself, so later reads with `security -g`
# never prompt. The command goes to `security -i` on stdin with the password
# hex-encoded (-X): it never appears in arguments, and no quoting can break it.
noc_save_password() {
  local acct="$1" pw hex
  case "$acct$KEYCHAIN_SERVICE$APP_NAME" in *'"'*|*'\'*|*$'\n'*) return 1 ;; esac
  IFS= read -r pw || [ -n "$pw" ] || return 1
  [ -n "$pw" ] || return 1
  [ ${#pw} -le 1000 ] || return 1   # security -i reads lines of about 4 KB
  hex="$(printf '%s' "$pw" | xxd -p | tr -d '\n')"
  printf 'add-generic-password -U -s "%s" -a "%s" -l "%s" -X %s\n' "$KEYCHAIN_SERVICE" "$acct" "$APP_NAME" "$hex" \
    | security -i >/dev/null 2>&1
  local rc=${PIPESTATUS[1]}
  unset hex
  # Success only if security reported none and the item now holds exactly this password
  # (an update can fail on an item whose access list does not trust security).
  if [ "$rc" = 0 ] && [ "$(noc_password "$acct")" = "$pw" ]; then unset pw; return 0; fi
  unset pw
  return 1
}

# The share list returned by `smbutil view`, without names that could act as a path.
noc_parse_shares() {
  NOC_EXCLUDE="$EXCLUDE_SHARES" perl -CSD -ne '
    BEGIN { %x = map { $_ => 1 } (split(" ", $ENV{NOC_EXCLUDE}), q{IPC$}) }
    next unless /^(.+?)\s+Disk(\s|$)/;
    my $n = $1;
    next if $n =~ m{/} || $n =~ /\.\./ || $n =~ /^\./ || $x{$n};
    print "$n\n";'
}

# Trimmed, NFC; upper case when USERNAME_UPPERCASE=yes (dotless i, U+0131, stays lower).
noc_normalize_user() {
  NOC_UC="$USERNAME_UPPERCASE" perl -CSD -MUnicode::Normalize -e '
    local $/; my $t = NFC(scalar <STDIN> // ""); $t =~ s/^\s+|\s+$//g;
    if ($ENV{NOC_UC} eq "yes") { $t =~ s/\x{131}/\x{1}/g; $t = uc $t; $t =~ s/\x{1}/\x{131}/g }
    print $t' <<< "$1"
}

# --- Where are we? -------------------------------------------------------------------------
noc_has_office() { [ -n "$OFFICE_HOST" ]; }
# No default route at all: Wi-Fi off, cable out, airplane mode.
noc_offline() { ! route -n get default >/dev/null 2>&1; }
noc_has_remote() { [ -n "$REMOTE_HOST" ]; }

noc_on_office_subnet() {
  noc_has_office && ifconfig 2>/dev/null | grep -qF "inet $OFFICE_SUBNET_PREFIX"
}

# yes | no | unknown. "yes" needs the default gateway's address, its MAC address from
# the ARP cache (read only: no packets, no Local Network prompt) and the subnet.
# "unknown" = everything matches but there is no ARP entry yet (or it expired);
# an "(incomplete)" entry means the router did not answer: "no".
noc_office_state() {
  local gw mac
  noc_has_office || { echo no; return; }
  gw="$(route -n get default 2>/dev/null | awk '/gateway:/ { print $2; exit }')"
  [ "$gw" = "$OFFICE_GATEWAY" ] && noc_on_office_subnet || { echo no; return; }
  mac="$(arp -n "$OFFICE_GATEWAY" 2>/dev/null | awk '{ print $4; exit }')"
  case "$mac" in '') echo unknown; return ;; '(incomplete)') echo no; return ;; esac
  if [ "$(noc_norm_mac "$mac")" = "$OFFICE_GATEWAY_MAC" ]; then echo yes; else echo no; fi
}
noc_in_office() { [ "$(noc_office_state)" = yes ]; }

noc_warp_org() {
  [ -x "$WARP_CLI" ] || return 1
  "$WARP_CLI" --accept-tos registration show 2>/dev/null | awk -F': *' '/^Organization:/ { gsub(/[[:space:]]+$/, "", $2); print $2; exit }'
}
noc_warp_enrolled()  { noc_has_remote && [ "$(noc_warp_org)" = "$WARP_TEAM" ]; }
noc_warp_connected() { noc_warp_enrolled && "$WARP_CLI" --accept-tos status 2>/dev/null | grep -q "Connected"; }
noc_remote_ok()      { noc_warp_connected && nc -z -G 4 "$REMOTE_HOST" 445 2>/dev/null; }

# Route for a new mount: WARP first (the office values are not secret, see README).
noc_pick_host() {
  if noc_remote_ok; then echo "$REMOTE_HOST"
  elif noc_in_office; then echo "$OFFICE_HOST"
  else return 1; fi
}

# Should an existing mount of ADDRESS be kept? An expired ARP entry is not a reason
# to drop an office mount.
noc_still_reachable() {
  if [ "$1" = "$OFFICE_HOST" ]; then [ "$(noc_office_state)" != no ]; else noc_remote_ok; fi
}

# --- Mounted shares ------------------------------------------------------------------------
# This user's SMB mounts of the NAS, one per line: address<TAB>mount point<TAB>share (NFC)
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
