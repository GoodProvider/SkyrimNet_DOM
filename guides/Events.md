# DOM events → SkyrimNet

How Diary of Mine activity reaches the LLM: Direct Narration, aged notifications, and SkyrimNet events. Source: [`SkyrimNet_DOM_Events.psc`](../Scripts/Source/SkyrimNet_DOM_Events.psc).

See also: [README](../README.md) · [Code](Code.md) · [Prompts](Prompts.md)

## Why chat can be quiet

DOM emits far more activity than we forward as Direct Narration. Much of it lands in history, short-lived events, or a per-actor **notification ring buffer** that bio prompts age into minutes/hours/days. Occasional manual Direct Narration still helps frame the story you want (see README Notes).

## Delivery paths

| Path | When | Effect |
|------|------|--------|
| `DirectNarration` | High-signal moments that should speak now | DN via SkyrimNet_SexLab utilities; always runs `SaveActorInfo` first |
| `DirectNarration_Optional` | Most ModEvent / notification handlers | Tries optional DN; on decline → `AddNotification` |
| `RegisterEvent` | Structured facts (e.g. lost virginity, reason to punish) | SkyrimNet event history (not necessarily DN) |
| `RegisterShortLivedEvent` | Ephemeral context | TTL’d event; expires from short-lived store |

`AddPunishmentReason` (API) uses `RegisterEvent("Reason to Punish", …)` — see [Punishment](Punishment.md).

## SaveActorInfo (paused bio JSON)

Every DN / optional-DN path calls `SaveActorInfo(slave)`, which writes:

```
Data/SKSE/Plugins/SkyrimNet_DOM/actors/<DisplayName>.json
```

That file is what prompts use when time is paused (`read_json("SkyrimNet_DOM/actors/<name>.json")`). Live play prefers the `dom_get_actor_info` decorator instead. See [Prompts](Prompts.md).

## What is registered today

On Setup, Events enables DOM external Ext / Ext1 and registers a **subset** of ModEvents, plus SexLab anim hooks:

**Live (examples):** `DOMOnCallForHelp`, `DOMOnKinkDiscovered`, `DOMOnLostVirginity`, `DOMOnRunaway`, `DOMOnMoodChange`, `DOMOnBehaviourChange`, `DOMOnNotificationSent`, `HookAnimationStart` / `HookAnimationEnd`.

**Not enabled:** `SetSendExternalEventsExt2` is commented out. Many Ext2 handlers (`DOMOnPraised`, `DOMOnPunished`, inspections, comfort, etc.) exist in the script but are not registered — do not assume every DOM Ext2 path fires here.

Orgasm text in `DOMOnNotificationSent` is routed to `SkyrimNet_SexLab_Handler_DOM` when present, then returns (no DN from that branch).

## Notification ring buffer

`AddNotification` keeps up to **20** recent messages per actor (JMap keyed by FormID), with game-time stamps. Duplicates of the last message are skipped. Bio slice `7200_dom_notifications.prompt` ages these into human-readable windows.

`OnNotificationSent` skips some noise (`OnNotifcationSkip`), skips the player, and requires a DOM slave. Freshly-captured text may be rewritten to include a capture beat before optional DN.

## SexLab hooks

`HookAnimationStart` / `HookAnimationEnd` keep scene state in sync with SkyrimNet_SexLab. Scene **starts** from YAML go through [Actions](Actions.md) → `SkyrimNet_DOM_Actions` → SexLab scene helpers, not through these ModEvents.

## Tips

- Prefer changing handlers or DN text in `SkyrimNet_DOM_Events` over editing Diary of Mine.
- If something “never shows up,” check whether its ModEvent is registered and whether it uses optional DN vs `RegisterEvent` only.
- Re-enable Ext2 only deliberately — DOM is spammy; optional DN + notifications exist to absorb volume.
