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

-- One view per class: every spec's macros under a header, no spec tabs
local W = ns.CLASSES.WARRIOR
local function visible(kind) local n = {} for _, f in ipairs(T.rows()) do if f.entry.kind == kind then n[#n + 1] = f end end return n end
local function goToPage(n) while true do local b = T.button("Prev"); if b._enabled then b._scripts.OnClick(b) else break end end for _ = 2, n do T.press("Next") end end
local function visit(fn) -- calls fn(pageNumber) on every page, then returns to page 1
  goToPage(1)
  local n = 1
  while true do
    fn(n)
    local b = T.button("Next")
    if not b._enabled then break end
    b._scripts.OnClick(b); n = n + 1
  end
  goToPage(1)
  return n
end
for _, f in ipairs(T.frames) do
  if f._kind == "Button" and f._text and (f._text == "Assassination" or f._text == "Arms" or f._text == "Fury" or f._text == "Protection" or f._text == "All specs") and f._shown then
    T.check(false, "no spec tab is visible on a class: " .. f._text)
  end
end
local total, wantHeaders = 0, 0
for _, spec in ipairs(W.specs) do if #(W.macros[spec] or {}) > 0 then wantHeaders = wantHeaders + 1 end end
if #(W.macros[ns.UTILITY] or {}) > 0 then wantHeaders = wantHeaders + 1 end
local seen, sawMacros, headerLast, firstMacroLine = {}, 0, false, nil
local pageCount = visit(function(n)
  local rs = T.rows()
  T.check(#rs <= 9, "page " .. n .. " has at most 9 rows")
  T.check(rs[1].entry.kind == "header", "page " .. n .. " opens with a header row")
  if rs[#rs].entry.kind == "header" then headerLast = true end
  for _, f in ipairs(rs) do
    if f.entry.kind == "header" then if not f.entry.label:find("continued", 1, true) then seen[f.entry.label] = true end
    else sawMacros = sawMacros + 1 end
  end
end)
local wantMacros = 0
for _, spec in ipairs(W.specs) do wantMacros = wantMacros + #(W.macros[spec] or {}) end
wantMacros = wantMacros + #(W.macros[ns.UTILITY] or {})
T.eq(sawMacros, wantMacros, "every Warrior macro appears exactly once across the pages")
local nSeen = 0; for _ in pairs(seen) do nSeen = nSeen + 1 end
T.eq(nSeen, wantHeaders, "one header per spec section")
T.check(seen["All specs"], "Utility macros sit under an \"All specs\" header")
T.check(not headerLast, "a header never ends a page")
T.check(pageCount > 1, "Warrior needs more than one page")
-- the page for the detected spec opens first (spec detection returns nothing in the mock, so first page)

-- Spec detection opens the class on the page that holds your spec
local lastSpecName = W.specs[#W.specs]
T.spec = #W.specs
T.fire("PLAYER_LOGIN")
local onPage = false
for _, f in ipairs(T.rows()) do if f.entry.kind == "header" and f.entry.spec == lastSpecName then onPage = true end end
T.check(onPage, "login opens the page with your detected spec (" .. lastSpecName .. ")")
T.spec = nil
local wiX = T.icon("WARRIOR"); wiX._scripts.OnClick(wiX)
T.check(T.rows()[1].entry.label ~= nil and T.rows()[1].entry.kind == "header", "choosing the class icon shows its first page")
-- a long section continues onto the next page with a (continued) header
local cont = false
visit(function() for _, f in ipairs(T.rows()) do if f.entry.kind == "header" and f.entry.label:find("continued", 1, true) then cont = true end end end)
T.check(cont, "a section that spans pages repeats its header as (continued)")

-- Adding a macro creates it in the character tab, once
local function findAndClick(name)
  local found
  visit(function() for _, f in ipairs(T.rows()) do if f.entry.kind == "macro" and f.entry.macro.name == name and not found then found = true; f._scripts.OnClick(f) end end end)
  T.check(found, name .. " found in the list")
end
local function goTo(name)
  local n = 1
  goToPage(1)
  while true do
    for _, f in ipairs(T.rows()) do if f.entry.kind == "macro" and f.entry.macro.name == name then return f end end
    local b = T.button("Next"); if not b._enabled then return nil end
    b._scripts.OnClick(b)
  end
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
