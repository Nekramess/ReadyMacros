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

-- Weapon swap: capture, build, recapture, update
ns.playerClass = "WARRIOR"
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
