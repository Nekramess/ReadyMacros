-- Ready Macros: one-click character-specific macros, organized by class and spec,
-- plus a library of your own macros and a weapon swap builder.
local ADDON, ns = ...

local ICON = 134400 -- question-mark icon; with #showtooltip the game shows the spell's icon
local GENERAL_ICON = "Interface\\Icons\\INV_Misc_Book_09"
local SAVED_ICON = "Interface\\Icons\\INV_Misc_Note_01"
local PREFIX = "|cff33ccffReady Macros:|r "
local MAX_ROWS = 8

local SAVED = "SAVED" -- the "My Macros" view
local SAVED_TABS = { "Saved", "Import", "Weapon swap" }

local VIEW_ORDER = {}
for _, key in ipairs(ns.CLASS_ORDER) do VIEW_ORDER[#VIEW_ORDER + 1] = key end
VIEW_ORDER[#VIEW_ORDER + 1] = SAVED

local selectedClass, selectedSpec
local page = 1

local function Print(msg) print(PREFIX .. msg) end

local function MaxCharMacros()
  return MAX_CHARACTER_MACROS or 18
end

local function ClassName(key)
  if key == "GENERAL" then return "General" end
  if key == SAVED then return "My Macros" end
  return (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[key]) or key or "?"
end

local function ClassColor(key)
  local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[key]
  if c then return c.r, c.g, c.b end
  return 1, 0.82, 0
end

-- Class icon: prefer the modern atlas, fall back to the classic class-icon sheet.
local function SetClassIcon(tex, key)
  if key == "GENERAL" then tex:SetTexture(GENERAL_ICON) return end
  if key == SAVED then tex:SetTexture(SAVED_ICON) return end
  local atlas = "classicon-" .. key:lower()
  if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas) then
    tex:SetAtlas(atlas)
  elseif CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[key] then
    tex:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
    tex:SetTexCoord(unpack(CLASS_ICON_TCOORDS[key]))
  else
    tex:SetTexture(ICON)
  end
end

-- Best-effort spec detection. Forever documents C_SpecializationInfo.GetSpecialization (the global is only a
-- deprecated shim there, gated by the loadDeprecationFallbacks CVar), so try that first. Only trusts a
-- sensible index; otherwise returns nil.
local function DetectSpecIndex(numSpecs)
  local fn = (C_SpecializationInfo and C_SpecializationInfo.GetSpecialization) or GetSpecialization
  if fn then
    local ok, idx = pcall(fn)
    if ok and type(idx) == "number" and idx >= 1 and idx <= numSpecs then return idx end
  end
end

local Refresh -- defined below

---------------------------------------------------------------------------
-- Macro creation
---------------------------------------------------------------------------
-- checkClass: class whose spells to verify in-game (nil = skip the check).
-- allowUpdate: if a macro with this name exists, overwrite its text instead of refusing.
local function AddMacro(m, checkClass, allowUpdate)
  if InCombatLockdown() then
    Print("Macros can't be created in combat.")
    return
  end
  local existing = GetMacroIndexByName(m.name)
  if existing ~= 0 then
    if allowUpdate then
      EditMacro(existing, m.name, m.icon or ICON, m.body)
      Print("Updated \"" .. m.name .. "\".")
    else
      Print("A macro named \"" .. m.name .. "\" already exists.")
    end
    return
  end
  local _, numChar = GetNumMacros()
  if numChar >= MaxCharMacros() then
    Print("Your character-specific macro slots are full.")
    return
  end
  local id = CreateMacro(m.name, m.icon or ICON, m.body, true) -- true = character-specific tab
  if not id then
    Print("Couldn't create \"" .. m.name .. "\".")
    return
  end
  Print("Added \"" .. m.name .. "\" to your character macros.")
  local status, details = ns.CheckMacro(m, checkClass)
  if status == "problem" then
    Print("Heads up: " .. table.concat(details, "; ") .. ".")
  elseif status == "unlearned" then
    Print("Note: \"" .. m.name .. "\" needs spells you haven't learned yet: " .. ns.UnlearnedLabel(details) .. ".")
  elseif status == "partial" then
    Print("Note: \"" .. m.name .. "\" works now; the rest unlocks at " .. ns.UnlearnedLabel(details) .. ".")
  elseif status == "unconfirmed" then
    Print("Heads up: a spell name in \"" .. m.name .. "\" isn't confirmed for Forever yet. Check your spellbook.")
  end
end

---------------------------------------------------------------------------
-- Main window
---------------------------------------------------------------------------
local frame = CreateFrame("Frame", "ReadyMacrosFrame", UIParent, "BasicFrameTemplateWithInset")
frame:SetSize(560, 530)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:SetClampedToScreen(true)
frame:Hide()
tinsert(UISpecialFrames, "ReadyMacrosFrame") -- Esc closes it

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
title:SetPoint("TOP", frame, "TOP", 0, -5)
title:SetText("Ready Macros")

local header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
header:SetPoint("TOP", frame, "TOP", 0, -84)

local status = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
status:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 14, 12)

