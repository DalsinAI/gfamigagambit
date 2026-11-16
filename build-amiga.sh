#!/bin/sh
# Builds Gambit (the game theory GUI) for GFOS (AmigaOS 3.2.3 with GFOpenUp,
# on the GFOpenKick ROM or a Kickstart) with a stove: 68040, soft float with
# the FPU taken when there is one (fpuauto), on the GFOpenWX Toolkit.
#   STOVE=.../stoves/os32-gcc16-open6 OUT=out ./build-amiga.sh
#   (WXT_SRC=... to use a toolkit tree already on disk)
# Gambit, the toolkit and fpuauto are fetched at the commits gambit.lock
# gives; nothing third-party is kept here. The build tree is kept, so a run
# that stops at BUDGET_TOTAL seconds goes on next time.
# OUT gets Parts/Gambit: a GFOpenUp part (its Part file and the files it puts
# in SYS:Utilities/Gambit), installed with
#   GFOpenUpTool INSTALL Parts/Gambit
# Copyright (c) 2026 AmiCradle Team. GPL-2 or later, like Gambit.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/gambit.lock"
STOVE=${STOVE:-"$HOME/AmiCradle/stoves/os32-gcc16-open6"}
# outside the checkout: Cradle cleans it (git clean -ffdx) before every job
WORK="${WORK:-$HOME/.cache/gfamigagambit/build}"; OUT="${OUT:-$WORK/out}"; JOBS=${JOBS:-12}
TC="$STOVE/prefix"; PATH="$TC/bin:$PATH"; export PATH
mkdir -p "$WORK/deps" "$OUT"; OUT=$(cd "$OUT" && pwd)
t0=$(date +%s)
BUDGET=${BUDGET_TOTAL:-840}
left() { echo $(( BUDGET - ($(date +%s) - t0) )); }

# a repository at one commit, fetched once (SPARSE: only those folders)
fetch() {
    d="$WORK/deps/$1"
    if [ "$(git -C "$d" rev-parse HEAD 2>/dev/null)" != "$3" ]; then
        rm -rf "${d:?}"; mkdir -p "$d"
        git -C "$d" init -q
        if [ -n "${4:-}" ]; then
            git -C "$d" config core.sparseCheckout true
            echo "$4" > "$d/.git/info/sparse-checkout"
            git -C "$d" fetch -q --depth 1 --filter=blob:none "$2" "$3"
        else
            git -C "$d" fetch -q --depth 1 "$2" "$3"
        fi
        git -C "$d" checkout -q FETCH_HEAD
        [ "$(git -C "$d" rev-parse HEAD)" = "$3" ] || { echo "$1: commit mismatch"; exit 1; }
    fi
}

# --- the toolkit's SDK, again only when its tree changed ---------------------
if [ -z "${WXT_SRC:-}" ]; then fetch gfopenwxtoolkit "$WXT_REPO" "$WXT_COMMIT"; WXT_SRC="$WORK/deps/gfopenwxtoolkit"; fi
WXB="$WORK/gfopenwx"
WXREV=$( (git -C "$WXT_SRC" rev-parse HEAD 2>/dev/null; git -C "$WXT_SRC" diff HEAD 2>/dev/null) | sha256sum | cut -c1-16)
if [ ! -x "$WXB/out/sdk/bin/wx-config" ] || [ "$(cat "$WXB/out/.rev" 2>/dev/null)" != "$WXREV" ]; then
    # stopped here, before Cradle's own cap, so the log says how far it got
    set +e
    STOVE="$STOVE" WORK="$WXB" OUT="$WXB/out" JOBS=$JOBS timeout "$BUDGET" sh "$WXT_SRC/build-amiga.sh" > "$WORK.wx.log" 2>&1
    rc=$?
    set -e
    if [ "$rc" = 124 ]; then
        echo "toolkit: out of time after $(( $(date +%s) - t0 )) s, run again to go on"
        echo "  base objects: $(find "$WXB/base" -name '*.o' 2>/dev/null | wc -l), GUI objects: $(find "$WXB/gui/obj" -name '*.o' 2>/dev/null | wc -l)"
        tail -5 "$WORK.wx.log"
        exit 0
    fi
    [ "$rc" = 0 ] || { tail -40 "$WORK.wx.log"; exit 1; }
    [ -x "$WXB/out/sdk/bin/wx-config" ] || { tail -40 "$WORK.wx.log"; echo "no toolkit SDK"; exit 1; }
    echo "$WXREV" > "$WXB/out/.rev"
