# DOM events → SkyrimNet

How Diary of Mine activity reaches the LLM: Direct Narration, aged notifications, and SkyrimNet events. Source: [`SkyrimNet_DOM_Events.psc`](../../Scripts/Source/SkyrimNet_DOM_Events.psc).

See also: [../developers/papyrus.md](../developers/papyrus.md) · [prompts.md](prompts.md) · [punishment.md](punishment.md)

## Why chat can be quiet

DOM emits far more activity than we forward as Direct Narration. Much of it lands in history, short-lived events, or a per-actor **notification ring buffer** that bio prompts age into minutes/hours/days. Occasional manual Direct Narration still helps frame the story you want (see [../players/overview.md](../players/overview.md)).

## Delivery paths

| Path | When | Effect |
|------|------|--------|
| `DirectNarration` | High-signal moments that should speak now | DN via SkyrimNet_SexLab utilities; always runs `SaveActorInfo` first |
| `DirectNarration_Optional` | Most ModEvent / notification handlers | Tries optional DN; on decline → `AddNotification` |
| `RegisterEvent` | Structured facts (e.g. lost virginity, reason to punish) | SkyrimNet event history (not necessarily DN) |
| `RegisterShortLivedEvent` | Ephemeral context | TTL’d event; expires from short-lived store |

`AddPunishmentReason` (API) uses `RegisterEvent("Reason to Punish", …)` — see [punishment.md](punishment.md).

## SaveActorInfo (paused bio JSON)

Every DN / optional-DN path calls `SaveActorInfo(slave)`, which writes:

```
Data/SKSE/Plugins/SkyrimNet_DOM/actors/<DisplayName>.json
```

That file is what prompts use when time is paused (`read_json("SkyrimNet_DOM/actors/<name>.json")`). Live play prefers the `dom_get_actor_info` decorator instead. See [prompts.md](prompts.md). Keys: [../reference/json-keys.md](../reference/json-keys.md).

## What is registered today

On Setup, Events enables DOM external Ext / Ext1 / **Ext3** via **`DOM_API.SetSendExternalEvents*`** (`main.d_api` on quest `DOM01`) and registers a **subset** of ModEvents, plus SexLab anim hooks. Do not call those toggles on `DOM_Core` — they are not runtime methods there. Dashboard settings live at `SKSE/Plugins/SkyrimNet/config/plugins/SkyrimNet_DOM/manifest.yaml` (`dom.events.*`); Papyrus reads `Plugin_SkyrimNet_DOM` via `GetConfig*`.

**Live (examples):** `DOMOnCallForHelp`, `DOMOnKinkDiscovered`, `DOMOnLostVirginity`, `DOMOnRunaway`, `DOMOnMoodChange`, `DOMOnBehaviourChange`, `DOMOnNotificationSent` (needs Ext3), `HookAnimationStart` / `HookAnimationEnd`.

**Ext2 (off by default):** `dom.events.ext2` in the SkyrimNet dashboard. When on, `SetSendExternalEventsExt2(true)` and Ext2 handlers (`DOMOnPraised`, `DOMOnPunished`, inspections, comfort, etc.) register. Default off is spam control. `DOMOnSex` stays with SkyrimNet_SexLab.

**Orgasm feed:** Prefer `DOMOnNotificationSent` over `DOMOnOrgasm` (notifications arrive faster in testing). `DOMOnOrgasm` stays unregistered to avoid double-calling `DOMSlave_Orgasmed`. Only Dom melt/climax phrasing (`brain melts`, `mind melts`, `overwhelmed by orgasm`, `submerged by orgasm`, and not `your orgasm`) is routed to `SkyrimNet_SexLab_Handler_DOM`; that branch returns (no DN from Events — Handler / OrgasmCustom owns DN). Do **not** match bare `"orgasm"`: the player-climax tease (`squirms under your grasp as your orgasm submerges you`) is `OnNotifcationSkip` (no DN, no notification ring). Orgasm-control HUD is also not a climax. Without Ext3, melt HUD still shows but ModEvent never fires → SexLab Combined can deny Dom slaves or narrate Bob-only while Dom melt fired.

## Notification ring buffer

`AddNotification` keeps a per-actor ring (JMap keyed by FormID), with game-time stamps. Size is `dom.events.notification_ring` (default **20**). New rings use the current size; existing rings keep theirs until you load a save. A duplicate anywhere in the ring refreshes its timestamp and moves to newest. It also fans out via `AddNotificationActor` to other DOM actors whose display name appears in the text. Bio slice `7200_dom_notifications.prompt` ages these into human-readable windows.

`OnNotificationSent` skips noise via `OnNotifcationSkip` (including generic trainer/trainee/follow/fetch lines and `"was just captured"`). Player / non-actor / non-slave early returns are currently commented out — delivery is wider than “DOM slave only.”

**Capture / abduction:** `StartMood` “was just captured” is too late (end of Mind `AfterAssign` / `SetPersonality`). Events instead scans `DOM02.actorAliases` every 2s (`GetMaxActorCount`). `GetActorCount` / `actorArray` stay empty until `UpdateActorArray` after Mind `AfterAssign`. A new player-owned alias (`mind.is_player_slave`) gets required `DirectNarration` (`OnCaptureAssigned`) once per FormID. Existing aliases are seeded on load. Do not hang capture DN on `notificationType == "freshly captured"` — that type is also used for personality/training blurbs.

## SexLab hooks

`HookAnimationStart` / `HookAnimationEnd` keep scene state in sync with SkyrimNet_SexLab. Scene **starts** from YAML go through [actions.md](actions.md) → `SkyrimNet_DOM_Actions` → SexLab scene helpers, not through these ModEvents.

## Tips

- Prefer changing handlers or DN text in `SkyrimNet_DOM_Events` over editing Diary of Mine.
- If something “never shows up,” check whether its ModEvent is registered, whether Ext toggles were set on `d_api` (not `d_core`), whether Ext3 is on for notifications, and whether it uses optional DN vs `RegisterEvent` only. Capture/abduction DN is `OnCaptureAssigned` (new `DOM02` alias), not `OnNotificationSent`.
- Re-enable Ext2 only deliberately (dashboard **Enable Ext2 events**) — DOM is spammy; optional DN + notifications exist to absorb volume.
