-- Ready Macros spell verification: checks macro spell names against the game client itself.
local _, ns = ...

-- Pull the spell names out of every /cast line, dropping [conditionals] and the ! prefix.
-- "/cast [stance:1] Charge; [stance:3] Intercept; Battle Stance" -> Charge, Intercept, Battle Stance
function ns.SpellsInBody(body)
  local spells = {}
  for line in body:gmatch("[^\n]+") do
    local cmd, args = line:match("^/(%a+)%s+(.+)$")
    if cmd and cmd:lower() == "cast" then
      for clause in args:gmatch("[^;]+") do
        local name = clause:gsub("%b[]", ""):gsub("^%s+", ""):gsub("%s+$", ""):gsub("^!", "")
        if name ~= "" then spells[#spells + 1] = name end
      end
    end
  end
  return spells
end

local function HasAPI()
  return (C_Spell and C_Spell.GetSpellInfo) or GetSpellInfo
end

local function LookUp(idOrName)
  if C_Spell and C_Spell.GetSpellInfo then
    local ok, info = pcall(C_Spell.GetSpellInfo, idOrName)
    return ok and info or nil
  elseif GetSpellInfo then
    local name, _, _, _, _, _, spellID = GetSpellInfo(idOrName)
    return name and { name = name, spellID = spellID } or nil
  end
end
ns.LookUp = LookUp

-- Remember the ID of every spell the client resolves by name, so spells with no ID on file
-- (like Victory Rush) get one from your own game. Stored in ReadyMacrosDB.seenIDs.
local function RecordSeen(name, info)
  if ReadyMacrosDB and info and info.spellID then
    ReadyMacrosDB.seenIDs = ReadyMacrosDB.seenIDs or {}
    ReadyMacrosDB.seenIDs[name] = info.spellID
  end
end

local function KnownByID(id)
  if IsPlayerSpell then
    local ok, known = pcall(IsPlayerSpell, id)
    if ok and known then return true end
  end
  return false
end

-- Check one spell name. Returns one of:
--   "known"                        you have it
--   "unlearned", entry             exists in the client, not learned yet (entry has level/talent)
--   "renamed",   newName           the ID now carries a different name
--   "gone"                         the ID doesn't resolve in the client at all
--   "missing"                      no ID on file and the name didn't resolve
-- By name, the client generally only resolves spells your character has learned.
function ns.CheckSpell(name)
  local byName = LookUp(name)
  if byName then
    RecordSeen(name, byName)
    return "known"
  end

  local entry = ns.SPELL_IDS and ns.SPELL_IDS[name]
  if not entry then
    local seen = ReadyMacrosDB and ReadyMacrosDB.seenIDs and ReadyMacrosDB.seenIDs[name]
    if not seen then return "missing" end
    entry = { id = seen } -- learned before on this character, e.g. then respecced away
  end

  local info = LookUp(entry.id)
  if not info then return "gone" end
  if info.name ~= name then return "renamed", info.name end
  if KnownByID(entry.id) then return "known" end
  return "unlearned", entry
end

-- Status for one macro, worst result wins:
--   "problem"     a spell was renamed, has vanished, or didn't resolve (details list why)
--   "unlearned"   every spell exists, some aren't learned yet (details list name + level)
--   "partial"     like unlearned, but at least one spell is known, so part of it works now
--   "found"       every spell is known
--   "ok"          nothing checkable in-game, and sources confirmed it (or it has no spells)
--   "unconfirmed" nothing checkable in-game, and sources didn't confirm it
-- Only the player's own class can be checked in-game; other classes use the research flag.
function ns.CheckMacro(m, classKey)
  local fallback = m.v and "ok" or "unconfirmed"
  if classKey ~= ns.playerClass or not HasAPI() then return fallback end

  local spells = ns.SpellsInBody(m.body)
  if #spells == 0 then return fallback end

  local problems, unlearned, knownCount = {}, {}, 0
  for _, s in ipairs(spells) do
    local st, extra = ns.CheckSpell(s)
    if st == "known" then
      local e = ns.SPELL_IDS and ns.SPELL_IDS[s]
      if not (e and e.stance) then knownCount = knownCount + 1 end
    elseif st == "renamed" then
      problems[#problems + 1] = s .. " is now called " .. extra
    elseif st == "gone" then
      problems[#problems + 1] = s .. " (spell ID not found in game)"
    elseif st == "missing" then
      problems[#problems + 1] = s .. " (not in spellbook)"
    elseif st == "unlearned" then
      unlearned[#unlearned + 1] = { name = s, level = extra.level, talent = extra.talent }
    end
  end
  if #problems > 0 then return "problem", problems end
  if #unlearned > 0 and knownCount > 0 then return "partial", unlearned end
  if #unlearned > 0 then return "unlearned", unlearned end
  return "found"
end

-- Short label for an unlearned macro: the level at which it fully works.
function ns.UnlearnedLabel(list)
  local maxLevel, talent = 0, false
  for _, u in ipairs(list) do
    if (u.level or 0) > maxLevel then maxLevel = u.level or 0 end
    if u.talent then talent = true end
  end
  if maxLevel == 0 then return talent and "talent" or "not learned" end
  if talent then return ("talent (lvl %d)"):format(maxLevel) end
  return ("trainer (lvl %d)"):format(maxLevel)
end

---------------------------------------------------------------------------
-- /mk ids report: every spell in your class's macros, checked against your client.
---------------------------------------------------------------------------
local function ClassSpellNames(classKey)
  local set, names = {}, {}
  local data = ns.CLASSES[classKey]
  if not data then return names end
  for _, list in pairs(data.macros) do
    for _, m in ipairs(list) do
      for _, s in ipairs(ns.SpellsInBody(m.body)) do
        if not set[s] then set[s] = true; names[#names + 1] = s end
      end
    end
  end
  table.sort(names)
  return names
end

-- Returns report lines plus a list of { name, id } for spells your client knows that have no ID on file.
function ns.IDReport(classKey)
  local lines, new = {}, {}
  local counts = { ok = 0, new = 0, unlearned = 0, problem = 0 }
  for _, name in ipairs(ClassSpellNames(classKey)) do
    local entry = ns.SPELL_IDS and ns.SPELL_IDS[name]
    local mine = LookUp(name)
    if mine then RecordSeen(name, mine) end
    local myID = mine and mine.spellID

    if mine and entry then
      local filed = LookUp(entry.id)
      if filed and filed.name == name then
        counts.ok = counts.ok + 1
        local note = (myID and myID ~= entry.id) and (" (your rank: %d)"):format(myID) or ""
        lines[#lines + 1] = ("OK        %s  id %d%s"):format(name, entry.id, note)
      else
        counts.problem = counts.problem + 1
        lines[#lines + 1] = ("MISMATCH  %s  filed id %d is %s in your game; yours is %s"):format(
          name, entry.id, filed and ('"' .. filed.name .. '"') or "missing", tostring(myID))
      end
    elseif mine then
      counts.new = counts.new + 1
      new[#new + 1] = { name = name, id = myID }
      lines[#lines + 1] = ("NEW       %s  id %s (from your spellbook, not on file)"):format(name, tostring(myID))
    else
      local st, extra = ns.CheckSpell(name)
      if st == "unlearned" then
        counts.unlearned = counts.unlearned + 1
        lines[#lines + 1] = ("LATER     %s  id %d, %s"):format(name, extra.id, ns.UnlearnedLabel({ extra }))
      elseif st == "renamed" then
        counts.problem = counts.problem + 1
        lines[#lines + 1] = ("RENAMED   %s  now called %s"):format(name, extra)
      elseif st == "gone" then
        counts.problem = counts.problem + 1
        lines[#lines + 1] = ("GONE      %s  id %d not found in your game"):format(name, entry.id)
      else
        counts.problem = counts.problem + 1
        lines[#lines + 1] = ("UNKNOWN   %s  not learned, no ID on file"):format(name)
      end
    end
  end
  table.insert(lines, 1, ("%s: %d ok, %d new, %d learn later, %d to check"):format(
    classKey, counts.ok, counts.new, counts.unlearned, counts.problem))
  table.insert(lines, 2, "")
  if #new > 0 then
    lines[#lines + 1] = ""
    lines[#lines + 1] = "-- New IDs from your client (paste these back to add them to SpellIDs.lua):"
    for _, n in ipairs(new) do
      lines[#lines + 1] = ('  ["%s"] = { id = %s },'):format(n.name, tostring(n.id))
    end
  end
  return lines
end
