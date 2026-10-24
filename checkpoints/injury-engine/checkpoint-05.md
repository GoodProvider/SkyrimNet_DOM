# Checkpoint 05: ESL pick fixed; custom reason trains as "bad slave"; bad slave / didnt obey always listed

Previous: [checkpoint-04.md](checkpoint-04.md). Repos and branches unchanged (SkyrimNet_DOM `webui`); everything is still uncommitted.
Logs: [logs/2026-10-23-22-11-05/](logs/2026-10-23-22-11-05/MANIFEST.txt) (the 22:00–22:03 retest; identical to the live files when read).

## Results: GetFormEx fix verified

- No `no slave for id` anywhere.
- **Pick "being a bad slave"** (first whip, `reasons=0`, `options=4`):
  - Dispatch: [SkyrimNet_SexLab.log:145](logs/2026-10-23-22-11-05/SkyrimNet_SexLab.log#L145).
  - `ApplyTortureReason Index:9 ... because she was failing to be a good slave for Bob`: [Papyrus.0.log:1095](logs/2026-10-23-22-11-05/Papyrus.0.log#L1095).
  - Event `dom_torture_punish`: [SkyrimNet.log:7083](logs/2026-10-23-22-11-05/SkyrimNet.log#L7083).
  - Summary "25 strokes for being a bad slave": [Papyrus.0.log:1577](logs/2026-10-23-22-11-05/Papyrus.0.log#L1577).
  - The provisional reason was already 9, so this test can't show that a different pick changes training.
- **Carry-over (test 1b)**: the second whip reopened the list (`reasons=2`, `options=5`). See [Papyrus.0.log:1956](logs/2026-10-23-22-11-05/Papyrus.0.log#L1956) and [SkyrimNet_SexLab.log:165](logs/2026-10-23-22-11-05/SkyrimNet_SexLab.log#L165).
- **Custom "refusing sex"**:
  - `custom: 'refusing sex'` → `Index:0 ... because of refusing sex.`: [Papyrus.0.log:1967-1970](logs/2026-10-23-22-11-05/Papyrus.0.log#L1967).
  - Event: [SkyrimNet.log:15438](logs/2026-10-23-22-11-05/SkyrimNet.log#L15438).
  - Gap: DOM's summary and training used the provisional reason ("6 strokes for being too slow", `Training: efficiency`, [Papyrus.0.log:2093-2099](logs/2026-10-23-22-11-05/Papyrus.0.log#L2093)). Cause: the unknown token got the default index 0.

## Changes this session (compiled: pyro, 3 of 3 succeeded)

User decisions: custom text maps to the "being a bad slave" index; "being a bad slave" and "didnt obey" are always in the list.
- `SkyrimNet_DOM_Menu.psc` `OpenTortureReasonList`: lists random, `REASON_BAD_SLAVE`, `REASON_DISOBEY`, the other open reasons (without those two), custom, no reason. The first whip now shows 5 options.
- `SkyrimNet_DOM_Main.psc` (+ `Headers/`): new `Has_Punishment_Reason` (a `JMap.hasKey` check on `punishment_to_index`).
- `SkyrimNet_DOM_API.psc` `NameRunningPunishment`: free text → the `being a bad slave` index. `whipping_reason_name` keeps the text.
- Docs updated: punishment.md, players/overview.md, the settings `manifest.yaml` description, CHANGELOG, CHANGELOG-user, KNOWLEDGEBASE (unknown token → index 0 → DOM keeps the provisional reason).
- Checkpoint skill: plan mode reads the live logs in place and snapshots them after plan mode ends.

Confidence 90%. Assumption: DOM's summary and training read `whipping_reason`. The pick test supports this.

## Not yet tested

- The new list order and contents. Custom → bad-slave training. "didnt obey".
- From checkpoint-04: no reason, custom with Cancel/empty, random, Esc, weapon whip double count, Healing Hands praise with an ESL slave.

## Next: retest in game (Skadi)

1. First whip: `options=5`/`6`, with "being a bad slave" and "didnt obey" listed, and no duplicates when the slave already has them open.
2. **Custom** "refusing sex":
   - `ApplyTortureReason Index:<bad slave index>`, event "because of refusing sex".
   - The summary or `Training:` follows "being a bad slave", not the provisional reason.
3. **didnt obey** → event "because Skadi didn't obey …", and the summary says the same.
4. A pick that differs from the provisional reason → `Training:` changes to match.
5. **No reason** → `index:0`, "for no reason".
6. **Custom**, Cancel or empty → `custom: ''`, no event.
7. **Random**.
8. **Esc** → no event.
9. Weapon whip: `Training:` counts once.
10. Healing Hands praise list with an ESL slave.

Then commit each repo separately, in the AGENTS.md format.
