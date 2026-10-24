# Changelog

## Unreleased

- Fix slave sex (and other LLM-ordered actions) always being refused. `SkyrimNet_DOM_Obedience.TryOrder` called DOM `WillObey` with 5 args; DOM now takes 6 (`choose_not`), so the call aborted and returned false. LLM actions (`SkyrimNet_DOM_Actions.GateSlave`) no longer roll `WillObey` (new `TryOrder` param `rollObedience`, default true). Menu and Scene Creator orders still roll and now pass all 6 args. `Headers_Source/DOM/DOM_Mind.psc`: `WillObey` gains `choose_not=true`.
- Injury Engine torture of a DOM slave is a DOM pain punishment. `SkyrimNet_DOM_Events` registers `Injury_Engine_Torture` (`OnInjuryTorture`). The first hit runs `StartPunishingByIndex(attacker, 0, "pain")` unless DOM's own OnHit already started it (weapon whips). The first batch of each punishment picks the reason (`SkyrimNet_DOM_API.TortureReasonNamed`, a StorageUtil marker of `whipping_reason` + `whipping_pain_damage`). Every hit calls `mind.HandlePunishmentOnHit`, so hand and spell torture keep the punishment going. DOM ends it and trains (`EndPunishing` → `TrainAfterPunished`). The torturer is the player, or someone `DOM_Core.IsAllowedToPunish` allows.
- Reason: the SkyrimNet_SexLab Punish panel's pick (`SkyrimNet_DOM_API.TakePanelReason`) if there is one, else the player's WebUI list (new setting `dom.punish.torture_choose_reason`, default on, through SexLab `Choice_Open`: random, "being a bad slave" and "didnt obey" always, the other open reasons, custom via UIExtensions `UITextEntryMenu`, no reason), else a random open reason ("being a bad slave" when none). The list JSON is built as a string (`Menu.TortureReasonChoice`): the JContainers serializer dropped the options from the hit event. `ApplyTortureReason` sets `whipping_reason` / `whipping_reason_name` and sends `RegisterEvent("dom_torture_punish", "Bob is punishing Nina because she refused to comply with the sexual demands of Bob.")`. The list callbacks (`TM_DoTortureReason`, the heal praise callback) resolve the slave with `Game.GetFormEx`: `Game.GetForm` missed ESL slaves. Custom text gets the "being a bad slave" index (`NameRunningPunishment`, new `Main.Has_Punishment_Reason`): the default index 0 made DOM summarize and train on the provisional reason.
- Punish panel: `SkyrimNet_DOM_API.PanelPunishReasons` (called from SexLab `Handler_DOM.SeedPunishReasons` at scene start) adds the slave's open DOM reasons to the panel. `PanelPunished` (called from SexLab C++ before the hit) maps the pick: a DOM text → that reason, a SexLab strategy or request reason → "didnt obey", anything else → "being a bad slave".
- Healing Hands (Skyrim.esm `0x04D3F2`) cast on a DOM slave: a shocked slave (`DOM_Mind.mood == "shocked"`) gets DOM "care" comfort without the hug animation (`Injury_Engine_HealStart` → `ComfortCareNoHug`, which copies `StartComfortingWith` "care"). Any other slave is praised (`StartPraising(caster, reason, "tell")`). New setting `dom.praise.heal_choose_reason` (default off): the player gets a `Choice_Open` list of praise reasons (`Menu.PraiseReasonList`, shared with `TM_ListPraiseReasons`) plus custom → `Menu.TM_DoHealPraise`. The list always starts with `Menu.DefaultPraiseReason` ("being a good slave" / "being a good slaver"), which is also used with the setting off or a blank custom. Closing the list gives no praise. `TM_ListPraiseReasons` lists the default first too.
- Needs SkyrimNet_SexLab whose `Choice_Open` list supports `opensText` rows (inline text → first dynamic mapping).
- `Headers_Source/DOM` stubs: `DOM_Mind` (`IsComforted`, `TrainRespect`, `TrainAnger`, `MOD_Ease`, `HandlePunishmentOnHit`, `whipping_pain_damage`, `time_last_*`, `SetNextPraiseReasonSilent`, `CheckAndRegisterKink`, `TrainSkillPredator`), `DOM_Actor.SendExternalEventSSB`, `DOM_Core` (`IsAllowedToPunish`, `GetActorMind`, `DOMPlayerAlias`), `DOM_Diary.NotifyEndComforted`, new `DOM_PlayerAlias.psc`. `Headers_Source/` is not in git.
- Needs Injury Engine with the `Injury_Engine_Torture` / `Injury_Engine_HealStart` mod events, and SkyrimNet_SexLab with `Choice_Open`.

## 0.1.1 (since 0.1.0)

- Remove Healing Hands `hit` trigger (`triggers/Healing_Hands.yaml`, `weapon_id` 316402). The `goodprovider.dom` bundle no longer ships `triggers/`; `manifest.json` version 0.1.1.

## 0.1.0 (since 0.0.6)

