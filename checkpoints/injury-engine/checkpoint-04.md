# Checkpoint 04: reason list works; the pick was dropped for an ESL slave

Previous: [checkpoint-03.md](checkpoint-03.md). Repos and branches unchanged; everything is still uncommitted.
Logs: [logs/2026-10-23-21-46-06/](logs/2026-10-23-21-46-06/MANIFEST.txt) (the list retest).

## Results: list verified, pick not applied

The list works:
- reasons=0: `Choice_Open options=4` (random, being a bad slave, custom, no reason). See [Papyrus.0.log:1085](logs/2026-10-23-21-46-06/Papyrus.0.log#L1085) and [SkyrimNet_SexLab.log:133](logs/2026-10-23-21-46-06/SkyrimNet_SexLab.log#L133).
- reasons=1: `options=4`. See [Papyrus.0.log:1526](logs/2026-10-23-21-46-06/Papyrus.0.log#L1526) and [SkyrimNet_SexLab.log:153](logs/2026-10-23-21-46-06/SkyrimNet_SexLab.log#L153).
- The user's pick was dispatched with the right label: `... TM_DoTortureReason (3 args) for being a bad slave` / `for begging to stop` ([SkyrimNet_SexLab.log:145,165](logs/2026-10-23-21-46-06/SkyrimNet_SexLab.log#L145)).
- Later lashes show `fresh:False`.

DOM dropped the pick:
- `TM_DoTortureReason no slave for id -33241028` ([Papyrus.0.log:1098](logs/2026-10-23-21-46-06/Papyrus.0.log#L1098), [1541](logs/2026-10-23-21-46-06/Papyrus.0.log#L1541)).
- There was no `ApplyTortureReason` and no "punishing Skadi for" event.
- The punishment trained on the provisional reason instead (`reason:9` / `reason:1`, then `Training: efficiency`, lines 1501, 2010).

## Cause and fix (compiled: pyro, 1 of 1 succeeded)

- Skadi is `0xFE04C83C`, an actor from an ESL plugin. The SexLab C++ (`ActionDispatch.cpp` `ExecutePapyrusOption`) passes the static `slaveId` string through unchanged. The failing step was vanilla `Game.GetForm`, which doesn't resolve `0xFE` forms.
- `SkyrimNet_DOM_Menu.psc`: `TM_DoTortureReason` and the heal praise callback (written by the parallel session, same pattern) now use `Game.GetFormEx(slaveId as Int)`.
- Docs: KNOWLEDGEBASE ("Resolve stored FormIDs with `Game.GetFormEx`"), CHANGELOG.

Confidence 90%. If `GetFormEx` also returns None, pass the slave as an actor dict (`{formId}`, which `ResolveActorDictEntry` already handles) instead of a string.

## Not yet tested

Everything from checkpoint-03 after the pick: steps 2–7.

## Next: retest in game (same slave, Skadi)

1. Whip, then pick a reason:
   - No `no slave for id`.
   - `ApplyTortureReason` uses that reason.
   - The event reads "… is punishing Skadi for <reason>".
   - `Training:` uses that reason.
2. **No reason** → `index:0`, event "for no reason".
3. **Custom**:
   - Type text → the event uses the text.
   - Cancel or leave it empty → `custom: ''`, no event.
4. **Random** → one of the open reasons.
5. Esc → no event; training uses the provisional reason.
6. Carry over:
   - Test 1b: whip, wait for `Training:`, whip again → the list opens again.
   - Weapon whip: check that `Training:` doesn't count twice.
   - Healing Hands praise list (other session) with an ESL slave.

Then commit each repo separately, in the AGENTS.md format.
