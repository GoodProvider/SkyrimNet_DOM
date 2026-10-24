# Checkpoint 02: player whip → reason list fix

Previous: [checkpoint-01.md](checkpoint-01.md). Repos and branches unchanged; everything is still uncommitted.
Logs: [logs/2026-10-23-21-19-02/](logs/2026-10-23-21-19-02/MANIFEST.txt) (Papyrus.0.log of the failed test 1).

## Test 1 failed: player whipped Skadi, no reason list

Log, 09:11:19:
- `DOM_Core: ... Start punishment of a fearful Skadi with pain for no reason` comes **before** IE's `NarrateRealHits ... whipping`.
- No `OnInjuryTorture` trace.

Cause: DOM's own OnHit (`DOM_Actor.StartWhipping` → `StartPunishingByIndex`) starts the punishment before the async `Injury_Engine_Torture` event. `OnInjuryTorture` picked the reason only inside `if !mind.whipping_active`, and the trace sat in the same branch.

DOM's start may already carry a real reason (`GetAnyPunishmentReason("")` → next reason), so `whipping_reason <= 0` can't serve as the trigger.

## Fix (compiled: pyro, 2 of 2 succeeded)

- `SkyrimNet_DOM_API.psc`:
  - `KEY_TORTURE_REASON_INDEX` / `KEY_TORTURE_DAMAGE` (StorageUtil on the slave).
  - `TortureReasonNamed(slave, mind)`: true when active, `whipping_reason` equals the stored index, and `whipping_pain_damage` is at least the stored damage.
  - `MarkTortureDamage`.
  - `NameRunningPunishment`, which `ApplyTortureReason` now uses.
- `SkyrimNet_DOM_Events.psc`:
  - `OnInjuryTorture` starts the punishment only if it isn't running. It calls `StartTortureReason(attacker, victim, mind)` when `fresh`, traces every batch (`reason:` / `fresh:`), and marks damage after `HandlePunishmentOnHit`.
  - `StartTortureReason`'s list branch first names a provisional random open reason, with no event. The list therefore doesn't reopen, and Esc still trains on a real reason.
- `Headers_Source/DOM/DOM_Mind.psc`: `whipping_pain_damage` stub. SexLab imports this folder first, so SexLab doesn't need a rebuild.
- Docs: KNOWLEDGEBASE ("DOM starts weapon whippings itself"), CHANGELOG, docs/authors/punishment.md.

## Next: retest in game

Repeat checkpoint-01's tests. Changes to expected results:
- Test 1: `OnInjuryTorture ... fresh:TRUE` appears once, then `OpenTortureReasonList`. Later lashes show `fresh:FALSE`.
- Test 1b: whip, wait for DOM's `Training:` line, whip again → the list opens again.
- Test 9: Esc → no event; the punishment trains on the provisional random open reason, not DOM's own.
- Watch the `Training:` amount for weapon whips: our `HandlePunishmentOnHit` plus DOM's OnHit may double-count. Fix only if the amount is off.

Then commit each repo separately, in the AGENTS.md format.
