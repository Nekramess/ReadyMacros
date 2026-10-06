-- Minimal stand-in for the WoW client API, enough to load Ready Macros outside the game.
-- It is NOT the real client: frames only record text, scripts and visibility. Passing tests
-- prove the addon's own logic, not how the game renders or behaves.
local M = { frames = {}, printed = {}, macros = {}, equipped = {}, known = {}, ids = {}, shift = false }

local function newObj(kind)
  local o = { _kind = kind, _shown = true, _scripts = {}, _text = "", _enabled = true }
  return setmetatable(o, { __index = function(_, k)
    -- Plain data fields the addon reads must be nil until set (unknown keys otherwise
    -- return a no-op method, which is truthy).
    if k == "dragging" then return nil end
    local methods = {
      SetScript = function(self, n, f) self._scripts[n] = f end,
      GetScript = function(self, n) return self._scripts[n] end,
      Show = function(self) self._shown = true; if self._scripts.OnShow then self._scripts.OnShow(self) end end,
      Hide = function(self) self._shown = false end,
      SetShown = function(self, v) if v then self:Show() else self:Hide() end end,
      IsShown = function(self) return self._shown end,
      SetText = function(self, v) self._text = v end,
      GetText = function(self) return self._text end,
      Enable = function(self) self._enabled = true end,
      Disable = function(self) self._enabled = false end,
      CreateFontString = function() return newObj("FontString") end,
      CreateTexture = function() return newObj("Texture") end,
      GetFontString = function() return newObj("FontString") end,
      -- Anchors are only recorded (lastPoint = { point, relativeTo, relativePoint, x, y }).
      ClearAllPoints = function(self) self.lastPoint = nil end,
      SetPoint = function(self, p, rel, rp, x, y)
        if type(rel) ~= "table" then rel, rp, x, y = nil, rel, rp, x end  -- (point, x, y) form
        self.lastPoint = { p, rel, rp, x, y }
      end,
    }
    return methods[k] or function() end
  end })
end