fi
echo "toolkit: $(( $(date +%s) - t0 )) s"
WXC="$WXB/out/sdk/bin/wx-config"

# --- fpuauto: libfpuauto.a and its link specs ---------------------------------
fetch fpuauto "$FPA_REPO" "$FPA_COMMIT" "/common/fpuauto/"
FA="$WORK/deps/fpuauto/common/fpuauto"; FAL="$WORK/fpuauto"
if [ ! -f "$FAL/libfpuauto.a" ] || [ "$(cat "$FAL/.rev" 2>/dev/null)" != "$FPA_COMMIT" ]; then
    rm -rf "$FAL"; mkdir -p "$FAL/obj"
    m68k-amigaos-gcc -m68040 -DFPUAUTO_COMMON -c "$FA/fpuauto.S" -o "$FAL/obj/fa_common.o"
    for n in $(sed 's/^--wrap=//' "$FA/fpuauto.wraps"); do
        m68k-amigaos-gcc -m68040 -DR_$n -c "$FA/fpuauto.S" -o "$FAL/obj/fa_$n.o"
    done
    m68k-amigaos-ar rcs "$FAL/libfpuauto.a" "$FAL"/obj/fa_*.o
    echo "$FPA_COMMIT" > "$FAL/.rev"
fi
LINK="-noixemul -m68040 -specs=$HERE/scripts/m68k-soft-m68040.specs -specs=$FA/fpuauto.specs -L$FAL"

# --- Gambit at its pinned commit (no patches: the AmigaOS pieces are forced
# in from compat/) ------------------------------------------------------------
SRC="$WORK/gambit"
if [ "$(cat "$SRC/.fetched" 2>/dev/null)" != "$GAMBIT_COMMIT" ]; then
    rm -rf "$SRC"; mkdir -p "$SRC"
    git -C "$SRC" init -q
    git -C "$SRC" fetch -q --depth 1 "$GAMBIT_GIT" "$GAMBIT_COMMIT"
    git -C "$SRC" checkout -q FETCH_HEAD
    [ "$(git -C "$SRC" rev-parse HEAD)" = "$GAMBIT_COMMIT" ] || { echo "commit mismatch"; exit 1; }
    echo "$GAMBIT_COMMIT" > "$SRC/.fetched"
    rm -rf "$WORK/obj"
fi

# objects made against another toolkit commit or another compat/ go: those
# headers are not in the compile rules, and stale objects crash at start
OBJREV="$WXT_COMMIT-$(cat "$HERE"/compat/*.h | sha256sum | cut -c1-16)"
if [ "$(cat "$WORK/.objs" 2>/dev/null)" != "$OBJREV" ]; then
    rm -rf "$WORK/obj"
    echo "$OBJREV" > "$WORK/.objs"
fi

LATE=""
if m68k-amigaos-gcc -fno-late-combine-instructions -S -o /dev/null -x c /dev/null 2>/dev/null; then LATE="-fno-late-combine-instructions"; fi
CF="-noixemul -m68040 -O2 -fno-delete-null-pointer-checks $LATE -DNDEBUG"

# Gambit's sources, from its own Makefile.am: the libraries, then the GUI
SOURCES=$(sh "$HERE/scripts/gambit-sources.sh" "$SRC/Makefile.am")
[ -n "$SOURCES" ] || { echo "no sources found in Makefile.am"; exit 1; }
O="$WORK/obj"; mkdir -p "$O"
objname() { echo "$1" | sed 's|^src/||; s|/|_|g; s|\.cc$|.o|'; }
for f in $SOURCES; do o="$O/$(objname "$f")"; [ -f "$o" ] || echo "$f"; done > "$O/todo"

