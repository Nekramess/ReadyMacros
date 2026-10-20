-- Minimap button with a simulated client. Frames are fake; this checks logic, not looks.
-- The button is registered through the embedded LibDBIcon-1.0 (the real library files are
-- loaded here, not a stand-in), because minimap button managers flag any other minimap
-- button as "a custom button". Forever has no GetMinimapShape (minimap addons define it), so
-- every test treats it as an optional global. The Minimap mock is 140x140 centred at
-- (1000,500); LibDBIcon rides 5 outside the edge, so the radius is 75.
local T = dofile("tools/tests/wowmock.lua")
local function near(a, b) return math.abs(a - b) < 1e-6 end

local function fresh(db, shapeFn, files)
  T.install({ class = "WARRIOR" })
  ReadyMacrosDB = db
  GetMinimapShape = shapeFn
  local ns = T.load(files)
  T.fire("PLAYER_LOGIN")
  return ns, ns.minimap
end
local function rmac(arg) SlashCmdList.READYMACROS("minimap" .. (arg and (" " .. arg) or "")) end
local function lib() return LibStub("LibDBIcon-1.0") end
local function btn() return lib():GetMinimapButton("ReadyMacros") end
local function pos() local p = btn().lastPoint; return p[4], p[5] end
local function radius() local x, y = pos(); return math.sqrt(x * x + y * y) end

-- Hook sanity: the mock must not invent GetMinimapShape (Forever does not have it).
T.install({})
T.check(GetMinimapShape == nil, "mock leaves GetMinimapShape undefined, like Forever")

-- The toc loads the four libraries before the addon files
local files = T.tocFiles()
local idx = {}
for i, f in ipairs(files) do idx[f] = i end
T.check(idx["Libs/LibStub/LibStub.lua"] and idx["Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua"]
  and idx["Libs/LibDataBroker-1.1/LibDataBroker-1.1.lua"] and idx["Libs/LibDBIcon-1.0/LibDBIcon-1.0.lua"], "toc lists the four libraries")
T.check(idx["Libs/LibStub/LibStub.lua"] < idx["Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua"]
  and idx["Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua"] < idx["Libs/LibDataBroker-1.1/LibDataBroker-1.1.lua"]
  and idx["Libs/LibDataBroker-1.1/LibDataBroker-1.1.lua"] < idx["Libs/LibDBIcon-1.0/LibDBIcon-1.0.lua"]
  and idx["Libs/LibDBIcon-1.0/LibDBIcon-1.0.lua"] < idx["Minimap.lua"], "libraries load in dependency order, before Minimap.lua")

-- Registered through LibDBIcon, shown, anchored on the minimap edge
local ns, M = fresh(nil)
T.check(lib():IsRegistered("ReadyMacros"), "registered with LibDBIcon at PLAYER_LOGIN")
local obj = LibStub("LibDataBroker-1.1"):GetDataObjectByName("ReadyMacros")
T.check(obj and obj.type == "launcher" and obj.icon, "LibDataBroker launcher object with an icon")
local b = btn()
T.check(b and b:IsShown(), "button created and shown")
T.eq(b._name, "LibDBIcon10_ReadyMacros", "button is the one LibDBIcon built")
local pt = b.lastPoint
T.check(pt and pt[1] == "CENTER" and pt[2] == Minimap and pt[3] == "CENTER", "button anchored CENTER to the Minimap")
T.eq(ReadyMacrosDB.minimap.minimapPos, 215, "default angle 215 saved as minimapPos")
T.eq(ReadyMacrosDB.minimap.hide, false, "default: not hidden")
local x, y = pos()
T.check(near(x, 75 * math.cos(math.rad(215))) and near(y, 75 * math.sin(math.rad(215))), "default placement on the round edge")
T.check(near(radius(), 75), "round: button sits on the circle")

