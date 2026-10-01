# Ready Macros

One-click, character-specific macros for World of Warcraft: Forever, sorted by class and spec.

## What it does

Ready Macros shows a list of ready-made macros for each class and spec. Click one and it is added to your character-specific macro tab. It checks the spells in each macro against your own spellbook, so you can see what works now, what you learn later, and what may be wrong. It also saves your own macros so you can add them on other characters, and builds weapon swap macros from the weapons you have equipped.

## Features

**Macro lists**
- Class icon row for all 9 classes, plus a General icon for macros that work on any class (Hearthstone, raid markers, `/reload`, and so on).
- Each class has a tab for each of its 3 specs, plus an "All specs" tab for class macros that fit any spec.
- Opens on your own class. It tries to open on your current spec. If it can't detect your spec, it opens on the last spec you viewed for that class, or the first spec.
- Up to 8 macros per page, with Prev/Next buttons for longer lists.
- Hover a macro to see its full text.
- 155 list entries in total. Some macros appear in more than one tab.

**Creating macros**
- Clicking a macro creates it in your **character-specific** macro tab, never the account-wide tab.
- New macros use the question-mark icon with `#showtooltip`, so the game shows the spell's own icon.
- It won't create a macro if one with the same name already exists, if your character macro slots are full, or during combat.
- A counter shows how many character macro slots you've used.

**Macro style**
- Many heals, dispels, DoTs and crowd control spells use mouseover: `[@mouseover,...][]` casts on your mouseover, or on your target if you're not hovering anything.
- Warrior macros that change stance: Charge/Intercept by stance, Overpower, Whirlwind, Pummel and Revenge switch to the right stance if you're not in it.
- Melee macros start auto-attacking (`/startattack`). The only exceptions are macros where attacking would be wrong: Sap, Vanish, cooldowns, buffs, seals, traps, and taunts aimed at a mouseover target. Rogue stealth openers only start attacking once you're out of stealth.

**Spell check (your own class only)**
- Each spell in a macro is checked against your client:
  - **Green, "in your spellbook":** you know every spell in the macro.
  - **Green, "works now, full at lvl X":** part of the macro works now, and the rest unlocks later.
  - **Grey, "trainer (lvl X)" or "talent (lvl X)":** the spell exists in the game, but you haven't learned it yet.
  - **Orange, "check tooltip":** a spell was renamed, isn't found in the game, or isn't in your spellbook and has no ID on file. The tooltip says which.
- Telling "not learned yet" apart from "missing" needs a spell ID. IDs are on file for 18 Warrior spells only. For other spells, the check can only confirm spells you already know.
- Other classes can't be checked in-game. Their macros are marked orange "check spell name" when the spell name wasn't confirmed by a Forever source.
- The list refreshes when you learn spells, change talents, change macros or change equipment.

**Spell ID report: `/mk ids`**
- Lists every spell in your class's macros: OK, NEW (known to your client, no ID on file), LATER (not learned yet), or a problem (MISMATCH, RENAMED, GONE, UNKNOWN).
- The text is selected so you can copy it with Ctrl+C.
- Spell IDs your client knows are recorded, so spells with no ID on file (such as Victory Rush) get one from your own game.

**My Macros (notepad icon at the end of the class row)**
- **Import:** lists every macro on the current character, account-wide and character-specific. Click one to save it.
- **Saved:** your saved macros, shared by every character on your account. Click one to add it to the current character. Shift-click to remove it from the saved list. If you save a different macro under a name that's already used, it's saved as "Name 2".
- **Weapon swap:** equip a set of weapons and click "Capture Set 1", then do the same for "Capture Set 2". You don't type item names. This creates "Weapon Set 1" and "Weapon Set 2" macros using `/equipslot`. After recapturing, click the macro again to update it. Weapon sets are stored per character.

## Install

1. Copy the `ReadyMacros` folder into `World of Warcraft/<game folder>/Interface/AddOns/`. During the beta the game folder is `_classic_beta_`. The folder name must be `AddOns`, not `Addons`.
2. Restart the game or type `/reload`.

### Upgrading from MacroKit

Ready Macros was called MacroKit before v0.7.0.

1. Delete the old `Interface/AddOns/MacroKit` folder. Both use `/mk`, so keeping both causes conflicts.
2. Optional: to keep your saved macros, weapon sets and recorded spell IDs, close the game first. Then, in `WTF/Account/<your account>/SavedVariables/`, copy `MacroKit.lua` to `ReadyMacros.lua`, and in the new file change `MacroKitDB` to `ReadyMacrosDB` on the first line.

