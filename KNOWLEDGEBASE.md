# Knowledgebase

Master reference for quirks, gotchas, and cross-version differences discovered while working on SkyrimNet_DOM (and shared Skyrim/Papyrus pitfalls).

**Standing rule:** consult this file before changes; after debugging or research sessions, append new facts here.

For agent policy (safety, confidence), see [AGENTS.md](AGENTS.md). For protocol contracts, see [docs/reference/](docs/reference/).

**Builds are the agent's job:** the agent runs the VS Code tasks (`compile: pyro` here, `compile: papyrus` in Injury_Engine, the SexLab tasks / CMake `--preset release`) itself, by running each task's command from `.vscode/tasks.json`, and reports the result. Do not hand compiling back to the maintainer.

## DOM-specific

| Fact | Notes |
|------|-------|
| DOM owns arousal | SLSO and other arousal mods do not drive DOM’s `arousal_factor`. See [docs/players/overview.md](docs/players/overview.md). |
| Ext2 not registered by default | Many DOM Ext2 ModEvents exist in `SkyrimNet_DOM_Events`. Dashboard `dom.events.ext2` (default false) gates `SetSendExternalEventsExt2` and those handlers — spam control. See [docs/authors/events.md](docs/authors/events.md). |
| Ext3 required for NotificationSent | `DOMOnNotificationSent` is Ext3-gated in `DOM_SendEvt`. Events must call **`DOM_API.SetSendExternalEventsExt3(true)`** (`main.d_api`, same quest as `DOM_Core`). Calling the toggle on `d_core` compiles only if a header stub exists and is a runtime no-op (`Method SetSendExternalEvents* not found on dom_core`) — HUD still shows, SkyrimNet never gets the ModEvent. Prefer notifications over `DOMOnOrgasm` (faster; leave Orgasm unregistered to avoid double `DOMSlave_Orgasmed`). |
| Actor lock key | Scene eligibility uses StorageUtil `skyrimnet_sexlab_scene_actor_lock` (shared with SkyrimNet_SexLab). |
| DomObedience skip window | `TryOrder` arms `ShouldSkipEventNarration` (~4s, FormID → steady_clock). Ext2 / `OnNotificationSent` / `DirectNarration_Optional` drop vanilla order DN for that slave. SexLab StageStart DN is never suppressed. Silent `WillObey(..., do_msg=false)` sets `timer_obedient` so the later vanilla roll short-circuits on `IsObedient()`. Refuse uses `RegisterEvent("Reason to Punish")` only — do not call `AddNextPunishmentReason` again (`WillObey` already queued the reason). Missing DLL: `TryOrder` returns `-1` and callers fall back to `OrderNarration`. |

## WebUI overlay (2026-09-16)

DOM does not ship a PrismaUI view. Player commands go through SexLab’s overlay. TargetMenu/MainPanels overlay into `SKSE/Plugins/SkyrimNet_SexLab/webui/` (`0800_dom_*.json`–`0880_dom_sack.json`, MainPanel `0850_dom_info.json`, plus Scene `0810_dom_abuse.json`) with `"source": "dom"` and `"requiresPlugin": "SkyrimNet_DOM.esp"`. There is no ControlPanel mode switch. Obedience gating is `SKSE/Plugins/SkyrimNet_DOM.dll` (`SkyrimNet_DOM_Native` / `SkyrimNet_DOM_Obedience`).

