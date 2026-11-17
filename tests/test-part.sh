#!/bin/sh
# Host test for scripts/write-part.sh: the Part file GFOpenUpTool reads.
# Copyright (c) 2026 AmiCradle Team. GPL-2 or later, like Gambit.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir -p "$T/Utilities/Gambit/Games"
: > "$T/Utilities/Gambit/Gambit"; : > "$T/Utilities/Gambit/Games/poker.efg"; : > "$T/Utilities/Gambit/Games/pd.nfg"
sh "$HERE/../scripts/write-part.sh" "$T" 17.0.0-beta.3
fail=0
expect() { grep -qxF "$1" "$T/Part" || { echo "FAIL: no line: $1"; fail=1; }; }
expect 'part Gambit 17.0.0-beta.3'
expect 'needs 68040'
expect 'copy "Utilities/Gambit/Gambit" "SYS:Utilities/Gambit/Gambit"'
expect 'copy "Utilities/Gambit/Games/poker.efg" "SYS:Utilities/Gambit/Games/poker.efg"'
expect 'copy "Utilities/Gambit/Games/pd.nfg" "SYS:Utilities/Gambit/Games/pd.nfg"'
[ "$(head -1 "$T/Part")" = 'part Gambit 17.0.0-beta.3' ] || { echo "FAIL: first line"; fail=1; }
[ "$(grep -c '^copy' "$T/Part")" = 3 ] || { echo "FAIL: copy count (the Part file itself must not be listed)"; fail=1; }
sh "$HERE/../scripts/write-part.sh" "$T" 17.0.0-beta.3   # a second run: same file
[ "$(grep -c '^copy' "$T/Part")" = 3 ] || { echo "FAIL: second run lists the Part file"; fail=1; }
[ $fail = 0 ] && echo "Part file: all checks passed"
exit $fail
