https://github.com/GoodProvider/SkyrimNet_DOM/releases/tag/0.2.1

Requires SkyrimNet 0.25.0 (Beta 25) or later and SkyrimNet_SexLab 0.36.5 or later.

## Unreleased

### Skyrim VR
- No UI code in DOM: its overlays open on VR with SexLab's Magelight controller chord (`UiEngine::BindVrChord`, `sexlab.editor.vr_*`).
- `GestureWatch::Install` logs `(VR: unverified)` on VR. Its thunk's `AddTask` (it can run on the main thread) is an open VR-hang audit item.

### Bug Fixes
- `actions/DOMSlave_StandHere.yaml`, `DOMSlave_DOMSlaveFollow.yaml`, `DOMSlave_Display.yaml`: static `arg` changed from blank `value:` (YAML null) to `value: ""`. SkyrimNet refused all three at `ActionLibrary.cpp:599` (`Static parameter 4 missing 'value' field`), then `CustomActionManager.cpp:214`.
- Fixed: 0.2.1 (and, by matching size, 0.2.0) shipped a Debug `SkyrimNet_DOM.dll`, which fails with Error 126 without Visual Studio. The Release build uses the static CRT, and `make release` now refuses a Debug DLL.

### Obedience
- `SkyrimNet_DOM_Obedience`: new `RefusePercent`, `RefuseLevel`, `AddLikelyRefusal`, `FillObedience` (no `WillObey` call) and `PassDomRoll`. Level thresholds 15/40/70 on the `generic` kind; `likely_refuses` lists `sex`, `respectful`, `naked`, `pose` at 50% or more.
- `SkyrimNet_DOM_Decorators.FillSlaveFields`: writes `obedience.*`; `is_obedient` is kept.
- `SkyrimNet_DOM_Actions.GateSlave`: `PassDomRoll` when `rollObedience=false` and `gate != 0`, because DOM handlers such as `SetShouldBeRespectful` roll `WillObey` again.
- `0551_dom_instructions.prompt`: `obedience.*` branches for all 22 moods, three long-term profiles, with the old `is_obedient` branch as the fallback for older saved JSON.
- `Headers_Source/DOM/DOM_Mind.psc` (local stub): added `MoodReactionFactor`, `HEXACO_Facets`, `HEXACO_InverseFacets`, `TRAINING_Stats`.