- **Actor → Scene catalog swap:** SexLab shows `TargetMenu/Actor` when focus is not animating and `TargetMenu/Scene` when it is (`SexLabAnimatingFaction`). Per-leaf sex locks on Actor JSON do not help mid-scene — Actor options are not loaded. Mid-scene verbal abuse lives under `webui/TargetMenu/Scene/options/0810_dom_abuse.json` (praise live cascade, scold/insult/flatter/threaten/promise, comfort care/guilt/threat/insult). Omits punish/upkeeping/comfort sex|rape. Scene **comfort → pain** uses `TM_ListComfortPainActions` / `TM_DoComfortByPain` (`*{speaker} comforts {target} by {painAction}*` TransformDialogue; param must not be named `action` — Papyrus reserved).
- **Pause:** SexLab `Focus(..., pause=true)` blocks DOM packages and SexLab `StartThread`. TargetMenu `closeWebUI: true`. Status/Slaves and live punish/praise openers stay open (`false`).
- **Actor-type pulldown gates:** TargetMenu shows only pulldowns that can be used on the focused actor. Each pulldown root has `eligibilityRules` (`logicalOperator: OR`) against slave rank / slaver faction / `webui_focus_kind`. Order / training / restrain / clothes are omitted for NPC/player targets. Restrain / clothes are omitted for a slaver target. Management / trainees: slaver **or** slave rank `== 2`. Services: NPC only. Nested pulldowns with zero remaining children are omitted by SexLab `ResolveOptionsArray`.
- **All Slaves:** sentinel on the Slaves MainPanel JSON, not player-as-group. `Target_Current` is None; eligibility `webui_focus_kind`. Group leaves call `DOMAllOrderSlaves` / `DOMAllOrderSlavesAndSlavers` / `DOMAllOrderBags`. Do not call `DOMDo*Menu` / `ShowCall*` / `OpenMenu()`.
- **Roster:** walk `DOM02.actorAliases` / `GetMaxActorCount` (same as GetThreads). Cap 43 rows (`truncated: true`). Row FormIDs may be signed ESL ints — SexLab JS/C++ coerce to uint32. `rowClickMainPanel: status` on the Slaves JSON.
- **Jail:** vanilla `DOMDoJail` opens `ShowJailMenu`. Status task uses `jail:1`–`jail:7` → `EnterJailTravel(mode)`. All Slaves Status applies the same group buttons.
- **Tie / restrain:** all bondage under restrain (rope poses, furniture `*ByIndex` via `TM_ListRestrainVariants` → SexLab `panel: fields` with names from `SKSE/Plugins/SkyrimNet_DOM/restrains/{kind}.json` + random, gag/plug, blindfold, cuffs, untie). Order does not nest tie-up. Do not use SexLab `panel: bondage`.
- **Follow panel:** vanilla Order slot is two-step (`DOMDoFollowMe` starts follow; a second click opens `DOMDoFollowMenu` because the wheel only has eight slots). That is **not** an obedience/reject roll. WebUI Order → Follow uses eligibility on `DOMActionFollowing` (rank 1 = following player) + `DOMFollowMode` so the row reads **follow** or **follow: tight|close|short|long**. Nested buttons apply modes **0–3** via `TM_DoFollowDistance` (DOM `SetFollowMode` clamps above 3). DN includes distance (`follow from a short distance`, etc.). Walk/crawl stays under Order → Walking (`TM_DoWalkingApply`; both crawl labels set `should_walk_on_four`). Walking does not start follow. Wait is a single `TM_DoNamed` button. **No DOM leash** — SkyrimNet_Leashed owns leash overlay rows. Cuffing / uncuff are on **restrain**. **Never** call `DOMDoFollowMe` when `behaviour == "follow_player"`.
- **Comfort sex/rape:** do **not** call `StartComfortingWith("sex"|"rape")` from WebUI — those paths call DOM `Anim_Sexlab`. Use `WebUI_StartScene_Comfort_Sex` / `_Rape`: TransformDialogue → public mind trains (`StartGuilt`/`TrainHumiliation` or `TrainSubmission`) → SexLab scene with intents `comfort with sex` / `pretend to comfort by sexual assault`.
- **Pose:** vanilla splits pose vs sexy-pose because of 8 slots. WebUI merges one list (Chair, Light, Flowers, Drinks, Cute, Dance, Music, Submissive, Ass, Breasts, Pussy).
- **Punish / praise live lists:** catalog JSON cannot hold mind-queued reasons (C++ catalog builds while paused). Overlay-open Papyrus `TM_PunishPanelOpen` walks `DOM_Mind` the same way as `ShowDOMPunishmentMenu` (no 8-cap) and pushes `WebUI_PushCascadeChoices` with `"panel": "fields"` (reason + method pulldowns, Start). Reason options **always** append **custom** (`opensText: true` → SexLab fields inline text; Ok adds the string to the pulldown and selects it; session-only) and **no reason**. Method **rape** expands SexLab `scene_start` controls without Custom; Start calls `TM_PunishRapeRecord` (mind `StartPunishing` only — no `Interact_Punish` / `Anim_Sexlab`) then SexLab `StartScene_Nonconsensual_*`. Other methods use `TM_DoPunish` → `StartPunishing`. `TM_DoPunish` for **no reason** + pain calls `mind.StartPunishingByIndex(speaker, 0, type)` because vanilla `GetAnyPunishmentReason("no reason")` remaps index 0. Free-text custom keeps the player string on `whipping_reason_name` / `current_punishment_reason_name` after Start; DOM may still remap the *index* for unknown tokens. Praise still uses button cascades (`TM_ListPraiseReasons`). Do **not** bake `punishment_reason.json` into the overlay. Cascade JSON uses `ObjectToLowerCaseKeyJson`; field keys are `fieldId` / `caption` / `choices` / choice `val`+`caption` (not `name`/`label`/`options`/`value` — string pool remaps those). Furniture variants use the same fields panel path (`TM_ListRestrainVariants`). Requires SexLab `setCascadeChoices` (`panel: fields`, `opensText`, `applyOnChange`).
- **nearby_actors:** pulldown `"optionsFrom": "nearby_actors"` + `optionTemplate` with `type: optionActor`. SexLab JS synthesizes buttons from `nearbyActors` (skip player + current target). Used for Upkeeping Follow-actor and Management Add/Unload trainee only — not Leash To.
- **Masturbate by faction:** idle (`DOMActionMasturbating` false) → pose panel; active → Stop / Harder (`StopScene_Masturbate` speaker is the slave; `MasturbateHarder`).
- **Training sex/rape:** consensual sex → `SkyrimNet_DOM_Actions.WebUI_StartScene_*` (DomObedience `TryOrder` kind `sex`, then SexLab). Rape stays SexLab `StartScene_Nonconsensual_*` (ungated). Scene Creator handoff JSON includes `_source` (`dom` from DOM pulldowns, else `sexlab`); DOM handoff gates via `TryOrderSexCast`. SexLab root sex is `0110_sex.json` (under Custom). Requires SexLab overlay HTML that keeps `navStack` for nested `scene_start` and supports `layout: buttons`.
- **Order DN:** gated leaves use `SkyrimNet_DOM_Obedience.TryOrder` (refuse `{slave} refuses {superior}'s command to {action}.` / obey+sex `{superior} orders {slave} to {action}.` — DirectNarration source=superior; sex `RegisterEvent` with the same order sentence). Sex `{action}` is `FormatSexCommand` (`have vaginal sex with {partner}`), not `style+" "+tags`. Ungated leaves and missing DLL use `OrderNarration` → `SkyrimNet_SexLab_Utilities.DirectNarration(msg, speaker, target)`. Papyrus forbids a variable named `action` (reserved). Keep `RegisterObeyCommand` for the short-lived LLM event. Skip window drops Ext2 / NotificationSent order DN; do not suppress SexLab StageStart DN.
- **Quest VMAD bind:** SexLab `ExecutePapyrusOption` / `DispatchPapyrusNoArg` use `FindBoundObject` on the quest. Catalog `scriptName` (`SkyrimNet_DOM_Menu` on `0x800`) must be attached in ESP VMAD. A compiled `Scripts/SkyrimNet_DOM_Menu.pex` is not enough — inventory/order clicks log `bound script 'SkyrimNet_DOM_Menu' not found` and Papyrus never runs. Add the script next to Main/Actions/Events on quest `SkyrimNet_DOM`; reload a save so the VM binds it.

