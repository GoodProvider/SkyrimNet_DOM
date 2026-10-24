# Checkpoint 01: Injury Engine torture → DOM punishment, Healing Hands → DOM comfort

Repos, branches and baseline commits (all changes are uncommitted):
- SkyrimNet_DOM `webui` @ `263b1f1`
- Injury_Engine `main` @ `095aed1`
- SkyrimNet_SexLab `profile` @ `902bcd77`

Plan: `C:\Users\bhuff\.claude\plans\update-so-that-injury-engine-snug-wave.md`
Logs: [logs/2026-10-23-21-12-42/](logs/2026-10-23-21-12-42/MANIFEST.txt). None were captured: nothing has run in game yet.

## Goal

- Injury Engine (IE) torture of a DOM slave counts as a DOM pain punishment and trains the slave.
- When the player tortures, the dashboard toggle **"When player tortures let player choose"** (`dom.punish.torture_choose_reason`, default on) decides how the reason is picked:
  - **On:** a scrollable WebUI list of the slave's open DOM reasons, plus "random".
  - **Off:** a random open reason.
- A slave with no open reasons is punished for "being a bad slave".
- SkyrimNet event: "Bob is punishing Nina because she refused to comply with the sexual demands of Bob."
- The SexLab Punish panel lists the slave's DOM reasons:
  - A DOM reason picked there → that reason.
  - A SexLab strategy or request reason → "didnt obey".
  - Anything else → "being a bad slave".
  - Punishing from the panel never opens the DOM list.
- Healing Hands cast on a slave counts as DOM "care" comfort, without the hug animation.

## Decisions

- IE sends mod events that DOM listens to. A soft dependency: nothing happens when IE is missing.
- Reason pool: only the slave's open reasons (`DOM_Mind.GetNextPunishmentReason`).
- The torture handler calls `mind.HandlePunishmentOnHit` for every IE batch. Hand torture and spell torture fire no `OnHit`, and without that call DOM would end the punishment after one tick.
- The panel reason goes straight from C++ to the global `SkyrimNet_DOM_API.PanelPunished`, not through Handler_DOM. The call is skipped when that script doesn't exist.
- Care comfort is a copy of DOM's `StartComfortingWith` "care" branch without `Anim_GetPlayerHug`. DOM's private `abuse_type` is not set.

## Results (what changed)

**Injury_Engine** ([Injury_Engine_Main.psc](../../../Injury_Engine/Scripts/Source/Injury_Engine_Main.psc))
- `NotifyTorture` sends `Injury_Engine_Torture(Form attacker, Form victim, String source, Int hits, String cause)`, once per landed batch:
  - from `NarrateHits` (torture branch);
  - from the silent paths of `Damage`, `Strike`, `TortureText`, `OnLash` and `Torture`.
- `NotifyHealStart` sends `Injury_Engine_HealStart(Form caster, Form target, Int source)` from `NarrateSourceHeal` on HEAL_START.
- Docs: CHANGELOG, docs/developers/papyrus.md, KNOWLEDGEBASE.

**SkyrimNet_SexLab**
- `Papyrus_WebUI.cpp` / `.h`: new native `Choice_Open(json)`. One Invoke per path: `openChoiceOnTop` or `openChoiceSolo`, then Show.
- `index.html`: `#choice-panel` with a scrolling `#choice-list` (60vh), a Close button, and Esc handling.
- `OrgasmEngine.cpp`: `PunishPlan.reason` and `strategyReason`. `NotifyDomPunishReason` runs before `PunishText`.
- `SkyrimNet_SexLab_WebUI.psc`: declares `Choice_Open`.
- Handler_DOM (and its Interface): `SeedPunishReasons`. `Scene.Engine_BeginScene` calls it for DOM slaves.
- Docs: CHANGELOG, docs/developers/webui.md, KNOWLEDGEBASE.
- The tree already had other uncommitted work (PushDomThreads, decorators, ActionCatalog), left untouched. Pyro also recompiled `Scene_Manager` with it, and the DLL build includes it.

