#!/usr/bin/env python3
"""Fallback runner for tools/run-tests.sh when no system Lua 5.1 is installed.

Uses lupa's bundled Lua 5.1 (pip install --break-system-packages lupa).
  run_lua_tests.py --syntax FILE...   syntax-check Lua files (like luac -p)
  run_lua_tests.py TEST...            run each test file in a fresh Lua state

Run from the repo root (run-tests.sh does this). Tests call os.exit(); inside lupa that
would kill Python, so os.exit is replaced by an error that carries the exit code.
Exit status is non-zero if any file fails.
"""
import sys

try:
    import lupa
except ImportError:
    sys.stderr.write("lupa not found (try: pip install --break-system-packages lupa)\n")
    sys.exit(2)


def new_lua():
    try:
        from lupa.lua51 import LuaRuntime  # explicit Lua 5.1 build when lupa ships one
    except ImportError:
        from lupa import LuaRuntime
    lua = LuaRuntime(unpack_returned_tuples=True)
    if not str(lua.eval("_VERSION")).endswith("5.1"):
        sys.stderr.write("warning: lupa's Lua is %s, not 5.1\n" % lua.eval("_VERSION"))
    return lua


def syntax(path):
    lua = new_lua()
    ok, err = lua.eval("function(p) local f, e = loadfile(p); return f ~= nil, e end")(path)
    if not ok:
        print("syntax error: %s: %s" % (path, err))
        return False
    return True


RUN = """
function(path)
  local realexit = os.exit
  os.exit = function(code)
    io.stdout:flush()
    if code == true or code == nil then code = 0 elseif code == false then code = 1 end
    error({ exit = code }, 0)
  end
  local ok, err = xpcall(function() dofile(path) end, function(e)
    if type(e) == "table" then return e end
    return debug.traceback(tostring(e), 2)
  end)
  io.stdout:flush()
  if ok then return 0, "" end
  if type(err) == "table" and err.exit then return err.exit, "" end
  return 1, err
end
"""


def run(path):
    lua = new_lua()
    code, err = lua.eval(RUN)(path)
    sys.stdout.flush()
    if err:
        sys.stderr.write("lua: %s\n" % err)
    return code == 0


def main(argv):
    if argv and argv[0] == "--syntax":
        results = [syntax(p) for p in argv[1:]]
    else:
        results = [run(p) for p in argv]
    return 0 if all(results) else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