## SkyrimNet Beta 25 content plugin (2026-09-13)

Beta 25 does not read `prompts/`, `config/triggers/`, or `config/actions/`. LLM content ships as `SKSE/Plugins/SkyrimNet/external/goodprovider.dom/` (`manifest.json` `id` must equal the folder name). Prompt paths inside the plugin are unchanged (`prompts/helpers/…`, submodules). Action YAML filename (before `.yaml`) must equal the in-file `name` (case-insensitive); keep `name` casing. The Healing Hands trigger was removed in 0.1.1; the bundle ships no triggers. Action and trigger file stems match `name` case-insensitively; form-keyed stems (`items/` etc.) must match exactly (SkyrimNet `CONTENT_ROOTS.md`). Settings schema stays at `config/plugins/SkyrimNet_DOM/manifest.yaml` (`schema.fields` + `defaultValue`; `plugin.name` SkyrimNet_DOM, `dom.events.*` keys) — that is not a content-plugin folder. Papyrus reads `Plugin_SkyrimNet_DOM` via `GetConfig*`. Item YAML stays at `config/items/`. JSON under `SKSE/Plugins/SkyrimNet_DOM/` is unchanged. Do not ship into `library/`. Upstream: SkyrimNet `docs/modding/MIGRATING_TO_BETA25.md`.

Pyro compile: `RaceMenu\scripts\source` is not in this mods tree. `skyrimse.ppj` imports `Headers_Source/NiOverride.psc` (stub) so SexLab's `sslActorAlias` can type-check. Do not ship that header as a runtime replacement for RaceMenu.

## DOM01 menu leaks into "Quests You Could Raise" (2026-09-26)

