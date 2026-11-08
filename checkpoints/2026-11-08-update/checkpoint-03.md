# Checkpoint 03: TargetMenu bath diagnosed; bath stages driven and narrated

Repo: `SkyrimNet_DOM` · Branch: `main` · Baseline commit: `993911f` · Date: 2026-11-08 · Supersedes [checkpoint-02.md](checkpoint-02.md)

Logs: [logs/2026-11-08-09-31-48/](logs/2026-11-08-09-31-48/) (`Papyrus.0.log`, `MANIFEST.txt`).

## Goal

TargetMenu > abuse > upkeeping > bath me / bath you failed while DOM's spell worked. Add narration when the animation begins, a different description at each stage change, and audio-queue gating when we run the bath ourselves. Nothing is committed.

## Status

Built, **not run in game**. Pyro: 3 succeeded, 0 failed. `SkyrimNet_DOM_Menu.pex` no longer contains `DoBathMaster` or `DoBathMe`.

## Findings

Against [Papyrus.0.log](logs/2026-11-08-09-31-48/Papyrus.0.log):

- Line 2283 (`DoBathMe not found on dom_actor`, `TM_DoNamed` line 1256) and line 5255 (`DoBathMaster`, line 1250): the game ran the old `mods/SkyrimNet DOM` copy. Only that folder's `.pex` has those calls, and its source matches both line numbers. Profile `SkyrimNet SexLab` has `+SkyrimNet DOM`, `-SkyrimNet_DOM`. The active profile was inferred from that modlist's 08:56 save time; `ModOrganizer.ini` wasn't found. **Checkpoint-02's fixes have therefore never been loaded in game.**
- Line 4835: the bridge obedience roll refused `bath_me`. A real refusal.
- Lines 3968-4742: spell bath worked. `bathing` behaviour at 09:13:09, animation ended 09:13:53, so about 15s per stage against DOM's 8s timer.

## What changed

1. [SkyrimNet_DOM_Bath.psc](../../Scripts/Source/SkyrimNet_DOM_Bath.psc), new. `Drive` runs the bath for the TargetMenu; `WaitForQuiet` holds each stage (minimum DOM's timer, then speech queue empty; 12s no-speech grace, 60s cap). `FollowDomBath` narrates DOM-run baths: DirectNarration for stage 1, `DirectNarration_Optional` for stages 2 and 3.
2. [SkyrimNet_DOM_Menu.psc](../../Scripts/Source/SkyrimNet_DOM_Menu.psc): `bath_me` / `bath_you` call `FinishOrder`, then `Drive`.
3. [SkyrimNet_DOM_Events.psc](../../Scripts/Source/SkyrimNet_DOM_Events.psc): `OnBehaviourChange` routes rank 3/4 `bathing` to `FollowDomBath` unless `DOM_bath_driven` is set.
4. `Headers_Source/DOM` (gitignored): new `DOM_Interactor`, `DOM_Bathing`, `DOM_EquipUtil`; JSON animation calls on `DOM_Actor`; `DOMInteract`, `DOMBathingMode` on `DOM_Core`.
5. Changelogs, `docs/developers/papyrus.md`, `manifest/DOM.md`, `KNOWLEDGEBASE.md`.

## Decisions

- Stage 2 text corrects the user's typed `washs ... bath with ther` to `washes ... back with their`. The word `back` is an assumption from stage 1; change it in `StageText` if wrong.
- `Drive` restores the speaker's follower pose. DOM restores the target's twice, which looks like a bug.
- The bridge obedience roll stays in front of DOM's own roll, so TargetMenu baths are refused more often than spell baths.

## Not yet tested

- Everything in game.
- `GetSpeechQueueSize()` counting the line currently playing (undocumented).
- The idles looping when held longer than DOM's 8s.
- `FollowDomBath` stage timing, which is expected to run a few seconds early.

## Known limit

A spell bath with a non-DOM NPC gets no narration: DOM sends no behaviour event for the player or for non-DOM actors.

## Next

1. In MO2, profile `SkyrimNet SexLab`: disable `SkyrimNet DOM`, enable `SkyrimNet_DOM`. Confirm the plugin list still loads.
2. TargetMenu bath me and bath you, with a slave and a non-slave NPC. Expect three different lines, each after the previous finishes.
3. Get a refusal: no stage narration and both actors released.
4. DOM spell bath on a slave: stage 1 spoken, no "is bathing" duplicate.
5. Search `Papyrus.0.log` for `not found on dom_` and read the `SkyrimNet_DOM_Bath` traces. If stages advance during speech, add a `GetTimeSinceLastAudioEnded` check to `WaitForQuiet`.
6. Run checkpoint-02's remaining in-game list, since it was never loaded. Then commit.