local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
hint:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 12)

-- Class icon buttons (one row, centered)
local ICON_SIZE, ICON_GAP = 40, 8
local classButtons = {}
local rowWidth = #VIEW_ORDER * ICON_SIZE + (#VIEW_ORDER - 1) * ICON_GAP
for i, key in ipairs(VIEW_ORDER) do
  local b = CreateFrame("Button", nil, frame)
  b:SetSize(ICON_SIZE, ICON_SIZE)
  b:SetPoint("TOPLEFT", frame, "TOP", -rowWidth / 2 + (i - 1) * (ICON_SIZE + ICON_GAP), -32)

  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetAllPoints()
  SetClassIcon(b.icon, key)

  -- colored bar under the selected class
  b.selected = b:CreateTexture(nil, "OVERLAY")
  b.selected:SetColorTexture(ClassColor(key))
  b.selected:SetPoint("TOPLEFT", b, "BOTTOMLEFT", 0, -2)
  b.selected:SetPoint("TOPRIGHT", b, "BOTTOMRIGHT", 0, -2)
  b.selected:SetHeight(3)

  b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
  b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:AddLine(ClassName(key), ClassColor(key))
    if key == SAVED then
      GameTooltip:AddLine("Your own macros, saved for every character, and weapon swaps.", 0.8, 0.8, 0.8, true)
    end
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", GameTooltip_Hide)

  b.key = key
  classButtons[key] = b
end

-- Spec tabs (up to 3 specs + Utility)
local specTabs = {}
for i = 1, 4 do
  local t = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  t:SetSize(126, 22)
  t:SetPoint("TOPLEFT", frame, "TOPLEFT", 16 + (i - 1) * 132, -108)
  t:Hide()
  specTabs[i] = t
end

-- Pager
local pager = CreateFrame("Frame", nil, frame)
pager:SetSize(220, 22)
pager:SetPoint("BOTTOM", frame, "BOTTOM", 0, 34)
local prevBtn = CreateFrame("Button", nil, pager, "UIPanelButtonTemplate")
prevBtn:SetSize(60, 22)
prevBtn:SetPoint("LEFT")
prevBtn:SetText("Prev")
local nextBtn = CreateFrame("Button", nil, pager, "UIPanelButtonTemplate")
nextBtn:SetSize(60, 22)
nextBtn:SetPoint("RIGHT")
nextBtn:SetText("Next")
local pageText = pager:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
pageText:SetPoint("CENTER")
prevBtn:SetScript("OnClick", function() page = page - 1; Refresh() end)
nextBtn:SetScript("OnClick", function() page = page + 1; Refresh() end)

