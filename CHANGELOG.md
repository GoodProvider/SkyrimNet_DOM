# Changelog

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
