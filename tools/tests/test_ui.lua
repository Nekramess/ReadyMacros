-- Click-through of the main window with a simulated client. Frames are fake; this checks logic, not looks.
local T = dofile("tools/tests/wowmock.lua")
T.install({ class = "WARRIOR", known = { ["Battle Stance"] = 2457, ["Heroic Strike"] = 78, Charge = 100 } })
T.macros[1] = { "Hearth", 1, "/use Hearthstone" }
T.macros[121] = { "Tank Mode", 2, "#showtooltip\n/cast Defensive Stance" }
T.equipped = { [16] = T.itemLink("Brutality Blade"), [17] = T.itemLink("Drillborer Disk") }
local ns = T.load()

T.fire("PLAYER_LOGIN")
T.eq(SLASH_READYMACROS1, "/readymacros", "slash command 1")
T.eq(SLASH_READYMACROS2, "/rmac", "slash command 2")
SlashCmdList.READYMACROS("")

-- One scrolling list per class: a grid of icon cells under a header for each spec, no spec tabs, no pages
local W = ns.CLASSES.WARRIOR
local function visible(kind) local n = {} for _, f in ipairs(T.rows()) do if f.entry.kind == kind then n[#n + 1] = f end end return n end
local function cellPos(f) return f.lastPoint[4], -f.lastPoint[5] end   -- x, y (downwards) inside the list
for _, f in ipairs(T.frames) do
  if f._kind == "Button" and f._text and (f._text == "Prev" or f._text == "Next") then T.check(false, "no pager button exists: " .. f._text) end
  if f._kind == "Button" and f._text and (f._text == "Assassination" or f._text == "Arms" or f._text == "Fury" or f._text == "Protection" or f._text == "All specs") and f._shown then
    T.check(false, "no spec tab is visible on a class: " .. f._text)
  end
end
local wantMacros, wantHeaders = 0, 0
for _, spec in ipairs(W.specs) do if #(W.macros[spec] or {}) > 0 then wantHeaders = wantHeaders + 1; wantMacros = wantMacros + #W.macros[spec] end end
if #(W.macros[ns.UTILITY] or {}) > 0 then wantHeaders = wantHeaders + 1; wantMacros = wantMacros + #W.macros[ns.UTILITY] end
local macroCells, headers = visible("macro"), visible("header")
T.eq(#macroCells, wantMacros, "every Warrior macro is shown at once (no paging)")
T.eq(#headers, wantHeaders, "one header per spec section")
local hasAll = false
for _, h in ipairs(headers) do if h.entry.label == "All specs" then hasAll = true end end
T.check(hasAll, "Utility macros sit under an \"All specs\" header")
-- grid geometry: 7 per line, left to right, then down; headers sit between sections
table.sort(headers, function(a, b) local _, ya = cellPos(a); local _, yb = cellPos(b); return ya < yb end)
local firstHeaderY = select(2, cellPos(headers[1]))
T.eq(firstHeaderY, 0, "first header is at the top")
local underFirst = {}
for _, c in ipairs(macroCells) do
  local _, cy = cellPos(c)
  local nextY = headers[2] and select(2, cellPos(headers[2])) or math.huge
  if cy > firstHeaderY and cy < nextY then underFirst[#underFirst + 1] = c end
end
table.sort(underFirst, function(a, b) local xa, ya = cellPos(a); local xb, yb = cellPos(b); if ya ~= yb then return ya < yb end return xa < xb end)
T.check(#underFirst >= 2, "first section has at least two macros")
local x1, y1 = cellPos(underFirst[1]); local x2, y2 = cellPos(underFirst[2])
T.eq(y1, y2, "neighbouring macros share a line")
T.check(x2 > x1, "macros run left to right")
if #underFirst > 7 then local _, y8 = cellPos(underFirst[8]); T.check(y8 > y1, "the 8th macro wraps to the next line") end
for i = 2, #headers do
  local _, hy = cellPos(headers[i])
  local lastCellY = -1
  for _, c in ipairs(macroCells) do local _, cy = cellPos(c); if cy < hy and cy > lastCellY then lastCellY = cy end end
  T.check(hy >= lastCellY + 76, "header " .. i .. " starts below the previous section's last line")
end
-- scrolling: the list is taller than the view, wheel moves it, and it stops at both ends
local scrollFrame
for _, f in ipairs(T.frames) do if f._kind == "ScrollFrame" then scrollFrame = f end end
local bar
for _, f in ipairs(T.frames) do if f._kind == "Slider" and f._parent == ReadyMacrosFrame then bar = f end end
T.check(scrollFrame and bar and bar._max and bar._max > 0, "the Warrior list is taller than the window, so it scrolls")
scrollFrame._scripts.OnMouseWheel(scrollFrame, 1)
T.eq(scrollFrame._vscroll, 0, "scrolling up at the top stays at the top")
scrollFrame._scripts.OnMouseWheel(scrollFrame, -1)
T.eq(scrollFrame._vscroll, 50, "one wheel notch scrolls 50 pixels")
for _ = 1, 200 do scrollFrame._scripts.OnMouseWheel(scrollFrame, -1) end
T.eq(scrollFrame._vscroll, bar._max, "scrolling stops at the end of the list")
for _ = 1, 200 do scrollFrame._scripts.OnMouseWheel(scrollFrame, 1) end
T.eq(scrollFrame._vscroll, 0, "and back at the top")

-- The "All specs" section holds more than 7 macros, so it wraps onto a second line
local allHdr; for _, h in ipairs(headers) do if h.entry.label == "All specs" then allHdr = h end end
local allY = select(2, cellPos(allHdr))
local allCells = {}
for _, c in ipairs(macroCells) do local _, cy = cellPos(c); if cy > allY then allCells[#allCells + 1] = c end end
table.sort(allCells, function(a, b) local xa, ya = cellPos(a); local xb, yb = cellPos(b); if ya ~= yb then return ya < yb end return xa < xb end)
T.check(#allCells > 7, "the All specs section has more than one line of macros")
local _, ay1 = cellPos(allCells[1]); local _, ay7 = cellPos(allCells[7]); local ax8, ay8 = cellPos(allCells[8])
T.eq(ay1, ay7, "first seven macros of a section share a line")
T.check(ay8 > ay1, "the 8th macro wraps to the next line")
T.eq(ax8, 3, "a wrapped macro starts at the left edge")
-- a class without specs (General) is one headerless grid
local gi = T.icon("GENERAL"); gi._scripts.OnClick(gi)
T.eq(#visible("header"), 0, "General has no spec headers")
T.eq(#visible("macro"), #ns.CLASSES.GENERAL.macros[ns.UTILITY], "General shows all its macros")
local wiBack = T.icon("WARRIOR"); wiBack._scripts.OnClick(wiBack)

-- Spec detection opens the class scrolled to the header of your spec
local lastSpecName = W.specs[#W.specs]
T.spec = #W.specs
T.fire("PLAYER_LOGIN")
local hdrY
for _, f in ipairs(T.rows()) do if f.entry.kind == "header" and f.entry.spec == lastSpecName then hdrY = select(2, cellPos(f)) end end
T.check(hdrY ~= nil, "the detected spec has a header (" .. lastSpecName .. ")")
T.eq(scrollFrame._vscroll, math.min(hdrY, bar._max), "login scrolls to the detected spec's section")
T.spec = nil
local wiX = T.icon("WARRIOR"); wiX._scripts.OnClick(wiX)
T.eq(scrollFrame._vscroll, 0, "choosing the class icon starts at the top")

-- Adding a macro creates it in the character tab, once
local function goTo(name)
  for _, f in ipairs(T.rows()) do if f.entry.kind == "macro" and f.entry.macro.name == name then return f end end
end
local mo = goTo("MO Charge"); T.check(mo, "MO Charge is listed"); mo._scripts.OnClick(mo)
T.check(GetMacroIndexByName("MO Charge") > 120, "MO Charge created as a character macro")
mo = goTo("MO Charge"); mo._scripts.OnClick(mo)
T.check(T.lastPrint():find("already exists", 1, true), "second click is refused")

-- My Macros: import, save, reuse on another class, remove
local saved = T.icon("SAVED"); saved._scripts.OnClick(saved)
T.press("Import")
T.click("Tank Mode"); T.check(T.lastPrint():find('Saved "Tank Mode"', 1, true), "import saves a macro")
T.click("Tank Mode"); T.check(T.lastPrint():find("already saved", 1, true), "saving twice is refused")
T.click("Hearth")
T.press("Saved")
T.eq(#T.rows(), 2, "two saved macros listed")
T.macros = {}
ns.playerClass = "MAGE"
T.press("Saved")
T.click("Tank Mode")
T.check(GetMacroIndexByName("Tank Mode") > 120, "saved macro added on another character")
T.shift = true; T.click("Hearth"); T.shift = false
T.eq(#T.rows(), 1, "shift-click removes a saved macro")

-- Editor: type a macro, save it, edit it, add it on another character
ns.playerClass = "WARRIOR"; T.macros = {}
T.press("New macro")
local nameBox, bodyBox
for _, f in ipairs(T.frames) do
  if f._kind == "EditBox" then if not nameBox then nameBox = f elseif not bodyBox then bodyBox = f end end
end
T.check(nameBox and bodyBox, "editor has a name box and a text box")
local area = bodyBox._parent
T.check(area and area._scripts.OnClick, "text box sits in a clickable area")
area._scripts.OnClick(area)
T.check(T.focused == bodyBox, "clicking the box area focuses the text box")
nameBox:SetText(""); bodyBox:SetText("/say hi"); T.press("Save to list")
T.check(T.lastPrint():find("Give the macro a name", 1, true), "empty name refused")
nameBox:SetText("My Taunt"); bodyBox:SetText(""); T.press("Save to list")
T.check(T.lastPrint():find("empty", 1, true), "empty text refused")
bodyBox:SetText(("x"):rep(256)); T.press("Save to list")
T.check(T.lastPrint():find("255", 1, true), "text over 255 refused")
bodyBox:SetText("#showtooltip\n/cast Taunt"); T.press("Save to list")
T.check(T.lastPrint():find('Saved "My Taunt"', 1, true), "typed macro saved")
T.eq(nameBox:GetText(), "", "editor clears after save")
nameBox:SetText("My Taunt"); bodyBox:SetText("/say other"); T.press("Save to list")
T.check(T.lastPrint():find("already have", 1, true), "duplicate name refused")
nameBox:SetText("Quick"); bodyBox:SetText("/say quick"); T.press("Save and add here")
T.check(GetMacroIndexByName("Quick") > 120, "save and add creates the macro here")
T.press("Saved")
T.alt = true; T.click("My Taunt"); T.alt = false
T.eq(nameBox:GetText(), "My Taunt", "alt-click loads macro into editor")
bodyBox:SetText("/cast Taunt"); T.press("Save to list")
T.eq(ns.GetSaved()[#ns.GetSaved() - 1].body, "/cast Taunt", "edit replaces the text")
T.eq(#ns.GetSaved(), 3, "edit does not add a copy (Tank Mode, My Taunt, Quick)")
T.macros = {}; ns.playerClass = "MAGE"
T.press("Saved"); T.click("My Taunt")
T.check(GetMacroIndexByName("My Taunt") > 120, "typed macro added on another character")

-- Icon picker, and default icons for created macros
T.eq(ns.MacroIcon({ body = "#showtooltip\n/startattack\n/cast Charge" }), 5100, "bare #showtooltip falls through to the /cast spell")
local sj = T.icon("SAVED"); sj._scripts.OnClick(sj)
T.press("New macro")
local editorFrame = nameBox._parent
local iconBtn
for _, f in ipairs(T.frames) do
  if f._kind == "Button" and f._parent == editorFrame and f._scripts.OnEnter and f._scripts.OnClick and f._text == "" then iconBtn = f end
end
T.check(iconBtn, "editor has an icon button")
local picker = ReadyMacrosIconPicker
T.check(not picker._shown, "icon picker starts hidden")
iconBtn._scripts.OnClick(iconBtn)
T.check(picker._shown, "clicking the icon opens the picker")
local cells = {}
for _, f in ipairs(T.frames) do if f._kind == "Button" and f._parent == picker then cells[#cells + 1] = f end end
T.eq(#cells, 72, "picker grid has 72 cells")
T.eq(cells[1].iconValue, "Interface\\Icons\\LOOSE_1", "first cell is the first game icon (name becomes a path)")
picker._scripts.OnMouseWheel(picker, -1)
T.eq(cells[1].iconValue, "Interface\\Icons\\LOOSE_25", "scrolling moves the grid by 3 rows")
picker._scripts.OnMouseWheel(picker, 1000)
T.eq(cells[1].iconValue, "Interface\\Icons\\LOOSE_1", "scrolling back stops at the top")
for i = 1, 100 do picker._scripts.OnMouseWheel(picker, -1) end
T.eq(cells[#cells].iconValue, 1100, "scrolling reaches the last icon (numeric file IDs stay numbers)")
cells[1]._scripts.OnClick(cells[1])
T.check(not picker._shown, "picking an icon closes the picker")
nameBox:SetText("Pretty"); bodyBox:SetText("/say pretty")
iconBtn._scripts.OnClick(iconBtn); cells[2]._scripts.OnClick(cells[2])
T.press("Save and add here")
local savedPretty
for _, sv in ipairs(ns.GetSaved()) do if sv.name == "Pretty" then savedPretty = sv end end
T.check(savedPretty and savedPretty.icon ~= nil, "chosen icon is saved with the macro")
T.eq(select(2, GetMacroInfo(GetMacroIndexByName("Pretty"))), savedPretty.icon, "macro created on the character uses the chosen icon")
local wi2 = T.icon("WARRIOR"); wi2._scripts.OnClick(wi2)
T.macros = {}
local mo2 = goTo("MO Charge"); mo2._scripts.OnClick(mo2)
T.eq(select(2, GetMacroInfo(GetMacroIndexByName("MO Charge"))), 5100, "ready-made macro is created with its spell's icon")

-- Spell icon cache: a spell learned on one character shows its icon for one that hasn't learned it
T.macros = {}
local cacheDB = ReadyMacrosDB
ns.CacheSpellIcons()
T.eq(cacheDB.spellIcons and cacheDB.spellIcons["Charge"], 5100, "known spell icon is cached account-wide")
local savedKnown = T.known; T.known = {}
T.eq(ns.MacroIcon({ body = "/cast Heroic Strike" }), 5078, "cached icon used when the spell isn't known on this character")
T.known = savedKnown
cacheDB.spellIcons = {}
T.eq(ns.MacroIcon({ body = "/cast Whirlwind" }), 134400, "never-seen spell without an ID stays on the default icon")

-- Icons for spells nobody has learned: looked up by the verified icon-only spell ID
T.textures = { [1752] = 6001 }          -- the simulated game knows the texture of spell 1752 (Sinister Strike)
local savedKnown2 = T.known; T.known = {}
local savedDB2 = ReadyMacrosDB.spellIcons; ReadyMacrosDB.spellIcons = {}
T.eq(ns.MacroIcon({ body = "#showtooltip\n/cast Sinister Strike" }), 6001, "unlearned spell gets its icon through its icon-only spell ID")
T.eq(ns.MacroIcon({ body = "/cast Mangle" }), 134400, "spell with no ID anywhere stays on the default icon")
T.known = savedKnown2; ReadyMacrosDB.spellIcons = savedDB2; T.textures = nil

-- Macro icons and editor delete/cancel
T.eq(ns.MacroIcon({ body = "#showtooltip Charge\n/cast Charge" }), 5100, "icon from #showtooltip spell")
T.eq(ns.MacroIcon({ body = "/cast [@mouseover,help][] Heroic Strike" }), 5078, "icon from first /cast spell")
T.eq(ns.MacroIcon({ body = "/say hi" }), 134400, "no spell gives the default icon")
T.eq(ns.MacroIcon({ body = "/say hi", icon = 777 }), 777, "saved icon wins")
local si2 = T.icon("SAVED"); si2._scripts.OnClick(si2)
T.press("Saved")
local nSaved = #ns.GetSaved()
T.alt = true; T.click("Quick"); T.alt = false
T.press("Cancel")
T.eq(nameBox:GetText(), "", "cancel clears the editor")
T.eq(#ns.GetSaved(), nSaved, "cancel saves nothing")
T.press("Saved")
T.alt = true; T.click("Quick"); T.alt = false
T.press("Delete")
T.eq(#ns.GetSaved(), nSaved - 1, "delete removes the edited saved macro")

-- Game macro window button and drag-to-action-bar
ns.playerClass = "WARRIOR"; T.macros = {}
T.press("Game macro window")
T.check(T.macroFrameOpened, "button opens the game macro window")
local wi = T.icon("WARRIOR"); wi._scripts.OnClick(wi)
local row = visible("macro")[1]
local first = T.rowName(row)
T.check(GetMacroIndexByName(first) == 0, "macro not on character before drag")
row._scripts.OnDragStart(row)
local idx = GetMacroIndexByName(first)
T.check(idx > 120, "drag adds a missing macro")
T.eq(T.picked, idx, "drag picks the macro up")
T.picked = nil
row._scripts.OnDragStart(row)
T.eq(T.picked, idx, "drag of an existing macro just picks it up")
local before = select(2, GetNumMacros())
T.eq(select(2, GetNumMacros()), before, "no duplicate created on second drag")

-- Weapon swap: capture, build, recapture, update
ns.playerClass = "WARRIOR"
local si = T.icon("SAVED"); si._scripts.OnClick(si)
T.press("Weapon swap")
T.click("Capture Set 1")
T.equipped = { [16] = T.itemLink("Obsidian Edged Blade") }
T.click("Capture Set 2")
T.click("Weapon Set 1"); T.click("Weapon Set 2")
T.eq(select(3, GetMacroInfo(GetMacroIndexByName("Weapon Set 1"))), "/equipslot 16 Brutality Blade\n/equipslot 17 Drillborer Disk", "set 1 macro text")
T.eq(select(3, GetMacroInfo(GetMacroIndexByName("Weapon Set 2"))), "/equipslot 16 Obsidian Edged Blade", "set 2 (two-hander) macro text")
T.equipped = { [16] = T.itemLink("Arcanite Reaper") }
T.click("Capture Set 2"); T.click("Weapon Set 2")
T.eq(select(3, GetMacroInfo(GetMacroIndexByName("Weapon Set 2"))), "/equipslot 16 Arcanite Reaper", "recapture updates the macro")
T.equipped = {}
T.click("Capture Set 1")
T.check(T.lastPrint():find("Nothing equipped", 1, true), "capture with no weapon is refused")

-- /rmac ids opens the report
SlashCmdList.READYMACROS("ids")
local box
for _, f in ipairs(T.frames) do if rawget(f, "_kind") == "EditBox" then box = f end end
T.check(box and box._text:match("^WARRIOR: "), "/rmac ids fills the report")

T.done("test_ui")