---------------------------------------------------------------------------
-- Tooltip for a macro row
---------------------------------------------------------------------------
local function AddCheckLines(m, checkClass)
  local st, details = ns.CheckMacro(m, checkClass)
  if st == "found" then
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("All spells found in your spellbook.", 0.3, 1, 0.3, true)
  elseif st == "unlearned" or st == "partial" then
    GameTooltip:AddLine(" ")
    if st == "partial" then
      GameTooltip:AddLine("Works now. These parts exist in Forever but aren't learned yet:", 0.6, 1, 0.6, true)
    else
      GameTooltip:AddLine("Exists in Forever, not learned yet:", 0.85, 0.85, 0.85, true)
    end
    for _, u in ipairs(details) do
      local where = u.talent and "talent" or "trainer"
      GameTooltip:AddLine(("  %s: %s, level %d"):format(u.name, where, u.level or 0), 0.85, 0.85, 0.85, true)
    end
  elseif st == "problem" then
    GameTooltip:AddLine(" ")
    for _, p in ipairs(details) do GameTooltip:AddLine(p, 1, 0.5, 0.1, true) end
  elseif st == "unconfirmed" then
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Spell name not yet confirmed for Forever. Check your spellbook.", 1, 0.5, 0.1, true)
  end
end

---------------------------------------------------------------------------
-- Rows
---------------------------------------------------------------------------
local rows = {}
local ROW_HEIGHT = 36

local function GetRow(i)
  if rows[i] then return rows[i] end
  local r = CreateFrame("Button", nil, frame)
  r:SetSize(526, ROW_HEIGHT)
  r:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -140 - (i - 1) * (ROW_HEIGHT + 2))
  r:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")

  r.name = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  r.name:SetPoint("TOPLEFT", 6, -4)
  r.desc = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  r.desc:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -2)
  r.desc:SetPoint("RIGHT", r, "RIGHT", -170, 0)
  r.desc:SetJustifyH("LEFT")
  r.desc:SetWordWrap(false)
  r.state = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  r.state:SetPoint("RIGHT", -8, 0)

  r:SetScript("OnClick", function(self)
    local e = self.entry
    if not e then return end
    if e.kind == "macro" then
      if IsShiftKeyDown() and e.onShift then e.onShift() else AddMacro(e.macro, e.checkClass, e.allowUpdate) end
    elseif e.onClick then
      e.onClick()
    end
    Refresh()
  end)
  r:SetScript("OnEnter", function(self)
    local e = self.entry
    if not e then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if e.kind == "macro" then
      GameTooltip:AddLine(e.macro.name, 1, 1, 1)
      GameTooltip:AddLine(e.macro.body, 0.8, 0.8, 0.8, true)
      AddCheckLines(e.macro, e.checkClass)
    else
      GameTooltip:AddLine(e.label, 1, 1, 1)
      if e.body then GameTooltip:AddLine(e.body, 0.8, 0.8, 0.8, true) end
    end
    for _, line in ipairs(e.tip or {}) do
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine(line, 0.6, 0.8, 1, true)
    end
    GameTooltip:Show()
  end)
  r:SetScript("OnLeave", GameTooltip_Hide)

  rows[i] = r
  return r
end

local function RenderMacroRow(r, e)
  local m = e.macro
  r.name:SetText(m.name)
  r.desc:SetText(m.desc or "")
  local st, details = ns.CheckMacro(m, e.checkClass)
  local exists = GetMacroIndexByName(m.name) ~= 0
  if exists and e.allowUpdate then
    r.state:SetText("click to update")
    r.name:SetTextColor(1, 0.82, 0)
  elseif exists then
    r.state:SetText("added")
    r.name:SetTextColor(0.5, 0.5, 0.5)
  elseif st == "found" then
    r.state:SetText("in your spellbook")
    r.name:SetTextColor(0.3, 1, 0.3)
  elseif st == "unlearned" then
    r.state:SetText(ns.UnlearnedLabel(details))
    r.name:SetTextColor(0.85, 0.85, 0.85)
  elseif st == "partial" then
    local lvl = ns.UnlearnedLabel(details):match("lvl %d+")
    r.state:SetText(lvl and ("works now, full at " .. lvl) or "works now, partly")
    r.name:SetTextColor(0.3, 1, 0.3)
  elseif st == "problem" then
    r.state:SetText("check tooltip")
    r.name:SetTextColor(1, 0.5, 0.1)
  elseif st == "unconfirmed" then
    r.state:SetText("check spell name")
    r.name:SetTextColor(1, 0.5, 0.1)
  else
    r.state:SetText("click to add")
    r.name:SetTextColor(1, 0.82, 0)
  end