**SkyrimNet_DOM**
- `SkyrimNet_DOM_API.psc`: `OpenPunishReasons`, `RandomOpenReason`, `ReasonClause`, `ApplyTortureReason` (sends event `dom_torture_punish`), `PanelPunishReasons`, `PanelPunished`, `TakePanelReason` (10 s window).
- `SkyrimNet_DOM_Events.psc`:
  - Registers both IE events.
  - `OnInjuryTorture` and `StartTortureReason`.
  - `OnInjuryHealStart`: source 1 (spell), caster has Healing Hands `Skyrim.esm 0x04D3F2` equipped, → `ComfortCareNoHug`.
- `SkyrimNet_DOM_Menu.psc`: `OpenTortureReasonList`, `TortureReasonChoice` (speaker plus static `reason` and `slaveId`), `TM_DoTortureReason`.
- `SkyrimNet_DOM_Main.psc`: the `torture_choose_reason` setting and `Get_Punishment_Description_Exact`.
- `manifest.yaml`: the new bool, category "Punishment".
- `Headers_Source/DOM` stubs: DOM_Mind, DOM_Actor, DOM_Core and DOM_Diary additions, plus a new DOM_PlayerAlias. **Not in git.**
- Docs: CHANGELOG, CHANGELOG-user, docs/authors/punishment.md, docs/players/overview.md, docs/developers/papyrus.md, KNOWLEDGEBASE (including "Builds are the agent's job").

**Builds (verified)**
- IE `compile: papyrus`: OK.
- DOM `compile: pyro`: 4 of 4 succeeded.
- SexLab `compile: pyro (main)`: 5 of 5 succeeded. The P+ bridge project wasn't run; no files there changed.
- SexLab CMake `build-release`: OK, copied to `SKSE/Plugins/SkyrimNet_SexLab.dll`. The one warning (`Papyrus_WebUI.cpp:476`, unused `thread`) was already there.

## Findings

- Before this work, the DOM `.pex` files were current: pyro had nothing to compile.
- DOM compiles against `Headers_Source\DOM` stubs before the real DOM source (Pyro: first import wins). Every DOM member the bridge uses has to be declared in the stubs.
- SexLab imports `SkyrimNet_DOM\Scripts\Source`. A change to DOM_API signatures means rebuilding SexLab too.

## Not yet tested (all in game)

1. Toggle on: the player whips a slave → the list appears and scrolls → pick a reason → the event text shows up in the SkyrimNet event log.
2. Hits stop → DOM's "End punishment" notification and training (Papyrus log `Training:`).
3. Toggle off: slap or pinch, or a torture spell → no list, a random reason, the event.
4. An NPC tortures a slave through `Torture_Target` → a random reason, no list.
5. SexLab Punish panel with a DOM slave:
   - DOM reasons are listed;
   - picking one uses it;
   - picking a strategy reason gives "didnt obey";
   - picking "no reason" gives "being a bad slave".
6. A slave with no open reasons → "being a bad slave", no list.
7. Healing Hands on a slave → comfort notification, no hug, `number_of_comfort` goes up.
8. Without IE: no errors. Without DOM: SexLab's Punish panel still works and logs no warning.
9. Close the list or press Esc mid-punishment → the WebUI closes, the punishment ends with DOM's own reason, no event.
10. Watch Papyrus.0.log for None or array errors from the new handlers.

## Open questions

- Event ordering between `PanelPunished` (VM dispatch from C++) and IE's torture event. Assumed in order; confirm in log test 5.
- Whether the solo `#choice-panel` sits well inside `#yesno-overlay` (it is placed next to the aid offer).

## Next

1. Deploy the three mods (MO2), start the game and run the tests above.
2. Capture `SkyrimNet_DOM` / `Papyrus.0.log`, the `SkyrimNet_SexLab` log (WebUI `Choice_Open` lines) and the Injury Engine log into `checkpoints/injury-engine/logs/<timestamp>/`.
3. Fix whatever fails, then commit each repo separately in the AGENTS.md commit format. Do not commit the other uncommitted SexLab work along with this.
