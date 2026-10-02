#!/usr/bin/env bash
# Runs the Ready Macros tests outside the game. Needs Lua 5.1 (lua5.1 or lua).
# These use a simulated client (tools/tests/wowmock.lua): they check the addon's logic,
# not how it looks or behaves in the real game.
set -u
cd "$(dirname "$0")/.."
LUA=$(command -v lua5.1 || command -v lua || true)
[ -n "$LUA" ] || { echo "Lua 5.1 not found (try: apt-get install lua5.1)" >&2; exit 1; }
fail=0
for f in *.lua; do luac5.1 -p "$f" 2>/dev/null || "$LUA" -e "assert(loadfile('$f'))" || { echo "syntax error: $f"; fail=1; }; done
for t in tools/tests/test_*.lua; do "$LUA" "$t" || fail=1; done
[ $fail -eq 0 ] && echo "All tests passed." || echo "Some tests FAILED."
exit $fail