end

local function RenderActionRow(r, e)
  r.name:SetText(e.label)
  r.desc:SetText(e.desc or "")
  r.state:SetText(e.state or "")
  r.name:SetTextColor(unpack(e.color or { 1, 0.82, 0 }))
end

---------------------------------------------------------------------------
-- What to list for the current view
---------------------------------------------------------------------------
local function FirstLine(body)
  for line in (body or ""):gmatch("[^\n]+") do
    if not line:match("^#") then return line end
  end
  return ""
end

local function SavedEntries()
  local entries = {}
  for i, s in ipairs(ns.GetSaved()) do
    local sameClass = s.class == ns.playerClass
    entries[#entries + 1] = {
      kind = "macro",
      macro = { name = s.name, body = s.body, icon = s.icon, v = true,
                desc = "Saved from " .. ClassName(s.class) .. ": " .. FirstLine(s.body) },
      checkClass = sameClass and ns.playerClass or nil,
      onShift = function()
        ns.RemoveSaved(i)
        Print("Removed \"" .. s.name .. "\" from your saved macros.")
      end,
      tip = { "Click to add to this character. Shift-click to remove it from your saved macros." },
    }
  end
  if #entries == 0 then
    entries[1] = { kind = "action", label = "Nothing saved yet", color = { 0.6, 0.6, 0.6 },
                   desc = "Open the Import tab to save macros from this character." }
  end
  return entries
end

local function ImportEntries()
  local entries = {}
  for _, m in ipairs(ns.CharacterMacros()) do
    local saved = ns.IsSaved(m.name, m.body)
    entries[#entries + 1] = {
      kind = "action",
      label = m.name,
      body = m.body,
      desc = (m.perChar and "Character: " or "Account: ") .. FirstLine(m.body),
      state = saved and "saved" or "click to save",
      color = saved and { 0.5, 0.5, 0.5 } or { 1, 0.82, 0 },
      onClick = function()
        local result, usedName = ns.SaveMacro(m.name, m.body, m.icon, ns.playerClass)
        if result == "exists" then
          Print("\"" .. m.name .. "\" is already saved.")
        elseif result == "renamed" then
          Print("Saved \"" .. m.name .. "\" as \"" .. usedName .. "\" (a different macro already had that name).")
        else
          Print("Saved \"" .. m.name .. "\". It's now in My Macros > Saved on every character.")
        end
      end,
      tip = { "Click to save this macro so you can add it on your other characters." },
    }
  end
  if #entries == 0 then
    entries[1] = { kind = "action", label = "No macros on this character", color = { 0.6, 0.6, 0.6 },
                   desc = "Make one in the game's macro window (/macro), then come back." }
  end
  return entries
end

