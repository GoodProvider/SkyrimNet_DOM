# Knowledgebase

Master reference for quirks, gotchas, and cross-version differences discovered while working on SkyrimNet_DOM (and shared Skyrim/Papyrus pitfalls).

**Standing rule:** consult this file before changes; after debugging or research sessions, append new facts here.

For agent policy (safety, confidence), see [AGENTS.md](AGENTS.md). For protocol contracts, see [docs/reference/](docs/reference/).

## DOM-specific

| Fact | Notes |
|------|-------|
| DOM owns arousal | SLSO and other arousal mods do not drive DOM’s `arousal_factor`. See [docs/players/overview.md](docs/players/overview.md). |
| Ext2 not registered by default | Many DOM Ext2 ModEvents exist in `SkyrimNet_DOM_Events`. Dashboard `dom.events.ext2` (default false) gates `SetSendExternalEventsExt2` and those handlers — spam control. See [docs/authors/events.md](docs/authors/events.md). |
| Ext3 required for NotificationSent | `DOMOnNotificationSent` is Ext3-gated in `DOM_SendEvt`. Events must call **`DOM_API.SetSendExternalEventsExt3(true)`** (`main.d_api`, same quest as `DOM_Core`). Calling the toggle on `d_core` compiles only if a header stub exists and is a runtime no-op (`Method SetSendExternalEvents* not found on dom_core`) — HUD still shows, SkyrimNet never gets the ModEvent. Prefer notifications over `DOMOnOrgasm` (faster; leave Orgasm unregistered to avoid double `DOMSlave_Orgasmed`). |
| Actor lock key | Scene eligibility uses StorageUtil `skyrimnet_sexlab_scene_actor_lock` (shared with SkyrimNet_SexLab). |

## SkyrimNet Beta 25 content plugin (2026-09-13)

Beta 25 does not read `prompts/`, `config/triggers/`, or `config/actions/`. LLM content ships as `SKSE/Plugins/SkyrimNet/external/goodprovider.dom/` (`manifest.json` `id` must equal the folder name). Prompt paths inside the plugin are unchanged (`prompts/helpers/…`, submodules). Action YAML filename (before `.yaml`) must equal the in-file `name` (case-insensitive); keep `name` casing. Trigger `Healing Hands` became `Healing_Hands`. Settings schema stays at `config/plugins/SkyrimNet_DOM/manifest.yaml` (`schema.fields` + `defaultValue`; `plugin.name` SkyrimNet_DOM, `dom.events.*` keys) — that is not a content-plugin folder. Papyrus reads `Plugin_SkyrimNet_DOM` via `GetConfig*`. Item YAML stays at `config/items/`. JSON under `SKSE/Plugins/SkyrimNet_DOM/` is unchanged. Do not ship into `library/`. Upstream: SkyrimNet `docs/modding/MIGRATING_TO_BETA25.md`.

Pyro compile: `RaceMenu\scripts\source` is not in this mods tree. `skyrimse.ppj` imports `Headers_Source/NiOverride.psc` (stub) so SexLab's `sslActorAlias` can type-check. Do not ship that header as a runtime replacement for RaceMenu.

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

## Shared engine gotchas

See the short list in [AGENTS.md](AGENTS.md). Expand here when a session proves a SE/VR or Papyrus quirk for this project.
