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

-- Paging on Warrior > All specs
T.press("All specs")
local page1 = T.rows()
T.eq(#page1, 8, "page 1 shows 8 rows")
T.eq(T.rowName(page1[1]), ns.CLASSES.WARRIOR.macros.Utility[1].name, "page 1 starts with the first macro")
T.press("Next")
T.eq(#T.rows(), #ns.CLASSES.WARRIOR.macros.Utility - 8, "page 2 shows the rest")

-- Adding a macro creates it in the character tab, once
T.press("Prev")
T.click("MO Charge")
T.check(GetMacroIndexByName("MO Charge") > 120, "MO Charge created as a character macro")
T.click("MO Charge")
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

-- Game macro window button and drag-to-action-bar
ns.playerClass = "WARRIOR"; T.macros = {}
T.press("Game macro window")
T.check(T.macroFrameOpened, "button opens the game macro window")
local wi = T.icon("WARRIOR"); wi._scripts.OnClick(wi)
T.press("All specs")
local row = T.rows()[1]
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