**Symptom**: the dialogue prompt (OpenRouter log) contains `### Diary Of Mine Readers Manager` with the player's Orders tree (`Bob: You'll do exactly what I tell you. [Orders]`, rope/chain poses) under core `0740_quest_dialogue.prompt`'s "Quests You Could Raise". Its lines are also fireable via `SpeakQuestLine`.

**Cause**: `available_dialogue(npc.UUID, "quest")` counts a topic as quest dialogue when its TIF touches a quest that has objectives or a quest type. `DOM01` (`DiaryOfMine.esm:000D61`) is Start Game Enabled, quest type 8 and has 1 QOBJ. The decorator has no exclude keyword.

**Fix**: SkyrimNet's Dialogue Actions blacklist can be shipped by plugins (rc11+, confirmed by the SkyrimNet dev). Add a `kind: lists` YAML under the plugin layer's `dialogue_actions/`: `external/goodprovider.dom/dialogue_actions/dom01_readers_manager.yaml` with `blacklist: [DOM01]`. Entries are quest EditorIDs or `TIF__XXXXXXXX`. Reference examples: `library/skyrimnet.base/dialogue_actions/` (NFF `nwsFollowerController`). In game it's under SkyrimNet Settings (search "blacklist"). Log: `[DialogueActionsLibrary] N whitelist and M blacklist entr(ies)`. See [docs/authors/content.md](docs/authors/content.md#dialogue-actions-blacklist).

## Dom melt without DirectNarration (2026-07-27)

**Symptom**: Papyrus shows `IsOrgasmingAfterArousal` + widget `… brain melts … orgasm` for a Dom slave (e.g. Toy), but SexLab DN is Bob-only (`Bob is orgasming`) or denies the slave (`… was denied an orgasm`) — no `" is orgasming."` for the Dom actor.

**Cause**: `SendExternalEventSSBS("NotificationSent", …)` early-returns when Ext3 is off. `OnNotificationSent` never runs → `Handler_DOM.DOMSlave_Orgasmed` / `OrgasmCustom` never feed custom orgasm text. SexLab Combined skips Dom fill and may treat `orgasm_expected[slave]=0` as deny.

**Fix**: Enable Ext3 via `main.d_api.SetSendExternalEventsExt3(true)` in `Register_Events`; keep `DOMOnOrgasm` commented. Do not call Ext toggles on `DOM_Core`.

## Player-orgasm tease is not a slave climax (2026-09-13)

**Symptom**: Oral-only scene (e.g. Nina giving, `orgasm_expected [0, 1]`). Dom never sent melt/`NotifyOrgasm` for the slave. SexLab Combined would have written `Nina is not orgasming right now. Bob is orgasming.` Instead DN was `Nina squirms under your grasp as your orgasm submerges you. Nina is orgasming.`

**Cause**: `DOM_Mind` `handleSeparateOrgasmEvent` / Combined `handleSexOrgasm` sends `{name} squirms under your grasp as your orgasm submerges you` when the **player** climaxes. `OnNotificationSent` used `Find(description, "orgasm")` and called `DOMSlave_Orgasmed` before Trace, so Papyrus never logged the tease.

**Fix**: `OnNotifcationSkip` drops squirms / `your orgasm submerges you` (no DN, no ring). `IsDomMeltOrgasm` routes only `brain melts` / `mind melts` / `overwhelmed by orgasm` / `submerged by orgasm`, and rejects `your orgasm`. SexLab `Handler_DOM.DOMSlave_Orgasmed` also refuses the tease.

## Ext toggles are on DOM_API, not DOM_Core (2026-09-13)

**Symptom**: DOM abduction (Nina) and other Ext0/Ext1/Ext3 activity produce HUD/DOM traces but no `OnNotificationSent` / Direct Narration. Papyrus: `Error: Method SetSendExternalEvents* not found on dom_core`.

**Cause**: `SetSendExternalEvents*` live on Diary of Mine `DOM_API` (forwards to `DOM_SendEvt`). `DOM_Core` has no such methods. Header stubs on `DOM_Core` let the bridge compile `d_core.SetSendExternalEvents*` and then fail at runtime, leaving Ext3 false.

**Fix**: Call `main.d_api.SetSendExternalEvents*` only. Header stubs for those functions belong on `DOM_API`, not `DOM_Core`.

## GetThreads must walk actorAliases (2026-09-13)

**Symptom**: Nina masturbating via DOM never appears in SexLab `0050_sexlab_activity.prompt`. `sexlab_get_threads` is blocked when a menu pauses the game; `threads.json` stayed the last empty dump.

**Cause**: `GetThreads` used `GetActorCount` / `GetActorByIndex` (`actorArray`), which lag until `UpdateActorArray` after Mind `AfterAssign`. DOM bio `0055` skips `masturbating.` so SexLab 0050 can own it — if GetThreads returns empty, neither prompt shows it.

**Fix**: Walk `DOM02.actorAliases` / `GetMaxActorCount` (same as capture `ScanCaptureAliases`). Masturbating = `is_behaviour_masturbate` or `behaviour == "masturbate"` or `DOMActionMasturbating`. Skip `IsBusy` so a live SexLab scene is not double-listed. `StartScene_masturbate` / `StopScene_Masturbate` dump SexLab `threads.json` synchronously after behaviour changes. `DOMOnBehaviourChange` is too late for the next paused prompt; SexLab `0050` also faction-gates live threads.

## Capture DN is alias-assignment, not StartMood (2026-09-13)

**Symptom**: After Ext3 is actually on, abduction still has no Direct Narration. Papyrus shows Actor/Mind `AfterAssign start` and a long `SetPersonality` dump; no `mood=just_captured start` / `OnNotificationSent`.

**Cause**: `just_captured` `StartMood` (`Nina was just captured`) runs only at the **end** of Mind `AfterAssign` → `SetPersonality` (outfit, SexLab seed, kinks). `AddActor` calls that synchronously; the grab animation already finished in `SendCaptureAnimationEvent` before `Capture()`. Ext3 cannot deliver a notification that has not been sent yet.

**Fix**: `SkyrimNet_DOM_Events` `OnUpdate` (2s) walks `DOM02.actorAliases` (filled at `ForceRefTo`, before Mind `AfterAssign`). `GetActorCount` / `actorArray` are only refreshed in `UpdateActorArray` **after** Mind `AfterAssign`, so they stay empty during capture. New player-owned aliases (`mind.is_player_slave`) get required grab `DirectNarration` once per FormID (`OnCaptureAssigned`). Existing aliases are seeded on load. Late `"was just captured"` stays in `OnNotifcationSkip`. Do not rewrite every `freshly captured` notification (personality “will be fairly easy to train” uses that type).

## DOM build must follow SexLab's header stubs (2026-10-23)

**Symptom**: After SexLab 0.36.x, `compile: pyro` fails on DOM. First it reports `Import path does not exist` (`SexLabFrameworkAE_v166b`, or the old extension's `pyro.exe` path in `.vscode/tasks.json`). After that, it reports unknown types in SexLab scripts.

**Cause**: DOM imports `SkyrimNet_SexLab\Scripts\Source`, and Papyrus type-checks the SexLab scripts DOM pulls in (`Utilities`, `Scene_Manager`, `Actions`, `Main`, `WebUI`). Since 2026-10-14, `SkyrimNet_SexLab_Utilities` references `SkyrimNet_SexLab_PPlus` and `TNG_PapyrusUtil`, and `Scene` → `LoversLedger` references `TTLL_*`. Those stubs live only in SexLab `Headers_Source\` (root) and `Headers_Source\LoversLedger\`.

**Fix**: `skyrimse.ppj` imports `@ModsFolder\SkyrimNet_SexLab\Headers_Source` and `...\Headers_Source\LoversLedger` last, so they only fill gaps. SexLab framework is `@ModsFolder\SexLabFrameworkAE\scripts\Source`. Pyro is `C:/Skyrim/tools/Pyro/pyro.exe` (same as SexLab). When SexLab adds a new `Headers_Source\<dir>` stub folder, mirror its import here; do not copy the stubs into DOM. `Headers/SkyrimNet_SexLab_*.psc` in this repo are stale copies that no build imports.

**Threads**: SexLab now pushes threads natively. `Scene_Manager.SaveThreadsJson` is a shim kept for DOM (→ `PushDomThreads` → `Threads_SetDom`). DOM keeps calling it. `skyrimnet_sexlab_scene_actor_lock` is still mirrored to StorageUtil (`ActorLocker.cpp`), so the `papyrus_util HasIntValue` YAML gates still work.

## Injury Engine torture as DOM punishment (2026-10-23)

**OnHit is not enough.** DOM counts a punishment's hits in `DOM_Actor.OnHit` → `HandlePunishmentOnHit`, and `HandlePunishmentOnUpdate` ends a pain punishment after one tick with no hit. Injury Engine hand torture (`External_*`, `Torture_Target` slap / pinch / pull) and torture-spell ticks fire no `OnHit`, so `OnInjuryTorture` calls `mind.HandlePunishmentOnHit` itself on every `Injury_Engine_Torture` batch. A whip lash can count twice (OnHit plus the event); that only changes DOM's pain tallies.

**DOM starts weapon whippings itself.** A weapon lash's `OnHit` runs `DOM_Actor.StartWhipping` → `StartPunishingByIndex` with DOM's next reason (or 0, "no reason") *before* the async `Injury_Engine_Torture` event arrives, so `whipping_active` is already true. Never gate the reason pick on `!whipping_active` (that hid the player's list, 2026-10-23 test). `SkyrimNet_DOM_API.TortureReasonNamed` keeps a StorageUtil marker per slave instead: the `whipping_reason` the bridge wrote plus `whipping_pain_damage` after its last batch. `StartPunishingByIndex` resets the damage and `EndPunishing` resets the reason, so either one changing means a new punishment.

**Reason after the fact.** `StartPunishingByIndex` returns early while `whipping_active`, so a reason picked later (WebUI list) is written straight to `mind.whipping_reason` / `whipping_reason_name` (`NameRunningPunishment`). While the list is up, the punishment carries a random open reason (no event). That keeps later batches from reopening the list, and a list closed without a pick still trains on a real reason.

**A punishment that never ends hides the reason list (2026-10-24).** A save carried Skadi in a pain punishment ("didnt obey", index 18) with `whipping_active` still true. Every batch after load logged `active:TRUE reason:18 fresh:False`, so there was no list and no `dom_torture_punish`. One trap: DOM's tick (`HandlePunishmentOnUpdate`) ends a punishment only when `whipping_by_trainer == false`. That flag is set when the abuser has a DOM mind, and then only the trainer's `punishing`-state `EndBehaviour` ends it. A player weapon `OnHit` clears the flag. It is not proven that this is what stuck it. Fix: `SkyrimNet_DOM_API.EndStalePainPunishment` caps a pain punishment at 60 real seconds (game time ÷ TimeScale; start in StorageUtil `skyrimnet_dom.pain_start`). It runs from the 2 s alias scan and at the top of `OnInjuryTorture`, then calls `DOM_Actor.EndWhipping` and clears the bridge markers. Injury Engine also sends `Injury_Engine_Torture` for leash trips (`falling`). `OnInjuryTorture` skips `falling` / `leash_dragging`.

A save-leftover pain punishment must end at once, not after the 20 s cap: it is "named" (StorageUtil `torture_reason_index` matches `whipping_reason`) but has no `skyrimnet_dom.pain_start`, since genuine bridge punishments get one from `MarkPainStart`. A cap that starts its timer on first sight made the first 20 s of whipping after every load of such a save open no reason list (no-box, 2026-10-24). `EndStalePainPunishment` traces `legacy:true` for it.

**Choice_Open JSON from a hit event: build it as a string.** `OpenTortureReasonList` built its options with JMap/JArray and `SkyrimNet_SexLab_Utilities.ObjectToLowerCaseKeyJson`. Called from `OnInjuryTorture`, the list arrived empty (`Choice_Open options=0` in SkyrimNet_SexLab.log, while Papyrus had built 2 rows). The same serializer works from menu callbacks. `JMapToJson` silently writes `null` when a nested call returns "", so a dropped array leaves no trace. The list now concatenates the JSON with `SkyrimNet_SexLab_Utilities.JsonQuote` and traces its first 200 chars. `OpenHealPraiseList` hit the same bug from the SexLab Aid event (panel opened with no rows, not even custom) and is built the same way (`HealPraiseChoice`). Any `Choice_Open` opened from a ModEvent or hit handler should be a string.

**Resolve stored FormIDs with `Game.GetFormEx`, not `Game.GetForm`.** `TM_DoTortureReason` gets the slave as a static string FormID through SexLab `Choice_Open`. For an ESL-plugin slave (`-33241028` = `0xFE04C83C`) `Game.GetForm(slaveId as Int)` returned None (`no slave for id -33241028`), so the pick was dropped. The string arrived intact; SKSE `Game.GetFormEx` resolves light-plugin forms. Other mods here (SeverActions, NL_CMD) use `GetFormEx` for the same reason.

**Care without the hug.** `StartComfortingWith(.., "care")` always plays `Anim_GetPlayerHug`. Healing Hands therefore copies the branch (`ComfortCareNoHug`). DOM's `abuse_type` is a private variable and is not set.

**Heal = praise unless shocked.** DOM has no "reward". Its reward is praise (`DOM_Actor.StartPraising(abuser, reason, type)`), which fires `DOMOnPraised`. Healing Hands praises with type `"tell"` so no pat or kiss idle interrupts the cast. Care comfort applies only when `DOM_Mind.mood == "shocked"` (the token `DOMOnMoodChange` sends; inferred, as DOM's source is not available locally). Papyrus `parameterMapping` order must match the callback's signature (`TM_DoHealPraise(speaker, slaveId, reason)`).

**SexLab Aid casts nothing.** `Aid.cpp` plays visuals and calls `Injury_Engine_Main.External_Heal`; no spell effect lands, so Injury Engine never sends `Injury_Engine_HealStart` for Aid. DOM listens to SexLab's `SkyrimNet_SexLab_AidStart` instead (caster FormID in strArg as a signed decimal so `as Int` parses ESL / FE ids).

**SexLab panel reason.** The Punish panel lands hits through `External_TortureText`, which has no cause. SexLab C++ `PunishNarrated` dispatches `SkyrimNet_DOM_API.PanelPunished` before the hit (only when that script exists), and the torture handler reads it within 10 s (`TakePanelReason`).

**Stubs.** Every DOM member used here must exist in `Headers_Source/DOM` (Pyro: first import wins), and that folder is not in git. Keep it in sync on other machines.

## Manifest YAML error drops the whole config (2026-10-23)

**One bad quote disables every setting.** If `config/plugins/SkyrimNet_DOM/manifest.yaml` does not parse, SkyrimNet logs `PluginConfig.cpp:198 ... yaml-cpp: error at line N, column M` and `PluginConfigDiscovery.cpp:95 Failed to load plugin config 'Plugin_SkyrimNet_DOM'` at startup. The config is never registered. Later, every Papyrus `GetConfigInt/Bool` logs `ConfigManager.h:236 Configuration 'Plugin_SkyrimNet_DOM' not found` and returns the default value, and the WebUI shows no DOM settings. The cause was an unescaped `"..."` inside a double-quoted `description:`. Use single quotes inside, or escape them as `\"`. When you see "not found", search the startup log for `PluginConfig`.

