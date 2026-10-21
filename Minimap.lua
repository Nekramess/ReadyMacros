-- Ready Macros: minimap button, registered through the standard LibDBIcon-1.0 library
-- (embedded in Libs/), so minimap button managers treat it as a normal button instead of
-- flagging it as a custom one. LibDBIcon also follows square and other non-round minimaps
-- through GetMinimapShape. Not yet seen in the live client.

local ADDON, ns = ...

local mm = {}
ns.minimap = mm

local ICON_NAME = "ReadyMacros"
local PREFIX = "|cff33ccffReady Macros:|r "

local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
local DBIcon = LibStub and LibStub("LibDBIcon-1.0", true)
local registered = false

-- Saved settings (ReadyMacrosDB is created by the game before PLAYER_LOGIN).
-- LibDBIcon keeps the angle in `minimapPos` (degrees) and the hidden flag in `hide`.
-- Settings from older versions used `angle` and `shape`; the angle carries over.
local function cfg()
  ReadyMacrosDB = ReadyMacrosDB or {}
  local c = ReadyMacrosDB.minimap
  if type(c) ~= "table" then c = {}; ReadyMacrosDB.minimap = c end
  if c.minimapPos == nil then c.minimapPos = tonumber(c.angle) or 215 end
  c.angle, c.shape = nil, nil
  c.hide = c.hide and true or false
  return c
end

local function register()
  if registered or not (LDB and DBIcon) then return end
  local obj = LDB:NewDataObject(ICON_NAME, {
    type = "launcher",
    text = "Ready Macros",
    icon = "Interface\\Icons\\INV_Misc_Note_01",
    OnClick = function()
      if ns.ToggleWindow then ns.ToggleWindow() end
    end,
    OnTooltipShow = function(tt)
      tt:AddLine("Ready Macros")
      tt:AddLine("Click: open or close the window", 1, 1, 1)
      tt:AddLine("Drag: move around the minimap", 1, 1, 1)
    end,
  })
  DBIcon:Register(ICON_NAME, obj, cfg())
  registered = true
end

-- Shows or hides the button according to the saved setting.
function mm.apply()
  register()
  if not registered then return end
  DBIcon:Refresh(ICON_NAME, cfg())
end

function mm.setShown(shown)
  cfg().hide = not shown
  mm.apply()
end

function mm.isShown()
  return not cfg().hide
end

-- /rmac minimap [on|off]
function ns.MinimapCommand(arg)
  arg = (arg or ""):lower()
  if arg == "on" or arg == "show" then mm.setShown(true)
  elseif arg == "off" or arg == "hide" then mm.setShown(false)
  else mm.setShown(not mm.isShown()) end
  print(PREFIX .. "Minimap button " .. (mm.isShown() and "shown." or "hidden. /rmac minimap brings it back."))
end

-- Register once the game has loaded saved settings.
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function() mm.apply() end)
