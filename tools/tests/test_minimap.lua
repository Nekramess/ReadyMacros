-- Minimap button with a simulated client. Frames are fake; this checks logic, not looks.
-- Forever has no GetMinimapShape (minimap addons define it), so every test treats it as an
-- optional global. The Minimap mock is 140x140 centred at (1000,500): edge offset 80.
local T = dofile("tools/tests/wowmock.lua")
local function near(a, b) return math.abs(a - b) < 1e-6 end

local function fresh(db, shapeFn)
  T.install({ class = "WARRIOR" })
  ReadyMacrosDB = db
  GetMinimapShape = shapeFn
  local ns = T.load()
  T.fire("PLAYER_LOGIN")
  return ns, ns.minimap
end
local function rmac(arg) SlashCmdList.READYMACROS("minimap" .. (arg and (" " .. arg) or "")) end
local function pos() local p = ReadyMacrosMinimapButton.lastPoint; return p[4], p[5] end

-- Hook sanity: the mock must not invent GetMinimapShape (Forever does not have it).
T.install({})
T.check(GetMinimapShape == nil, "mock leaves GetMinimapShape undefined, like Forever")

-- Button created, shown, anchored on the minimap edge
local ns, M = fresh(nil)
local b = ReadyMacrosMinimapButton
T.check(b and b:IsShown(), "button created and shown at PLAYER_LOGIN")
local pt = b.lastPoint
T.check(pt and pt[1] == "CENTER" and pt[2] == Minimap and pt[3] == "CENTER", "button anchored CENTER to the Minimap")
T.eq(ReadyMacrosDB.minimap.angle, 215, "default angle 215 saved")
local x, y = pos()
T.check(near(x, 80 * math.cos(math.rad(215))) and near(y, 80 * math.sin(math.rad(215))), "default placement on the round edge")
T.check(near(math.sqrt(x * x + y * y), 80), "round: button sits 80 from the centre")

-- Pure position math
local px, py = M.shapedPosition(0, 80, 80, "ROUND")
T.check(near(px, 80) and near(py, 0), "position at 0 degrees")
px, py = M.shapedPosition(math.pi / 2, 80, 80, "ROUND")
T.check(near(px, 0) and near(py, 80), "position at 90 degrees")
T.check(near(M.angleTo(0, 0, 0, 5), math.pi / 2), "angle to cursor (up)")
T.check(near(M.angleTo(0, 0, -5, 0), math.pi), "angle to cursor (left)")
T.check(near(M.angleTo(10, 10, 15, 10), 0), "angle to cursor (right of non-origin centre)")
px, py = M.shapedPosition(math.rad(45), 80, 80, "SQUARE")
T.check(px > 60 and py > 60 and px <= 80 and py <= 80, "square: 45 degrees rides the box, not the circle")
px, py = M.shapedPosition(0, 80, 80, "SQUARE")
T.check(near(px, 80) and near(py, 0), "square: straight right is the middle of the right edge")
px, py = M.shapedPosition(math.rad(225), 80, 80, "CORNER-TOPRIGHT")
T.check(px < -60 and py < -60, "CORNER-TOPRIGHT: bottom-left quadrant square")
px, py = M.shapedPosition(math.rad(45), 80, 80, "CORNER-TOPRIGHT")
T.check(near(px, 80 * math.cos(math.rad(45))) and near(py, 80 * math.sin(math.rad(45))), "CORNER-TOPRIGHT: top-right quadrant round")
for name, q in pairs({ ["CORNER-TOPLEFT"] = 135, ["CORNER-BOTTOMLEFT"] = 225, ["CORNER-BOTTOMRIGHT"] = 315, ["CORNER-TOPRIGHT"] = 45 }) do
  px, py = M.shapedPosition(math.rad(q), 80, 80, name)
  T.check(near(math.sqrt(px * px + py * py), 80), name .. ": its own quadrant is round")
  px, py = M.shapedPosition(math.rad((q + 180) % 360), 80, 80, name)
  T.check(math.sqrt(px * px + py * py) > 90, name .. ": opposite quadrant is square")
end
for name in pairs(M.SHAPES) do
  px, py = M.shapedPosition(math.rad(135), 80, 80, name)
  T.check(math.abs(px) <= 80 + 1e-9 and math.abs(py) <= 80 + 1e-9, name .. ": stays within the box")
end
px, py = M.shapedPosition(math.rad(45), 80, 80, "NOPE")
T.check(near(math.sqrt(px * px + py * py), 80), "shapedPosition with unknown name is round")