## Slave idle gestures need an engine hook (2026-10-24)

**DOM gestures fire no event.** `DOM_Mind.ChooseIdle` calls `DOM_Actor.Anim_Salute/LookDown/CrossArms/CoverSelf/...`, which use `Debug.SendAnimationEvent` or `PlayIdle` and nothing else. We do not override `DOM_Actor.pex` (it runs past 23k lines, and every DOM update would break the override). `SkyrimNet_DOM.dll` instead hooks vfunc 1 on `VTABLE_Character[3]` (`IAnimationGraphManagerHolder::NotifyAnimationGraph`, NPCs only). It checks a pointer-keyed whitelist of event names and defers the faction check, cooldown and ModEvent to the main thread. Not yet verified: that `PlayIdle` gestures reach this vfunc with `TESIdleForm::animEventName`. Check with `dom.events.gesture_debug`. Held poses need no hook, because `DOM_Actor.poseId` is a public auto property.

## DOM Info view = SexLab `actor_profile` (2026-10-24)

**What**: `MainPanels/0850_dom_info.json` (type `actor_profile`) shows PrismaUI-for-DOM's profile inside the SexLab ControlPanel. `SkyrimNet_DOM_Menu.WebUI_DomInfoOpen` → `SkyrimNet_DOM_InfoPanel.BuildPanelJson`. SexLab draws it with the generic `renderActorProfile` (pills / bars / radar / recs / events / lines). SexLab re-runs the open foreign panel's `openFunction` on every ControlPanel target change (`ActionCatalog::RefreshForeignMainPanel`), so the view follows the target.