- Ship LLM actions, prompts, and the Healing Hands trigger as SkyrimNet Beta 25 external plugin `goodprovider.dom` (`SKSE/Plugins/SkyrimNet/external/goodprovider.dom/`). Loose `config/actions/`, `config/triggers/`, and `prompts/` are removed; Beta 25 does not read those folders.
- Action YAML filenames now equal in-file `name` (e.g. `DOMSlave_Sex_Two_Fucking.yaml`); `name` values unchanged. Trigger `Healing Hands` → `Healing_Hands`.
- Settings schema at [`config/plugins/SkyrimNet_DOM/manifest.yaml`](SKSE/Plugins/SkyrimNet/config/plugins/SkyrimNet_DOM/manifest.yaml) (`plugin.name` SkyrimNet_DOM, `dom.events.ext2` / `notification_ring` / `short_lived_ttl`). Papyrus `ApplyPluginConfig` reads `Plugin_SkyrimNet_DOM`.
- Requires SkyrimNet **0.25.0+**. Plugin should appear under Installed Plugins with an **External** badge. Item YAML stays at `config/items/`.
- Ext toggles (`SetSendExternalEvents*`) via `main.d_api` (`DOM_API`), not `d_core` — calling them on `DOM_Core` is a runtime no-op (HUD still shows; SkyrimNet never gets the ModEvent).
- Capture / abduction Direct Narration: Events `OnUpdate` (2s) walks `DOM02.actorAliases` (`GetMaxActorCount`); new player-owned aliases (`mind.is_player_slave`) get required `DirectNarration` once per FormID (`OnCaptureAssigned`). `GetActorCount` / `actorArray` stay empty until `UpdateActorArray` after Mind `AfterAssign`.
- Melt / climax routing: `IsDomMeltOrgasm` (`brain melts` / `mind melts` / `overwhelmed by orgasm` / `submerged by orgasm`; reject `your orgasm`). Player-climax tease (`squirms under your grasp` / `your orgasm submerges you`) is `OnNotifcationSkip` (no DN, no ring, no `DOMSlave_Orgasmed`).
- `GetThreads` walks `actorAliases` / `GetMaxActorCount` for live masturbate threads (incl. `DOMActionMasturbating`). `StartScene_masturbate` / `StopScene_Masturbate` dump SexLab `threads.json` via `SaveThreadsJson`.
- `RegisterObeyCommand` TTL from dashboard `dom.events.short_lived_ttl`; notification ring size from `dom.events.notification_ring` (existing rings keep size until load).
- Docs: `docs/players/*`, `docs/authors/*`, `docs/developers/papyrus.md`, KNOWLEDGEBASE aligned to plugin layout, Ext2/Ext3, capture DN, and melt vs tease.

## 0.0.6 (since 0.0.5)

- `dom_get_actor_info` fills thin / slaver / slave buckets (`dom_faction`, trainees, skills, career, orders, experience, love/loyal, virgin, promise, …) — contract: [docs/reference/json-keys.md](docs/reference/json-keys.md)
- Bio load gate uses `DOMActorFaction` (`0006_dom_variables.prompt`); new slices `0016`–`0031` for slaver/slave detail; `0515` skills sentences refined
- `AddNotification`: duplicate anywhere in the ring refreshes timestamp and rotates to newest; fans out to other DOM actors named in the text (`AddNotificationActor`)
- `OnNotificationSent`: player / non-actor / non-slave early returns commented out (wider delivery)
- `OnNotifcationSkip` / aged-notification filter: skip generic trainer / trainee / follow / fetch / punish-trainee status lines
- Docs: `docs/authors/prompts.md`, `docs/authors/events.md`, `docs/reference/json-keys.md` aligned to buckets and notification behavior

## 0.0.5 (since 0.0.3)

- Enabled `SetSendExternalEventsExt3(true)` so Dom melt/orgasm notifications reach `OnNotificationSent` → SexLab Handler DN (Ext3 was off; HUD melt showed while DN denied Dom slaves / Bob-only)
- Split two-person consensual sex into `DOMSlave_Sex_Two_Fucking` (penis) and `DOMSlave_Sex_Two_Giving` (`no_penis`); removed monolithic `DOMSlave_sex_start_2`
- Dropped `style` from punish and three-person sex YAML/Papyrus quest args to stay within SkyrimNet’s 8-parameter limit (2P sex still maps `style`)
- Fixed eligibility lock key to `skyrimnet_sexlab_scene_actor_lock` on Be/Pose/FightForMe/punish/sex category actions
- Tightened `Be_FlatteredSexy` eligibility (`required: true`); `Be_Refused` uses `rejector`
- Hardened null checks for punishment reasons, event registration, and masturbate stop/threads
- Animation-end cleanup now routes through `GetActorsFinishedWithScene` (incl. SexLab clear-animating)
- Moved author docs to `docs/` (players / authors / developers / reference); README/AGENTS/llms updated
- Release zip includes full `SKSE/` again (0.0.3 was scripts-only)
