# Checkpoint 01: align SkyrimNet_DOM with current SkyrimNet_SexLab

Repo: `SkyrimNet_DOM` · branch `webui` · baseline `9224968` (uncommitted changes below)
Sibling: `SkyrimNet_SexLab` @ `902bcd77` (0.36.5 + uncommitted `profile` work: decorators in C++, native threads push)
Logs: [logs/2026-10-23-20-41-09/](logs/2026-10-23-20-41-09/) ([MANIFEST.txt](logs/2026-10-23-20-41-09/MANIFEST.txt))

## Goal

SexLab has 116 commits since DOM's last change (2026-09-27). Make DOM build and behave correctly against the current SexLab.

## Results

### Contract audit (no change needed)

| Surface | Status |
|---|---|
| DOM → SexLab Papyrus (`Actions.StartScene_*`, `Scene_Manager.SaveThreadsJson/IsBusy`, `Main.sexlab`, `Handler_DOM.DOMSlave_Orgasmed`, `Utilities.DirectNarration[_Optional]` / `ObjectToLowerCaseKeyJson`, `WebUI_GetFocusActor/Kind`, `WebUI_PushCascadeChoices/MainPanelData`) | Signatures match. `GetThread` / `AnimsDialog` appear only in commented-out code ([SkyrimNet_DOM_Events.psc:786-799](../../Scripts/Source/SkyrimNet_DOM_Events.psc#L786-L799)). |
| SexLab → DOM (`SkyrimNet_DOM_API.GetSlave/IsDOMSlave/GetThreads/Start_Masturbate/StartScene_*`) | Match. |
| `SaveThreadsJson` | SexLab keeps it as a DOM shim → `PushDomThreads` → native `Threads_SetDom`. Kept the call (works on older SexLab too). |
| Prompt [0551_dom_instructions.prompt](../../SKSE/Plugins/SkyrimNet/external/goodprovider.dom/prompts/submodules/user_final_instructions/0551_dom_instructions.prompt): `sexlab_get_threads`, `threads.json`, `thread.names/victims`, `skyrimnet_sexlab_active_sex` | All still produced. |
| YAML `papyrus_util HasIntValue skyrimnet_sexlab_scene_actor_lock` (11 actions) | Still mirrored to StorageUtil by SexLab `ActorLocker.cpp`. |
| Removed SexLab decorators (`sexlab_intent`, `sexlab_get_player_los_distance`, `sexlab_ostim_player`), `SexLab_Strategy_*`, `SexLab_Force`, mental break | DOM references none. |
| WebUI `decoratorName`s (`webui_focus_kind`, `is_in_faction`, `get_faction_rank`) | Registered. |

### Build breaks found and fixed

1. **Missing SexLab header stubs.** Since 2026-10-14, SexLab `Utilities` references `SkyrimNet_SexLab_PPlus` and `TNG_PapyrusUtil`, and `Scene` → `LoversLedger` references `TTLL_*`. These live only in SexLab `Headers_Source\` and `Headers_Source\LoversLedger\`.
2. **Dead import** `SexLabFrameworkAE_v166b` (Pyro aborted: `Import path does not exist`). Now `SexLabFrameworkAE`, as in SexLab's ppj.
3. **Dead Pyro path** in `.vscode/tasks.json`: the 2024 extension is gone. Now `C:/Skyrim/tools/Pyro/pyro.exe`, as in SexLab.

### Files changed

- [skyrimse.ppj](../../skyrimse.ppj): `SexLabFrameworkAE` import; SexLab `Headers_Source` + `Headers_Source\LoversLedger` added last (gap-fill only)
- [.vscode/tasks.json](../../.vscode/tasks.json): `compile: pyro` → `C:/Skyrim/tools/Pyro/pyro.exe`
- [Scripts/Source/SkyrimNet_DOM_Actions.psc](../../Scripts/Source/SkyrimNet_DOM_Actions.psc): `SaveThreadsJson` comment and trace only ("pushed DOM threads")
- [docs/developers/papyrus.md](../../docs/developers/papyrus.md): threads shim + build import note
- [KNOWLEDGEBASE.md](../../KNOWLEDGEBASE.md): new "DOM build must follow SexLab's header stubs (2026-10-23)"
- `Scripts/*.pex`: all 9 rebuilt

### Verified

- Full `pyro --no-incremental-build`: exit 0, no errors, 9/9 `.pex` rebuilt, no SexLab `.pex` written into DOM `Scripts/` ([pyro-full.log:66](logs/2026-10-23-20-41-09/pyro-full.log)). The earlier incremental run is [pyro-incremental.log](logs/2026-10-23-20-41-09/pyro-incremental.log).

## Findings left alone (old, not caused by SexLab drift)

- `Headers/SkyrimNet_SexLab_*.psc` are stale copies that no build imports (SexLab imports only DOM `Headers\DOM` and `Headers\Ostim`). Candidates for deletion.
- `optionsFrom` / `optionTemplate` in [0810_dom_abuse.json:2283](../../SKSE/Plugins/SkyrimNet_SexLab/webui/TargetMenu/Actor/options/0810_dom_abuse.json#L2283) and [0850_dom_management.json:399](../../SKSE/Plugins/SkyrimNet_SexLab/webui/TargetMenu/Actor/options/0850_dom_management.json#L399) / `:470`: SexLab's WebUI never implemented these keys, so those nearby-actor rows probably render empty.
- AGENTS.md and [manifest/DOM.md](../../manifest/DOM.md) still describe the DOM Status/Slaves MainPanels, which were deleted in `978fdce` (2026-09-16).

## Not yet tested (in game)

- DOM masturbate start/stop → `SaveThreadsJson` trace in Papyrus log, DOM thread present in `Data/SKSE/Plugins/SkyrimNet_SexLab/threads.json` and in `sexlab_get_threads`.
- DOM punish YAML stays ineligible while the actor is in a SexLab scene (actor lock gate).
- WebUI DOM menus (order/abuse/management) open and dispatch with SexLab 0.36.5's TargetMenu (1 s hover hold, cascade changes).
- DOM slave orgasm → `Handler_DOM.DOMSlave_Orgasmed` narration with SexLab's new narration levels.

## Next

1. Deploy the rebuilt DOM `.pex` alongside current SexLab (0.36.5 + profile build) and run the in-game tests above. Capture `Papyrus.0.log`, `SkyrimNet.log`, `SkyrimNet_SexLab/threads.json`.
2. Decide on the three leftover findings (delete stale `Headers/SkyrimNet_SexLab_*`, implement or remove `optionsFrom` rows, fix the MainPanel docs).
3. Commit (AGENTS.md format), e.g. `Keep DOM compiling against SexLab 0.36.5 header stubs`.