**Quirks**:
- The DOM stub headers in `Headers_Source\DOM` (gitignored, local only) win over the full `PAH Diary Of Mine\Scripts\Source` import. Every new DOM member needs its exact signature copied into the stub (`DOM_Mind` HEXACO/PRISM/MOD_*/memory_abuse_*, `DOM_Core` factions + `DOMGenerator` + `GetDifficultyLevel`, the new `DOM_Generator.psc`).
- `key` cannot be used as a Papyrus identifier ("key is not a variable").
- SKSE `StringUtil` has no `ToUpper`. Use `AsOrd` / `AsChar`.
- Enum string values (`bars`, `live`, `bipolar`) can come back with another casing from the Papyrus string pool, so SexLab JS lowercases them (`apKey`).
- **Keys too:** `ObjectToLowerCaseKeyJson` does not lowercase in practice. `JsonLowerCaseKeys` returns a BSFixedString, and the case-insensitive pool hands back the still-live raw JSON with its original casing. `name` / `label` / `text` / `lo` / `hi` arrived as `Name` / `Label` / `Text` / `Lo` / `Hi`, so the name, pill captions, bar names, radar words and event text drew blank. The CSS/SVG rework in checkpoint 02 was a dead end. Fix: `renderActorProfile` runs `apLowerKeys` on the payload first.
- The Prisma mood tips are keyed by mood code, but DOM pushes the mood display name: strip it to letters, then alias `inshock→shocked`, `nothappy→depressed`, `annoyed→jealous`, `outraged→defiant`, `offended→proud`.
- **Enjoyment section** (`dom.info.show_enjoyment`, default off): `InfoPanel.AddEnjoyment` calls `events.handler` (`SkyrimNet_SexLab_Handler_DOM`) `IsRefractory` / `EstimateChance` / `OrgasmMeter` and does not copy their formulas, so the panel matches the SexLab HUD's DOM bar. If the handler esp is missing, the section is skipped. Bars carry an optional `text` (`x1.25`, `37%`, `Refractory`) that is shown in place of the number.

