/* A Shell gives 4 KB of stack; libnix's startup sets this much up instead.
 * wxWidgets' event handling and Gambit's game-tree walks nest deeply.
 * Copyright (c) 2026 AmiCradle Team. GPL-2 or later, like Gambit. */
unsigned long __stack = 512 * 1024;
static const char version[] __attribute__((used)) = "$VER: Gambit 17.0.0-beta.3 Amiga (16.11.2026)";