-- Install globals. opts: class ("WARRIOR"), known = { [spellName] = spellID }, ids = { [spellID] = name }
function M.install(opts)
  opts = opts or {}
  M.known = opts.known or {}
  M.ids = opts.ids or {}
  for name, id in pairs(M.known) do M.ids[id] = name end
  CreateFrame = function(kind, name)
    local f = newObj(kind); M.frames[#M.frames + 1] = f
    if type(name) == "string" then _G[name] = f end   -- named frames become globals, as in the client
    return f
  end
  -- Minimap support. Forever's UI source defines the Minimap frame (Blizzard_Minimap) and
  -- GetCursorPosition (InputDocumentation.lua) but NO GetMinimapShape: that global comes
  -- from minimap addons, so install() never defines it. Tests set/clear _G.GetMinimapShape.
  M.cursor, M.timers = { 0, 0 }, {}
  GetCursorPosition = function() return M.cursor[1], M.cursor[2] end
  C_Timer = { After = function(_, fn) M.timers[#M.timers + 1] = fn end }
  GetMinimapShape = nil
  local mm = newObj("Minimap")
  mm.GetWidth, mm.GetHeight = function() return 140 end, function() return 140 end
  mm.GetCenter = function() return 1000, 500 end   -- centre in UIParent units (may return nothing in the real client)
  mm.GetEffectiveScale = function() return 1 end
  Minimap = mm
  UIParent, GameTooltip = newObj("Frame"), newObj("GameTooltip")
  UISpecialFrames, SlashCmdList, ChatFontNormal = {}, {}, {}
  tinsert, unpack = table.insert, unpack or table.unpack
  GameTooltip_Hide = function() end
  RAID_CLASS_COLORS = { WARRIOR = { r = 0.78, g = 0.61, b = 0.43 } }
  LOCALIZED_CLASS_NAMES_MALE = { WARRIOR = "Warrior", PALADIN = "Paladin", MAGE = "Mage" }
  print = function(...)
    local t = {}
    for i = 1, select("#", ...) do t[#t + 1] = tostring(select(i, ...)) end
    M.printed[#M.printed + 1] = table.concat(t, " ")
  end
  InCombatLockdown = function() return false end
  IsShiftKeyDown = function() return M.shift end
  local class = opts.class or "WARRIOR"
  UnitClass = function() return class, class end
  UnitName = function() return "Tester" end
  GetRealmName = function() return "Forever" end
  MAX_ACCOUNT_MACROS, MAX_CHARACTER_MACROS = 120, 18
  GetNumMacros = function()
    local a, c = 0, 0
    for i in pairs(M.macros) do if i <= 120 then a = a + 1 else c = c + 1 end end
    return a, c
  end
  GetMacroInfo = function(i) local m = M.macros[i]; if m then return m[1], m[2], m[3] end end
  GetMacroIndexByName = function(n) for i, m in pairs(M.macros) do if m[1] == n then return i end end return 0 end
  CreateMacro = function(n, icon, body) local i = 121; while M.macros[i] do i = i + 1 end; M.macros[i] = { n, icon, body }; return i end
  EditMacro = function(i, n, icon, body) M.macros[i] = { n, icon, body } end
  GetInventoryItemLink = function(_, slot) return M.equipped[slot] end
  GetInventoryItemTexture = function(_, slot) return 9000 + slot end
  C_Spell = { GetSpellInfo = function(x)
    if type(x) == "number" then local n = M.ids[x]; return n and { name = n, spellID = x } or nil end
    local id = M.known[x]; return id and { name = x, spellID = id } or nil
  end }
  IsPlayerSpell = function(id) local n = M.ids[id]; return n ~= nil and M.known[n] ~= nil end
  -- Forever's real namespaces (Blizzard_APIDocumentationGenerated: SpellBookDocumentation, SpecializationInfoDocumentation)
  Enum = Enum or {}
  Enum.SpellBookSpellBank = { Player = 0, Pet = 1 }
  C_SpellBook = { IsSpellKnown = function(id, bank) local n = M.ids[id]; return n ~= nil and M.known[n] ~= nil end }
  C_SpecializationInfo = { GetSpecialization = function() return M.spec end }
end

-- Files listed in ReadyMacros.toc, in load order.
function M.tocFiles()
  local files = {}
  for line in io.lines("ReadyMacros.toc") do
    line = line:gsub("\r", ""):match("^%s*(.-)%s*$")
    if line ~= "" and not line:match("^#") then files[#files + 1] = line end
  end
  return files
end

-- Load addon files from the repo root (default: the .toc list), sharing one namespace table.
function M.load(files)
  files = files or M.tocFiles()
  local ns = {}
  for _, f in ipairs(files) do assert(loadfile(f))("ReadyMacros", ns) end
  return ns
end

function M.itemLink(name) return "|cffffffff|Hitem:1|h[" .. name .. "]|h|r" end

-- Fire an event on every frame that has an OnEvent script.
function M.fire(event, ...)
  for _, f in ipairs(M.frames) do
    if f._scripts.OnEvent then f._scripts.OnEvent(f, event, ...) end
  end
end

-- Visible macro/action rows in the main window.
function M.rows()
  local r = {}
  for _, f in ipairs(M.frames) do
    if rawget(f, "entry") ~= nil and f._shown then r[#r + 1] = f end
  end
  return r
end

function M.rowName(f) local e = f.entry; return e.kind == "macro" and e.macro.name or e.label end

function M.click(name)
  for _, f in ipairs(M.rows()) do
    if M.rowName(f) == name then f._scripts.OnClick(f); return end
  end
  error("no visible row named " .. name, 2)
end

function M.button(text)
  for _, f in ipairs(M.frames) do
    if f._text == text and f._scripts.OnClick then return f end
  end
  error("no button labelled " .. text, 2)
end

function M.press(text) local b = M.button(text); b._scripts.OnClick(b) end

function M.icon(key)
  for _, f in ipairs(M.frames) do if rawget(f, "key") == key then return f end end
  error("no class icon " .. key, 2)
end

-- Run and clear pending C_Timer.After callbacks (delay is ignored).
function M.runTimers()
  local t = M.timers; M.timers = {}
  for _, fn in ipairs(t) do fn() end
end

function M.lastPrint() return M.printed[#M.printed] or "" end

-- Tiny test runner
local passed, failed = 0, 0
function M.check(ok, msg)
  if ok then passed = passed + 1 else failed = failed + 1; io.write("  FAIL: ", msg, "\n") end
end
function M.eq(got, want, msg)
  M.check(got == want, ("%s (got %s, want %s)"):format(msg, tostring(got), tostring(want)))
end
function M.done(name)
  io.write(("%s: %d passed, %d failed\n"):format(name, passed, failed))
  os.exit(failed == 0 and 0 or 1)
end

return M