## Leash Framework leash on a just-captured slave fights DOM (2026-10-26)

**Symptom**: Right after capture, with SkyrimNet_Leashed active, the slave flips between being yanked up (leash) and lying on her back (DOM). Pressing E fires DOM `OnActivate` → `HandleDialogueOnActivate` but no dialogue opens. Leash Framework logs repeated "Interrupting forced-recovery get-up", and Leashed logs `stuck knockdown … knock=6; BleedOutStop` and then `ResetStuckActor` (Disable/Enable).

**Cause**: The capture DN makes the slave's LLM pick `leashed_leash_speaker`. That puts on a tight Leash Framework leash, and the Framework ragdoll-pulls her while she is still on the floor. DOM's own `OnLeashRagdollPulled` → `EnterFollowTarget` does nothing, because `GetActor` fails while Actor/Mind `AfterAssign` runs (~20 s). When `AfterAssign` ends, DOM starts `flee_and_cower` (`is_restrained`; its default quietPose is `Anim_BleedOutStart`). Leashed's watchdog then sends `BleedOutStop` at that pose. Knock state 6 = kGetUp, stuck. The LLM re-picked the leash action every ~20 s, so each "replaced" leash yanked her again.

**Fix**: `SkyrimNet_DOM_Events` registers `LeashFramework_OnLeash` when `Leash.esm`/`.esp` is loaded. A holder leash marks the actor pending for 60 s (JMap `leash_sync_pending`). The 2 s capture scan (`SyncLeashFollow`) calls `DOM_Actor.EnterFollowTarget(holder)` once `is_initializing` is false and DOM is not already following. This is what DOM's own `DOMDoLeash` does. It skips SexLab scenes and furniture. After the window ends, kneel/wait orders while leashed are left alone. Wall/floor ties (no holder) are ignored. Compile-only stub `Headers_Source/LeashFramework.psc` (`IsLeashed`, `GetLeashHolder`); the `is_initializing` property was added to the `Headers_Source/DOM/DOM_Actor.psc` stub. SkyrimNet_Leashed side: `AnimationController` returns "Diary of Mine" for `DOMActionPosing` / `DOMActionTied` / `DOMActionFleeing`, `TickDowned` treats that as not stuck, and `leashed_leash_speaker` / `leashed_leashLeashed` need `speaker_is_leashed == "unavailable"`.

