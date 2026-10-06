-- Rules for Data.lua and SpellIDs.lua. No game API needed.
local T = dofile("tools/tests/wowmock.lua")
local ns = T.load({ "Data.lua", "SpellIDs.lua" })

local total, unverified = 0, 0
for _, key in ipairs(ns.CLASS_ORDER) do
  local c = ns.CLASSES[key]
  T.check(c ~= nil, "class " .. key .. " exists")
  if c then
    local tabs = {}
    for _, s in ipairs(c.specs) do tabs[#tabs + 1] = s end
    tabs[#tabs + 1] = ns.UTILITY
    for _, s in ipairs(tabs) do
      local list = c.macros[s]
      T.check(list ~= nil, key .. " has a " .. s .. " list")
      local seen = {}
      for _, m in ipairs(list or {}) do
        total = total + 1
        if not m.v then unverified = unverified + 1 end
        T.check(#m.name <= 16, ("%s %s: name '%s' is %d chars (max 16)"):format(key, s, m.name, #m.name))
        T.check(#m.body <= 255, ("%s %s: '%s' body is %d chars (max 255)"):format(key, s, m.name, #m.body))
        T.check(not seen[m.name], ("%s %s: '%s' appears twice in one tab"):format(key, s, m.name))
        T.check(type(m.desc) == "string" and m.desc ~= "", ("%s %s: '%s' has a description"):format(key, s, m.name))
        seen[m.name] = true
      end
    end
  end
end

-- A macro name is one slot in the game, so the same name must always have the same text within a class.
for key, c in pairs(ns.CLASSES) do
  local bodies = {}
  for _, list in pairs(c.macros) do
    for _, m in ipairs(list) do
      T.check(bodies[m.name] == nil or bodies[m.name] == m.body,
        ("%s: '%s' has different text in different tabs"):format(key, m.name))
      bodies[m.name] = m.body
    end
  end
end

-- Melee rule: every macro in a melee tab starts auto-attacking, or has a nostart reason.
local MELEE = {
  WARRIOR = { "Utility", "Arms", "Fury", "Protection" },
  ROGUE   = { "Utility", "Assassination", "Combat", "Subtlety" },
  PALADIN = { "Protection", "Retribution" },
  SHAMAN  = { "Enhancement" },
  HUNTER  = { "Survival" },
  DRUID   = { "Feral Combat" },
}
for cls, specs in pairs(MELEE) do
  for _, spec in ipairs(specs) do
    for _, m in ipairs(ns.CLASSES[cls].macros[spec]) do
      local has = m.body:find("/startattack", 1, true) ~= nil
      T.check(has or m.nostart, ("%s %s: '%s' needs /startattack or a nostart reason"):format(cls, spec, m.name))
      T.check(not (has and m.nostart), ("%s %s: '%s' has /startattack and nostart"):format(cls, spec, m.name))
    end
  end
end

-- No macro may run Lua or change console settings.
for key, c in pairs(ns.CLASSES) do
  for _, list in pairs(c.macros) do
    for _, m in ipairs(list) do
      local low = m.body:lower()
      T.check(not (low:find("/run", 1, true) or low:find("/script", 1, true) or low:find("/console", 1, true)),
        ("%s: '%s' uses /run, /script or /console"):format(key, m.name))
    end
  end
end

-- Spell IDs: unique, numeric levels, and each one used by at least one macro.
local used = {}
for _, c in pairs(ns.CLASSES) do
  for _, list in pairs(c.macros) do
    for _, m in ipairs(list) do
      for line in m.body:gmatch("[^\n]+") do
        if line:match("^/cast") then
          for clause in line:gsub("^/cast%s+", ""):gmatch("[^;]+") do
            used[clause:gsub("%b[]", ""):match("^%s*!?(.-)%s*$")] = true
          end
        end
      end
    end
  end
end
local idSeen = {}
for name, e in pairs(ns.SPELL_IDS) do
  T.check(type(e.id) == "number" and not idSeen[e.id], name .. ": unique numeric spell ID")
  T.check(type(e.level) == "number", name .. ": has a level")
  T.check(used[name], name .. ": is used by at least one macro")
  idSeen[e.id] = true
end

-- README's count of unconfirmed spell names must match the data.
local readme = io.open("README.md"):read("*a")
local claimed = tonumber(readme:match("(%d+) macros use a spell name that has not been confirmed"))
T.eq(claimed, unverified, "README count of unconfirmed macros matches Data.lua")

io.write(("macro entries: %d, unconfirmed (v = false): %d, spell IDs: "):format(total, unverified))
local n = 0; for _ in pairs(ns.SPELL_IDS) do n = n + 1 end
io.write(n, "\n")
T.done("test_data")