local function WeaponEntries()
  local entries = {}
  local hints = { "your one-hander + shield", "your two-hander or dual wield" }
  for i = 1, 2 do
    local set = ns.GetWeaponSet(i)
    entries[#entries + 1] = {
      kind = "action",
      label = "Capture Set " .. i,
      desc = set and ns.DescribeWeaponSet(set) or ("Equip " .. hints[i] .. ", then click"),
      state = set and "click to recapture" or "click to capture",
      color = { 1, 0.82, 0 },
      onClick = function()
        local captured, err = ns.CaptureWeaponSet(i)
        if captured then
          Print("Set " .. i .. " captured: " .. ns.DescribeWeaponSet(captured) .. ".")
        else
          Print(err)
        end
      end,
      tip = { "Captures the weapons you have equipped right now. Nothing to type." },
    }
  end
  for i = 1, 2 do
    local m, err = ns.WeaponSetMacro(i)
    if m then
      entries[#entries + 1] = {
        kind = "macro", macro = m, allowUpdate = true,
        tip = { "Adds a \"Weapon Set " .. i .. "\" macro. If you recapture, click again to update it." },
      }
    else
      entries[#entries + 1] = { kind = "action", label = "Weapon Set " .. i .. " macro",
        desc = err or ("Capture Set " .. i .. " first"), color = { 0.6, 0.6, 0.6 } }
    end
  end
  return entries
end