### Baths
- New `SkyrimNet_DOM_Bath` (Hidden, global; no ESP change). `Drive` reimplements `DOM_Interactor.Interact_BathClient` / `Interact_BathActor` with `WaitForQuiet` between stages (`GetSpeechQueueSize`, minimum DOM's `8.0 + perfectionism`, 12s no-speech grace, 60s cap). Unlike DOM, it restores the speaker's follower pose instead of the target's twice.
- `SkyrimNet_DOM_Menu.TM_DoNamed`: `bath_me` / `bath_you` call `Drive`, after `FinishOrder` because `Drive` blocks.
- `SkyrimNet_DOM_Events.OnBehaviourChange`: `bathing` at `DOMBathingMode` rank 3/4 calls `FollowDomBath` unless `DOM_bath_driven` is set. Stage timing there is an estimate from DOM's timer.
- `SkyrimNet_DOM_Bath`: `StageText` stage 4 is the optional end line. `Drive` sends it after `EndJSONAnimation` unless interrupted; `FollowDomBath` sends it when `DOMBathingMode` is removed, within a 60s cap.
- `SkyrimNet_DOM_Events.OnBehaviourChange`: `bathing` at rank 2 calls `SkyrimNet_DOM_Bath.NarrateSelfWash` instead of narrating "is bathing". Leaving `bathing` narrates "stops washing." through the same `current` check as "stops masturbating."; partnered baths store `bathing_partner` so they skip it.
- `SkyrimNet_DOM_Menu.TM_DoNamed`: `shower` checks `SkyrimNet_DOM_Bath.CanSelfWash`, then calls `TryOrder` with `rollObedience=false`, because `DOM_Mind.StartBathing` makes the same `WillObey(28,-15,2)` roll.
- `Headers_Source/DOM` (local stubs): added `DOM_Interactor`, `DOM_Bathing`, `DOM_EquipUtil`, the JSON animation calls on `DOM_Actor`, and `DOM_Interactor.CanAnimateActor`.
- `SkyrimNet_DOM_Bath.Drive`: `DOM_bath_driven` is set before the strip and cleared on refusal. `StandUp` sends `IdleForceDefaultState` to non-player, unbound participants after `EndJSONAnimation`. `WornGear` / `RestoreGear` re-equip the player's own gear for bath me, on refusal too, because DOM's redress can't equip the player.
- `SkyrimNet_DOM_Obedience.TryOrder`: returns 0 while `SkyrimNet_DOM_Bath.IsDriven(slave)`, with no refusal or punishment.
- 12 actions that call `DOM_Keys` directly (`DOMSlave_BePromised*`, `DOMSlave_Be_PromisedFreedom`, `DOMSlave_BeScolded`, `DOMSlave_Be_FlatteredSexy`, `DOMSlave_Be_InsultedDegrading`, `DOMSlave_Be_PraisedGropeAss`, `DOMSlave_Be_PraisedHoldChin`, `DOMSlave_Be_PraisedKissDominant`, `DOMSlave_InspectFront`): eligibility requires `DOMActionBathing` rank < 0.

### Diary of Mine 8.5.6d
- Minimum DOM is now 8.5.6d (the only version verified).
- `SkyrimNet_DOM_Menu`: removed `DoShower`, `DoBathMaster`, `DoBathMe`, `DOMDoNPCBathMe`, `DoBreastsPresentation` replaced by `Interact_Bathing`, `Interact_BathClient`, `Interact_BathActor`, `DOMDoNPCBathClient`, `DOMDoNPCBathActor`, `DoBreastPresentation`. The NPC bath-you call is now `(target, speaker)`.
- `SkyrimNet_DOM_Events.OnWashSelf`: added `Form abuser` to match `SendExternalEventSASB("WashSelf", ...)`.
- `punishment_reason.json`, `dom_punishment_reason.prompt`, `DOMSlave_AddPunishmentReason.yaml`: indices 28, 35-37, 39, 40 follow DOM's `PunishmentReasons.json`; index 20 stays because DOM's code still uses it.
- `slave_behaviours.json`: `bathing`, `on_duty_restrained`, `jail_restrained`. `tied up` is only a `GetBehaviourString()` label; the behaviour value is `tied`.
- `Headers_Source/DOM` (local stubs): stale members removed and new names added. SkyrimNet_SexLab builds against them and needs its matching `Handler_DOM` change.

## 0.2.1

### Items
- Item YAMLs ship in the content plugin: `external/goodprovider.dom/items/diaryofmine-esm_EB8659.yaml` and `diaryofmine-esm_BB1B47.yaml`; `config/items/` copies removed
- DOM Training Info uses `show_in_prompts: false` (was `enabled: false`, which items refuse) and is now hidden from NPC equipment in prompts

### Bug Fixes
- Fixed: a Leash Framework holder leash on a DOM slave makes DOM follow the holder (`SkyrimNet_DOM_Events.OnLeashFrameworkLeash`, `SyncLeashFollow`)

### Install
- A legacy file SkyrimNet migrated into `overlay/items/` overrides the plugin record; users must delete it
- The leash fix needs the matching SkyrimNet_Leashed update

### Build
- Manifests at 0.2.1; the release zip no longer includes the 32 MB `SkyrimNet_DOM.pdb`

## 0.2.0

### Poses and gestures
- Slave poses and gestures are sent to the AI through a new SKSE hook and `dom.events.*` settings

### Torture counts as punishment
- Injury Engine torture of a slave is a DOM pain punishment (`Injury_Engine_Torture`) and trains them
- The player picks the reason (`dom.punish.torture_choose_reason`); the Punish panel lists DOM reasons
- SkyrimNet is told why through the `dom_torture_punish` event

### Healing counts as praise
- Healing Hands and SexLab Aid (`SkyrimNet_SexLab_AidStart`) praise the slave; a shocked slave gets care
- The reason list is `dom.praise.heal_choose_reason`

### Bug Fixes
- Fixed: LLM-ordered actions were always refused after DOM's `WillObey` gained a sixth argument
- Fixed: pain punishments stuck; they now end after 20 s idle (`EndWhipping`)
- Removed the Healing Hands `hit` trigger

### WebUI
- DOM TargetMenu entries `08xx_dom_*` and the **DOM Info** MainPanel `0850_dom_info.json`
- `dom.info.show_enjoyment` adds the orgasm-meter inputs

## 0.1.0

https://github.com/GoodProvider/SkyrimNet_DOM/releases/tag/0.1.0

Requires SkyrimNet 0.25.0 (Beta 25) or later. LLM actions and prompts install as plugin `goodprovider.dom` (External on the Plugins page). Do not use Plugins > Import Old Content for this mod's files.

- Actions, prompts, and Healing Hands now live in the SkyrimNet plugin folder. Files left in the old `prompts/` or `config/actions/` places are ignored.
- Tune Ext2 spam, notification history size, and short-lived event lifetime in the SkyrimNet dashboard (`dom.events.*`).
- Newly captured slaves get Direct Narration when they are assigned, instead of waiting for a late “just captured” mood.
- Slave melt/climax text still drives orgasm narration; the “squirms as your orgasm” tease no longer counts as the slave climaxing.
- Masturbating DOM slaves show up in SexLab activity prompts even when the game is paused.
