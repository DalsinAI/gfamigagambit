# Gambit for GFOS

[Gambit](https://www.gambit-project.org/), the game theory software, as its
GUI for GFOS (AmigaOS 3.2.3 with GFOpenUp) on the GFOpenWX Toolkit: build
extensive (game tree) and strategic (table) games, then find their Nash
equilibria and quantal response paths with Gambit's own solvers.

- 68040, soft float with the FPU taken when there is one (fpuauto).
- Gambit 17.0.0-beta.3 is fetched at the commit `gambit.lock` pins; nothing
  third-party is kept here. Its GUI runs every solver in-process on a
  wxThread, so no gambit-* command programs are needed.
- The sources come from Gambit's own `Makefile.am`
  (`scripts/gambit-sources.sh`); the libraries go into one archive so only
  what the GUI calls is linked.
- `compat/gbt_amiga_mutex.h` gives `std::mutex` on the AmigaOS pthread
  library when the C++ library has no threads of its own.

## Build

    STOVE=~/AmiCradle/stoves/os32-gcc16-open6 OUT=out ./build-amiga.sh

`out/Parts/Gambit` is a GFOpenUp part:

    GFOpenUpTool INSTALL Parts/Gambit

It puts Gambit in `SYS:Utilities/Gambit` and Gambit's example games in
`SYS:Utilities/Gambit/Games`.

## Tests

    make -C tests test

Host tests for the mutex (two threads, lock_guard, unique_lock), the source
list and the Part file.

## Licence

Gambit: GNU GPL version 2 or later, The Gambit Project. This port: the same,
Copyright (c) 2026 AmiCradle Team.

Designed, tested and delivered by The AmiCradle Team.