# --- compile: each source once; what is made stays for the next run ----------
CC_FLAGS="$CF -std=gnu++20 $("$WXC" --cxxflags) -include $HERE/compat/gbt_amiga_mutex.h -I$SRC/src -DVERSION=\"$GAMBIT_VERSION\" -Wno-deprecated-declarations"
export CC_FLAGS O SRC
if [ -s "$O/todo" ]; then
    l=$(left)
    [ "$l" -gt 60 ] || { echo "out of time: run again to go on ($(wc -l < "$O/todo") files left)"; exit 0; }
    set +e
    # shellcheck disable=SC2016
    timeout "$l" xargs -P "$JOBS" -I{} sh -c '
        o="$O/$(echo "$1" | sed "s|^src/||; s|/|_|g; s|\.cc\$|.o|")"
        nice -n 19 m68k-amigaos-g++ $CC_FLAGS -c "$SRC/$1" -o "$o.tmp" > "${o%.o}.log" 2>&1 && mv "$o.tmp" "$o"' _ {} < "$O/todo"
    rc=$?
    set -e
    for f in $(cat "$O/todo"); do
        o="$O/$(objname "$f")"
        [ -f "$o" ] || { echo "== $f"; grep -E 'error' "${o%.o}.log" 2>/dev/null | head -12; }
    done
    if [ "$rc" = 124 ]; then echo "out of time: run again to go on"; echo "compile: $(( $(date +%s) - t0 )) s"; exit 0; fi
    [ "$rc" = 0 ] || { echo "compile failed"; exit 1; }
fi
m68k-amigaos-gcc $CF -c "$HERE/compat/amiga_stack.c" -o "$O/amiga_stack.o"
echo "compile: $(( $(date +%s) - t0 )) s"

# --- the libraries as one archive, so only what the GUI calls is linked ------
LIBOBJS=""; GUIOBJS=""
for f in $SOURCES; do
    case "$f" in src/gui/*) GUIOBJS="$GUIOBJS $O/$(objname "$f")" ;; *) LIBOBJS="$LIBOBJS $O/$(objname "$f")" ;; esac
done
rm -f "$O/libgambit.a"
# shellcheck disable=SC2086
m68k-amigaos-ar rcs "$O/libgambit.a" $LIBOBJS

# --- the link: soft-float specs, then fpuauto's ------------------------------
# shellcheck disable=SC2046,SC2086
m68k-amigaos-g++ $LINK -o "$O/Gambit.debug" $GUIOBJS "$O/amiga_stack.o" "$O/libgambit.a" \
    $("$WXC" --libs std) > "$O/link.log" 2>&1 || { head -60 "$O/link.log"; exit 1; }

# --- the GFOpenUp part: Parts/Gambit ------------------------------------------
P="$OUT/Parts/Gambit"; D="$P/Utilities/Gambit"; rm -rf "$P"; mkdir -p "$D/Games"
m68k-amigaos-strip -o "$D/Gambit" "$O/Gambit.debug"
# the example games: extensive (.efg), strategic (.nfg) and action-graph (.agg, .bagg)
cp "$SRC"/contrib/games/*.efg "$SRC"/contrib/games/*.nfg "$SRC"/contrib/games/*.agg "$SRC"/contrib/games/*.bagg "$D/Games/" 2>/dev/null || true
cp "$SRC/COPYING" "$D/COPYING.txt"
sh "$HERE/scripts/write-part.sh" "$P" "$GAMBIT_VERSION"
ls -l "$D/Gambit"
echo "part: $(grep -c '^copy' "$P/Part") files ($(ls "$D/Games" | wc -l) games), $(du -sk "$P" | cut -f1) KB"
echo "fpuauto: $(m68k-amigaos-nm "$O/Gambit.debug" | grep -c ' T ___wrap_') wrapped routines"
echo "total: $(( $(date +%s) - t0 )) s"