local function ClassEntries(data)
  local entries = {}
  for _, m in ipairs(data.macros[selectedSpec] or data.macros[ns.UTILITY] or {}) do
    entries[#entries + 1] = { kind = "macro", macro = m, checkClass = selectedClass }
  end
  return entries
end

---------------------------------------------------------------------------
-- Refresh
---------------------------------------------------------------------------
function Refresh()
  if not selectedClass then return end
  local isSaved = selectedClass == SAVED
  local data = ns.CLASSES[selectedClass]

  for key, b in pairs(classButtons) do
    local on = key == selectedClass
    b.icon:SetDesaturated(not on)
    b.icon:SetAlpha(on and 1 or 0.55)
    b.selected:SetShown(on)
  end

  header:SetText(ClassName(selectedClass))
  header:SetTextColor(ClassColor(selectedClass))

  -- tabs
  local tabs = {}
  if isSaved then
    for _, s in ipairs(SAVED_TABS) do tabs[#tabs + 1] = s end
  else
    for _, s in ipairs(data.specs) do tabs[#tabs + 1] = s end
    if #tabs > 0 then tabs[#tabs + 1] = ns.UTILITY end
  end
  for i, t in ipairs(specTabs) do
    local spec = tabs[i]
    if spec then
      t:SetText(spec == ns.UTILITY and "All specs" or spec)
      t.spec = spec
      if spec == selectedSpec then t:LockHighlight() else t:UnlockHighlight() end
      t:Show()
    else
      t:Hide()
    end
  end

  -- entries
  local entries
  if isSaved then
    if selectedSpec == "Import" then entries = ImportEntries()
    elseif selectedSpec == "Weapon swap" then entries = WeaponEntries()
    else entries = SavedEntries() end
    hint:SetText(selectedSpec == "Saved" and "Shift-click a saved macro to remove it." or "")
  else
    entries = ClassEntries(data)
    hint:SetText("Green = known. Grey = learn later. Orange = check it.")
  end

  -- paging
  local pages = math.max(1, math.ceil(#entries / MAX_ROWS))
  page = math.min(math.max(page, 1), pages)
  pager:SetShown(pages > 1)
  pageText:SetText(("Page %d / %d"):format(page, pages))
  if page > 1 then prevBtn:Enable() else prevBtn:Disable() end
  if page < pages then nextBtn:Enable() else nextBtn:Disable() end

  local first = (page - 1) * MAX_ROWS
  local shown = 0
  for i = 1, MAX_ROWS do
    local e = entries[first + i]
    if e then
      local r = GetRow(i)
      r.entry = e
      if e.kind == "macro" then RenderMacroRow(r, e) else RenderActionRow(r, e) end
      r:Show()
      shown = i
    end
  end
  for i = shown + 1, #rows do rows[i].entry = nil; rows[i]:Hide() end

  local _, numChar = GetNumMacros()
  status:SetText(("Character macros: %d / %d"):format(numChar, MaxCharMacros()))
end

local function SelectSpec(spec)
  selectedSpec = spec
  page = 1
  if ReadyMacrosDB and selectedClass then ReadyMacrosDB.lastSpec[selectedClass] = spec end
  Refresh()
end

local function SelectClass(key, preferredSpec)
  selectedClass = key
  page = 1
  local default = key == SAVED and SAVED_TABS[1] or (ns.CLASSES[key].specs[1] or ns.UTILITY)
  selectedSpec = preferredSpec or (ReadyMacrosDB and ReadyMacrosDB.lastSpec[key]) or default
  Refresh()
end

for key, b in pairs(classButtons) do
  b:SetScript("OnClick", function() SelectClass(key) end)
end
for _, t in ipairs(specTabs) do
  t:SetScript("OnClick", function(self) SelectSpec(self.spec) end)
end

frame:SetScript("OnShow", Refresh)

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("UPDATE_MACROS")
events:RegisterEvent("SPELLS_CHANGED")        -- re-check spell names when you learn or respec
events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED") -- keep the weapon swap view current
events:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGIN" then
    ReadyMacrosDB = ReadyMacrosDB or {}
    ReadyMacrosDB.lastSpec = ReadyMacrosDB.lastSpec or {}

    local _, classFile = UnitClass("player")
    ns.playerClass = classFile
    local key = ns.CLASSES[classFile] and classFile or "GENERAL"
    local data = ns.CLASSES[key]
    local idx = DetectSpecIndex(#data.specs)
    SelectClass(key, idx and data.specs[idx] or nil)
  elseif frame:IsShown() then
    Refresh()
  end
end)

---------------------------------------------------------------------------
-- /rmac ids: copyable spell ID report
---------------------------------------------------------------------------
local report = CreateFrame("Frame", "ReadyMacrosReport", UIParent, "BasicFrameTemplateWithInset")
report:SetSize(620, 460)
report:SetPoint("CENTER", 0, 20)
report:SetFrameStrata("DIALOG")
report:SetMovable(true)
report:EnableMouse(true)
report:RegisterForDrag("LeftButton")
report:SetScript("OnDragStart", report.StartMoving)
report:SetScript("OnDragStop", report.StopMovingOrSizing)
report:Hide()
tinsert(UISpecialFrames, "ReadyMacrosReport")

local reportTitle = report:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
reportTitle:SetPoint("TOP", report, "TOP", 0, -5)
reportTitle:SetText("Ready Macros spell IDs")

local reportHint = report:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
reportHint:SetPoint("BOTTOM", report, "BOTTOM", 0, 10)
reportHint:SetText("Text is selected: Ctrl+C to copy. Esc to close.")

local reportBox = CreateFrame("EditBox", nil, report)
reportBox:SetMultiLine(true)
reportBox:SetAutoFocus(false)
reportBox:SetFontObject(ChatFontNormal)
reportBox:SetPoint("TOPLEFT", report, "TOPLEFT", 14, -32)
reportBox:SetPoint("BOTTOMRIGHT", report, "BOTTOMRIGHT", -14, 28)
reportBox:SetScript("OnEscapePressed", function() report:Hide() end)

local function ShowIDReport()
  if not ns.playerClass then return end
  local lines = ns.IDReport(ns.playerClass)
  reportBox:SetText(table.concat(lines, "\n"))
  report:Show()
  reportBox:SetFocus()
  reportBox:HighlightText()
  if frame:IsShown() then Refresh() end
end

function ns.ToggleWindow()
  frame:SetShown(not frame:IsShown())
end

SLASH_READYMACROS1 = "/readymacros"
SLASH_READYMACROS2 = "/rmac"
SlashCmdList.READYMACROS = function(msg)
  msg = (msg or ""):lower():match("^%s*(.-)%s*$")
  local cmd, rest = msg:match("^(%S*)%s*(.-)$")
  if cmd == "ids" then
    ShowIDReport()
  elseif cmd == "minimap" then
    if ns.MinimapCommand then ns.MinimapCommand(rest) end
  else
    ns.ToggleWindow()
  end
end
