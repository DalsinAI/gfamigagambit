#!/bin/sh
# Host test for scripts/gambit-sources.sh on a Makefile.am shaped like
# Gambit's: wildcards, headers, the tools and pygambit stay out, each source
# once, in order.
# Copyright (c) 2026 AmiCradle Team. GPL-2 or later, like Gambit.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cat > "$T/Makefile.am" <<'MK'
EXTRA_DIST = src/core/*.cc src/games/*/*.cc
core_SOURCES = \
	src/core/integer.cc \
	src/core/function.h
game_SOURCES = \
	src/games/game.cc \
    src/games/agg/trie_map.cc
bimatrix_SOURCES = \
	src/solvers/linalg/lpsolve.cc \
	src/solvers/enummixed/enummixed.h
tool_SOURCES = src/tools/enumpure/enumpure.cc src/pygambit/gambit.cc
again_SOURCES = src/core/integer.cc
gambit_SOURCES = \
	src/gui/app.cc \
	src/gui/welcome.cc \
	src/gui/welcome.h
MK
sh "$HERE/../scripts/gambit-sources.sh" "$T/Makefile.am" > "$T/got"
cat > "$T/want" <<'W'
src/core/integer.cc
src/games/game.cc
src/games/agg/trie_map.cc
src/solvers/linalg/lpsolve.cc
src/gui/app.cc
src/gui/welcome.cc
W
if cmp -s "$T/got" "$T/want"; then echo "sources: all checks passed"; else echo "FAIL: sources"; diff "$T/want" "$T/got"; exit 1; fi
