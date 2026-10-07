# Ready Macros: notes for Claude sessions

World of Warcraft: Forever addon (Lua 5.1). Players pick a class and spec, click a ready-made macro, and it is created in their character-specific macro tab. It also checks macro spells against the player's spellbook, saves macros for reuse on other characters, and builds weapon swap macros.

Owner: Anthony (GitHub `Nekramess`). He values verified facts over confident guesses: say what is confirmed, what isn't, and where a fact came from.

## Current state (keep this section up to date)

- Version 0.8.1, `## Interface: 16001` (the number the Forever beta client reports; Anthony checked it in-game on 30 Sep 2026 with `/run print(select(4, GetBuildInfo()))`).
- Commands: `/readymacros`, `/rmac`, `/rmac ids`, `/rmac minimap on|off|square|round|auto`.
- Seen working in the live client: class icon row, spec tabs, spell check colors and level labels (on a level 9 Warrior).
- Tested only with the simulated client in `tools/tests/`: `/rmac ids`, My Macros, weapon swap, paging, `/startattack` changes, the Paladin blessing macros, the minimap button (`Minimap.lua`, tested in `tools/tests/test_minimap.lua`; not yet seen in the live client; Forever's UI source does not define `GetMinimapShape`, it is an optional global that minimap addons define).
- Forever API notes (checked against the Forever UI source, 6 Oct 2026): spec detection uses `C_SpecializationInfo.GetSpecialization` with the global as fallback, and "known by ID" uses `C_SpellBook.IsSpellKnown(id, Enum.SpellBookSpellBank.Player)` with `IsPlayerSpell` as fallback; both globals are only deprecated shims in Forever (CVar `loadDeprecationFallbacks`). Not confirmed in the live client.
- Unconfirmed: whether `/equipslot` works in Forever (and in combat); whether `IsPlayerSpell(rank1ID)` is true once a higher rank is learned; spec detection (`GetSpecialization` may not exist or match in Forever).

## Naming rule

The addon was renamed before release. Never reintroduce the previous addon name or its old short slash command anywhere: code, README, file names, zips, commit messages or PR text. Anthony requires a complete break from it. All identifiers use `ReadyMacros` / `READYMACROS` / "Ready Macros".

## Files (load order is `ReadyMacros.toc`)

| File | What it holds |
|---|---|
| `ReadyMacros.toc` | Interface, Title, Version, `SavedVariables: ReadyMacrosDB`, file list |
| `Data.lua` | Every macro: `ns.CLASS_ORDER`, `ns.UTILITY` ("Utility" = the "All specs" tab), `ns.CLASSES` |
| `SpellIDs.lua` | `ns.SPELL_IDS`: spell name -> `{ id, level, talent?, stance? }` |
| `Verify.lua` | Spell check: parses `/cast` lines, `ns.CheckSpell`, `ns.CheckMacro`, `ns.UnlearnedLabel`, `ns.IDReport` |
| `Library.lua` | Saved macros (account-wide) and weapon swap sets (per character) |
| `ReadyMacros.lua` | Window, class icons, tabs, paging, rows, tooltips, events, slash commands, `/rmac ids` report |
| `tools/package.sh` | Builds `ReadyMacros-v<Version>-forever.zip` from the `.toc` |
| `tools/release.sh`, `tools/check-release.sh`, `releases/` | `release.sh` stores the current zip in `releases/` (the one place to download it for CurseForge); `check-release.sh` (run by the `Tests` Action) fails if that zip is missing, misnamed or stale |
| `tools/run-tests.sh`, `tools/tests/` | Tests with a simulated client |
| `.github/workflows/package.yml` | Builds the zip and creates a GitHub Release |
| `docs/logo.png` | 400x400 CurseForge logo |

`ReadyMacrosDB` keys: `lastSpec[class]`, `saved` (list of `{name, body, icon, class}`), `weaponSets["Name-Realm"][1|2]` (`{main, off, icon}`), `seenIDs[spellName]`.

## Macro data format

```lua
{ name = "MO BoP", desc = "Blessing of Protection on mouseover, else yourself",
  body = "#showtooltip Blessing of Protection\n/cast [@mouseover,help,nodead][@player] Blessing of Protection",
  v = true },                 -- true only if every spell name was confirmed by a Forever source
-- nostart = "reason"         -- required in melee tabs when the macro has no /startattack
```

Conventions:
- Mouseover heals, dispels and DoTs: `[@mouseover,help,nodead][]` (falls back to target). Paladin Blessing of Protection, Blessing of Freedom and Purify fall back to the player: `[@mouseover,help,nodead][@player]`.
- Melee tabs (all Warrior and Rogue tabs; Paladin Protection/Retribution; Enhancement; Survival; Feral Combat): every macro has `/startattack`, or a `nostart` reason. Mouseover gap closers use `/startattack [@mouseover,harm,nodead][]`; mouseover shocks use plain `/startattack` so swings stay on the target; Rogue openers use `/startattack [nostealth]`.
- Warrior stances: Battle = 1, Defensive = 2, Berserker = 3.
- Paladin spells "Judgement" (with the e). Warlock "Bane of Agony", not Curse of Agony.
- Each class block in `Data.lua` has a comment naming the sources that confirmed its spells. Add to it when you add spells.

## Rules the tests enforce

Name at most 16 characters; body at most 255; no duplicate name in a tab; the same name has the same text in every tab of a class; melee rule above; no `/run`, `/script` or `/console`; every `SPELL_IDS` entry has a unique ID, a level, and is used by some macro; the README's "N macros use a spell name that has not been confirmed" matches the number of `v = false` entries.

## Verifying spell names and IDs

- Wowhead's Forever database: `https://www.wowhead.com/forever/spell=<id>`. Accept an ID only when the page title ends in "Forever", the name matches exactly, and it requires the right class. Example trap: 403434 "Victory Rush" is listed as a Mage spell, so Warrior Victory Rush has no ID on file yet.
- Wowhead search pages are blocked for automated fetches; direct spell pages work.
- Icy Veins' Forever class overviews (`icy-veins.com/wow-forever/<class>-class-overview`) were the main name source. Boosting/SEO sites disagreed with each other; don't rely on them alone.
- The player's client is the final word: `/rmac ids` lists NEW IDs from the spellbook with paste-ready lines, and `/dump C_Spell.GetSpellInfo("Spell Name")` shows a spell's ID.

## Testing

```
bash tools/run-tests.sh      # needs Lua 5.1 (apt-get install -y lua5.1), or python3 + lupa (pip install lupa) as a fallback
```

The `Tests` GitHub Action runs this and a package build on every PR.

The mock in `tools/tests/wowmock.lua` is not the game. Passing tests prove logic, not rendering or real API behavior; say so when reporting results. When adding a feature, add a test and check it fails when the feature is broken.

## Releasing

The current release zip lives in the repo: `releases/ReadyMacros-v<Version>-forever.zip` (exactly one zip). Full text: `docs/RELEASING.md`.

- One piece of work = one branch = one PR. While Anthony is testing and changes go back and forth, add commits to the same branch and PR and keep `## Version` as it is; run `bash tools/release.sh` in every commit that changes addon files so the zip in the repo is the one he tests.
- The version is finalized only when Anthony says "push": set the number in `ReadyMacros.toc`, update README (Known limits, counts), run `bash tools/run-tests.sh` and `bash tools/release.sh`, then push to the same PR.
- After merge Anthony downloads `releases/<zip>` from `main` and uploads it to CurseForge as is (game version: Forever, release type: Release). Or Actions > Package > Run workflow creates release `v<Version>`; it refuses a version that already has a release. That workflow has not yet been run on GitHub.

## Git workflow

- Never commit to `main`. Use a branch and open a PR; Anthony merges.
- `gh` is not installed in the cloud sessions. Open PRs with the GitHub API: `curl -X POST https://api.github.com/repos/Nekramess/ReadyMacros/pulls -H "Content-Type: application/json" --data-binary @body.json` (the Content-Type header is required).
- Shallow clones only track `main`; after pushing a branch run `git config --replace-all remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*' && git fetch` so the branch shows as pushed.
- `*.zip` is gitignored except `releases/` (the stored release zip).

## Open items

- 14 macros use spell names no Forever source confirmed (the README gives only the count; `grep -n "v = false }" Data.lua` lists them: Bestial Wrath, Counterspell, Divine Shield, Feign Death, Frost Nova, Hunter's Mark, Kick, Dispel Magic, Flash Heal, Moonfire, Polymorph, Renew, Mend Pet, Sinister Strike).
- Spell IDs exist only for Warrior and three Paladin spells. Next step was IDs for the other classes, one class at a time.
- Asked, not yet answered: should Paladin MO Cleanse fall back to the player like Purify? Should Purify also appear in the Holy tab?
- `/rmac ids` report box doesn't scroll.
