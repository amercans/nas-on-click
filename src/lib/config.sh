# shellcheck shell=bash disable=SC2034
# Config loader: reads KEY=value lines into variables without executing anything.
# Only the keys listed in NOC_KEYS are accepted, and each value is validated.

NOC_KEYS="APP_NAME ORG_NAME SUPPORT_CONTACT LANGUAGE DATA_DIR BUNDLE_ID FOLDER_NAME
KEYCHAIN_SERVICE OFFICE_HOST OFFICE_GATEWAY OFFICE_GATEWAY_MAC OFFICE_SUBNET_PREFIX
REMOTE_HOST WARP_TEAM LOGIN_ACCOUNT EXCLUDE_SHARES USERNAME_UPPERCASE UPDATE_URL
INSTALLER_NAME LEGACY_LABELS LEGACY_BUNDLE_PREFIXES"

noc_config_error() { echo "config: $*" >&2; return 1; }

# Lower-case a MAC address and drop leading zeros per octet (the form `arp` prints).
noc_norm_mac() {
  printf '%s' "$1" | tr 'A-F' 'a-f' | awk -F: '{ for (i = 1; i <= NF; i++) { sub(/^0+/, "", $i); if ($i == "") $i = "0" } ; OFS=":"; $1=$1; print }'
}

