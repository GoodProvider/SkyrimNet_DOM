# Healing rewards — checkpoint 02

Repos and baselines are unchanged from 01. Nothing is committed yet.

## Bug (from in-game test)
A SexLab Aid heal by the player opened the "praise X for" panel, but it was empty. The "being a good slave" and custom rows were missing too.

## Cause
`OpenHealPraiseList` built its JSON with JMap/JArray and `ObjectToLowerCaseKeyJson`. When it is called from the `SkyrimNet_SexLab_AidStart` event, the JContainers serializer drops `options`. This is the same failure as `OpenTortureReasonList` (KNOWLEDGEBASE "Choice_Open JSON from a hit event").

## Fix
In `SkyrimNet_DOM_Menu.psc`:
- `OpenHealPraiseList` now builds the JSON as a string. The rows are:
  1. `DefaultPraiseReason`: always shown, even with no DOM_Actor or mind.
  2. Other `PraiseReasonList` entries (index ≥ 1).
  3. `custom`: always shown, with `opensText:1` and a dynamic `reason`.
- `HealPraiseChoice(reason, slaveId, isCustom)` now returns a JSON string. The mapping order is speaker, slaveId, reason, which matches `TM_DoHealPraise`.
- `custom` is a reserved word in Papyrus, so the parameter is named `isCustom`.

Docs were updated: KNOWLEDGEBASE line 114 and the CHANGELOG.md healing bullet.

## Results
Pyro compiled Menu with 1 succeeded and 0 failed. Not tested in game.

## Next
1. Deploy `SkyrimNet_DOM_Menu.pex`.
2. Test a HUD Num 0 heal on a calm slave. Expect "being a good slave", any queued reasons, and "custom".
   - Pick a reason → praise.
   - Custom text → praise for that text.
   - Close → nothing.
3. Papyrus log: `OpenHealPraiseList ... json(N)=` should show the options.
4. Then do the remaining checkpoint-01 tests and commit.
