-- Spell check logic (Verify.lua) against a simulated spellbook.
local T = dofile("tools/tests/wowmock.lua")
T.install({ class = "WARRIOR" })
local ns = T.load({ "Data.lua", "SpellIDs.lua", "Verify.lua" })
ReadyMacrosDB = {}

-- Parser
local function parsed(body) return table.concat(ns.SpellsInBody(body), " | ") end
T.eq(parsed("#showtooltip\n/cast [stance:1] Charge; [stance:3] Intercept; Battle Stance"), "Charge | Intercept | Battle Stance", "parser: stance fallbacks")
T.eq(parsed("#showtooltip Shadowform\n/cast !Shadowform"), "Shadowform", "parser: ! prefix")
T.eq(parsed("#showtooltip\n/cast [@mouseover,help,nodead][] Power Word: Shield"), "Power Word: Shield", "parser: colon in name")
T.eq(parsed("#showtooltip\n/cast [@mouseover,help,nodead][@player] Purify"), "Purify", "parser: @player fallback")
T.eq(parsed("#showtooltip Hearthstone\n/use Hearthstone"), "", "parser: /use is not a spell")
T.eq(parsed("#showtooltip\n/startattack\n/cast Tiger's Fury"), "Tiger's Fury", "parser: apostrophe, skips /startattack")

-- Every spell ID on file exists in this client; a level 8 Warrior knows four spells.
for name, e in pairs(ns.SPELL_IDS) do T.ids[e.id] = name end
T.known = { ["Battle Stance"] = 2457, ["Heroic Strike"] = 78, Charge = 100, ["Thunder Clap"] = 6343 }
ns.playerClass = "WARRIOR"

local function status(spec, name)
  for _, m in ipairs(ns.CLASSES.WARRIOR.macros[spec]) do
    if m.name == name then
      local st, d = ns.CheckMacro(m, "WARRIOR")
      local label = (st == "unlearned" or st == "partial") and ns.UnlearnedLabel(d) or ""
      return st, label
    end
  end
  error("no macro " .. name)
end
local cases = {
  { "Utility", "Charge", "partial", "trainer (lvl 30)" },
  { "Utility", "MO Charge", "found", "" },
  { "Utility", "MO Intercept", "unlearned", "trainer (lvl 30)" },
  { "Utility", "Interrupt", "unlearned", "trainer (lvl 38)" },
  { "Utility", "Heroic Strike", "found", "" },
  { "Utility", "Sunder", "unlearned", "trainer (lvl 10)" },
  { "Utility", "Victory Rush", "problem", "" },          -- no ID on file and not learned
  { "Arms", "Overpower", "unlearned", "trainer (lvl 12)" }, -- Battle Stance alone doesn't count as "works now"
  { "Arms", "Mortal Strike", "unlearned", "talent (lvl 40)" },
  { "Protection", "Thunder Clap", "found", "" },
}
for _, c in ipairs(cases) do
  local st, label = status(c[1], c[2])
  T.eq(st, c[3], "level 8 Warrior: " .. c[2] .. " status")
  T.eq(label, c[4], "level 8 Warrior: " .. c[2] .. " label")
end

-- Other classes are not checked in-game; they use the research flag.
T.eq(ns.CheckMacro(ns.CLASSES.MAGE.macros.Utility[1], "MAGE"), "unconfirmed", "other class, unconfirmed name")
T.eq(ns.CheckMacro({ name = "x", body = "#showtooltip\n/cast Frostbolt", v = true }, "MAGE"), "ok", "other class, confirmed name")

-- Renamed and removed spells
T.ids[355] = "Challenging Taunt"
local st, newName = ns.CheckSpell("Taunt")
T.eq(st, "renamed", "renamed spell detected"); T.eq(newName, "Challenging Taunt", "renamed spell's new name")
T.ids[355] = "Taunt"
T.ids[6572] = nil
T.eq(ns.CheckSpell("Revenge"), "gone", "spell ID no longer in client")
T.ids[6572] = "Revenge"

-- Paladin: level 9, knows Purify; Blessings not learned yet. Blessings fall back to the player.
ns.playerClass = "PALADIN"
T.known = { Purify = 1152 }
local want = { ["MO Purify"] = { "found", "" }, ["MO BoP"] = { "unlearned", "trainer (lvl 10)" }, ["MO Freedom"] = { "unlearned", "trainer (lvl 18)" } }
for _, m in ipairs(ns.CLASSES.PALADIN.macros.Utility) do
  local w = want[m.name]
  if w then
    local s, d = ns.CheckMacro(m, "PALADIN")
    T.eq(s, w[1], "level 9 Paladin: " .. m.name .. " status")
    T.eq((s == "unlearned") and ns.UnlearnedLabel(d) or "", w[2], "level 9 Paladin: " .. m.name .. " label")
    T.check(m.body:find("[@mouseover,help,nodead][@player]", 1, true), m.name .. " falls back to the player")
    want[m.name] = nil
  end
end
T.check(next(want) == nil, "all three Paladin mouseover macros exist")

-- /rmac ids report: spells known to the client but missing from SPELL_IDS are offered as NEW and recorded.
ns.playerClass = "WARRIOR"
T.known = { ["Battle Stance"] = 2457, ["Heroic Strike"] = 78, Charge = 100, ["Thunder Clap"] = 6343, ["Victory Rush"] = 555001 }
T.ids[555001] = "Victory Rush"
local report = table.concat(ns.IDReport("WARRIOR"), "\n")
T.check(report:find("NEW       Victory Rush  id 555001", 1, true), "report lists Victory Rush as NEW")
T.check(report:find('["Victory Rush"] = { id = 555001 },', 1, true), "report offers a paste-ready line")
T.eq(ReadyMacrosDB.seenIDs and ReadyMacrosDB.seenIDs["Victory Rush"], 555001, "seen ID recorded")
T.known["Victory Rush"] = nil
T.eq(ns.CheckSpell("Victory Rush"), "unlearned", "recorded ID used after the spell is unlearned")

-- Forever has no global IsPlayerSpell unless the deprecation CVar is on; only C_SpellBook.IsSpellKnown.
-- To make "known by ID" decisive, the spell's name no longer resolves (not in T.known) but its ID still does.
local legacy, book = IsPlayerSpell, C_SpellBook
local hsID = ns.SPELL_IDS["Heroic Strike"].id
T.known = { Charge = 100 }
IsPlayerSpell = nil
C_SpellBook = { IsSpellKnown = function(id, bank) return id == hsID and bank == Enum.SpellBookSpellBank.Player end }
T.eq(ns.CheckSpell("Heroic Strike"), "known", "Forever-like client (no IsPlayerSpell global): known through C_SpellBook.IsSpellKnown(id, Player)")
C_SpellBook = { IsSpellKnown = function() return false end }
T.eq(ns.CheckSpell("Heroic Strike"), "unlearned", "Forever-like client: C_SpellBook says not known -> unlearned")
C_SpellBook = { IsSpellKnown = function() error("boom") end }
T.eq(ns.CheckSpell("Heroic Strike"), "unlearned", "C_SpellBook error is contained (pcall) -> unlearned, no crash")
C_SpellBook = nil
IsPlayerSpell = function(id) return id == hsID end
T.eq(ns.CheckSpell("Heroic Strike"), "known", "retail-like client (global only, no C_SpellBook): still known")
IsPlayerSpell, C_SpellBook = legacy, book

T.done("test_spellcheck")