Macros you already created stay in your macro window either way.

## Usage

1. Type `/mk` (or `/readymacros`) to open or close the window. Esc also closes it.
2. Click a class icon. Your own class is selected when you log in.
3. Click a spec tab, or "All specs".
4. Hover a macro to see its text and check result. Click it to add it to your character macros.
5. Place the macro from the game's macro window (`/macro`) onto your action bar.
6. To reuse a macro on another character: open the notepad icon, go to Import, and click the macro. Then log in to the other character, go to Saved, and click it.
7. To make weapon swap macros: open the notepad icon, go to Weapon swap, equip each set and capture it, then click "Weapon Set 1" and "Weapon Set 2".
8. Type `/mk ids` for the spell ID report.

| Command | What it does |
|---|---|
| `/mk`, `/readymacros` | Open or close the main window |
| `/mk ids` | Show the copyable spell ID report for your class |

## Known limits

- **Tested in-game:** the class icon row, spec tabs, spell check colors and level labels were seen working on a level 9 Warrior (up to v0.4.1).
- **Not yet tested in-game:** v0.5 and later features (`/mk ids`, My Macros, the weapon swap builder, paging, the `/startattack` changes, and the v0.7.0 rename). These were tested only against a simulated game API.
- **`/equipslot` in Forever is unconfirmed.** It works in Classic and modern WoW. Whether it works in combat in Forever is not confirmed.
- **Spell names come from beta coverage** (mainly Icy Veins' Forever class guides, checked 27 Sept 2026) and may change before or after launch. 14 macros use a spell name no Forever source confirmed. They are marked orange for other classes:
  Bestial Wrath, Counterspell, Divine Shield, Feign Death, Frost Nova, Hunter's Mark, Kick, Dispel Magic, Flash Heal, Moonfire, Polymorph, Renew, Mend Pet, Sinister Strike.
- **Spell IDs are on file for Warrior only.** Victory Rush has no confirmed Forever ID yet.
- **Rank checks are untested.** It's not confirmed whether the game recognizes a rank 1 spell ID after you've learned a higher rank. The name check covers this case.
- **Spec detection is a best guess.** Forever's talent API isn't documented, so Ready Macros may open on the wrong spec tab.
- **Macros that combine spells show a single level.** They show the level at which the whole macro works. For example, Interrupt shows level 38 (Pummel), although its Shield Bash part works from level 12. The tooltip lists each spell.
- **Warrior stance macros assume** Battle = 1, Defensive = 2, Berserker = 3.
- **Existing macros are never overwritten,** except "Weapon Set" macros. To get an updated version of a macro, delete your copy in `/macro` and click it again.
- **The `/mk ids` report doesn't scroll.** A very long list may be cut off.
- **Weapon swap uses two buttons, not a toggle.**

## Version

- Version: 0.7.0
- Interface: 16001 (the number the Forever beta client reports, checked in-game 30 Sep 2026)
- Saved variables: `ReadyMacrosDB`. Saved macros and recorded spell IDs are shared across your account. Weapon sets and the last viewed spec per class are also stored there; weapon sets are kept per character.

## Changelog

- **0.7.0** (30 Sep 2026): Renamed from MacroKit to Ready Macros. Interface set to 16001. Added `/readymacros` (`/mk` still works; `/macrokit` removed). Saved data moved to `ReadyMacrosDB` (see Upgrading from MacroKit).
- **0.6.1** (29 Sep 2026): Melee macros start auto-attacking, with documented exceptions. Added Enhancement Shaman macros that start attacking: Enh Flame Shock, Enh Earth Shock and Enh Bolt.
- **0.6.0** (27 Sep 2026): Warrior mouseover Charge, Intercept and Taunt. Stance-aware mouseover Charge/Intercept and Interrupt. Paging. My Macros (Saved, Import, Weapon swap).
- **0.5.0** (27 Sep 2026): `/mk ids` report. Spell IDs are recorded from your client.
- **0.4.1** (27 Sep 2026): Stance swaps no longer count as "works now".
- **0.4.0** (27 Sep 2026): Spell IDs for Warrior. The spell check now separates "learn later" (with level) from "renamed or missing".
- **0.3.0** (27 Sep 2026): Spell names are checked against your client.
- **0.2.0** (27 Sep 2026): Spec tabs, class icons, spell names checked against Forever sources, unconfirmed names flagged.
- **0.1.0** (27 Sep 2026): First version. Class lists and one-click character macros.
