# Checkpoint 06: "didnt obey" verified in game; the other torture-reason tests are still open

Previous: [checkpoint-05.md](checkpoint-05.md). Repos and branches are unchanged (SkyrimNet_DOM `webui`). Everything is still uncommitted, and **someone else will do the commits** (user decision).
Logs: [logs/2026-10-23-22-25-15/](logs/2026-10-23-22-25-15/MANIFEST.txt) (the 22:13–22:21 retest with Skadi).

No code changes this session. It was log review only.

## Results: "didnt obey" verified

- **First whip** (`reasons=1`, `options=6` = random, bad slave, didnt obey, 1 open reason, custom, no reason):
  - List: [Papyrus.0.log:1084](logs/2026-10-23-22-25-15/Papyrus.0.log#L1084), [SkyrimNet_SexLab.log:134](logs/2026-10-23-22-25-15/SkyrimNet_SexLab.log#L134).
  - Dispatch `TM_DoTortureReason ... for didnt obey`: [SkyrimNet_SexLab.log:146](logs/2026-10-23-22-25-15/SkyrimNet_SexLab.log#L146).
  - `ApplyTortureReason Index:18 ... because she explicitly disobeyed a direct order from Bob.`: [Papyrus.0.log:1099](logs/2026-10-23-22-25-15/Papyrus.0.log#L1099).
  - Event `dom_torture_punish`: [SkyrimNet.log:7104](logs/2026-10-23-22-25-15/SkyrimNet.log#L7104).
  - Summary "7 strokes for didnt obey": [Papyrus.0.log:1468](logs/2026-10-23-22-25-15/Papyrus.0.log#L1468).
- **Second whip** (`reasons=3`, `options=8`):
  - [Papyrus.0.log:1510](logs/2026-10-23-22-25-15/Papyrus.0.log#L1510), [SkyrimNet_SexLab.log:161](logs/2026-10-23-22-25-15/SkyrimNet_SexLab.log#L161).
  - `Index:18` again: [Papyrus.0.log:1525](logs/2026-10-23-22-25-15/Papyrus.0.log#L1525). Event: [SkyrimNet.log:13900](logs/2026-10-23-22-25-15/SkyrimNet.log#L13900).
  - Summary "6 strokes for didnt obey again": [Papyrus.0.log:1882](logs/2026-10-23-22-25-15/Papyrus.0.log#L1882).
- Side path (not on the test list): the WebUI panel punish "yelling" → `PanelPunished` → `ApplyTortureReason Index:6 ... raising their voice`. See [Papyrus.0.log:3644-3654](logs/2026-10-23-22-25-15/Papyrus.0.log#L3644). It works.

## Findings / not confirmed

- `Training: efficiency` both times ([Papyrus.0.log:1467](logs/2026-10-23-22-25-15/Papyrus.0.log#L1467), [1881](logs/2026-10-23-22-25-15/Papyrus.0.log#L1881)). This run can't show whether training follows the pick (test 4). Either "didnt obey" trains efficiency, or the provisional reason is still driving training. Check this against a pick whose training differs.
- The list JSON is truncated in the Papyrus trace (only `Random` is visible). The option counts fit the expected list, but the "no duplicates" check is confirmed by count only, not by labels.

## Not yet tested

1. **Custom** "refusing sex" → `Index:<bad slave>`. The summary and `Training:` should follow "being a bad slave".
2. A pick that differs from the provisional reason → `Training:` changes to match.
3. **No reason** → `index:0`, "for no reason".
4. **Custom** with Cancel or empty → `custom: ''`, no event.
5. **Random**.
6. **Esc** → no event.
7. Weapon whip: `Training:` counts once.
8. Healing Hands praise list with an ESL slave.

## Next

1. Run the in-game tests above (Skadi), then capture the logs.
2. Commits are being handled by someone else. Don't commit from this checkpoint unless asked.
