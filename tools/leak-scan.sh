#!/bin/bash
# Refuses to publish anything that looks private. Scans tracked files and the whole
# git history for:
#   - addresses outside the documentation ranges (IPv4 and MAC),
#   - e-mail addresses outside example domains and GitHub no-reply addresses,
#   - private key material,
#   - every pattern in your own list (one per line, case-insensitive), kept OUTSIDE the
#     repository: $NOC_LEAK_PATTERNS or ~/.config/nas-on-click/forbidden-patterns.txt
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1
LIST="${NOC_LEAK_PATTERNS:-$HOME/.config/nas-on-click/forbidden-patterns.txt}"
found=0
report() { echo "leak-scan: $1"; found=1; }

content() { git ls-files -z | xargs -0 cat 2>/dev/null; git log -p --all 2>/dev/null; git log --all --format='%an %ae %cn %ce %B' 2>/dev/null; }

ips="$(content | perl -ne 'print "$&\n" while /(?<![\d.])(?:\d{1,3}\.){3}\d{1,3}(?![\d.])/g' | sort -u \
  | grep -Ev '^(192\.0\.2\.|198\.51\.100\.|203\.0\.113\.|127\.0\.0\.1$|0\.0\.0\.0$)')"
[ -n "$ips" ] && report "IPv4 addresses outside documentation ranges: $(echo "$ips" | tr '\n' ' ')"

macs="$(content | perl -ne 'while (/(?<![0-9A-Fa-f:])(?:[0-9A-Fa-f]{1,2}:){5}[0-9A-Fa-f]{1,2}(?![0-9A-Fa-f:])/g) { print join(":", map { sprintf "%02x", hex } split /:/, $&), "\n" }' | sort -u | grep -v '^00:00:5e:00:53:')"
[ -n "$macs" ] && report "MAC addresses outside the documentation range: $(echo "$macs" | tr '\n' ' ')"

mails="$(content | perl -ne 'print lc($&), "\n" while /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g' | sort -u \
  | grep -Ev '@(example\.(com|org|net)|users\.noreply\.github\.com)$')"
[ -n "$mails" ] && report "e-mail addresses: $(echo "$mails" | tr '\n' ' ')"

content | grep -q -- '-----BEGIN [A-Z ]*PRIVATE KEY-----' && report "private key material"

if [ -f "$LIST" ]; then
  hits="$(content | grep -ioF -f <(grep -v '^[[:space:]]*$' "$LIST" | grep -v '^#') | tr 'A-Z' 'a-z' | sort -u)"
  [ -n "$hits" ] && report "forbidden patterns: $(echo "$hits" | tr '\n' ' ')"
else
  echo "leak-scan: note - no private pattern list at $LIST"
fi

[ $found = 0 ] && echo "leak-scan: clean"
exit $found
