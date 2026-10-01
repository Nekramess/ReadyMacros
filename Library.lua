-- Ready Macros library: your own saved macros (shared across characters) and weapon swap sets.
local _, ns = ...

local MAIN_HAND, OFF_HAND = 16, 17

function ns.CharKey()
  local name = UnitName("player") or "?"
  local realm = (GetRealmName and GetRealmName()) or "?"
  return name .. "-" .. realm
end

---------------------------------------------------------------------------
-- Saved macros (account-wide: ReadyMacrosDB is shared by every character on the account)
---------------------------------------------------------------------------
function ns.GetSaved()
  ReadyMacrosDB.saved = ReadyMacrosDB.saved or {}
  return ReadyMacrosDB.saved
end

function ns.IsSaved(name, body)
  for _, s in ipairs(ns.GetSaved()) do
    if s.name == name and s.body == body then return true end
  end
  return false
end

-- Returns "saved", "exists" (same name + text already saved) or "renamed" (name taken by
-- different text, so it was saved as "Name 2" etc.), plus the name used.
function ns.SaveMacro(name, body, icon, classKey)
  if ns.IsSaved(name, body) then return "exists", name end
  local saved = ns.GetSaved()
  local taken = {}
  for _, s in ipairs(saved) do taken[s.name] = true end
  local finalName, n = name, 2
  while taken[finalName] do
    local suffix = " " .. n
    finalName = name:sub(1, 16 - #suffix) .. suffix -- macro names max 16 chars
    n = n + 1
  end
  saved[#saved + 1] = { name = finalName, body = body, icon = icon, class = classKey }
  return finalName == name and "saved" or "renamed", finalName
end

function ns.RemoveSaved(index)
  table.remove(ns.GetSaved(), index)
end

-- Every macro on this character: account-wide tab first, then character-specific.
function ns.CharacterMacros()
  local list = {}
  local numAccount, numChar = GetNumMacros()
  local charOffset = MAX_ACCOUNT_MACROS or 120
  local function add(index, perChar)
    local name, icon, body = GetMacroInfo(index)
    if name then list[#list + 1] = { name = name, icon = icon, body = body or "", perChar = perChar } end
  end
  for i = 1, numAccount do add(i, false) end
  for i = 1, numChar do add(charOffset + i, true) end
  return list
end

---------------------------------------------------------------------------
-- Weapon sets (per character): capture what's equipped, then build a macro from it
---------------------------------------------------------------------------
local function ItemNameFromLink(link)
  return link and link:match("%[(.-)%]")
end

local function SetsForCharacter()
  ReadyMacrosDB.weaponSets = ReadyMacrosDB.weaponSets or {}
  local key = ns.CharKey()
  ReadyMacrosDB.weaponSets[key] = ReadyMacrosDB.weaponSets[key] or {}
  return ReadyMacrosDB.weaponSets[key]
end

function ns.GetWeaponSet(index)
  return SetsForCharacter()[index]
end

-- Captures main and off hand. Off hand is nil for a two-hander or an empty slot.
function ns.CaptureWeaponSet(index)
  local main = ItemNameFromLink(GetInventoryItemLink("player", MAIN_HAND))
  if not main then return nil, "Nothing equipped in your main hand." end
  local off = ItemNameFromLink(GetInventoryItemLink("player", OFF_HAND))
  local set = { main = main, off = off, icon = GetInventoryItemTexture("player", MAIN_HAND) }
  SetsForCharacter()[index] = set
  return set
end

function ns.DescribeWeaponSet(set)
  if not set then return "Not captured yet" end
  if set.off then return set.main .. " + " .. set.off end
  return set.main .. " (no off hand)"
end

-- Macro that equips the set by slot. For a two-hander only the main hand line is needed:
-- equipping it clears the off hand automatically.
function ns.WeaponSetMacro(index)
  local set = ns.GetWeaponSet(index)
  if not set then return nil end
  local lines = { "/equipslot " .. MAIN_HAND .. " " .. set.main }
  if set.off then lines[#lines + 1] = "/equipslot " .. OFF_HAND .. " " .. set.off end
  local body = table.concat(lines, "\n")
  if #body > 255 then return nil, "Item names are too long to fit in one macro." end
  return { name = "Weapon Set " .. index, desc = ns.DescribeWeaponSet(set), body = body, icon = set.icon, v = true }
end
