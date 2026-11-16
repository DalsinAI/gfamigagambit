#!/bin/sh
# Lists the C++ sources the Gambit GUI is built from, read from Gambit's own
# Makefile.am: the core, games and solver libraries and the GUI (src/core,
# src/games, src/solvers, src/gui), once each, in order. The command-line
# tools and pygambit are left out.
#   gambit-sources.sh <Makefile.am>
# Copyright (c) 2026 AmiCradle Team. GPL-2 or later, like Gambit.
set -eu
grep -oE 'src/(core|games|solvers|gui)/[A-Za-z0-9_./-]+\.cc' "$1" | awk '!seen[$0]++'