-- Shape from GetMinimapShape (auto mode)
GetMinimapShape = nil
T.eq(M.shape(), "ROUND", "no GetMinimapShape: round")
GetMinimapShape = function() return "SQUARE" end
T.eq(M.shape(), "SQUARE", "SQUARE followed")
GetMinimapShape = function() return "corner-topright" end
T.eq(M.shape(), "CORNER-TOPRIGHT", "lowercase CORNER-TOPRIGHT normalised")
GetMinimapShape = function() return "CORNER-BOTTOMLEFT" end
T.eq(M.shape(), "CORNER-BOTTOMLEFT", "CORNER-BOTTOMLEFT followed")
GetMinimapShape = function() return "nonsense" end
T.eq(M.shape(), "ROUND", "unknown shape name: round")
GetMinimapShape = function() return 5 end
T.eq(M.shape(), "ROUND", "non-string shape: round")
GetMinimapShape = function() return nil end
T.eq(M.shape(), "ROUND", "nil shape: round")
GetMinimapShape = function() error("boom") end
T.eq(M.shape(), "ROUND", "erroring GetMinimapShape: round")
GetMinimapShape = "not a function"
T.eq(M.shape(), "ROUND", "non-function GetMinimapShape: round")

-- Placement follows the shape (45 degrees saved)
ns, M = fresh({ minimap = { hide = false, angle = 45 } })
x, y = pos(); T.check(near(math.sqrt(x * x + y * y), 80), "angle 45, no shape fn: on the circle")
GetMinimapShape = function() return "SQUARE" end
SlashCmdList.READYMACROS("minimap auto")
x, y = pos(); T.check(x > 70 and y > 70 and x <= 80 and y <= 80 and math.sqrt(x * x + y * y) > 85, "angle 45, SQUARE: pushed toward the box corner")
GetMinimapShape = function() return "CORNER-TOPRIGHT" end
SlashCmdList.READYMACROS("minimap auto")
x, y = pos(); T.check(near(math.sqrt(x * x + y * y), 80), "angle 45, CORNER-TOPRIGHT: top-right is round")
GetMinimapShape = function() error("boom") end
SlashCmdList.READYMACROS("minimap auto")
x, y = pos(); T.check(near(math.sqrt(x * x + y * y), 80), "angle 45, erroring shape fn: round")

-- /rmac minimap modes and saved settings
ns, M = fresh(nil, function() return "SQUARE" end)
b = ReadyMacrosMinimapButton
T.eq(M.shape(), "SQUARE", "auto follows the minimap addon")
rmac("round")
T.eq(M.shape(), "ROUND", "round override beats the addon")
T.eq(ReadyMacrosDB.minimap.shape, "round", "round saved")
T.check(T.lastPrint():find("shape: round", 1, true), "round confirmed in chat")
x, y = pos(); T.check(near(math.sqrt(x * x + y * y), 80), "round override: placed on the circle")
rmac("square")
T.eq(M.shape(), "SQUARE", "square override")
T.eq(ReadyMacrosDB.minimap.shape, "square", "square saved")
GetMinimapShape = nil
T.eq(M.shape(), "SQUARE", "square override works without an addon")
rmac("auto")
T.eq(ReadyMacrosDB.minimap.shape, nil, "auto clears the saved shape")
T.eq(M.shape(), "ROUND", "auto without an addon: round")
GetMinimapShape = function() return "SQUARE" end
T.eq(M.shape(), "SQUARE", "auto follows the addon again")
T.check(T.lastPrint():find("auto", 1, true), "auto confirmed in chat")
rmac("ROUND"); T.eq(ReadyMacrosDB.minimap.shape, "round", "argument is case-insensitive")
rmac("auto")

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
rmac("hide"); T.check(not b:IsShown(), "hide alias")
rmac("show"); T.check(b:IsShown(), "show alias")
rmac("bogus"); T.check(not b:IsShown(), "unknown argument toggles")
rmac("on")
-- a shape change while hidden must not show the button
rmac("off"); rmac("square")
T.check(not b:IsShown(), "shape change keeps a hidden button hidden")
rmac("on"); rmac("auto")

