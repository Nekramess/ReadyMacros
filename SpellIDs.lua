-- Ready Macros spell IDs, used to tell "not learned yet" apart from "doesn't exist / renamed".
--
-- Each ID is the rank 1 (or only) ID on Wowhead's Forever database, checked 27 Sept 2026:
-- the Forever page title and spell name matched for every entry below.
-- level  = "Requires level" from that page (beta data, may shift before launch)
-- talent = learned from the talent tree, not a trainer
-- stance = a stance swap; knowing it alone doesn't mean the macro "works now"
--
-- Spells missing here fall back to the name-only check.
-- Victory Rush: no confirmed Forever Warrior ID yet (the ID found, 403434, is listed as a Mage spell).
local _, ns = ...

ns.SPELL_IDS = {
  -- Warrior
  ["Battle Stance"]    = { id = 2457,  level = 1, stance = true },
  ["Heroic Strike"]    = { id = 78,    level = 1 },
  ["Charge"]           = { id = 100,   level = 4 },
  ["Thunder Clap"]     = { id = 6343,  level = 6 },
  ["Defensive Stance"] = { id = 71,    level = 10, stance = true },
  ["Sunder Armor"]     = { id = 7386,  level = 10 },
  ["Taunt"]            = { id = 355,   level = 10 },
  ["Overpower"]        = { id = 7384,  level = 12 },
  ["Shield Bash"]      = { id = 72,    level = 12 },
  ["Revenge"]          = { id = 6572,  level = 14 },
  ["Shield Block"]     = { id = 2565,  level = 16 },
  ["Execute"]          = { id = 5308,  level = 24 },
  ["Intercept"]        = { id = 20252, level = 30 },
  ["Berserker Stance"] = { id = 2458,  level = 30, stance = true },
  ["Whirlwind"]        = { id = 1680,  level = 36 },
  ["Pummel"]           = { id = 6552,  level = 38 },
  ["Mortal Strike"]    = { id = 12294, level = 40, talent = true },
  ["Bloodthirst"]      = { id = 23881, level = 40, talent = true },

  -- Paladin (checked on Wowhead's Forever database, 1 Oct 2026)
  ["Purify"]                 = { id = 1152, level = 8 },
  ["Blessing of Protection"] = { id = 1022, level = 10 },
  ["Blessing of Freedom"]    = { id = 1044, level = 18 },
}
