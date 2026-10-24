# Healing rewards — checkpoint 01

Repos and baselines (unchanged from 00, all uncommitted):
- `SkyrimNet_DOM`: branch `webui`, baseline `263b1f1`.
- `SkyrimNet_SexLab`: branch `profile`, baseline `902bcd77`, mixed with unrelated pending edits.

Logs: none yet. Not tested in game.

## Goal (added)
SkyrimNet_SexLab Aid heals must reward the slave the same way Healing Hands does: praise, or care if the slave is shocked.

## Finding
SexLab Aid **casts nothing**. `Aid.cpp` plays visuals (`PlaySpellVisuals`) and calls `Injury_Engine_Main.External_Heal`. Injury Engine sends `Injury_Engine_HealStart` only from `Seen()` (healing effects active on the actor), so Aid never reached DOM.

## Decisions
- Any **health** Aid counts, spell or potion (user choice). Stamina-only Aid and self-aid send nothing.
- Any caster counts, with no Healing Hands check. The reason list still appears only for the player with `dom.praise.heal_choose_reason`.

## Changes

### SkyrimNet_SexLab
- `SKSE_Source/src/Aid.cpp`: new `NotifyAidStart` sends ModEvent `SkyrimNet_SexLab_AidStart`:
  - sender = target
  - strArg `"<spell|potion>|<caster FormID signed decimal>"`
  - numArg = health
  - Called from the game-thread task in `Aid::Apply`, and once per `Aid::StartChannel` (queued with AddTask).
- Docs: `docs/developers/orgasm-engine.md` (ModEvents table + note), `CHANGELOG-developer.md`.

### SkyrimNet_DOM
- `SkyrimNet_DOM_Events.psc`:
  - Registers `SkyrimNet_SexLab_AidStart` → `OnSexLabAidStart`.
  - The shared routing moved out of `OnInjuryHealStart` into `HealSlave(caster, target, fn)`.
- Comments in `Main.psc` (heal_choose_reason) and `Menu.psc` (OpenHealPraiseList).
- Docs: `CHANGELOG.md`, `CHANGELOG-user.md`, `docs/developers/papyrus.md` (item 6), `docs/players/overview.md`, `KNOWLEDGEBASE.md` ("SexLab Aid casts nothing").

## Results
- Pyro: Events, Main and Menu compile with 3 succeeded and 0 failed.
- SexLab `cmake --build --preset build-release`: OK. The DLL was copied to `SKSE/Plugins/SkyrimNet_SexLab.dll`.

## Risks
- The signed FormID round trip through `as Int` / `Game.GetFormEx` is untested for ESL casters. The player and Skyrim.esm NPCs are safe.
- Earlier risks still stand: the `"shocked"` mood string, positional parameterMapping, and the HTML deploy.

## Next
1. Deploy the DOM `.pex` files, the SexLab DLL and `index.html`.
2. Run the checkpoint-00 tests, plus these Aid tests:
   - HUD Num 0 heal on a calm slave → praise.
   - Healing potion accepted → praise. Refused → nothing.
   - Aid panel concentration channel → praise once.
   - LLM `SexLab_Aid` from a follower → praise from that follower.
   - Shocked slave → care.
   - Setting on → reason list.
   - Stamina-only Aid → nothing.
   - Healing Hands cast normally → still fires once.
3. Traces:
   - SexLab log: `Aid: AidStart`.
   - DOM: `OnSexLabAidStart` / `HealSlave`.
   - Save them into `checkpoints/healing-rewards/logs/`.
4. Commit. In SexLab, stage only `Aid.cpp`, `orgasm-engine.md`, `CHANGELOG-developer.md`, `index.html` and `webui.md`.
