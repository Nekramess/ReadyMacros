-- Ready Macros macro library for World of Warcraft: Forever.
--
-- Structure: ns.CLASSES[CLASS] = { specs = {...}, macros = { [spec] = {...}, Utility = {...} } }
-- Each macro: name (max 16 chars), desc, body (max 255 chars),
--             v = true when every spell name in it was confirmed in a Forever source
--             (see the "Sources" comment on each class). v = false means the name is
--             carried over from original Classic and should be checked in your spellbook.
--
-- Research date: 27 Sept 2026, against beta/BlizzCon-demo coverage. Forever is still in beta,
-- so names can change before the 4 Nov 2026 launch.
local _, ns = ...

ns.CLASS_ORDER = {
  "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST",
  "SHAMAN", "MAGE", "WARLOCK", "DRUID", "GENERAL",
}

ns.UTILITY = "Utility" -- tab shown for every class: macros that fit any spec

ns.CLASSES = {
  ---------------------------------------------------------------------------
  GENERAL = {
    specs = {},
    macros = {
      Utility = {
        { name = "Stop Casting", desc = "Interrupt your own cast", body = "/stopcasting", v = true },
        { name = "Reload UI", desc = "Reload the interface", body = "/reload", v = true },
        { name = "Hearthstone", desc = "Use your Hearthstone", body = "#showtooltip Hearthstone\n/use Hearthstone", v = true },
        { name = "Follow Target", desc = "Follow your current target", body = "/follow", v = true },
        { name = "Mark Skull", desc = "Put a skull on your target", body = "/tm 8", v = true },
        { name = "Mark Cross", desc = "Put a cross on your target", body = "/tm 7", v = true },
        { name = "Clear Marks", desc = "Remove your target's marker", body = "/tm 0", v = true },
      },
    },
  },

  ---------------------------------------------------------------------------
  -- Sources: icy-veins.com/wow-forever/warrior-class-overview (Charge, Intercept, Heroic Strike,
  -- Sunder Armor, Shield Bash, Pummel, Revenge, Mortal Strike, Whirlwind, Execute, Overpower,
  -- Victory Rush, Thunder Clap, Shield Block, Taunt, Bloodthirst confirmed).
  -- Stance numbers assume Battle = 1, Defensive = 2, Berserker = 3.
  -- Mouseover Charge / Intercept / Taunt added from Wowhead's Classic Warrior macro guide
  -- (wowhead.com/classic/guide/classes/warrior/fury/dps-macros); spell names are the same in Forever.
  WARRIOR = {
    specs = { "Arms", "Fury", "Protection" },
    macros = {
      Utility = {
        { name = "Charge", desc = "Charge in Battle, Intercept in Berserker",
          body = "#showtooltip\n/startattack\n/cast [stance:1] Charge; [stance:3] Intercept; Battle Stance", v = true },
        { name = "MO Charge", desc = "Charge your mouseover, else target",
          body = "#showtooltip Charge\n/cast [@mouseover,harm,nodead][] Charge\n/startattack [@mouseover,harm,nodead][]", v = true },
        { name = "MO Intercept", desc = "Intercept your mouseover, else target",
          body = "#showtooltip Intercept\n/cast [@mouseover,harm,nodead][] Intercept\n/startattack [@mouseover,harm,nodead][]", v = true },
        { name = "MO Charge Any", desc = "Mouseover Charge or Intercept by stance",
          body = "#showtooltip\n/cast [stance:1,@mouseover,harm,nodead][stance:1] Charge; [stance:3,@mouseover,harm,nodead][stance:3] Intercept; Battle Stance\n/startattack [@mouseover,harm,nodead][]", v = true },
        { name = "Interrupt", desc = "Pummel in Berserker, else Shield Bash",
          body = "#showtooltip\n/startattack\n/cast [stance:3] Pummel; Shield Bash", v = true },
        { name = "MO Taunt", desc = "Taunt mouseover, else target",
          body = "#showtooltip\n/cast [@mouseover,harm,nodead][] Taunt", nostart = "Taunts an off-target; keeps your swings on your main target", v = true },
        { name = "Victory Rush", desc = "Start attacking + Victory Rush",
          body = "#showtooltip\n/startattack\n/cast Victory Rush", v = true },
        { name = "Heroic Strike", desc = "Start attacking + Heroic Strike",
          body = "#showtooltip\n/startattack\n/cast Heroic Strike", v = true },
        { name = "Sunder", desc = "Start attacking + Sunder Armor",
          body = "#showtooltip\n/startattack\n/cast Sunder Armor", v = true },
      },
      Arms = {
        { name = "Mortal Strike", desc = "Start attacking + Mortal Strike",
          body = "#showtooltip\n/startattack\n/cast Mortal Strike", v = true },
        { name = "Overpower", desc = "Overpower, swapping to Battle Stance",
          body = "#showtooltip Overpower\n/startattack\n/cast [stance:1] Overpower; Battle Stance", v = true },
        { name = "Execute", desc = "Start attacking + Execute",
          body = "#showtooltip\n/startattack\n/cast Execute", v = true },
        { name = "Victory Rush", desc = "Start attacking + Victory Rush",
          body = "#showtooltip\n/startattack\n/cast Victory Rush", v = true },
      },
      Fury = {
        { name = "Bloodthirst", desc = "Start attacking + Bloodthirst",
          body = "#showtooltip\n/startattack\n/cast Bloodthirst", v = true },
        { name = "Whirlwind", desc = "Whirlwind, swapping to Berserker Stance",
          body = "#showtooltip Whirlwind\n/startattack\n/cast [stance:3] Whirlwind; Berserker Stance", v = true },
        { name = "Pummel", desc = "Interrupt, swapping to Berserker Stance",
          body = "#showtooltip Pummel\n/startattack\n/cast [stance:3] Pummel; Berserker Stance", v = true },
        { name = "MO Intercept", desc = "Intercept your mouseover, else target",
          body = "#showtooltip Intercept\n/cast [@mouseover,harm,nodead][] Intercept\n/startattack [@mouseover,harm,nodead][]", v = true },
        { name = "Execute", desc = "Start attacking + Execute",
          body = "#showtooltip\n/startattack\n/cast Execute", v = true },
      },
      Protection = {
        { name = "Revenge", desc = "Revenge, swapping to Defensive Stance",
          body = "#showtooltip Revenge\n/startattack\n/cast [stance:2] Revenge; Defensive Stance", v = true },
        { name = "MO Taunt", desc = "Taunt mouseover, else target",
          body = "#showtooltip\n/cast [@mouseover,harm,nodead][] Taunt", nostart = "Taunts an off-target; keeps your swings on your main target", v = true },
        { name = "Shield Bash", desc = "Interrupt with Shield Bash",
          body = "#showtooltip\n/startattack\n/cast Shield Bash", v = true },
        { name = "Interrupt", desc = "Pummel in Berserker, else Shield Bash",
          body = "#showtooltip\n/startattack\n/cast [stance:3] Pummel; Shield Bash", v = true },
        { name = "Shield Block", desc = "Shield Block",
          body = "#showtooltip\n/cast Shield Block", nostart = "Defensive cooldown, not an attack", v = true },
        { name = "Thunder Clap", desc = "Thunder Clap (usable in Defensive now)",
          body = "#showtooltip\n/startattack\n/cast Thunder Clap", v = true },
      },
    },
  },

  ---------------------------------------------------------------------------
  -- Sources: icy-veins.com/wow-forever/paladin-class-overview (Holy Strike, Judgement spelling,
  -- Holy Shock, Flash of Light, Holy Light, Seal of Fury/Righteousness/Command, Consecration,
  -- Exorcism, Cleanse, Righteous Fury). Divine Shield not confirmed there.
  PALADIN = {
    specs = { "Holy", "Protection", "Retribution" },
    macros = {
      Utility = {
        -- Blessings and Purify fall back to yourself, not your target, when you aren't hovering a friendly unit.
        { name = "MO BoP", desc = "Blessing of Protection on mouseover, else yourself",
          body = "#showtooltip Blessing of Protection\n/cast [@mouseover,help,nodead][@player] Blessing of Protection", v = true },
        { name = "MO Freedom", desc = "Blessing of Freedom on mouseover, else yourself",
          body = "#showtooltip Blessing of Freedom\n/cast [@mouseover,help,nodead][@player] Blessing of Freedom", v = true },
        { name = "MO Purify", desc = "Purify on mouseover, else yourself",
          body = "#showtooltip Purify\n/cast [@mouseover,help,nodead][@player] Purify", v = true },
        { name = "MO Cleanse", desc = "Cleanse mouseover, else target",
          body = "#showtooltip\n/cast [@mouseover,help,nodead][] Cleanse", v = true },
        { name = "MO Flash", desc = "Flash of Light on mouseover, else target",
          body = "#showtooltip\n/cast [@mouseover,help,nodead][] Flash of Light", v = true },
        { name = "Judgement", desc = "Start attacking + Judgement (keeps seal now)",
          body = "#showtooltip\n/startattack\n/cast Judgement", v = true },
        { name = "Divine Shield", desc = "Divine Shield",
          body = "#showtooltip\n/cast Divine Shield", v = false },
      },
      Holy = {
        { name = "MO Holy Shock", desc = "Holy Shock mouseover (heal or damage)",
          body = "#showtooltip\n/cast [@mouseover,exists,nodead][] Holy Shock", v = true },
        { name = "MO Flash", desc = "Flash of Light on mouseover, else target",
          body = "#showtooltip\n/cast [@mouseover,help,nodead][] Flash of Light", v = true },
        { name = "MO Holy Light", desc = "Holy Light on mouseover, else target",
          body = "#showtooltip\n/cast [@mouseover,help,nodead][] Holy Light", v = true },
        { name = "MO Cleanse", desc = "Cleanse mouseover, else target",
          body = "#showtooltip\n/cast [@mouseover,help,nodead][] Cleanse", v = true },
      },
      Protection = {
        { name = "Seal of Fury", desc = "Tank seal (judging it taunts)",
          body = "#showtooltip\n/cast Seal of Fury", nostart = "Seal, not an attack", v = true },
        { name = "MO Judge", desc = "Judgement on mouseover (taunt with Fury)",
          body = "#showtooltip Judgement\n/cast [@mouseover,harm,nodead][] Judgement", nostart = "Taunts an off-target; keeps your swings on your main target", v = true },
        { name = "Consecration", desc = "Consecration",
          body = "#showtooltip\n/startattack\n/cast Consecration", v = true },
        { name = "Righteous Fury", desc = "Threat buff",
          body = "#showtooltip\n/cast Righteous Fury", nostart = "Self-buff, not an attack", v = true },
        { name = "Holy Strike", desc = "Start attacking + Holy Strike",
          body = "#showtooltip\n/startattack\n/cast Holy Strike", v = true },
      },
      Retribution = {
        { name = "Holy Strike", desc = "Start attacking + Holy Strike",
          body = "#showtooltip\n/startattack\n/cast Holy Strike", v = true },
        { name = "Judgement", desc = "Start attacking + Judgement",
          body = "#showtooltip\n/startattack\n/cast Judgement", v = true },
        { name = "Seal Command", desc = "Seal of Command",
          body = "#showtooltip\n/cast Seal of Command", nostart = "Seal, not an attack", v = true },
        { name = "Consecration", desc = "Consecration",
          body = "#showtooltip\n/startattack\n/cast Consecration", v = true },
        { name = "Exorcism", desc = "Exorcism",
          body = "#showtooltip\n/startattack\n/cast Exorcism", v = true },
      },
    },
  },

  ---------------------------------------------------------------------------
  -- Sources: icy-veins.com/wow-forever/hunter-class-overview (Aimed Shot baseline, Arcane Shot,
  -- Multi-Shot, Explosive Trap, Mongoose Bite, Summon Hawk, Sniper Shot, Strider Kick; Survival
  -- is now melee). Hunter's Mark, Feign Death, Mend Pet, Bestial Wrath not confirmed there.
  HUNTER = {
    specs = { "Beast Mastery", "Marksmanship", "Survival" },
    macros = {
      Utility = {
        { name = "Pet Attack", desc = "Send pet to attack", body = "/petattack", v = true },
        { name = "Pet Follow", desc = "Call pet back", body = "/petfollow", v = true },
        { name = "Feign Death", desc = "Feign Death and drop target",
          body = "#showtooltip Feign Death\n/petfollow\n/cast Feign Death", v = false },
        { name = "Mark + Pet", desc = "Hunter's Mark and send pet",
          body = "#showtooltip\n/cast Hunter's Mark\n/petattack", v = false },
      },
      ["Beast Mastery"] = {
        { name = "Arcane + Pet", desc = "Send pet + Arcane Shot",
          body = "#showtooltip\n/petattack\n/cast Arcane Shot", nostart = "Ranged shot, used before closing to melee", v = true },
        { name = "Summon Hawk", desc = "Summon a hawk (talent)",
          body = "#showtooltip\n/cast Summon Hawk", v = true },
        { name = "Bestial Wrath", desc = "Bestial Wrath + send pet",
          body = "#showtooltip\n/petattack\n/cast Bestial Wrath", v = false },
        { name = "Mend Pet", desc = "Heal your pet",
          body = "#showtooltip\n/cast Mend Pet", v = false },
      },
      Marksmanship = {
        { name = "Aimed Shot", desc = "Aimed Shot (shares CD with Multi-Shot)",
          body = "#showtooltip\n/cast Aimed Shot", v = true },
        { name = "Multi-Shot", desc = "Multi-Shot",
          body = "#showtooltip\n/cast Multi-Shot", v = true },
        { name = "Arcane Shot", desc = "Arcane Shot",
          body = "#showtooltip\n/cast Arcane Shot", v = true },
        { name = "Sniper Shot", desc = "Capstone burst shot (4 sec cast)",
          body = "#showtooltip\n/cast Sniper Shot", v = true },
      },
      Survival = {
        { name = "Mongoose Bite", desc = "Start attacking + Mongoose Bite",
          body = "#showtooltip\n/startattack\n/cast Mongoose Bite", v = true },
        { name = "Strider Kick", desc = "Start attacking + Strider Kick",
          body = "#showtooltip\n/startattack\n/cast Strider Kick", v = true },
        { name = "Explosive Trap", desc = "Explosive Trap",
          body = "#showtooltip\n/cast Explosive Trap", nostart = "Trap, not an attack", v = true },
        { name = "Arcane + Pet", desc = "Send pet + Arcane Shot",
          body = "#showtooltip\n/petattack\n/cast Arcane Shot", nostart = "Ranged shot, used before closing to melee", v = true },
      },
    },
  },

  ---------------------------------------------------------------------------
  -- Sources: icy-veins.com/wow-forever/rogue-class-overview (Kidney Shot, Sap, Adrenaline Rush,
  -- Blade Flurry, Evasion, Vanish, Backstab, Rupture, Mutilate, Ambush, Cold Blood, Hemorrhage).
  -- Sinister Strike, Kick, Cheap Shot, Eviscerate not confirmed there.
  ROGUE = {
    specs = { "Assassination", "Combat", "Subtlety" },
    macros = {
      Utility = {
        { name = "Sap", desc = "Sap only out of combat while stealthed",
          body = "#showtooltip\n/cast [nocombat,stealth] Sap", nostart = "Swinging would break the Sap", v = true },
        { name = "Kidney Shot", desc = "Kidney Shot",
          body = "#showtooltip\n/startattack\n/cast Kidney Shot", v = true },
        { name = "Vanish", desc = "Stop attacking, then Vanish",
          body = "#showtooltip Vanish\n/stopattack\n/cast Vanish", nostart = "Stops attacking on purpose so you can re-stealth", v = true },
        { name = "Kick", desc = "Interrupt with Kick",
          body = "#showtooltip\n/startattack\n/cast Kick", v = false },
      },
      Assassination = {
        { name = "Mutilate", desc = "Start attacking + Mutilate",
          body = "#showtooltip\n/startattack\n/cast Mutilate", v = true },
        { name = "Rupture", desc = "Rupture",
          body = "#showtooltip\n/startattack\n/cast Rupture", v = true },
        { name = "Cold Blood", desc = "Cold Blood",
          body = "#showtooltip\n/cast Cold Blood", nostart = "Cooldown, not an attack", v = true },
        { name = "Opener Mut", desc = "Ambush in stealth, else Mutilate",
          body = "#showtooltip\n/cast [stealth] Ambush; Mutilate\n/startattack [nostealth]", v = true },
      },
      Combat = {
        { name = "Sinister", desc = "Start attacking + Sinister Strike",
          body = "#showtooltip\n/startattack\n/cast Sinister Strike", v = false },
        { name = "Adrenaline", desc = "Adrenaline Rush",
          body = "#showtooltip\n/cast Adrenaline Rush", nostart = "Cooldown, not an attack", v = true },
        { name = "Blade Flurry", desc = "Blade Flurry",
          body = "#showtooltip\n/cast Blade Flurry", nostart = "Cooldown, not an attack", v = true },
        { name = "Evasion", desc = "Evasion",
          body = "#showtooltip\n/cast Evasion", nostart = "Defensive cooldown, not an attack", v = true },
      },
      Subtlety = {
        { name = "Opener", desc = "Ambush in stealth, else Backstab",
          body = "#showtooltip\n/cast [stealth] Ambush; Backstab\n/startattack [nostealth]", v = true },
        { name = "Hemorrhage", desc = "Start attacking + Hemorrhage",
          body = "#showtooltip\n/startattack\n/cast Hemorrhage", v = true },
        { name = "Backstab", desc = "Start attacking + Backstab",
          body = "#showtooltip\n/startattack\n/cast Backstab", v = true },
        { name = "Vanish", desc = "Stop attacking, then Vanish",
          body = "#showtooltip Vanish\n/stopattack\n/cast Vanish", nostart = "Stops attacking on purpose so you can re-stealth", v = true },
      },
    },
  },

  ---------------------------------------------------------------------------
  -- Sources: icy-veins.com/wow-forever/priest-class-overview (Shadow Word: Death, Devouring
  -- Plague, Fear Ward, Divine Spirit baseline; Penance, Prayer of Mending, Binding Heal talents;
  -- Power Word: Shield, Prayer of Healing, Shadow Word: Pain, Mind Flay, Vampiric Embrace,
  -- Shadowform). Flash Heal, Renew, Dispel Magic not confirmed there.
  PRIEST = {
    specs = { "Discipline", "Holy", "Shadow" },
    macros = {
      Utility = {
        { name = "MO Shield", desc = "Power Word: Shield on mouseover",
          body = "#showtooltip\n/cast [@mouseover,help,nodead][] Power Word: Shield", v = true },
        { name = "MO Fear Ward", desc = "Fear Ward on mouseover (now baseline)",
          body = "#showtooltip\n/cast [@mouseover,help,nodead][] Fear Ward", v = true },
        { name = "MO SW Death", desc = "Shadow Word: Death on mouseover",
          body = "#showtooltip\n/cast [@mouseover,harm,nodead][] Shadow Word: Death", v = true },
        { name = "MO Dispel", desc = "Dispel Magic on mouseover, else target",
          body = "#showtooltip\n/cast [@mouseover,exists,nodead][] Dispel Magic", v = false },
      },
      Discipline = {
        { name = "MO Penance", desc = "Penance mouseover (heal or damage)",
          body = "#showtooltip\n/cast [@mouseover,exists,nodead][] Penance", v = true },
        { name = "MO Shield", desc = "Power Word: Shield on mouseover",
          body = "#showtooltip\n/cast [@mouseover,help,nodead][] Power Word: Shield", v = true },
        { name = "MO Spirit", desc = "Divine Spirit on mouseover",
          body = "#showtooltip\n/cast [@mouseover,help,nodead][] Divine Spirit", v = true },
        { name = "MO Flash Heal", desc = "Flash Heal on mouseover, else target",
          body = "#showtooltip\n/cast [@mouseover,help,nodead][] Flash Heal", v = false },
      },
      Holy = {
        { name = "MO Mending", desc = "Prayer of Mending on mouseover",
          body = "#showtooltip\n/cast [@mouseover,help,nodead][] Prayer of Mending", v = true },
        { name = "MO Binding", desc = "Binding Heal on mouseover",
          body = "#showtooltip\n/cast [@mouseover,help,nodead][] Binding Heal", v = true },
        { name = "Group Heal", desc = "Prayer of Healing",
          body = "#showtooltip\n/cast Prayer of Healing", v = true },
        { name = "MO Renew", desc = "Renew on mouseover, else target",
          body = "#showtooltip\n/cast [@mouseover,help,nodead][] Renew", v = false },
      },
      Shadow = {
        { name = "MO SW Pain", desc = "Shadow Word: Pain on mouseover",
          body = "#showtooltip\n/cast [@mouseover,harm,nodead][] Shadow Word: Pain", v = true },
        { name = "MO Plague", desc = "Devouring Plague on mouseover",
          body = "#showtooltip\n/cast [@mouseover,harm,nodead][] Devouring Plague", v = true },
        { name = "Mind Flay", desc = "Mind Flay",
          body = "#showtooltip\n/cast Mind Flay", v = true },
        { name = "Shadowform", desc = "Enter Shadowform (won't cancel it)",
          body = "#showtooltip Shadowform\n/cast !Shadowform", v = true },
        { name = "MO Vamp Embrace", desc = "Vampiric Embrace on mouseover",
          body = "#showtooltip\n/cast [@mouseover,harm,nodead][] Vampiric Embrace", v = true },
      },
    },
  },

  ---------------------------------------------------------------------------
  -- Sources: icy-veins.com/wow-forever/shaman-class-overview (Lava Burst, Fire Nova rework,
  -- Lightning Bolt, Chain Lightning, Earth Shock as interrupt, Flame Shock, Healing Wave,
  -- Chain Heal, Stormstrike, Riptide, Water Shield, Call of the Elements, Totemic Recall).
  SHAMAN = {
    specs = { "Elemental", "Enhancement", "Restoration" },
    macros = {
      Utility = {
        { name = "Drop Totems", desc = "Call of the Elements (drops your set)",
          body = "#showtooltip\n/cast Call of the Elements", v = true },
        { name = "Totem Recall", desc = "Totemic Recall",
          body = "#showtooltip\n/cast Totemic Recall", v = true },
        { name = "MO Earth Shock", desc = "Earth Shock mouseover (interrupt)",
          body = "#showtooltip\n/cast [@mouseover,harm,nodead][] Earth Shock", v = true },
      },
      Elemental = {
        { name = "Lava Burst", desc = "Lava Burst",
          body = "#showtooltip\n/cast Lava Burst", v = true },
        { name = "Lightning Bolt", desc = "Lightning Bolt",
          body = "#showtooltip\n/cast Lightning Bolt", v = true },
        { name = "Chain Light", desc = "Chain Lightning",
          body = "#showtooltip\n/cast Chain Lightning", v = true },
        { name = "MO Flame Shock", desc = "Flame Shock on mouseover, else target",
          body = "#showtooltip\n/cast [@mouseover,harm,nodead][] Flame Shock", v = true },
      },
      Enhancement = {
        { name = "Stormstrike", desc = "Start attacking + Stormstrike",
          body = "#showtooltip\n/startattack\n/cast Stormstrike", v = true },
        -- Plain /startattack keeps your swings on your target while the shock goes to your mouseover.
        { name = "Enh Flame Shock", desc = "Start attacking + Flame Shock (mouseover)",
          body = "#showtooltip Flame Shock\n/startattack\n/cast [@mouseover,harm,nodead][] Flame Shock", v = true },
        { name = "Enh Earth Shock", desc = "Start attacking + Earth Shock (mouseover)",
          body = "#showtooltip Earth Shock\n/startattack\n/cast [@mouseover,harm,nodead][] Earth Shock", v = true },
        { name = "Enh Bolt", desc = "Start attacking + Lightning Bolt",
          body = "#showtooltip Lightning Bolt\n/startattack\n/cast Lightning Bolt", v = true },
      },
      Restoration = {
        { name = "MO Riptide", desc = "Riptide on mouseover, else target",
          body = "#showtooltip\n/cast [@mouseover,help,nodead][] Riptide", v = true },
        { name = "MO Heal Wave", desc = "Healing Wave on mouseover, else target",
          body = "#showtooltip\n/cast [@mouseover,help,nodead][] Healing Wave", v = true },
        { name = "MO Chain Heal", desc = "Chain Heal on mouseover, else target",
          body = "#showtooltip\n/cast [@mouseover,help,nodead][] Chain Heal", v = true },
        { name = "Water Shield", desc = "Water Shield",
          body = "#showtooltip\n/cast Water Shield", v = true },
      },
    },
  },

  ---------------------------------------------------------------------------
  -- Sources: icy-veins.com/wow-forever/mage-class-overview (Frostfire Bolt, Ice Lance,
  -- Arcane Blast, Arcane Missiles, Pyroblast, Fire Blast, Frostbolt, Fireball); games.gg Forever
  -- class guide (Frostfire Bolt baseline). Polymorph, Counterspell, Frost Nova, Conjure spells
  -- not confirmed there.
  MAGE = {
    specs = { "Arcane", "Fire", "Frost" },
    macros = {
      Utility = {
        { name = "MO Polymorph", desc = "Polymorph mouseover, else target",
          body = "#showtooltip\n/cast [@mouseover,harm,nodead][] Polymorph", v = false },
        { name = "Counterspell", desc = "Stop casting, then Counterspell",
          body = "#showtooltip Counterspell\n/stopcasting\n/cast Counterspell", v = false },
        { name = "Frostfire", desc = "Frostfire Bolt (baseline now)",
          body = "#showtooltip\n/cast Frostfire Bolt", v = true },
      },
      Arcane = {
        { name = "Arcane Blast", desc = "Arcane Blast",
          body = "#showtooltip\n/cast Arcane Blast", v = true },
        { name = "Arcane Missile", desc = "Arcane Missiles",
          body = "#showtooltip\n/cast Arcane Missiles", v = true },
      },
      Fire = {
        { name = "Fireball", desc = "Fireball",
          body = "#showtooltip\n/cast Fireball", v = true },
        { name = "Pyroblast", desc = "Pyroblast",
          body = "#showtooltip\n/cast Pyroblast", v = true },
        { name = "Fire Blast", desc = "Fire Blast",
          body = "#showtooltip\n/cast Fire Blast", v = true },
      },
      Frost = {
        { name = "Frostbolt", desc = "Frostbolt",
          body = "#showtooltip\n/cast Frostbolt", v = true },
        { name = "Ice Lance", desc = "Ice Lance",
          body = "#showtooltip\n/cast Ice Lance", v = true },
        { name = "Frost Nova", desc = "Frost Nova",
          body = "#showtooltip\n/cast Frost Nova", v = false },
      },
    },
  },

  ---------------------------------------------------------------------------
  -- Sources: icy-veins.com/wow-forever/warlock-class-overview (Shadow Bolt, Corruption, Immolate,
  -- Bane of Agony, Life Tap, Drain Life, Drain Soul, Fear, Conflagrate, Soul Fire, Searing Pain,
  -- Siphon Life, Incinerate); foreverwisp.com warlock beta guide (Curse -> Bane rename).
  WARLOCK = {
    specs = { "Affliction", "Demonology", "Destruction" },
    macros = {
      Utility = {
        { name = "Life Tap", desc = "Life Tap",
          body = "#showtooltip\n/cast Life Tap", v = true },
        { name = "MO Fear", desc = "Fear mouseover, else target",
          body = "#showtooltip\n/cast [@mouseover,harm,nodead][] Fear", v = true },
        { name = "Pet Attack", desc = "Send pet to attack", body = "/petattack", v = true },
        { name = "Pet Follow", desc = "Call pet back", body = "/petfollow", v = true },
      },
      Affliction = {
        { name = "MO Corruption", desc = "Corruption on mouseover, else target",
          body = "#showtooltip\n/cast [@mouseover,harm,nodead][] Corruption", v = true },
        { name = "MO Agony", desc = "Bane of Agony on mouseover (was Curse)",
          body = "#showtooltip\n/cast [@mouseover,harm,nodead][] Bane of Agony", v = true },
        { name = "MO Siphon Life", desc = "Siphon Life on mouseover, else target",
          body = "#showtooltip\n/cast [@mouseover,harm,nodead][] Siphon Life", v = true },
        { name = "Drain Soul", desc = "Drain Soul",
          body = "#showtooltip\n/cast Drain Soul", v = true },
      },
      Demonology = {
        { name = "Bolt + Pet", desc = "Send pet + Shadow Bolt",
          body = "#showtooltip\n/petattack\n/cast Shadow Bolt", v = true },
        { name = "MO Corruption", desc = "Corruption on mouseover, else target",
          body = "#showtooltip\n/cast [@mouseover,harm,nodead][] Corruption", v = true },
        { name = "Soul Fire", desc = "Soul Fire",
          body = "#showtooltip\n/cast Soul Fire", v = true },
      },
      Destruction = {
        { name = "MO Immolate", desc = "Immolate on mouseover, else target",
          body = "#showtooltip\n/cast [@mouseover,harm,nodead][] Immolate", v = true },
        { name = "Conflagrate", desc = "Conflagrate",
          body = "#showtooltip\n/cast Conflagrate", v = true },
        { name = "Incinerate", desc = "Incinerate",
          body = "#showtooltip\n/cast Incinerate", v = true },
        { name = "Searing Pain", desc = "Searing Pain",
          body = "#showtooltip\n/cast Searing Pain", v = true },
      },
    },
  },

  ---------------------------------------------------------------------------
  -- Sources: icy-veins.com/wow-forever/druid-class-overview (Revive, Rebirth, Omen of Clarity,
  -- Nature's Grasp baseline; Mangle, Berserk, Wild Growth talents; Maul, Rake, Rip,
  -- Rejuvenation, Healing Touch, Lacerate, Swiftmend, Tiger's Fury); wowhead Forever tuning
  -- (Wrath). Moonfire, Cat Form not confirmed there.
  DRUID = {
    specs = { "Balance", "Feral Combat", "Restoration" },
    macros = {
      Utility = {
        { name = "MO Rebirth", desc = "Combat res on mouseover, else target",
          body = "#showtooltip\n/cast [@mouseover,help,dead][] Rebirth", v = true },
        { name = "MO Revive", desc = "Out-of-combat res on mouseover",
          body = "#showtooltip\n/cast [@mouseover,help,dead][] Revive", v = true },
        { name = "Nature Grasp", desc = "Nature's Grasp (baseline now)",
          body = "#showtooltip\n/cast Nature's Grasp", v = true },
      },
      Balance = {
        { name = "Wrath", desc = "Wrath",
          body = "#showtooltip\n/cast Wrath", v = true },
        { name = "MO Moonfire", desc = "Moonfire on mouseover, else target",
          body = "#showtooltip\n/cast [@mouseover,harm,nodead][] Moonfire", v = false },
      },
      ["Feral Combat"] = {
        { name = "Maul", desc = "Start attacking + Maul",
          body = "#showtooltip\n/startattack\n/cast Maul", v = true },
        { name = "Mangle", desc = "Start attacking + Mangle (bear talent)",
          body = "#showtooltip\n/startattack\n/cast Mangle", v = true },
        { name = "Lacerate", desc = "Start attacking + Lacerate",
          body = "#showtooltip\n/startattack\n/cast Lacerate", v = true },
        { name = "Rake", desc = "Start attacking + Rake",
          body = "#showtooltip\n/startattack\n/cast Rake", v = true },
        { name = "Rip", desc = "Rip",
          body = "#showtooltip\n/startattack\n/cast Rip", v = true },
        { name = "Tiger's Fury", desc = "Tiger's Fury",
          body = "#showtooltip\n/cast Tiger's Fury", nostart = "Cooldown, not an attack", v = true },
        { name = "Berserk", desc = "Berserk (talent)",
          body = "#showtooltip\n/cast Berserk", nostart = "Cooldown, not an attack", v = true },
      },
      Restoration = {
        { name = "MO Rejuv", desc = "Rejuvenation on mouseover, else target",
          body = "#showtooltip\n/cast [@mouseover,help,nodead][] Rejuvenation", v = true },
        { name = "MO Healing T", desc = "Healing Touch on mouseover, else target",
          body = "#showtooltip\n/cast [@mouseover,help,nodead][] Healing Touch", v = true },
        { name = "MO Swiftmend", desc = "Swiftmend (no longer eats your HoT)",
          body = "#showtooltip\n/cast [@mouseover,help,nodead][] Swiftmend", v = true },
        { name = "MO Wild Growth", desc = "Wild Growth on mouseover (talent)",
          body = "#showtooltip\n/cast [@mouseover,help,nodead][] Wild Growth", v = true },
      },
    },
  },
}
