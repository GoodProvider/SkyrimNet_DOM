# Checkpoint 03: empty torture reason list; always offer no reason + custom

Previous: [checkpoint-02.md](checkpoint-02.md). Repos and branches unchanged; everything is still uncommitted.
Logs: [logs/2026-10-23-21-34-30/](logs/2026-10-23-21-34-30/MANIFEST.txt) (the empty-list test).

## Retest result: list opened with no rows

The checkpoint-02 fix works up to the list: `OnInjuryTorture ... fresh:TRUE` fires once, then later lashes show `fresh:False` ([Papyrus.0.log:1085-1106](logs/2026-10-23-21-34-30/Papyrus.0.log#L1085)).

The list itself was empty:
- Papyrus: `OpenTortureReasonList Skadi reasons=1`, so "random" plus 1 reason were built ([Papyrus.0.log:1091](logs/2026-10-23-21-34-30/Papyrus.0.log#L1091)).
- C++: `Choice_Open options=0` ([SkyrimNet_SexLab.log:134](logs/2026-10-23-21-34-30/SkyrimNet_SexLab.log#L134)).

The rows were therefore lost turning the JMap into JSON (`ObjectToLowerCaseKeyJson`). `JMapToJson` writes `null` without a trace when a nested call returns "". The source doesn't show the exact trigger. The same serializer works from menu callbacks; this call runs inside a hit event.

## Fix (compiled: pyro, 3 of 3 succeeded)

- `SkyrimNet_DOM_Menu.psc`:
  - `OpenTortureReasonList` / `TortureReasonChoice` build the JSON as a string with `SkyrimNet_SexLab_Utilities.JsonQuote`. Keys are camelCase, as `firePapyrusOption` reads them.
  - Rows: random, the open reasons (or "being a bad slave"), custom, no reason.
  - Traces `json(<len>)=<first 200 chars>`.
- `TM_DoTortureReason`:
  - "custom" → UIExtensions `UITextEntryMenu`. Empty text keeps the provisional reason, with no event.
  - "random" → `RandomOpenReason`.
- `SkyrimNet_DOM_API.psc`:
  - `NameRunningPunishment`: "no reason" → index 0. Free text gets DOM's default index and keeps its own name.
  - `ApplyTortureReason`: "… is punishing X for no reason."
- `SkyrimNet_DOM_Events.psc` `StartTortureReason`: the list also opens when the slave has no open reasons. The provisional reason is `RandomOpenReason` (bad slave when there are none).
- Docs: KNOWLEDGEBASE ("Choice_Open JSON from a hit event: build it as a string"), CHANGELOG, CHANGELOG-user, docs/authors/punishment.md, docs/players/overview.md, manifest.yaml description.

## Parallel work (other session, not this one)

Another session is adding a Healing Hands praise list (`OpenHealPraiseList`, `PraiseReasonList`, `DefaultPraiseReason`) in the same `SkyrimNet_DOM_Menu.psc`, plus SexLab `Choice_Open` `opensText` support.
- It still builds `Choice_Open` JSON with JMap + `ObjectToLowerCaseKeyJson`, and it is called from `OnInjuryHealStart`. It may hit the same `options=0`.
- Once SexLab's inline `opensText` lands, torture "custom" could switch to it instead of UIExtensions.

## Not yet tested

Everything in the fix.

## Next: retest in game

1. Whip a slave with open reasons:
   - `Choice_Open options=N`, with N = reasons + 3.
   - The `OpenTortureReasonList json(...)` trace shows the rows.
   - The list shows random, the reasons, custom, no reason.
2. Pick a reason → `ApplyTortureReason` with it. Later lashes show `fresh:False`.
3. Pick **no reason** → `index:0`, event "for no reason", training on no reason.
4. **custom**:
   - Type text → the event uses the text.
   - Cancel or leave it empty → `TM_DoTortureReason custom: ''`, no event.
5. Slave with no open reasons → the list still opens with "being a bad slave".
6. Esc → no event; the punishment trains on the provisional reason.
7. Carry over from checkpoint-02: test 1b (whip, wait for `Training:`, whip again → the list opens again) and the weapon-whip `Training:` double-count check.

Then commit each repo separately, in the AGENTS.md format.