noc_load_config() {
  local file="$1" line key val k known
  [ -f "$file" ] || { noc_config_error "file not found: $file"; return 1; }
  for k in $NOC_KEYS; do printf -v "$k" '%s' ""; done
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"
    line="${line#"${line%%[![:space:]]*}"}"
    case "$line" in ''|'#'*) continue ;; esac
    case "$line" in *=*) ;; *) noc_config_error "not a KEY=value line: $line"; return 1 ;; esac
    key="${line%%=*}"; val="${line#*=}"
    key="$(printf '%s' "$key" | tr -d '[:space:]')"
    val="${val#"${val%%[![:space:]]*}"}"; val="${val%"${val##*[![:space:]]}"}"
    case "$val" in \"*\") val="${val:1:${#val}-2}" ;; \'*\') val="${val:1:${#val}-2}" ;; esac
    known=0
    for k in $NOC_KEYS; do [ "$k" = "$key" ] && known=1 && break; done
    [ $known = 1 ] || { noc_config_error "unknown key: $key"; return 1; }
    case "$val" in *'"'*|*'\'*|*'%'*|*'$'*|*'`'*) noc_config_error "$key contains a forbidden character"; return 1 ;; esac
    printf -v "$key" '%s' "$val"
  done < "$file"
  noc_validate_config
}

noc_validate_config() {
  local ip='^([0-9]{1,3}\.){3}[0-9]{1,3}$' name
  [ -n "$APP_NAME" ] && [ ${#APP_NAME} -le 40 ] || { noc_config_error "APP_NAME must be 1-40 characters"; return 1; }
  [ -n "$ORG_NAME" ] || ORG_NAME="$APP_NAME"
  case "${LANGUAGE:-auto}" in auto|en|tr|de|fr|es|ru) LANGUAGE="${LANGUAGE:-auto}" ;; *) noc_config_error "LANGUAGE must be auto, en, tr, de, fr, es or ru"; return 1 ;; esac
  [[ $DATA_DIR =~ ^\.[A-Za-z0-9._-]+$ ]] || { noc_config_error "DATA_DIR must be a hidden folder name like .nas-on-click"; return 1; }
  [[ $BUNDLE_ID =~ ^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$ ]] || { noc_config_error "BUNDLE_ID must look like com.example.name"; return 1; }
  case "$FOLDER_NAME" in ''|.*|*/*) noc_config_error "FOLDER_NAME must be a plain folder name"; return 1 ;; esac
  [[ $KEYCHAIN_SERVICE =~ ^[A-Za-z0-9._-]+$ ]] || { noc_config_error "KEYCHAIN_SERVICE may only use letters, digits, . _ -"; return 1; }

  if [ -n "$OFFICE_HOST$OFFICE_GATEWAY$OFFICE_GATEWAY_MAC$OFFICE_SUBNET_PREFIX" ]; then
    [[ $OFFICE_HOST =~ $ip ]] && [[ $OFFICE_GATEWAY =~ $ip ]] || { noc_config_error "OFFICE_HOST and OFFICE_GATEWAY must be IPv4 addresses"; return 1; }
    [[ $OFFICE_GATEWAY_MAC =~ ^[0-9A-Fa-f]{1,2}(:[0-9A-Fa-f]{1,2}){5}$ ]] || { noc_config_error "OFFICE_GATEWAY_MAC must look like 00:00:5e:00:53:01"; return 1; }
    [[ $OFFICE_SUBNET_PREFIX =~ ^([0-9]{1,3}\.){1,3}$ ]] || { noc_config_error "OFFICE_SUBNET_PREFIX must look like 192.0.2."; return 1; }
    OFFICE_GATEWAY_MAC="$(noc_norm_mac "$OFFICE_GATEWAY_MAC")"
  fi
  if [ -n "$REMOTE_HOST$WARP_TEAM" ]; then
    [[ $REMOTE_HOST =~ $ip ]] || { noc_config_error "REMOTE_HOST must be an IPv4 address"; return 1; }
    [[ $WARP_TEAM =~ ^[a-z0-9-]+$ ]] || { noc_config_error "WARP_TEAM must be a Cloudflare team name"; return 1; }
  fi
  [ -n "$OFFICE_HOST$REMOTE_HOST" ] || { noc_config_error "set OFFICE_HOST, REMOTE_HOST or both"; return 1; }
  # The address tells the two routes apart (clean-up and forced unmounts rely on it).
  [ -z "$OFFICE_HOST" ] || [ "$OFFICE_HOST" != "$REMOTE_HOST" ] || { noc_config_error "OFFICE_HOST and REMOTE_HOST must differ"; return 1; }

  for name in $EXCLUDE_SHARES; do case "$name" in */*) noc_config_error "EXCLUDE_SHARES: bad name $name"; return 1 ;; esac; done
  case "${USERNAME_UPPERCASE:-no}" in yes|no) USERNAME_UPPERCASE="${USERNAME_UPPERCASE:-no}" ;; *) noc_config_error "USERNAME_UPPERCASE must be yes or no"; return 1 ;; esac
  if [ -n "$UPDATE_URL" ]; then
    [[ $UPDATE_URL =~ ^https://[A-Za-z0-9.-]+(/[A-Za-z0-9._~-]+)*/?$ ]] || { noc_config_error "UPDATE_URL must be an https URL"; return 1; }
    UPDATE_URL="${UPDATE_URL%/}"
  fi
  for name in $LEGACY_LABELS $LEGACY_BUNDLE_PREFIXES; do
    [[ $name =~ ^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$ ]] || { noc_config_error "legacy entry is not a bundle id: $name"; return 1; }
  done
  [ -n "$INSTALLER_NAME" ] || INSTALLER_NAME="$APP_NAME Setup"
  case "$INSTALLER_NAME" in */*|.*) noc_config_error "INSTALLER_NAME must be a plain name"; return 1 ;; esac

  # Derived values used everywhere
  NOC_DIR="$HOME/$DATA_DIR"
  NOC_AGENT_LABEL="$BUNDLE_ID"
  NOC_SLEEP_LABEL="$BUNDLE_ID.sleep"
  NOC_LAUNCHER_PREFIX="$BUNDLE_ID.open"
  return 0
}

# The Mac's preferred language if a translation exists, otherwise English.
noc_system_language() {
  local l
  l="$(defaults read -g AppleLanguages 2>/dev/null | sed -n '2p' | tr -d ' ",' | cut -c1-2)"
  case "$l" in en|tr|de|fr|es|ru) echo "$l" ;; *) echo en ;; esac
}

# Loads the language file that sits next to lib/. Must be called after noc_load_config.
# LANGUAGE=auto follows the Mac's language.
noc_load_lang() {
  local base="$1"
  [ "$LANGUAGE" = auto ] && LANGUAGE="$(noc_system_language)"
  # shellcheck source=/dev/null
  . "$base/lang/$LANGUAGE.sh" || return 1
  [ -n "$SUPPORT_CONTACT" ] || SUPPORT_CONTACT="$L_DEFAULT_SUPPORT"
  # shellcheck source=/dev/null
  . "$base/lang/$LANGUAGE.sh"
}
