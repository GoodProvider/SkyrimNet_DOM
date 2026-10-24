# start-sex-failed — checkpoint 00

Repo `c:\Skyrim\dev\mods\SkyrimNet_DOM` · branch `webui` · baseline `263b1f1` (uncommitted; working tree also holds the earlier injury-engine / healing-rewards work)

## Goal

A DOM slave (Skadi) tried to start sex with the player (Bob) through the LLM action `StartScene_Consensual_Two` (oral, `no_penis`). It was refused every time. Fix it.

## Findings

Logs: [logs/2026-10-23-21-47-45/](logs/2026-10-23-21-47-45/) ([MANIFEST.txt](logs/2026-10-23-21-47-45/MANIFEST.txt)).

- [Papyrus.0.log](logs/2026-10-23-21-47-45/Papyrus.0.log) around lines 1973–1993 and 2018–2033 (21:38:21 and 21:38:44), same both times:
  ```
  Error: Incorrect number of arguments passed to function dom_mind.WillObey(int reason,int ifacet,int itraining,float Strength,bool do_msg,bool choose_not). Expected 6, got 5 instead!
    skyrimnet_dom_obedience.TryOrder() Line 54
    SkyrimNet_DOM_Actions.GateSlave() Line 46
    SkyrimNet_DOM_Actions.StartScene_Consensual_Two() Line 168
  DOM_Actor:  Skadi: ChooseAnswerNo
  [skyrimnet_dom_obedience.TryOrder] Skadi refused kind=sex have oral sex with Bob
  ```
- Root cause: the installed Diary of Mine (`PAH Diary Of Mine/Scripts/Source/DOM_Mind.psc:16630`) added `bool choose_not=true` to `WillObey`. Our stub `Headers_Source/DOM/DOM_Mind.psc:38` still had 5 params. Papyrus fills default args in at the caller's compile time, so the .pex passed 5. The VM aborts the call and returns None, which reads as false: refused every time. Every `TryOrder` gate was affected (sex, masturbate, undress/dress, `DOMOrder_Execute`, menu orders), not only sex.
- `choose_not=false` in DOM means "reluctantly accepts" (always obey). `true` is the old may-refuse behaviour.

## Decisions

- Your call: LLM actions do not call `WillObey`, because the LLM already decided the slave obeys. WebUI menu orders keep the roll.
- `TryOrderSexCast` (Scene Creator gate, a player action) keeps the roll too.

## Results

- `Scripts/Source/SkyrimNet_DOM_Obedience.psc` `TryOrder`: new last param `Bool rollObedience = true`. The `WillObey` / `ChooseAnswerNo` block runs only when it is true. The call now passes all 6 args (`..., 1.0, false, true`).
- `Scripts/Source/SkyrimNet_DOM_Actions.psc` `GateSlave`: `TryOrder(..., false)`.
- `Headers_Source/DOM/DOM_Mind.psc`: `WillObey` has `bool choose_not=true` (this folder is not in git).
- Pyro compiled `SkyrimNet_DOM_Obedience`, `SkyrimNet_DOM_Actions` (2 succeeded, 0 failed). I then touched `SkyrimNet_DOM_Menu.psc` and recompiled it (1 succeeded). Without that, the old Menu.pex would call the 5-param `TryOrder` with 4 args and fail the same way. Output: [pyro.log](logs/2026-10-23-21-47-45/pyro.log).
- `KNOWLEDGEBASE.md`: two new "Shared engine gotchas" entries: compile-time default args and header drift, and LLM actions skipping WillObey.
- `CHANGELOG.md` / `CHANGELOG-user.md`: Unreleased entries.
- Not committed.

## Not yet tested

- In game: an LLM sex action now starts the SexLab scene.
- In game: a WebUI menu order no longer hits the arity error, and its refusals come only from real DOM reasons.
- Other mods (e.g. SkyrimNet_SexLab) may call DOM functions whose signatures DOM also changed. Only `WillObey` was checked.

## Next

1. In game: get a slave to agree to sex through the LLM. Expect no `WillObey` error and no `ChooseAnswerNo`, the trace `TryOrder ... sex order kind=sex`, and the scene to start.
2. Give a menu order (e.g. undress) and check Papyrus.0.log has no `Incorrect number of arguments`.
3. Capture `Papyrus.0.log` + `SKSE/SkyrimNet_SexLab.log` into `checkpoints/start-sex-failed/logs/` for the next session.
4. Optional: diff all of `Headers_Source/DOM/*.psc` against `PAH Diary Of Mine/Scripts/Source` for other signature drift.
5. Commit when verified.
