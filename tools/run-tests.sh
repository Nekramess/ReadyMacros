#!/usr/bin/env bash
# Runs the Ready Macros tests outside the game. Needs Lua 5.1 (lua5.1 or lua); if neither is
# installed it falls back to python3 + lupa via tools/run_lua_tests.py
# (pip install --break-system-packages lupa).
# These use a simulated client (tools/tests/wowmock.lua): they check the addon's logic,
# not how it looks or behaves in the real game.
set -u
cd "$(dirname "$0")/.."
LUA=$(command -v lua5.1 || command -v lua || true)
fail=0
if [ -n "$LUA" ]; then
  for f in *.lua; do luac5.1 -p "$f" 2>/dev/null || "$LUA" -e "assert(loadfile('$f'))" || { echo "syntax error: $f"; fail=1; }; done
  for t in tools/tests/test_*.lua; do "$LUA" "$t" || fail=1; done
else
  PY=$(command -v python3 || true)
  if [ -z "$PY" ] || ! "$PY" -c "import lupa" 2>/dev/null; then
    echo "Lua 5.1 not found (try: apt-get install lua5.1, or pip install --break-system-packages lupa for the python3 fallback)" >&2
    exit 1
  fi
  echo "No system Lua found; using python3 + lupa (tools/run_lua_tests.py)."
  "$PY" tools/run_lua_tests.py --syntax *.lua || fail=1
  for t in tools/tests/test_*.lua; do "$PY" tools/run_lua_tests.py "$t" || fail=1; done
fi
[ $fail -eq 0 ] && echo "All tests passed." || echo "Some tests FAILED."
exit $fail
