# Checkpoint 01: no punishment dialogue after whipping Skadi

Repo: `SkyrimNet_DOM` (branch `webui`, baseline `e7f4b72`; changes **uncommitted**, compiled)
Plan: `C:\Users\bhuff\.claude\plans\in-the-last-play-hidden-flurry.md`
Logs: [logs/2026-10-24-20-34-45/](logs/2026-10-24-20-34-45/) (Papyrus.0.log, Papyrus.3.log, SkyrimNet_SexLab.log, SkyrimNet_DOM.log; see `MANIFEST.txt`)

## Goal

When the player whips a DOM slave, the punishment reason list should open (`OpenTortureReasonList`) and the `dom_torture_punish` event ("Bob is punishing Skadi because…") should reach the LLM. In the last playthrough neither happened.

## Findings

- **The save carries a pain punishment that never ended.**
  - Every `OnInjuryTorture` in the session logs `active:TRUE reason:18 fresh:False`.
  - The first one ([Papyrus.0.log:1736](logs/2026-10-24-20-34-45/Papyrus.0.log#L1736), 20:20:07) came from a leash trip (source `falling`), before any lash.
  - The whip batches follow at [1773–1814](logs/2026-10-24-20-34-45/Papyrus.0.log#L1773).
  - The 15:51 load of the same save shows the same line ([Papyrus.3.log:1637](logs/2026-10-24-20-34-45/Papyrus.3.log#L1637)).
  - No 10/24 session logs a DOM "Start punishment" notice. The punishment ("didnt obey", index 18) was already running at load.
- **Why the list didn't open.** The bridge's StorageUtil marker still matched: `torture_reason_index` was 18 and the damage was at or below the current count. So `SkyrimNet_DOM_API.TortureReasonNamed` returned true, `fresh` stayed false, and `StartTortureReason` (list or event) never ran.
- **Why DOM never ended it: not proven.**
  - `DOM_Mind.HandlePunishmentOnUpdate` (DOM_Mind.psc:17343 in `PAH Diary Of Mine`) ends a pain punishment only when `whipping_by_trainer == false`.
  - `StartPunishingByIndex` sets that flag when the abuser has a DOM mind. Only the trainer's `punishing`-state `EndBehaviour` (DOM_Actor.psc:20282) then ends it.
  - The other possibility is that Skadi's mind OnUpdate stopped running.
  - The new trace (`trainer:`) will tell next time.
- **Leash trips count as torture.** Injury Engine sends `Injury_Engine_Torture` for `falling` (a leash yank). With the punishment not stuck, a leash trip would have started a pain punishment and opened the list.
- The actor snapshot `Data/SKSE/Plugins/SkyrimNet_DOM/actors/Skadi.json` was not found on disk (not in `C:\Skyrim\overwrite`). Its location is unknown.

## Results (what changed)

User decisions: cap each pain punishment at 1 minute; ignore leash falls and drags.

- `Headers_Source/DOM/DOM_Actor.psc`: stub `EndWhipping(Actor akAbuser)` (the real one is at top level, DOM_Actor.psc:12887).
- `Headers_Source/DOM/DOM_Mind.psc`: stub `bool Property whipping_by_trainer = false Auto Hidden`.
- `Scripts/Source/SkyrimNet_DOM_API.psc`:
  - `KEY_PAIN_START()` (`skyrimnet_dom.pain_start`, game days).
  - `PAIN_PUNISH_TIMEOUT_SECONDS()` = 60.
  - `EndStalePainPunishment(slaveActor, slave, abuser)`: records when it first sees a punishment running. Past 60 real seconds (game time × 86400 ÷ TimeScale `0x3A`), it calls `slave.EndWhipping(abuser)`, which is DOM's normal close and training. It then clears `pain_start`, `torture_reason_index` and `torture_damage`, and writes the `EndStalePainPunishment` trace.
  - `MarkPainStart(slaveActor)`.
- `Scripts/Source/SkyrimNet_DOM_Events.psc`:
  - `OnInjuryTorture` returns early for `falling` / `leash_dragging`.
  - It calls `EndStalePainPunishment` before the `whipping_active` check, and `MarkPainStart` on a fresh punishment.
  - Its trace adds `trainer:`.
  - `ScanCaptureAliases` (the 2 s `OnUpdate`) calls `EndStalePainPunishment` for every filled alias. The `capture_narrated == 0` guard now gates only `MarkCaptureNarrated`, so the scan always runs.
- Docs: `KNOWLEDGEBASE.md` ("A punishment that never ends hides the reason list") and `docs/authors/punishment.md` (1-minute cap, leash sources).
- Compiled with `compile: pyro`: `SkyrimNet_DOM_API` and `SkyrimNet_DOM_Events`, 2 succeeded, 0 failed.

## Not yet tested

- All of it in game.
- `EndWhipping` called from a bridge global function, including its training and notice on the old "didnt obey" punishment.
- That `capture_narrated == 0` never happens in practice, now that `CheckPoseChange` also runs in that case.
- A continuous whipping longer than 60 s now ends and restarts the punishment, so the list reopens. That is by design (user decision), but the feel is untested.

## Next

1. Deploy the new `Scripts/SkyrimNet_DOM_API.pex` and `SkyrimNet_DOM_Events.pex`, then load the same Skadi save.
2. Wait about 60 s without hitting Skadi. Papyrus.0.log should show `[SkyrimNet_DOM_API.EndStalePainPunishment] Skadi reason:18 'didnt obey' trainer:… elapsed:…`, followed by DOM's "Punishing … strokes for didnt obey" notice. Note the `trainer:` value.
3. Leash-yank Skadi: there should be no `OnInjuryTorture … falling` line.
4. Whip Skadi: expect `OnInjuryTorture … fresh:TRUE`, then `OpenTortureReasonList`. Pick a reason, then check `ApplyTortureReason` and that Skadi reacts to the `dom_torture_punish` event.
5. Stop for more than 60 s, then whip again: the list should reopen.
6. Capture logs after the test, and start the next session from `checkpoints/no-punishsment-dialogue/checkpoint-02.md`.