-- Regression for the reported "This is a custom button" message: Ready Macros must not
-- create any minimap-parented button of its own; every one is a LibDBIcon10_* button.
local custom = {}
for _, f in ipairs(T.frames) do
  if f._kind == "Button" and f._parent == Minimap and not tostring(f._name):find("^LibDBIcon10_") then custom[#custom + 1] = tostring(f._name) end
end
T.eq(#custom, 0, "no hand-built minimap button (" .. table.concat(custom, ",") .. ")")
T.check(rawget(_G, "ReadyMacrosMinimapButton") == nil, "old custom button frame is gone")

-- Shape: LibDBIcon follows GetMinimapShape (checked on the next placement)
ns, M = fresh({ minimap = { hide = false, minimapPos = 45 } })
T.check(near(radius(), 75), "angle 45, no shape fn: on the circle")
ns, M = fresh({ minimap = { hide = false, minimapPos = 45 } }, function() return "SQUARE" end)
x, y = pos()
T.check(x > 65 and y > 65 and x <= 75 and y <= 75 and radius() > 80, "angle 45, SQUARE: pushed toward the box corner")
ns, M = fresh({ minimap = { hide = false, minimapPos = 45 } }, function() return "CORNER-TOPRIGHT" end)
T.check(near(radius(), 75), "angle 45, CORNER-TOPRIGHT: top-right is round")

-- Settings from before the library: angle carries over, shape override is dropped
ns, M = fresh({ minimap = { hide = true, angle = 123, shape = "square" } })
T.eq(ReadyMacrosDB.minimap.minimapPos, 123, "old angle becomes minimapPos")
T.eq(ReadyMacrosDB.minimap.angle, nil, "old angle key removed")
T.eq(ReadyMacrosDB.minimap.shape, nil, "old shape key removed")
T.eq(ReadyMacrosDB.minimap.hide, true, "old hidden flag kept")
T.check(not btn():IsShown(), "old hidden setting keeps the button hidden")
ns, M = fresh({ minimap = { hide = false, angle = "junk" } })
T.eq(ReadyMacrosDB.minimap.minimapPos, 215, "unusable old angle: default")
ns, M = fresh({ minimap = "garbage" })
T.eq(ReadyMacrosDB.minimap.minimapPos, 215, "non-table settings replaced by defaults")

-- /rmac minimap
ns, M = fresh(nil)
b = btn()
rmac("off")
T.check(not b:IsShown() and ReadyMacrosDB.minimap.hide == true, "off hides and saves")
T.check(T.lastPrint():find("hidden", 1, true), "off says hidden")
rmac("on")
T.check(b:IsShown() and ReadyMacrosDB.minimap.hide == false, "on shows and saves")
T.check(T.lastPrint():find("shown", 1, true), "on says shown")
rmac()
T.check(not b:IsShown() and ReadyMacrosDB.minimap.hide == true, "bare toggle hides")
rmac()
T.check(b:IsShown() and ReadyMacrosDB.minimap.hide == false, "bare toggle shows")
rmac("HIDE"); T.check(not b:IsShown(), "hide alias, case-insensitive")
rmac("show"); T.check(b:IsShown(), "show alias")
rmac("bogus"); T.check(not b:IsShown(), "unknown argument toggles")
rmac("on")
rmac("square")                                   -- retired argument: just toggles, never errors
T.check(not b:IsShown(), "retired shape argument toggles like any unknown argument")
rmac("on")

-- Saved variables round trip (simulated reload)
rmac("off")
ReadyMacrosDB.minimap.minimapPos = 123
local saved = ReadyMacrosDB
ns, M = fresh(saved)
T.check(not btn():IsShown(), "hidden setting survives reload")
T.eq(ReadyMacrosDB.minimap.minimapPos, 123, "angle survives reload")
rmac("on")
b = btn()
T.check(b:IsShown(), "on after reload shows the button")
x, y = pos()
T.check(near(x, 75 * math.cos(math.rad(123))) and near(y, 75 * math.sin(math.rad(123))), "saved angle used for placement")

-- Click toggles the window; drag saves the angle
ns, M = fresh(nil)
b = btn()
local win = ReadyMacrosFrame
local was = win:IsShown()
b._scripts.OnClick(b, "LeftButton")
T.check(win:IsShown() ~= was, "click toggles the window")
b._scripts.OnClick(b, "LeftButton")
T.check(win:IsShown() == was, "second click toggles it back")
T.check(b._scripts.OnDragStart and b._scripts.OnDragStop, "drag scripts set (button is not locked)")

T.cursor = { 1000, 600 }                         -- straight up from the minimap centre (1000,500)
b._scripts.OnDragStart(b)
T.check(b._scripts.OnUpdate ~= nil, "drag start installs OnUpdate")
b._scripts.OnUpdate(b)
T.check(near(ReadyMacrosDB.minimap.minimapPos, 90), "drag saves angle 90 (cursor above centre)")
x, y = pos(); T.check(near(x, 0) and near(y, 75), "button follows the cursor to the top")
T.cursor = { 900, 500 }
b._scripts.OnUpdate(b)
T.check(near(ReadyMacrosDB.minimap.minimapPos, 180), "drag saves angle 180 (cursor left)")
T.cursor = { 1000, 400 }
b._scripts.OnUpdate(b)
T.check(near(ReadyMacrosDB.minimap.minimapPos, 270), "angle is normalised to 0-360 (cursor below)")
b._scripts.OnDragStop(b)
T.check(b._scripts.OnUpdate == nil, "drag stop removes OnUpdate")
-- the saved angle is read back by a later refresh (e.g. /rmac minimap on)
rmac("off"); rmac("on")
x, y = pos(); T.check(near(x, 0) and near(y, -75), "angle 270 kept after hide/show")

-- Tooltip: LibDBIcon calls OnTooltipShow with its own tooltip
local lines = {}
obj = LibStub("LibDataBroker-1.1"):GetDataObjectByName("ReadyMacros")
local tip = { AddLine = function(_, text) lines[#lines + 1] = text end }
obj.OnTooltipShow(tip)
T.eq(lines[1], "Ready Macros", "tooltip title")
T.check(#lines >= 2, "tooltip explains click and drag")
T.check(pcall(b._scripts.OnEnter, b) and pcall(b._scripts.OnLeave, b), "enter/leave scripts run")

-- Libraries missing (e.g. a broken install): no errors, the rest of the addon still loads
ns, M = fresh(nil, nil, (function()
  local keep = {}
  for _, f in ipairs(T.tocFiles()) do if not f:find("^Libs/") then keep[#keep + 1] = f end end
  return keep
end)())
T.check(pcall(rmac, "off"), "/rmac minimap without the libraries does not error")
T.check(ReadyMacrosFrame ~= nil, "main window still builds without the libraries")

T.done("test_minimap")
