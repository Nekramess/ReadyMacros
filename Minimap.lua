-- Ready Macros: minimap button (own implementation, no library). Follows square and other
-- non-round minimaps through GetMinimapShape, the way other addon buttons do.
-- Same design as the UI Snapshot minimap button. Not yet seen in the live client.

local ADDON, ns = ...

local mm = {}
ns.minimap = mm

local button
local PREFIX = "|cff33ccffReady Macros:|r "

-- Saved settings (ReadyMacrosDB is created by the game before PLAYER_LOGIN).
local function cfg()
  ReadyMacrosDB = ReadyMacrosDB or {}
  ReadyMacrosDB.minimap = ReadyMacrosDB.minimap or { hide = false, angle = 215 }
  return ReadyMacrosDB.minimap
end

-- Angle from the minimap centre to the cursor (pure).
function mm.angleTo(cx, cy, px, py)
  return math.atan2(py - cy, px - cx)
end

-- Which quadrants of the minimap are round, per the GetMinimapShape convention
-- (https://warcraft.wiki.gg/wiki/GetMinimapShape). Order: bottom-right,
-- bottom-left, top-right, top-left. true = round, false = square corner.
local SHAPES = {
    ["ROUND"] = {true, true, true, true},
    ["SQUARE"] = {false, false, false, false},
    ["CORNER-TOPLEFT"] = {false, false, false, true},
    ["CORNER-TOPRIGHT"] = {false, false, true, false},
    ["CORNER-BOTTOMLEFT"] = {false, true, false, false},
    ["CORNER-BOTTOMRIGHT"] = {true, false, false, false},
    ["SIDE-LEFT"] = {false, true, false, true},
    ["SIDE-RIGHT"] = {true, false, true, false},
    ["SIDE-TOP"] = {false, false, true, true},
    ["SIDE-BOTTOM"] = {true, true, false, false},
    ["TRICORNER-TOPLEFT"] = {false, true, true, true},
    ["TRICORNER-TOPRIGHT"] = {true, false, true, true},
    ["TRICORNER-BOTTOMLEFT"] = {true, true, false, true},
    ["TRICORNER-BOTTOMRIGHT"] = {true, true, true, false},
}
mm.SHAPES = SHAPES

-- Shape name to use: the saved override ("round" or "square") or, in auto mode,
-- whatever the minimap addon reports through GetMinimapShape.
function mm.shape()
    local mode = cfg().shape
    if mode == "square" then return "SQUARE" end
    if mode == "round" then return "ROUND" end
    local fn = _G.GetMinimapShape
    if type(fn) == "function" then
        local ok, name = pcall(fn)
        if ok and type(name) == "string" and SHAPES[name:upper()] then return name:upper() end
    end
    return "ROUND"
end

-- Offset from the minimap centre for an angle, following the minimap's shape.
-- halfW/halfH are the distances to the edge the button rides on. Pure.
function mm.shapedPosition(angle, halfW, halfH, shapeName)
    local x, y = math.cos(angle), math.sin(angle)
    local q = 1
    if x < 0 then q = q + 1 end
    if y > 0 then q = q + 2 end
    local quads = SHAPES[shapeName or "ROUND"] or SHAPES.ROUND
    if quads[q] then return x * halfW, y * halfH end
    -- square corner: push out to the box edge instead of the circle
    local dw = math.sqrt(2 * halfW * halfW) - 10
    local dh = math.sqrt(2 * halfH * halfH) - 10
    return math.max(-halfW, math.min(x * dw, halfW)), math.max(-halfH, math.min(y * dh, halfH))
end


local function parent()
  return _G.Minimap or UIParent
end

local function place()
  if not button then return end
  local m = parent()
  local w = m:GetWidth()
  if type(w) ~= "number" then w = 140 end
  local h = m.GetHeight and m:GetHeight()
  if type(h) ~= "number" then h = w end
  local x, y = mm.shapedPosition(math.rad(cfg().angle or 215), w / 2 + 10, h / 2 + 10, mm.shape())
  button:ClearAllPoints()
  button:SetPoint("CENTER", m, "CENTER", x, y)
end

local function onDragUpdate()
  local m = parent()
  local cx, cy = m:GetCenter()
  local px, py = GetCursorPosition()
  local scale = m:GetEffectiveScale()
  if not (cx and px and scale) then return end
  cfg().angle = math.deg(mm.angleTo(cx, cy, px / scale, py / scale)) % 360
  place()
end

local function build()
  local b = CreateFrame("Button", "ReadyMacrosMinimapButton", parent())
  b:SetSize(31, 31)
  b:SetFrameStrata("MEDIUM")
  b:SetFrameLevel(8)
  b:RegisterForClicks("AnyUp")
  b:RegisterForDrag("LeftButton")
  b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

  local overlay = b:CreateTexture(nil, "OVERLAY")
  overlay:SetSize(53, 53)
  overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  overlay:SetPoint("TOPLEFT")
  local back = b:CreateTexture(nil, "BACKGROUND")
  back:SetSize(20, 20)
  back:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  back:SetPoint("TOPLEFT", 7, -5)
  local icon = b:CreateTexture(nil, "ARTWORK")
  icon:SetSize(17, 17)
  icon:SetTexture("Interface\\Icons\\INV_Misc_Note_01")
  icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
  icon:SetPoint("TOPLEFT", 7, -6)

  b:SetScript("OnClick", function(self)
    if self.dragging then return end
    if ns.ToggleWindow then ns.ToggleWindow() end
  end)
  b:SetScript("OnDragStart", function(self)
    self.dragging = true
    self:SetScript("OnUpdate", onDragUpdate)
  end)
  b:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    -- Let the click that ends a drag pass before clicks count again.
    if C_Timer and C_Timer.After then C_Timer.After(0.05, function() self.dragging = false end)
    else self.dragging = false end
  end)
  b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Ready Macros")
    GameTooltip:AddLine("Click: open or close the window", 1, 1, 1)
    GameTooltip:AddLine("Drag: move around the minimap", 1, 1, 1)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  button = b
  return b
end

-- Shows or hides the button according to the saved setting.
function mm.apply()
  if cfg().hide then
    if button then button:Hide() end
    return
  end
  if not button then build() end
  place()
  button:Show()
end

function mm.setShown(shown)
  cfg().hide = not shown
  mm.apply()
end

function mm.isShown()
  return not cfg().hide
end

-- /rmac minimap [on|off|square|round|auto]
function ns.MinimapCommand(arg)
  arg = (arg or ""):lower()
  if arg == "square" or arg == "round" then
    cfg().shape = arg
    mm.apply()
    print(PREFIX .. "Minimap button shape: " .. arg .. ".")
    return
  elseif arg == "auto" then
    cfg().shape = nil
    mm.apply()
    print(PREFIX .. "Minimap button shape: auto (follows your minimap addon).")
    return
  elseif arg == "on" or arg == "show" then mm.setShown(true)
  elseif arg == "off" or arg == "hide" then mm.setShown(false)
  else mm.setShown(not mm.isShown()) end
  print(PREFIX .. "Minimap button " .. (mm.isShown() and "shown." or "hidden. /rmac minimap brings it back."))
end

-- Create the button once the game has loaded saved settings and every addon, so a minimap
-- addon has had the chance to define its shape. Place it again after entering the world.
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGIN" then mm.apply() else place() end
end)