-- Saved variables round trip (simulated reload)
rmac("round"); rmac("off")
ReadyMacrosDB.minimap.angle = 123
local saved = ReadyMacrosDB
ns, M = fresh(saved, function() return "SQUARE" end)
T.check(ReadyMacrosMinimapButton == nil or not ReadyMacrosMinimapButton:IsShown(), "hidden setting survives reload (no visible button)")
T.eq(M.shape(), "ROUND", "round override survives reload")
T.eq(ReadyMacrosDB.minimap.angle, 123, "angle survives reload")
rmac("on")
b = ReadyMacrosMinimapButton
T.check(b and b:IsShown(), "on after reload builds and shows the button")
x, y = pos()
T.check(near(x, 80 * math.cos(math.rad(123))) and near(y, 80 * math.sin(math.rad(123))), "saved angle used for placement")
-- PLAYER_ENTERING_WORLD re-places the button
b.lastPoint = nil
T.fire("PLAYER_ENTERING_WORLD")
T.check(b.lastPoint ~= nil, "PLAYER_ENTERING_WORLD places the button again")

-- Click toggles the window; drag saves the angle and suppresses the click that ends it
ns, M = fresh(nil)
b = ReadyMacrosMinimapButton
local win = ReadyMacrosFrame
local was = win:IsShown()
b._scripts.OnClick(b, "LeftButton")
T.check(win:IsShown() ~= was, "click toggles the window")
b._scripts.OnClick(b, "LeftButton")
T.check(win:IsShown() == was, "second click toggles it back")
T.check(b._scripts.OnDragStart and b._scripts.OnDragStop, "drag scripts set")

T.cursor = { 1000, 600 }                 -- straight up from the minimap centre (1000,500)
b._scripts.OnDragStart(b)
T.check(b._scripts.OnUpdate ~= nil, "drag start installs OnUpdate")
b._scripts.OnUpdate(b)
T.check(near(ReadyMacrosDB.minimap.angle, 90), "drag saves angle 90 (cursor above centre)")
x, y = pos(); T.check(near(x, 0) and near(y, 80), "button follows the cursor to the top")
T.cursor = { 900, 500 }
b._scripts.OnUpdate(b)
T.check(near(ReadyMacrosDB.minimap.angle, 180), "drag saves angle 180 (cursor left)")
T.cursor = { 1000, 400 }
b._scripts.OnUpdate(b)
T.check(near(ReadyMacrosDB.minimap.angle, 270), "angle is normalised to 0-360 (cursor below)")
T.cursor = { 1100, 500 }
b._scripts.OnUpdate(b)
T.check(near(ReadyMacrosDB.minimap.angle, 0), "drag saves angle 0 (cursor right)")
-- square shape: dragging up-right pushes toward the box corner
rmac("square")
T.cursor = { 1100, 600 }
b._scripts.OnUpdate(b)
T.check(near(ReadyMacrosDB.minimap.angle, 45), "drag angle 45")
x, y = pos(); T.check(math.sqrt(x * x + y * y) > 85, "square: dragged button leaves the circle")
rmac("auto")
-- click that ends a drag is ignored, then clicks count again
local before = win:IsShown()
b._scripts.OnClick(b, "LeftButton")
T.check(win:IsShown() == before, "click during/right after a drag is ignored")
b._scripts.OnDragStop(b)
T.check(b._scripts.OnUpdate == nil, "drag stop removes OnUpdate")
b._scripts.OnClick(b, "LeftButton")
T.check(win:IsShown() == before, "click right after drag stop still ignored (timer pending)")
T.runTimers()
b._scripts.OnClick(b, "LeftButton")
T.check(win:IsShown() ~= before, "click works after the drag guard timer")
-- drag with no minimap centre (GetCenter returns nothing) must not error or save
local savedAngle = ReadyMacrosDB.minimap.angle
Minimap.GetCenter = function() end
b._scripts.OnDragStart(b)
T.check(pcall(b._scripts.OnUpdate, b), "OnUpdate without a minimap centre does not error")
T.eq(ReadyMacrosDB.minimap.angle, savedAngle, "no centre: angle unchanged")
Minimap.GetCenter = function() return 1000, 500 end
b._scripts.OnDragStop(b); T.runTimers()
-- tooltip handlers run without error
T.check(pcall(b._scripts.OnEnter, b) and pcall(b._scripts.OnLeave, b), "tooltip scripts run")

-- Falls back to UIParent when the Minimap frame is missing
T.install({}); Minimap = nil; ReadyMacrosDB = nil
ns = T.load(); T.fire("PLAYER_LOGIN")
T.check(ReadyMacrosMinimapButton and ReadyMacrosMinimapButton.lastPoint[2] == UIParent, "no Minimap frame: anchored to UIParent")

T.done("test_minimap")