## Shared engine gotchas

See the short list in [AGENTS.md](AGENTS.md). Expand here when a session proves a SE/VR or Papyrus quirk for this project.

**Default args are filled in at the caller's compile time.** DOM added `bool choose_not=true` to `DOM_Mind.WillObey`, but `Headers_Source/DOM/DOM_Mind.psc` still had 5 params. `SkyrimNet_DOM_Obedience.TryOrder` compiled a 5-arg call. At runtime: `Incorrect number of arguments passed to function dom_mind.WillObey ... Expected 6, got 5`, the call returns None (false), and every gated order is refused. After a DOM update, diff `Headers_Source/DOM` against the installed DOM source. When you add a param to one of our own global functions (e.g. `TryOrder`), recompile every caller: Pyro incremental skips unchanged callers, and their old .pex fail the same way.

**LLM actions skip WillObey.** `SkyrimNet_DOM_Actions.GateSlave` passes `rollObedience=false` because the LLM already decided the slave obeys. WebUI menu (`Menu.GateOrder`) and Scene Creator (`TryOrderSexCast`) orders still roll.

**Unknown punishment reason tokens fall back to index 0.** `Main.Get_Punishment_To_Index` returns `punishment_default_index` (0) for free text. With `whipping_reason = 0`, DOM's end-of-punishment summary and training use the slave's queued/provisional reason instead ("custom: 'refusing sex'" → "6 strokes for being too slow", `Training: efficiency`). Map free text to a real token (`Main.Has_Punishment_Reason` check → `being a bad slave`) and keep the text on `whipping_reason_name`.
